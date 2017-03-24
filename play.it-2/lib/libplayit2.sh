#!/bin/sh

###
# Copyright (c) 2015-2017, Antoine Le Gonidec
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# This software is provided by the copyright holders and contributors "as is"
# and any express or implied warranties, including, but not limited to, the
# implied warranties of merchantability and fitness for a particular purpose
# are disclaimed. In no event shall the copyright holder or contributors be
# liable for any direct, indirect, incidental, special, exemplary, or
# consequential damages (including, but not limited to, procurement of
# substitute goods or services; loss of use, data, or profits; or business
# interruption) however caused and on any theory of liability, whether in
# contract, strict liability, or tort (including negligence or otherwise)
# arising in any way out of the use of this software, even if advised of the
# possibility of such damage.
###

###
# common functions for ./play.it scripts
# send your bug reports to vv221@dotslashplay.it
###

library_version=2.0
library_revision=20170323.1

# build .pkg.tar package, .deb package or .tar archive
# USAGE: build_pkg $pkg[…]
# NEEDED VARS: $pkg_PATH, PACKAGE_TYPE
# CALLS: testvar, liberror, build_pkg_arch, build_pkg_deb, build_pkg_tar
build_pkg() {
	for pkg in $@; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'build_pkg'
		local pkg_path="$(eval echo \$${pkg}_PATH)"
		case $PACKAGE_TYPE in
			('arch')
				build_pkg_arch
			;;
			('deb')
				build_pkg_deb
			;;
			(*)
				liberror 'PACKAGE_TYPE' 'build_pkg'
			;;
		esac
	done
}

# build .pkg.tar package
# USAGE: build_pkg_arch
# NEEDED VARS: PLAYIT_WORKDIR, COMPRESSION_METHOD
# CALLS: build_pkg_print
# CALLED BY: build_pkg
build_pkg_arch() {
	local pkg_filename="${PWD}/${pkg_path##*/}.pkg.tar"
	local tar_options='--create --group=root --owner=root'
	case $COMPRESSION_METHOD in
		('gzip')
			tar_options="$tar_options --gzip"
			pkg_filename="${pkg_filename}.gz"
		;;
		('xz')
			tar_options="$tar_options --xz"
			pkg_filename="${pkg_filename}.xz"
		;;
		('none') ;;
		(*)
			liberror 'PACKAGE_TYPE' 'build_pkg'
		;;
	esac
	build_pkg_print
	(
		cd "$pkg_path"
		local files="* .PKGINFO"
		if [ -e '.INSTALL' ]; then
			files="$files .INSTALL"
		fi
		tar $tar_options --file "$pkg_filename" $files
	)
	export ${pkg}_PKG="$pkg_filename"
}

# build .deb package
# USAGE: build_pkg_deb
# NEEDED VARS: PLAYIT_WORKDIR, COMPRESSION_METHOD
# CALLS: build_pkg_print
# CALLED BY: build_pkg
build_pkg_deb() {
	local pkg_filename="${PWD}/${pkg_path##*/}.deb"
	local dpkg_options="-Z$COMPRESSION_METHOD"
	build_pkg_print
	TMPDIR="$PLAYIT_WORKDIR" fakeroot -- dpkg-deb $dpkg_options --build "$pkg_path" "$pkg_filename" 1>/dev/null
	export ${pkg}_PKG="$pkg_filename"
}

# print package building message
# USAGE: build_pkg_print
# CALLED BY: build_pkg_deb, build_pkg_tar
build_pkg_print() {
	local string
	case ${LANG%_*} in
		('fr')
			string='Construction de %s\n'
		;;
		('en'|*)
			string='Building %s\n'
		;;
	esac
	printf "$string" "${pkg_filename##*/}"
}

# check script dependencies
# USAGE: check_deps
# NEEDED VARS: ARCHIVE_TYPE, SCRIPT_DEPS, CHECKSUM_METHOD, PACKAGE_TYPE
# CALLS: check_deps_7z, check_deps_icon, check_deps_failed
check_deps() {
	case "$ARCHIVE_TYPE" in
		('innosetup')
			SCRIPT_DEPS="$SCRIPT_DEPS innoextract"
		;;
		('nixstaller')
			SCRIPT_DEPS="$SCRIPT_DEPS gzip tar unxz"
		;;
		('mojosetup')
			SCRIPT_DEPS="$SCRIPT_DEPS bsdtar"
		;;
		('zip')
			SCRIPT_DEPS="$SCRIPT_DEPS unzip"
		;;
		('rar')
			SCRIPT_DEPS="$SCRIPT_DEPS unar"
		;;
		('tar.gz')
			SCRIPT_DEPS="$SCRIPT_DEPS gzip tar"
		;;
	esac
	if [ "$CHECKSUM_METHOD" = 'md5sum' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS md5sum"
	fi
	if [ "$PACKAGE_TYPE" = 'deb' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS fakeroot dpkg"
	fi
	if [ "${APP_MAIN_ICON##*.}" = 'ico' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS icotool"
	fi
	for dep in $SCRIPT_DEPS; do
		case $dep in
			('7z')
				check_deps_7z
			;;
			('convert'|'icotool'|'wrestool')
				check_deps_icon "$dep"
			;;
			(*)
				if ! which $dep >/dev/null 2>&1; then
					check_deps_failed "$dep"
				fi
			;;
		esac
	done
}

# check presence of a software to handle .7z archives
# USAGE: check_deps_7z
# CALLS: check_deps_failed
# CALLED BY: check_deps
check_deps_7z() {
	if which 7zr >/dev/null 2>&1; then
		extract_7z() { 7zr x -o"$2" -y "$1"; }
	elif which 7za >/dev/null 2>&1; then
		extract_7z() { 7za x -o"$2" -y "$1"; }
	elif which unar >/dev/null 2>&1; then
		extract_7z() { unar -output-directory "$2" -force-overwrite -no-directory "$1"; }
	else
		check_deps_failed 'p7zip'
	fi
}

# check presence of a software to handle icon extraction
# USAGE: check_deps_icon $command_name
# NEEDED VARS: NO_ICON
# CALLED BY: check_deps
check_deps_icon() {
	if [ -z "$(which $1 2>/dev/null)" ] && [ "$NO_ICON" != '1' ]; then
		NO_ICON='1'
		case ${LANG%_*} in
			('fr')
				printf '%s est introuvable. Les icônes ne seront pas extraites.\n' "$1"
			;;
			('en'|*)
				printf '%s not found. Skipping icons extraction.\n' "$1"
			;;
		esac
	fi
}

# display a message if a required dependency is missing
# USAGE: check_deps_failed $command_name
# CALLED BY: check_deps, check_deps_7z
check_deps_failed() {
	print_error
	case ${LANG%_*} in
		('fr')
			printf '%s est introuvable. Installez-le avant de lancer ce script.\n' "$1"
		;;
		('en'|*)
			printf '%s not found. Install it before running this script.\n' "$1"
		;;
	esac
	return 1
}

# extract data from given archive
# USAGE: extract_data $archive[…]
# NEEDED_VARS: $PLAYIT_WORKDIR $ARCHIVE $ARCHIVE_TYPE $ARCHIVE_PASSWD
# CALLS: liberror extract_7z (declared by check_deps_7z)
extract_data_from() {
	for file in "$@"; do
		extract_data_from_print
		local destination="${PLAYIT_WORKDIR}/gamedata"
		mkdir --parents "$destination"
		case "$(eval echo \$${ARCHIVE}_TYPE)" in
			('7z')
				extract_7z "$file" "$destination"
			;;
			('innosetup')
				innoextract --extract --lowercase --output-dir "$destination" --progress=1 --silent "$file"
			;;
			('mojosetup')
				bsdtar --directory "$destination" --extract --file "$file"
				fix_rights "$destination"
			;;
			('mojosetup_unzip')
				unzip -d "$destination" "$file" 1>/dev/null 2>&1 || true
				fix_rights "$destination"
			;;
			('nix_stage1')
				local input_blocksize=$(head --lines=514 "$file" | wc --bytes | tr --delete ' ')
				dd if="$file" ibs=$input_blocksize skip=1 obs=1024 conv=sync 2>/dev/null | gunzip --stdout | tar --extract --file - --directory "$destination"
			;;
			('nix_stage2')
				tar --extract --xz --file "$file" --directory "$destination"
			;;
			('rar')
				if [ -n "$ARCHIVE_PASSWD" ]; then
					UNAR_OPTIONS="-password \"$ARCHIVE_PASSWD\""
				fi
				unar -no-directory -output-directory "$destination" $UNAR_OPTIONS "$file" 1>/dev/null
			;;
			('tar'|'tar.gz')
				tar --extract --file "$file" --directory "$destination"
			;;
			('zip')
				unzip -d "$destination" "$file" 1>/dev/null
			;;
			(*)
				liberror 'ARCHIVE_TYPE' 'extract_data_from'
			;;
		esac
	done
}

# print data extraction message
# USAGE: extract_data_from_print
# CALLED BY: extract_data_from
extract_data_from_print() {
	local file="$(basename "$file")"
	case ${LANG%_*} in
		('fr')
			printf 'Extraction des données de %s\n' "$file"
		;;
		('en'|*)
			printf 'Extracting data from %s \n' "$file"
		;;
	esac
}

# parse arguments given to the script
# USAGE: fetch_args $argument[…]
# CALLS: fetch_args_set_var
fetch_args() {
	unset CHECKSUM_METHOD
	unset COMPRESSION_METHOD
	unset GAME_LANG
	unset GAME_LANG_AUDIO
	unset GAME_LANG_TXT
	unset ICON_CHOICE
	unset INSTALL_PREFIX
	unset MOVIES_SUPPORT
	unset PACKAGE_TYPE
	unset SOURCE_ARCHIVE
	for arg in "$@"; do
		case "$arg" in
			('--checksum='*)
				export CHECKSUM_METHOD="${arg#*=}"
			;;
			('--compression='*)
				export COMPRESSION_METHOD="${arg#*=}"
			;;
			('--icon='*)
				export ICON_CHOICE="${arg#*=}"
			;;
			('--prefix='*)
				export INSTALL_PREFIX="${arg#*=}"
			;;
			('--lang='*)
				export GAME_LANG="${arg#*=}"
			;;
			('--lang-audio='*)
				export GAME_LANG_AUDIO="${arg#*=}"
			;;
			('--lang-txt='*)
				export GAME_LANG_TXT="${arg#*=}"
			;;
			('--package='*)
				export PACKAGE_TYPE="${arg#*=}"
			;;
			('--movies=')
				export MOVIES_SUPPORT="${arg#*=}"
			;;
			('--'*)
				return 1
			;;
			(*)
				export SOURCE_ARCHIVE="$arg"
			;;
		esac
	done
	fetch_args_set_var 'CHECKSUM_METHOD'
	fetch_args_set_var 'COMPRESSION_METHOD'
	fetch_args_set_var 'GAME_LANG'
	fetch_args_set_var 'GAME_LANG_AUDIO'
	fetch_args_set_var 'GAME_LANG_TXT'
	fetch_args_set_var 'INSTALL_PREFIX'
	fetch_args_set_var 'MOVIES_SUPPORT'
	fetch_args_set_var 'PACKAGE_TYPE'
}

# set global vars not already set by script arguments
# USAGE: fetch_args_set_var $var_name
# CALLED BY: fetch_args
fetch_args_set_var() {
	local value="$(eval echo \$$1)"
	if [ -z "$value" ]; then
		local value_default="$(eval echo \$DEFAULT_$1)"
		if [ -n "$value_default" ]; then
			export $1="$value_default"
		fi
	fi
}

# check integrity of target file
# USAGE: file_checksum $file
# NEEDED VARS: CHECKSUM_METHOD
# CALLS: file_checksum_md5, file_checksum_none, liberror
file_checksum() {
	case $CHECKSUM_METHOD in
		('md5')
			file_checksum_md5 "$1"
		;;
		('none')
			return 0
		;;
		(*)
			liberror 'CHECKSUM_METHOD' 'file_checksum'
		;;
	esac
}

# check integrity of target file against MD5 control sum
# USAGE: file_checksum_md5 $file
# NEEDED VARS: ARCHIVE ARCHIVE_MD5
# CALLS: file_checksum_print, file_checksum_error
# CALLED BY: file_checksum
file_checksum_md5() {
	file_checksum_print "$(basename "$1")"
	FILE_MD5="$(md5sum "$1" | cut --delimiter=' ' --fields=1)"
	if [ "$FILE_MD5" = "$(eval echo \$${ARCHIVE}_MD5)" ]; then
		return 0
	fi
	file_checksum_error "$1"
	return 1
}

# print integrity check message
# USAGE: file_checksum_print $file_name
# CALLED BY: file_checksum_md5
file_checksum_print() {
	local string
	case ${LANG%_*} in
		('fr')
			string='Contrôle de l’intégrité de %s\n'
		;;
		('en'|*)
			string='Checking integrity of %s\n'
		;;
	esac
	printf "$string" "$1"
}

# print integrity check error message
# USAGE: file_checksum_error $file
# CALLED BY: file_checksum_md5
file_checksum_error() {
	print_error
	local string1
	local string2
	case ${LANG%_*} in
		('fr')
			string1='Somme de contrôle incohérente. %s n’est pas le fichier attendu.\n'
			string2='Utilisez --checksum=none pour forcer son utilisation.\n'
		;;
		('en'|*)
			string1='Hashsum mismatch. %s is not the expected file.\n'
			string2='Use --checksum=none to force its use.\n'
		;;
	esac
	printf "$string1" "$1"
	printf "$string2"
}

# set defaults rights on files (755 for dirs & 644 for regular files)
# USAGE: fix_rights $dir[…]
fix_rights() {
	for dir in "$@"; do
		if [ ! -d "$dir" ]; then
			return 1
		fi
		find "$dir" -type d -exec chmod 755 '{}' +
		find "$dir" -type f -exec chmod 644 '{}' +
	done
}

# extract .png or .ico files from given file
# USAGE: extract_icon_from $file[…]
# NEEDED VARS: $PLAYIT_WORKDIR
# CALLS: liberror
extract_icon_from() {
	for file in "$@"; do
		local destination="$PLAYIT_WORKDIR/icons"
		mkdir --parents "$destination"
		case ${file##*.} in
			('exe')
				if [ "$WRESTOOL_NAME" ]; then
					WRESTOOL_OPTIONS="--name=$WRESTOOL_NAME"
				fi
				wrestool --extract --type=14 $WRESTOOL_OPTIONS --output="$destination" "$file"
			;;
			('ico')
				icotool --extract --output="$destination" "$file" 2>/dev/null
			;;
			('bmp')
				local filename="${file##*/}"
				convert "$file" "$destination/${filename%.bmp}.png"
			;;
			(*)
				liberror 'file_ext' 'extract_icon_from'
			;;
		esac
	done
}

# create icons tree
# USAGE: sort_icons $app
# NEEDED VARS: $app_ID, $app_ICON_RES, PKG, $PKG_PATH, PACKAGE_TYPE
# CALLS: sort_icons_arch, sort_icons_deb, sort_icons_tar
sort_icons() {
for app in $@; do
	testvar "$app" 'APP' || liberror 'app' 'sort_icons'
	local app_id="$(eval echo \$${app}_ID)"
	if [ -z "$app_id" ]; then
		app_id="$GAME_ID"
	fi
	local icon_res="$(eval echo \$${app}_ICON_RES)"
	local pkg_path="$(eval echo \$${PKG}_PATH)"
	case $PACKAGE_TYPE in
		('arch')
			sort_icons_arch
		;;
		('deb')
			sort_icons_deb
		;;
		(*)
			liberror 'PACKAGE_TYPE' 'sort_icons'
		;;
	esac
done
}

# create icons tree for .pkg.tar.xz package
# USAGE: sort_icons_arch
# NEEDED VARS: PATH_ICON_BASE, PLAYIT_WORKDIR
# CALLED BY: sort_icons
sort_icons_arch() {
	for res in $icon_res; do
		path_icon="${PATH_ICON_BASE}/${res}/apps"
		mkdir -p "${pkg_path}${path_icon}"
		for file in "${PLAYIT_WORKDIR}"/icons/*${res}x*.png; do
			mv "${file}" "${pkg_path}${path_icon}/${app_id}.png"
		done
	done
}

# create icons tree for .deb package
# USAGE: sort_icons_deb
# NEEDED VARS: PATH_ICON_BASE, PLAYIT_WORKDIR
# CALLED BY: sort_icons
sort_icons_deb() {
	for res in $icon_res; do
		path_icon="${PATH_ICON_BASE}/${res}/apps"
		mkdir -p "${pkg_path}${path_icon}"
		for file in "${PLAYIT_WORKDIR}"/icons/*${res}x*.png; do
			mv "${file}" "${pkg_path}${path_icon}/${app_id}.png"
		done
	done
}

# extract and sort icons from given .ico or .exe file
# USAGE: extract_and_sort_icons_from $app[…]
# NEEDED VARS: $NO_ICON $PLAYIT_WORKDIR $APP_ID $APP_ICON $APP_ICON_RES $PKG
# 	$PKG_PATH $PACKAGE_TYPE $PATH_GAME
# CALLS: liberror extract_icon_from sort_icons
extract_and_sort_icons_from() {
	local app_icon
	local pkg_path="$(eval echo \$${PKG}_PATH)"
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'sort_icons'
		if [ "$NO_ICON" = '0' ]; then
			app_icon="$(eval echo \$${app}_ICON)"
			extract_icon_from "${pkg_path}${PATH_GAME}/$app_icon"
			if [ "${app_icon##*.}" = 'exe' ]; then
				extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
			fi
			sort_icons "$app"
			rm --recursive "$PLAYIT_WORKDIR/icons"
		fi
	done
}

# display an error if a function has been called with invalid arguments
# USAGE: liberror $var_name $calling_function
liberror() {
	local var="$1"
	local value="$(eval echo \$$var)"
	local func="$2"
	print_error
	case ${LANG%_*} in
		('fr')
			printf 'valeur incorrecte pour %s appelée par %s : %s\n' "$var" "$func" "$value"
		;;
		('en'|*)
			printf 'invalid value for %s called by %s: %s\n' "$var" "$func" "$value"
		;;
	esac
	return 1
}

# put files from archive in the right package directories (alias)
# USAGE: organize_data
# CALLS: organize_data_generic
organize_data() {
	if [ -n "${ARCHIVE_DOC_PATH}" ]; then
		organize_data_generic 'DOC'  "$PATH_DOC"
	fi
	if [ -n "${ARCHIVE_DOC1_PATH}" ]; then
		organize_data_generic 'DOC1' "$PATH_DOC"
	fi
	if [ -n "${ARCHIVE_DOC2_PATH}" ]; then
		organize_data_generic 'DOC2' "$PATH_DOC"
	fi
	if [ -n "${ARCHIVE_GAME_PATH}" ]; then
		organize_data_generic 'GAME' "$PATH_GAME"
	fi
}

# put files from archive in the right package directories (generic function)
# USAGE: organize_data_generic $id $path
# NEEDED VARS: $PKG, $PKG_PATH, $PLAYIT_WORKDIR
# CALLED BY: organize_data
organize_data_generic() {
	local archive_path="$(eval echo \$ARCHIVE_${1}_PATH)"
	if [ "$archive_path" ] && [ -e "$PLAYIT_WORKDIR/gamedata/$archive_path" ]; then
		local pkg_path="$(eval echo \$${PKG}_PATH)${2}"
		mkdir --parents "$pkg_path"
		(
			cd "$PLAYIT_WORKDIR/gamedata/$archive_path"
			for file in $(eval echo \$ARCHIVE_${1}_FILES); do
				if [ -e "$file" ]; then
					cp --recursive --link --parents "$file" "$pkg_path"
					rm --recursive "$file"
				fi
			done
		)
	fi
}

# print a localized error message
# USAGE: print_error
print_error() {
	case ${LANG%_*} in
		('fr')
			printf '\n\033[1;31mErreur :\033[0m\n'
		;;
		('en'|*)
			printf '\n\033[1;31mError:\033[0m\n'
		;;
	esac
}

# print installation instructions
# USAGE: print_instructions $pkg[…]
# NEEDED VARS: PKG
print_instructions() {
	case ${LANG%_*} in
		('fr')
			printf '\nInstallez %s en lançant la série de commandes suivantes en root :\n' "$GAME_NAME"
		;;
		('en'|*)
			printf '\nInstall %s by running the following commands as root:\n' "$GAME_NAME"
		;;
	esac
	case $PACKAGE_TYPE in
		('arch')
			printf 'pacman -U'
			for pkg in $@; do
				printf ' %s' "$pkg"
			done
			printf '\n'
		;;
		('deb')
			printf 'dpkg -i'
			for pkg in $@; do
				printf ' %s' "$pkg"
			done
			printf '\n'
			printf 'apt-get install -f\n'
		;;
		(*)
			liberror 'PACKAGE_TYPE' 'build_pkg'
		;;
	esac
	printf '\n'
}

# set package distribution-specific architecture
# USAGE: set_arch
# NEEDED VARS: $PACKAGE_TYPE
# CALLED BY: set_workdir_pkg write_metadata
set_arch() {
	case $PACKAGE_TYPE in

		('arch')
			case "$(eval echo \$${pkg}_ARCH)" in
				('32'|'64')
					pkg_arch='x86_64'
				;;
				(*)
					pkg_arch='any'
				;;
			esac
		;;

		('deb')
			case "$(eval echo \$${pkg}_ARCH)" in
				('32')
					pkg_arch='i386'
				;;
				('64')
					pkg_arch='amd64'
				;;
				(*)
					pkg_arch='all'
				;;
			esac
		;;

	esac
}

# set archive for data extraction
# USAGE: set_archive $name $archive[…]
# NEEDED_VARS: SOURCE_ARCHIVE
# CALLS: set_archive_print
set_archive() {
	local name=$1
	shift 1
	for archive in "$@"; do
		if [ -f "$archive" ]; then
			export $name="$archive"
			set_archive_print "$archive"
			return 0
		elif [ -f "${SOURCE_ARCHIVE%/*}/$archive" ]; then
			export $name="${SOURCE_ARCHIVE%/*}/$archive"
			set_archive_print "${SOURCE_ARCHIVE%/*}/$archive"
			return 0
		fi
	done
	unset $name
}

# set source archive for data extraction
# USAGE: set_source_archive $archive[…]
# NEEDED_VARS: SOURCE_ARCHIVE
# CALLS: set_source_archive_vars set_source_archive_error set_archive_print
set_source_archive() {
	for archive in "$@"; do
		file="$(eval echo \$$archive)"
		if [ -n "$SOURCE_ARCHIVE" ] && [ "${SOURCE_ARCHIVE##*/}" = "$file" ]; then
			ARCHIVE="$archive"
			set_archive_print "$SOURCE_ARCHIVE"
			set_source_archive_vars
			return 0
		elif [ -z "$SOURCE_ARCHIVE" ] && [ -f "$file" ]; then
			SOURCE_ARCHIVE="$file"
			ARCHIVE="$archive"
			set_archive_print "$SOURCE_ARCHIVE"
			set_source_archive_vars
			return 0
		fi
	done
	if [ -z "$SOURCE_ARCHIVE" ]; then
		set_source_archive_error_not_found
	fi
}

# set archive-related vars
# USAGE: set_source_archive_vars
# NEEDED_VARS: ARCHIVE ARCHIVE_MD5 ARCHIVE_TYPE ARCHIVE_UNCOMPRESSED_SIZE
# CALLS: set_source_archive_error_no_type
# CALLED BY: set_source_archive file_checksum
set_source_archive_vars() {
	ARCHIVE_TYPE="$(eval echo \$${archive}_TYPE)"
	if [ -z "$ARCHIVE_TYPE" ]; then
		case "${SOURCE_ARCHIVE##*/}" in
			(gog_*.sh)
				ARCHIVE_TYPE='mojosetup'
			;;
			(setup_*.exe|patch_*.exe)
				ARCHIVE_TYPE='innosetup'
			;;
			(*.zip)
				ARCHIVE_TYPE='zip'
			;;
			(*.tar.gz)
				ARCHIVE_TYPE='tar.gz'
			;;
			(*)
				set_source_archive_error_no_type
			;;
		esac
		eval ${archive}_TYPE=$ARCHIVE_TYPE
	fi
	ARCHIVE_MD5="$(eval echo \$${archive}_MD5)"
	ARCHIVE_UNCOMPRESSED_SIZE="$(eval echo \$${archive}_UNCOMPRESSED_SIZE)"
	PKG_VERSION="$(eval echo \$${archive}_VERSION)"
}

# print archive use message
# USAGE: set_archive_print $file
# CALLED BY: set_archive set_source_archive
set_archive_print() {
	local string
	case ${LANG%_*} in
		('fr')
			string='Utilisation de %s\n'
		;;
		('en'|*)
			string='Using %s\n'
		;;
	esac
	printf "$string" "$1"
}

# display an error message telling the target archive has not been found
# USAGE: set_source_archive_error_not_found
# CALLED BY: set_source_archive
set_source_archive_error_not_found() {
	print_error
	case ${LANG%_*} in
		('fr')
			printf 'La cible de ce script est introuvable\n'
		;;
		('en'|*)
			printf 'The script target could not be found\n'
		;;
	esac
	return 1
}

# display an error message telling the type of the target archive is not set
# USAGE: set_source_archive_error_no_type
# CALLED BY: set_source_archive_vars
set_source_archive_error_no_type() {
	print_error
	case ${LANG%_*} in
		('fr')
			printf 'ARCHIVE_TYPE n’est pas défini pour %s\n' "$SOURCE_ARCHIVE"
		;;
		('en'|*)
			printf 'ARCHIVE_TYPE is not set for %s\n' "$SOURCE_ARCHIVE"
		;;
	esac
	return 1
}

# set default values for common vars
# USAGE: set_common_defaults
set_common_defaults() {
	DEFAULT_CHECKSUM_METHOD='md5'
	DEFAULT_COMPRESSION_METHOD='none'
	DEFAULT_GAME_LANG='en'
	DEFAULT_GAME_LANG_AUDIO='en'
	DEFAULT_GAME_LANG_TXT='en'
	DEFAULT_INSTALL_PREFIX='/usr/local'
	DEFAULT_ICON_CHOICE='original'
	DEFAULT_MOVIES_SUPPORT='0'
	NO_ICON='0'
	unset winecfg_desktop
	unset winecfg_launcher
	
	# Try to detect the host distribution through lsb_release
	if [ $(which lsb_release 2>/dev/null 2>&1) ]; then
		case "$(lsb_release -si)" in
			('Debian'|'Ubuntu')
				DEFAULT_PACKAGE_TYPE='deb'
			;;
			('Arch')
				DEFAULT_PACKAGE_TYPE='arch'
			;;
		esac
	fi
	# Fall back on deb format by default
	if ! [ "$DEFAULT_PACKAGE_TYPE" ]; then
		DEFAULT_PACKAGE_TYPE='deb'
	fi
}

# set package paths
# USAGE: set_common_paths
# NEEDED VARS: PACKAGE_TYPE
# CALLS: set_common_paths_arch, set_common_paths_deb, set_common_paths_tar, liberror
set_common_paths() {
	case $PACKAGE_TYPE in
		('arch')
			set_common_paths_arch
		;;
		('deb')
			set_common_paths_deb
		;;
		(*)
			liberror 'PACKAGE_TYPE' 'set_common_paths'
		;;
	esac
}

# set .pkg.tar.xz package paths
# USAGE: set_common_paths_arch
# NEEDED VARS: INSTALL_PREFIX, GAME_ID
# CALLED BY: set_common_paths
set_common_paths_arch() {
	PATH_BIN="${INSTALL_PREFIX}/bin"
	PATH_DESK='/usr/local/share/applications'
	PATH_DOC="${INSTALL_PREFIX}/share/doc/${GAME_ID}"
	PATH_GAME="${INSTALL_PREFIX}/share/${GAME_ID}"
	PATH_ICON_BASE='/usr/local/share/icons/hicolor'
}

# set .deb package paths
# USAGE: set_common_paths_deb
# NEEDED VARS: INSTALL_PREFIX, GAME_ID
# CALLED BY: set_common_paths
set_common_paths_deb() {
	PATH_BIN="${INSTALL_PREFIX}/games"
	PATH_DESK='/usr/local/share/applications'
	PATH_DOC="${INSTALL_PREFIX}/share/doc/${GAME_ID}"
	PATH_GAME="${INSTALL_PREFIX}/share/games/${GAME_ID}"
	PATH_ICON_BASE='/usr/local/share/icons/hicolor'
}

# set working directories
# USAGE: set_workdir $pkg[…]
# CALLS: set_workdir_workdir testvar set_workdir_pkg
set_workdir() {
	if [ $# = 1 ]; then
		PKG="$1"
	fi
	set_workdir_workdir
	mkdir --parents "$PLAYIT_WORKDIR/scripts"
	export postinst="$PLAYIT_WORKDIR/scripts/postinst"
	export prerm="$PLAYIT_WORKDIR/scripts/prerm"
	while [ $# -ge 1 ]; do
		local pkg=$1
		testvar "$pkg" 'PKG'
		set_workdir_pkg $pkg
		shift 1
	done
}

# set gobal working directory
# USAGE: set_workdir_workdir
# NEEDED VARS: $ARCHIVE $ARCHIVE_UNCOMPRESSED_SIZE
# CALLED BY: set_workdir
set_workdir_workdir() {
	local workdir_name=$(mktemp --dry-run ${GAME_ID}.XXXXX)
	local archive_size=$(eval echo \$${ARCHIVE}_UNCOMPRESSED_SIZE)
	local needed_space=$(($archive_size * 2))
	local free_space_tmp=$(df --output=avail /tmp | tail --lines=1)
	if [ $free_space_tmp -ge $needed_space ]; then
		export PLAYIT_WORKDIR="/tmp/play.it/${workdir_name}"
	else
		if [ ! -w "$XDG_CACHE_HOME" ]; then
			XDG_CACHE_HOME="${HOME}/.cache"
		fi
		local free_space_cache="$(df --output=avail "$XDG_CACHE_HOME" | tail --lines=1)"
		if [ $free_space_cache -ge $needed_space ]; then
			export PLAYIT_WORKDIR="${XDG_CACHE_HOME}/play.it/${workdir_name}"
		else
			export PLAYIT_WORKDIR="${PWD}/play.it/${workdir_name}"
		fi
	fi
}

# set package-secific working directory
# USAGE: set_workdir_pkg $pkg
# NEEDED VARS: $PKG_ID $PKG_VERSION $PKG_ARCH $PLAYIT_WORKDIR
# CALLED BY: set_workdir
set_workdir_pkg() {
	local pkg_id="$(eval echo \$${pkg}_ID)"
	if [ ! "$pkg_id" ]; then
		pkg_id="$GAME_ID"
	fi

	local pkg_version="$(eval echo \$${pkg}_VERSION)"
	if [ ! "$pkg_version" ]; then
		pkg_version="$PKG_VERSION"
	fi
	if [ ! "$pkg_version" ]; then
		pkg_version='1.0-1'
	fi

	local pkg_arch
	set_arch

	if [ "$PACKAGE_TYPE" = 'arch' ] && [ "$(eval echo \$${pkg}_ARCH)" = '32' ]; then
		local pkg_path="${PLAYIT_WORKDIR}/lib32-${pkg_id}_${pkg_version}_${pkg_arch}"
	else
		local pkg_path="${PLAYIT_WORKDIR}/${pkg_id}_${pkg_version}_${pkg_arch}"
	fi

	export ${pkg}_PATH="$pkg_path"
}

# test the validity of the argument given to parent function
# USAGE: testvar $var_name $pattern
testvar() {
	if [ -z "$(echo "$1" | grep ^${2})" ]; then
		return 1
	fi
}

# convert files name to lower case
# USAGE: tolower $dir[…]
tolower() {
	for dir in "$@"; do
		if [ ! -d "$dir" ]; then
			return 1
		fi
		find "$dir" -depth | while read file; do
			newfile="${file%/*}/$(echo "${file##*/}" | tr [:upper:] [:lower:])"
			if [ ! -e "$newfile" ] && [ "$file" != "$dir" ]; then
				mv "$file" "$newfile"
			fi
		done
	done
}

# write launcher script
# USAGE: write_bin $app
# NEEDED VARS: APP_ID APP_TYPE PKG PATH_BIN APP_EXE APP_OPTIONS APP_LIBS
# CALLS: liberror write_bin_header write_bin_set_vars write_bin_set_exe
# 	write_bin_set_prefix write_bin_build_userdirs write_bin_build_prefix
# 	write_bin_run
write_bin() {
	PKG_PATH="$(eval echo \$${PKG}_PATH)"
	local app
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'write_bin'
		local app_id="$(eval echo \$${app}_ID)"
		if [ -z "$app_id" ]; then
			app_id="$GAME_ID"
		fi
		local app_type="$(eval echo \$${app}_TYPE)"
		if [ "$winecfg_launcher" != 'done' ] && [ "$app_type" = 'wine' ]; then
			winecfg_launcher='done'
			write_bin_winecfg
		fi
		local file="${PKG_PATH}${PATH_BIN}/$app_id"
		mkdir --parents "${file%/*}"
		
		# Write launcher headers
		cat > "$file" <<- EOF
		#!/bin/sh
		set -o errexit
		EOF
		printf '\n' >> "$file"
		
		write_bin_set_vars
		if [ "$app_type" != 'scummvm' ]; then
			local app_exe="$(eval echo \$${app}_EXE)"
			local app_libs="$(eval echo \$${app}_LIBS)"
			local app_options="$(eval echo \$${app}_OPTIONS)"
			local app_prerun="$(eval echo \$${app}_PRERUN)"
			if [ -e "${PKG_PATH}${PATH_GAME}/$app_exe" ]; then
				chmod +x "${PKG_PATH}${PATH_GAME}/$app_exe"
			fi
			if [ "$app_id" != "${GAME_ID}_winecfg" ]; then
				write_bin_set_exe
			fi
			write_bin_set_prefix
			write_bin_build_userdirs
			write_bin_build_prefix
		fi
		write_bin_run
		sed -i 's/  /\t/g' "$file"
		chmod 755 "$file"
	done
}

# write winecfg launcher script
# USAGE: write_bin_winecfg
# NEEDED VARS: GAME_ID
# CALLS: write_bin
write_bin_winecfg() {
	APP_WINECFG_ID="${GAME_ID}_winecfg"
	APP_WINECFG_TYPE='wine'
	APP_WINECFG_EXE='winecfg'
	write_bin 'APP_WINECFG'
	local target="${PKG_PATH}${PATH_BIN}/$APP_WINECFG_ID"
	sed --in-place 's/# Run the game/# Run WINE configuration/' "$target"
	sed --in-place 's|cd "$PATH_PREFIX"||' "$target"
	sed --in-place 's|wine "$APP_EXE" $APP_OPTIONS $@|winecfg|' "$target"
}

# write launcher script - set common user-writables directories
# USAGE: write_bin_build_userdirs
write_bin_build_userdirs() {
	cat >> "$file" <<- EOF
	# Build user-writable directories
	
	if [ ! -e "\$PATH_CACHE" ]; then
	  mkdir --parents "\$PATH_CACHE"
	  init_userdir_dirs "\$PATH_CACHE" \$CACHE_DIRS
	  init_userdir_files "\$PATH_CACHE" \$CACHE_FILES
	fi
	if [ ! -e "\$PATH_CONFIG" ]; then
	  mkdir --parents "\$PATH_CONFIG"
	  init_userdir_dirs "\$PATH_CONFIG" \$CONFIG_DIRS
	  init_userdir_files "\$PATH_CONFIG" \$CONFIG_FILES
	fi
	if [ ! -e "\$PATH_DATA" ]; then
	  mkdir --parents "\$PATH_DATA"
	  init_userdir_dirs "\$PATH_DATA" \$DATA_DIRS
	  init_userdir_files "\$PATH_DATA" \$DATA_FILES
	fi
	
	EOF
}

# write launcher script - set WINE-specific user-writables directories
# USAGE: write_bin_build_userdirs_wine
write_bin_build_userdirs_wine() {
	cat >> "$file" <<- EOF
	export WINEPREFIX WINEARCH WINEDEBUG WINEDLLOVERRIDES
	if ! [ -e "\$WINEPREFIX" ]; then
	  mkdir --parents "\${WINEPREFIX%/*}"
	  wineboot --init 2>/dev/null
	EOF

	if [ "$APP_WINETRICKS" ]; then
		cat >> "$file" <<- EOF
		  winetricks $APP_WINETRICKS
		EOF
	fi

	cat >> "$file" <<- EOF
	  rm "\$WINEPREFIX/dosdevices/z:"
	fi
	EOF
}

# write launcher script - build game prefix
# USAGE: write_bin_build_prefix
write_bin_build_prefix() {
	cat >> "$file" <<- EOF
	# Build prefix
	
	EOF
	[ "$app_type" = 'wine' ] && write_bin_build_userdirs_wine
	cat >> "$file" <<- EOF
	if [ ! -e "\$PATH_PREFIX" ]; then
	  mkdir --parents "\$PATH_PREFIX"
	  cp --force --recursive --symbolic-link --update "\${PATH_GAME}"/* "\${PATH_PREFIX}"
	fi
	init_prefix_files "\$PATH_CACHE"
	init_prefix_files "\$PATH_CONFIG"
	init_prefix_files "\$PATH_DATA"
	init_prefix_dirs "\$PATH_CACHE" \$CACHE_DIRS
	init_prefix_dirs "\$PATH_CONFIG" \$CONFIG_DIRS
	init_prefix_dirs "\$PATH_DATA" \$DATA_DIRS
	
	EOF
}

# write launcher script - run the game, then clean the user-writable directories
# USAGE: write_bin_run
# CALLS: write_bin_run_dosbox write_bin_run_native write_bin_run_scummvm
# 	write_bin_run_wine
write_bin_run() {
	cat >> "$file" <<- EOF
	# Run the game
	EOF

	case $app_type in
		('dosbox')
			write_bin_run_dosbox
		;;
		('native')
			write_bin_run_native
		;;
		('scummvm')
			write_bin_run_scummvm
		;;
		('wine')
			write_bin_run_wine
		;;
	esac

	if [ $app_type != 'scummvm' ]; then
		cat >> "$file" <<- EOF
		clean_userdir "\$PATH_CACHE" \$CACHE_FILES
		clean_userdir "\$PATH_CONFIG" \$CONFIG_FILES
		clean_userdir "\$PATH_DATA" \$DATA_FILES
		EOF
	fi

	cat >> "$file" <<- EOF
	exit 0
	EOF
}

# write launcher script - run the DOSBox game
# USAGE: write_bin_run_dosbox
# CALLED BY: write_bin_run
write_bin_run_dosbox() {
	cat >> "$file" <<- EOF
	cd "\$PATH_PREFIX"
	dosbox -c "mount c .
	c:
	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	if [ "$GAME_IMAGE" ]; then
		cat >> "$file" <<- EOF
		imgmount d $GAME_IMAGE -t iso -fs iso
		EOF
	fi

	cat >> "$file" <<- EOF
	\$APP_EXE \$APP_OPTIONS \$@
	exit"
	EOF
}

# write launcher script - run the native game
# USAGE: write_bin_run_native
# CALLED BY: write_bin_run
write_bin_run_native() {
	cat >> "$file" <<- EOF
	cd "\$PATH_PREFIX"
	rm --force "\$APP_EXE"
	if [ -e "\$PATH_DATA/\$APP_EXE" ]; then
	  source_dir="\$PATH_DATA"
	else
	  source_dir="\$PATH_GAME"
	fi
	mkdir --parents "\$(dirname \$APP_EXE)"
	cp "\$source_dir/\$APP_EXE" "\$APP_EXE"
	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- EOF
	"./\$APP_EXE" \$APP_OPTIONS \$@
	EOF
}

# write launcher script - run the ScummVM game
# USAGE: write_bin_run_scummvm
# CALLED BY: write_bin_run
write_bin_run_scummvm() {
	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- EOF
	scummvm -p "\$PATH_PREFIX" \$APP_OPTIONS \$@ \$SCUMMVM_ID
	EOF
}

# write launcher script - run the WINE game
# USAGE: write_bin_run_wine
# CALLED BY: write_bin_run
write_bin_run_wine() {
	cat >> "$file" <<- EOF
	cd "\$PATH_PREFIX"
	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- EOF
	wine "\$APP_EXE" \$APP_OPTIONS \$@
	EOF
}

# write launcher script - set common vars
# USAGE: write_bin_set_vars
write_bin_set_vars() {
	cat >> "$file" <<- EOF
	# Set game-specific variables
	
	GAME_ID="$GAME_ID"
	PATH_GAME="$PATH_GAME"
	
	EOF
	if [ "$app_type" != 'scummvm' ]; then
		cat >> "$file" <<- EOF
		CACHE_DIRS='$CACHE_DIRS'
		CACHE_FILES='$CACHE_FILES'
	
		CONFIG_DIRS='$CONFIG_DIRS'
		CONFIG_FILES='$CONFIG_FILES'
	
		DATA_DIRS='$DATA_DIRS'
		DATA_FILES='$DATA_FILES'
	
		EOF
	else
		cat >> "$file" <<- EOF
		SCUMMVM_ID='$(eval echo \$${app}_SCUMMID)'
	
		EOF
	fi
}

# write launcher script - set target binary/script to run the game
# USAGE: write_bin_set_exe
# CALLED BY: write_bin
write_bin_set_exe() {
	cat >> "$file" <<- EOF
	# Set executable file
	APP_EXE="$app_exe"
	APP_OPTIONS="$app_options"
	export LD_LIBRARY_PATH="$app_libs:\$LD_LIBRARY_PATH"
	
	EOF
}

# write launcher script - set prefix path
# USAGE: write_bin_set_prefix
# CALLS: write_bin_set_prefix_vars, write_bin_set_prefix_funcs
write_bin_set_prefix() {
	cat >> "$file" <<- EOF
	# Set prefix name
	
	if [ -z "\$PREFIX_ID" ]; then
	  PREFIX_ID="$GAME_ID"
	fi
	
	EOF
	write_bin_set_prefix_vars
	write_bin_set_prefix_funcs
}

# write launcher script - set prefix-specific vars
# USAGE: write_bin_set_prefix_vars
# CALLED BY: write_bin_set_prefix
# CALLS: write_bin_set_prefix_wine
write_bin_set_prefix_vars() {
	cat >> "$file" <<- EOF
	# Set prefix-specific variables
	
	if [ ! -w "\$XDG_CACHE_HOME" ]; then
	  XDG_CACHE_HOME="\${HOME}/.cache"
	fi
	if [ ! -w "\$XDG_CONFIG_HOME" ]; then
	  XDG_CONFIG_HOME="\${HOME}/.config"
	fi
	if [ ! -w "\$XDG_DATA_HOME" ]; then
	  XDG_DATA_HOME="\${HOME}/.local/share"
	fi
	
	PATH_CACHE="\${XDG_CACHE_HOME}/\${PREFIX_ID}"
	PATH_CONFIG="\${XDG_CONFIG_HOME}/\${PREFIX_ID}"
	PATH_DATA="\${XDG_DATA_HOME}/games/\${PREFIX_ID}"
	EOF
	if [ "$app_type" = 'wine' ] ; then
		write_bin_set_prefix_vars_wine
	else
		cat >> "$file" <<- EOF
		PATH_PREFIX="\${XDG_DATA_HOME}/play.it/prefixes/\${PREFIX_ID}"
		EOF
	fi
}

# write launcher script - set WINE-specific prefix-specific vars
# USAGE: write_bin_set_prefix_vars_wine
# CALLED BY: write_bin_set_prefix_vars
write_bin_set_prefix_vars_wine() {
	cat >> "$file" <<- EOF
	WINEPREFIX="\${XDG_DATA_HOME}/play.it/prefixes/\${PREFIX_ID}"
	PATH_PREFIX="\${WINEPREFIX}/drive_c/\${GAME_ID}"
	WINEARCH='win32'
	WINEDEBUG='-all'
	WINEDLLOVERRIDES='winemenubuilder.exe,mscoree,mshtml=d'
	
	EOF
}

# write launcher script - set prefix-specific functions
# USAGE: write_bin_set_prefix_funcs
# CALLED BY: write_bin_set_prefix
write_bin_set_prefix_funcs() {
	cat >> "$file" <<- EOF
	clean_userdir() {
	  local target="\$1"
	  shift 1
	  for file in "\$@"; do
	  if [ -f "\${file}" ] && [ ! -f "\${target}/\${file}" ]; then
	    mkdir --parents "\${target}/\${file%/*}"
	    mv "\${file}" "\${target}/\${file}"
	    ln --symbolic "\${target}/\${file}" "\${file}"
	  fi
	  done
	}
	
	init_prefix_dirs() {
	  (
	    cd "\$1"
	    shift 1
	    for dir in \$@; do
	      rm --force --recursive "\${PATH_PREFIX}/\${dir}"
	      mkdir --parents "\${PATH_PREFIX}/\${dir%/*}"
	      ln --symbolic "\$(readlink -e "\${dir}")" "\${PATH_PREFIX}/\${dir}"
	    done
	  )
	}
	
	init_prefix_files() {
	  (
	    cd "\$1"
	    find . -type f | while read file; do
	      local file_prefix="\$(readlink -e "\$PATH_PREFIX/\$file")"
	      local file_real="\$(readlink -e "\$file")"
	      if [ "\$file_real" != "\$file_prefix" ]; then
	        rm --force "\$PATH_PREFIX/\$file"
	        mkdir --parents "\$PATH_PREFIX/\${file%/*}"
	        ln --symbolic "\$file_real" "\$PATH_PREFIX/\$file"
	      fi
	    done
	  )
	}
	
	init_userdir_dirs() {
	  (
	    local dest="\$1"
	    shift 1
	    cd "\$PATH_GAME"
	    for dir in \$@; do
	      if [ -e "\$dir" ]; then
	        cp --parents --recursive "\$dir" "\$dest"
	      else
	        mkdir --parents "\$dest/\$dir"
	      fi
	    done
	  )
	}
	
	init_userdir_files() {
	  (
	    local dest="\$1"
	    shift 1
	    cd "\$PATH_GAME"
	    for file in \$@; do
	      if [ -e "\$file" ]; then
	        cp --parents "\$file" "\$dest"
	      fi
	    done
	  )
	}
	
	EOF
}

# write menu entry
# USAGE: write_desktop $app
# NEEDED VARS: $app_TYPE, $app_ID, $app_NAME, $app_CAT, PKG_PATH, PATH_DESK
# CALLS: liberror
write_desktop() {
	local app
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'write_desktop'
		local type="$(eval echo \$${app}_TYPE)"
		if [ "$winecfg_desktop" != 'done' ] && [ "$type" = 'wine' ]; then
			winecfg_desktop='done'
			write_desktop_winecfg
		fi
		local id="$(eval echo \$${app}_ID)"
		if [ -z "$id" ]; then
			id="$GAME_ID"
		fi
		local name="$(eval echo \$${app}_NAME)"
		if [ -z "$name" ]; then
			name="$GAME_NAME"
		fi
		local cat="$(eval echo \$${app}_CAT)"
		if [ -z "$cat" ]; then
			cat='Game'
		fi
		local target="${PKG_PATH}${PATH_DESK}/${id}.desktop"
		mkdir --parents "${target%/*}"
		cat > "${target}" <<- EOF
		[Desktop Entry]
		Version=1.0
		Type=Application
		Name=$name
		Icon=$id
		Exec=$id
		Categories=$cat
		EOF
	done
}

# write winecfg launcher script
# USAGE: write_desktop_winecfg
# NEEDED VARS: GAME_ID
# CALLS: write_desktop
write_desktop_winecfg() {
	APP_WINECFG_ID="${GAME_ID}_winecfg"
	APP_WINECFG_NAME="$GAME_NAME - WINE configuration"
	APP_WINECFG_CAT='Settings'
	write_desktop 'APP_WINECFG'
	sed --in-place 's/Icon=.\+/Icon=winecfg/' "${PKG_PATH}${PATH_DESK}/${APP_WINECFG_ID}.desktop"
}

# write package meta-data
# USAGE: write_metadata $pkg
# NEEDED VARS: $PKG_ARCH_ARCH $PKG_ARCH_DEB $PKG_CONFLICTS_ARCH
# 	$PKG_CONFLICTS_DEB $PKG_DEPS_ARCH $PKG_DEPS_DEB $PKG_DESCRIPTION
# 	$PKG_ID $PKG_PATH $PKG_PROVIDES_ARCH $PKG_PROVIDES_DEB $PKG_VERSION
# 	$PACKAGE_TYPE
# CALLS: testvar liberror write_metadata_arch write_metadata_deb
write_metadata() {
	for pkg in $@; do

		testvar "$pkg" 'PKG' || liberror 'pkg' 'write_metadata'

		local pkg_arch
		set_arch
		local pkg_id="$(eval echo \$${pkg}_ID)"
		local pkg_description="$(eval echo \$${pkg}_DESCRIPTION)"
		local pkg_maint="$(whoami)@$(hostname)"
		local pkg_path="$(eval echo \$${pkg}_PATH)"
		local pkg_version="$(eval echo \$${pkg}_VERSION)"

		if [ ! "$pkg_id" ]; then
			pkg_id="$GAME_ID"
		fi

		if [ ! "$pkg_version" ]; then
			pkg_version="$PKG_VERSION"
		fi
		if [ ! "$pkg_version" ]; then
			pkg_version='1.0-1'
		fi

		case $PACKAGE_TYPE in
			('arch')
				local pkg_conflicts="$(eval echo \$${pkg}_CONFLICTS_ARCH)"
				local pkg_deps="$(eval echo \$${pkg}_DEPS_ARCH)"
				local pkg_provides="$(eval echo \$${pkg}_PROVIDES_ARCH)"
				local pkg_size=$(du --total --block-size=1 --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
				write_metadata_arch
			;;
			('deb')
				local pkg_conflicts="$(eval echo \$${pkg}_CONFLICTS_DEB)"
				local pkg_deps="$(eval echo \$${pkg}_DEPS_DEB)"
				local pkg_provides="$(eval echo \$${pkg}_PROVIDES_DEB)"
				local pkg_size=$(du --total --block-size=1K --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
				write_metadata_deb
			;;
		esac

	done
}

# write .pkg.tar package meta-data
# USAGE: write_metadata_arch
# CALLED BY: write_metadata
write_metadata_arch() {
	local target="${pkg_path}/.PKGINFO"

	mkdir --parents "${target%/*}"

	cat > "${target}" <<- EOF
	pkgname = $pkg_id
	pkgver = $pkg_version
	packager = $pkg_maint
	builddate = $(date +"%m%d%Y")
	size = $pkg_size
	arch = $pkg_arch
	EOF

	if [ "$pkg_description" ]; then
		cat >> "${target}" <<- EOF
		pkgdesc = $GAME_NAME - $pkg_description - ./play.it script version $script_version
		EOF
	else
		cat >> "${target}" <<- EOF
		pkgdesc = $GAME_NAME - ./play.it script version $script_version
		EOF
	fi

	for dep in $pkg_deps; do
		cat >> "${target}" <<- EOF
		depend = $dep
		EOF
	done

	for conflict in $pkg_conflicts; do
		cat >> "${target}" <<- EOF
		conflict = $conflict
		EOF
	done

	for provide in $pkg_provides; do
		cat >> "${target}" <<- EOF
		provide = $provide
		EOF
	done

	target="${pkg_path}/.INSTALL"

	if [ -e "$postinst" ]; then
		cat >> "$target" <<- EOF
		post_install() {
		EOF
		cat "$postinst" >> "$target"
		cat >> "$target" <<- EOF
		}
		post_upgrade() {
		post_install
		}
		EOF
	fi

	if [ -e "$prerm" ]; then
		cat >> "$target" <<- EOF
		pre_remove() {
		EOF
		cat "$prerm" >> "$target"
		cat >> "$target" <<- EOF
		}
		pre_upgrade() {
		pre_remove
		}
		EOF
	fi
}

# write .deb package meta-data
# USAGE: write_metadata_deb
# CALLED BY: write_metadata
write_metadata_deb() {
	local target="$pkg_path/DEBIAN/control"

	mkdir --parents "${target%/*}"

	cat > "$target" <<- EOF
	Package: $pkg_id
	Version: $pkg_version
	Architecture: $pkg_arch
	Maintainer: $pkg_maint
	Installed-Size: $pkg_size
	Section: non-free/games
	EOF

	if [ "$pkg_conflicts" ]; then
		cat >> "$target" <<- EOF
		Conflicts: $pkg_conflicts
		EOF
	fi

	if [ "$pkg_provides" ]; then
		cat >> "$target" <<- EOF
		Provides: $pkg_provides
		EOF
	fi

	if [ "$pkg_deps" ]; then
		cat >> "$target" <<- EOF
		Depends: $pkg_deps
		EOF
	fi

	if [ "$pkg_description" ]; then
		cat >> "${target}" <<- EOF
		Description: $GAME_NAME - $pkg_description
		 ./play.it script version $script_version
		EOF
	else
		cat >> "${target}" <<- EOF
		Description: $GAME_NAME
		 ./play.it script version $script_version
		EOF
	fi

	if [ "$pkg_arch" = 'all' ]; then
		sed -i 's/Architecture: all/&\nMulti-Arch: foreign/' "$target"
	fi

	if [ -e "$postinst" ]; then
		target="$pkg_path/DEBIAN/postinst"
		cat > "$target" <<- EOF
		#!/bin/sh -e
		EOF
		cat "$postinst" >> "$target"
		cat >> "$target" <<- EOF
		exit 0
		EOF
		chmod 755 "$target"
	fi

	if [ -e "$prerm" ]; then
		target="$pkg_path/DEBIAN/prerm"
		cat > "$target" <<- EOF
		#!/bin/sh -e
		EOF
		cat "$prerm" >> "$target"
		cat >> "$target" <<- EOF
		exit 0
		EOF
		chmod 755 "$target"
	fi
}

