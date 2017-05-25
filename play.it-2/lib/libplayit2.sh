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
library_revision=20170523.1

# set package distribution-specific architecture
# USAGE: set_architecture $pkg
# CALLS: liberror set_architecture_arch set_architecture_deb
# NEEDED VARS: (ARCHIVE) (PACKAGE_TYPE) (PKG_ARCH)
# CALLED BY: set_temp_directories write_metadata
set_architecture() {
	local architecture
	if [ "$ARCHIVE" ] && [ -n "$(eval echo \$${1}_ARCH_${ARCHIVE#ARCHIVE_})" ]; then
		architecture="$(eval echo \$${1}_ARCH_${ARCHIVE#ARCHIVE_})"
		export ${1}_ARCH="$architecture"
	else
		architecture="$(eval echo \$${1}_ARCH)"
	fi
	case $PACKAGE_TYPE in
		('arch')
			set_architecture_arch "$architecture"
		;;
		('deb')
			set_architecture_deb "$architecture"
		;;
		(*)
			liberror 'PACKAGE_TYPE' 'set_architecture'
		;;
	esac
}

# test the validity of the argument given to parent function
# USAGE: testvar $var_name $pattern
testvar() {
	test "${1%%_*}" = "$2"
}

# set defaults rights on files (755 for dirs & 644 for regular files)
# USAGE: set_standard_permissions $dir[…]
set_standard_permissions() {
	for dir in "$@"; do
		[  -d "$dir" ] || return 1
		find "$dir" -type d -exec chmod 755 '{}' +
		find "$dir" -type f -exec chmod 644 '{}' +
	done
}

# print a localized error message
# USAGE: print_error
# NEEDED VARS: (LANG)
print_error() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Erreur :'
		;;
		('en'|*)
			string='Error:'
		;;
	esac
	printf '\n\033[1;31m%s\033[0m\n' "$string"
}

# convert files name to lower case
# USAGE: tolower $dir[…]
tolower() {
	for dir in "$@"; do
		[ -d "$dir" ] || return 1
		find "$dir" -depth -mindepth 1 | while read file; do
			newfile="${file%/*}/$(echo "${file##*/}" | tr [:upper:] [:lower:])"
			[ -e "$newfile" ] || mv "$file" "$newfile"
		done
	done
}

# display an error if a function has been called with invalid arguments
# USAGE: liberror $var_name $calling_function
# NEEDED VARS: (LANG)
liberror() {
	local var="$1"
	local value="$(eval echo \$$var)"
	local func="$2"
	print_error
	case "${LANG%_*}" in
		('fr')
			string='Valeur incorrecte pour %s appelée par %s : %s\n'
		;;
		('en'|*)
			string='Invalid value for %s called by %s: %s\n'
		;;
	esac
	printf "$string" "$var" "$func" "$value"
	return 1
}

# set distribution-specific package architecture for Arch Linux target
# USAGE: set_architecture_arch $architecture
# CALLED BY: set_architecture
set_architecture_arch() {
	case "$1" in
		('32'|'64')
			pkg_architecture='x86_64'
		;;
		(*)
			pkg_architecture='any'
		;;
	esac
}

# set distribution-specific package architecture for Debian target
# USAGE: set_architecture_deb $architecture
# CALLED BY: set_architecture
set_architecture_deb() {
	case "$1" in
		('32')
			pkg_architecture='i386'
		;;
		('64')
			pkg_architecture='amd64'
		;;
		(*)
			pkg_architecture='all'
		;;
	esac
}

# set source archive for data extraction
# USAGE: set_source_archive $archive[…]
# NEEDED VARS: (LANG)
# CALLS: set_archive
set_source_archive() {
	set_archive 'SOURCE_ARCHIVE' "$@"
	[ "$SOURCE_ARCHIVE" ] && return 0
	print_error
	local string
	if [ "$#" = 1 ]; then
		case "${LANG%_*}" in
			('fr')
				string='Le fichier suivant est introuvable :\n'
			;;
			('en'|*)
				string='The following file could not be found:\n'
			;;
		esac
	else
		case "${LANG%_*}" in
			('fr')
				string='Aucun des fichiers suivant n’est présent :\n'
			;;
			('en'|*)
				string='None of the following files could be found:\n'
			;;
		esac
	fi
	printf "$string"
	for archive in "$@"; do
		printf '%s\n' "$(eval echo \$$archive)"
	done
	return 1
}

# set archive for data extraction
# USAGE: set_archive $name $archive[…]
# NEEDED_VARS: (LANG) (SOURCE_ARCHIVE)
# CALLS: set_archive_vars
set_archive() {
	local name=$1
	shift 1
	if [ -n "$(eval echo \$$name)" ]; then
		for archive in "$@"; do
			local file="$(eval echo \$$archive)"
			if [ "$(basename "$(eval echo \$$name)")" = "$file" ]; then
				set_archive_vars "$archive" "$name" "$(eval echo \$$name)"
				return 0
			fi
		done
	else
		for archive in "$@"; do
			local file="$(eval echo \$$archive)"
			if [ -f "$file" ]; then
				set_archive_vars "$archive" "$name" "$file"
				return 0
			elif [ "$SOURCE_ARCHIVE" ] && [ -f "${SOURCE_ARCHIVE%/*}/$file" ]; then
				file="${SOURCE_ARCHIVE%/*}/$file"
				set_archive_vars "$archive" "$name" "$file"
				return 0
			fi
		done
	fi
	unset $name
}

# set archive-specific variables
# USAGE: set_archive_vars $archive $name $file
# CALLS: archive_guess_type check_deps set_archive_print
# NEEDED_VARS: (LANG)
# CALLED BY: set_archive
set_archive_vars() {
	export ARCHIVE="$1"

	local name="$2"
	local file="$3"

	set_archive_print "$file"

	# set target file
	export $name="$file"

	# set archive type + check dependencies
	if [ -z "$(eval echo \$${ARCHIVE}_TYPE)" ]; then
		archive_guess_type "$file"
	fi
	export ${name}_TYPE="$(eval echo \$${ARCHIVE}_TYPE)"
	check_deps

	# compute total size of all archives
	if [ -n "$(eval echo \$${ARCHIVE}_SIZE)" ]; then
		[ "$ARCHIVE_SIZE" ] || export ARCHIVE_SIZE='0'
		export ARCHIVE_SIZE="$(($ARCHIVE_SIZE + $(eval echo \$${ARCHIVE}_SIZE)))"
	fi

	# set package version
	if [ -n "$(eval echo \$${ARCHIVE}_VERSION)" ]; then
		PKG_VERSION="$(eval echo \$${ARCHIVE}_VERSION)+${script_version}"
	fi

	# check file integrity
	if [ -n "$(eval echo \$${ARCHIVE}_MD5)" ]; then
		file_checksum "$file"
	fi
}

# try to guess archive type from file name
# USAGE: archive_guess_type $file
# CALLS: archive_guess_type_error
# NEEDED VARS: ARCHIVE (LANG)
# CALLED BY: set_archive_vars
archive_guess_type() {
	case "${1##*/}" in
		(gog_*.sh)
			export ${ARCHIVE}_TYPE='mojosetup'
		;;
		(setup_*.exe|patch_*.exe)
			export ${ARCHIVE}_TYPE='innosetup'
		;;
		(*.zip)
			export ${ARCHIVE}_TYPE='zip'
		;;
		(*.tar.gz|*.tgz)
			export ${ARCHIVE}_TYPE='tar.gz'
		;;
		(*)
			archive_guess_type_error
		;;
	esac
}

# display an error message telling the type of the target archive is not set
# USAGE: archive_guess_type_error
# NEEDED VARS: ARCHIVE (LANG)
# CALLED BY: archive_guess_type
archive_guess_type_error() {
	print_error
	local string
	case "${LANG%_*}" in
		('fr')
			string='ARCHIVE_TYPE n’est pas défini pour %s\n'
		;;
		('en'|*)
			string='ARCHIVE_TYPE is not set for %s\n'
		;;
	esac
	printf "$string" "$ARCHIVE"
	return 1
}

# print archive use message
# USAGE: set_archive_print $file
# NEEDED VARS: (LANG)
# CALLED BY: set_archive_vars
set_archive_print() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Utilisation de %s\n'
		;;
		('en'|*)
			string='Using %s\n'
		;;
	esac
	printf "$string" "$1"
}

# check integrity of target file
# USAGE: file_checksum $file
# NEEDED VARS: ARCHIVE CHECKSUM_METHOD (LANG)
# CALLS: file_checksum_md5 liberror
file_checksum() {
	case "$CHECKSUM_METHOD" in
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
# NEEDED VARS: ARCHIVE
# CALLS: file_checksum_print file_checksum_error
# CALLED BY: file_checksum
file_checksum_md5() {
	file_checksum_print "$1"
	FILE_MD5="$(md5sum "$1" | cut --delimiter=' ' --fields=1)"
	if [ "$FILE_MD5" = "$(eval echo \$${ARCHIVE}_MD5)" ]; then
		return 0
	else
		file_checksum_error "$1"
		return 1
	fi
}

# print integrity check message
# USAGE: file_checksum_print $file
# NEEDED VARS: (LANG)
# CALLED BY: file_checksum_md5
file_checksum_print() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Contrôle de l’intégrité de %s\n'
		;;
		('en'|*)
			string='Checking integrity of %s\n'
		;;
	esac
	printf "$string" "$(basename "$1")"
}

# print integrity check error message
# USAGE: file_checksum_error $file
# NEEDED VARS: (LANG)
# CALLED BY: file_checksum_md5
file_checksum_error() {
	print_error
	local string1
	local string2
	case "${LANG%_*}" in
		('fr')
			string1='Somme de contrôle incohérente. %s n’est pas le fichier attendu.\n'
			string2='Utilisez --checksum=none pour forcer son utilisation.\n'
		;;
		('en'|*)
			string1='Hashsum mismatch. %s is not the expected file.\n'
			string2='Use --checksum=none to force its use.\n'
		;;
	esac
	printf "$string1" "$(basename "$1")"
	printf "$string2"
}

# check script dependencies
# USAGE: check_deps
# NEEDED VARS: (ARCHIVE) (ARCHIVE_TYPE) (CHECKSUM_METHOD) (LANG) (PACKAGE_TYPE) (SCRIPT_DEPS)
# CALLS: check_deps_7z check_deps_error_not_found
check_deps() {
	if [ "$ARCHIVE" ]; then
		case "$(eval echo \$${ARCHIVE}_TYPE)" in
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
	fi
	if [ "$CHECKSUM_METHOD" = 'md5sum' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS md5sum"
	fi
	if [ "$PACKAGE_TYPE" = 'deb' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS fakeroot dpkg"
	fi
	if [ "${APP_MAIN_ICON##*.}" = 'bmp' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS convert"
	fi
	if [ "${APP_MAIN_ICON##*.}" = 'ico' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS icotool"
	fi
	for dep in $SCRIPT_DEPS; do
		case $dep in
			('7z')
				check_deps_7z
			;;
			(*)
				if ! which $dep >/dev/null 2>&1; then
					check_deps_error_not_found "$dep"
				fi
			;;
		esac
	done
}

# check presence of a software to handle .7z archives
# USAGE: check_deps_7z
# NEEDED VARS: (LANG)
# CALLS: check_deps_error_not_found
# CALLED BY: check_deps
check_deps_7z() {
	if which 7zr >/dev/null 2>&1; then
		extract_7z() { 7zr x -o"$2" -y "$1"; }
	elif which 7za >/dev/null 2>&1; then
		extract_7z() { 7za x -o"$2" -y "$1"; }
	elif which unar >/dev/null 2>&1; then
		extract_7z() { unar -output-directory "$2" -force-overwrite -no-directory "$1"; }
	else
		check_deps_error_not_found 'p7zip'
	fi
}

# display a message if a required dependency is missing
# USAGE: check_deps_error_not_found $command_name
# NEEDED VARS: (LANG)
# CALLED BY: check_deps check_deps_7z
check_deps_error_not_found() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='%s est introuvable. Installez-le avant de lancer ce script.\n'
		;;
		('en'|*)
			string='%s not found. Install it before running this script.\n'
		;;
	esac
	printf "$string" "$1"
	return 1
}

# set temporary directories
# USAGE: set_temp_directories $pkg[…]
# NEEDED VARS: (ARCHIVE_SIZE) GAME_ID (LANG) (PWD) (XDG_CACHE_HOME) (XDG_RUNTIME_DIR)
# CALLS: set_temp_directories_error_no_size set_temp_directories_error_not_enough_space set_temp_directories_pkg testvar
set_temp_directories() {

	# If $PLAYIT_WORKDIR is already set, delete it before setting a new one
	[ "$PLAYIT_WORKDIR" ] && rm --force --recursive "$PLAYIT_WORKDIR"

	# If there is only a single package, make it the default one for the current instance
	[ $# = 1 ] && PKG="$1"

	# Generate an unique name for the current instance
	local name="play.it/$(mktemp --dry-run ${GAME_ID}.XXXXX)"

	# Look for a directory with enough free space to work in
	if [ "$ARCHIVE_SIZE" ]; then
		local needed_space=$(($ARCHIVE_SIZE * 2))
	else
		set_temp_directories_error_no_size
	fi
	[ "$XDG_RUNTIME_DIR" ] || XDG_RUNTIME_DIR="/run/user/$(id -u)"
	[ "$XDG_CACHE_HOME" ]  || XDG_CACHE_HOME="$HOME/.cache"
	local free_space_run=$(df --output=avail "$XDG_RUNTIME_DIR" 2>/dev/null | tail --lines=1)
	local free_space_tmp=$(df --output=avail /tmp 2>/dev/null | tail --lines=1)
	local free_space_cache=$(df --output=avail "$XDG_CACHE_HOME" 2>/dev/null | tail --lines=1)
	local free_space_pwd=$(df --output=avail "$PWD" 2>/dev/null | tail --lines=1)
	if [ -w "$XDG_RUNTIME_DIR" ] && [ $free_space_run -ge $needed_space ]; then
		export PLAYIT_WORKDIR="$XDG_RUNTIME_DIR/$name"
	elif [ -w '/tmp' ] && [ $free_space_tmp -ge $needed_space ]; then
		export PLAYIT_WORKDIR="/tmp/$name"
	elif [ -w "$XDG_CACHE_HOME" ] && [ $free_space_cache -ge $needed_space ]; then
		export PLAYIT_WORKDIR="$XDG_CACHE_HOME/$name"
	elif [ -w "$PWD" ] && [ $free_space_pwd -ge $needed_space ]; then
		export PLAYIT_WORKDIR="$PWD/$name"
	else
		set_temp_directories_error_not_enough_space
	fi

	# If $PLAYIT_WORKDIR is an already existing directory, set a new one
	if [ -e "$PLAYIT_WORKDIR" ]; then
		set_temp_directories
		return 0
	fi

	# Set $postinst and $prerm
	mkdir --parents "$PLAYIT_WORKDIR/scripts"
	export postinst="$PLAYIT_WORKDIR/scripts/postinst"
	export prerm="$PLAYIT_WORKDIR/scripts/prerm"

	# Set temporary directories for each package to build
	for pkg in "$@"; do
		testvar "$pkg" 'PKG'
		set_temp_directories_pkg $pkg
	done
}

# set package-secific temporary directory
# USAGE: set_temp_directories_pkg $pkg
# NEEDED VARS: (ARCHIVE) (PACKAGE_TYPE) PLAYIT_WORKDIR (PKG_ARCH) PKG_ID|GAME_ID PKG_VERSION|script_version
# CALLED BY: set_temp_directories
set_temp_directories_pkg() {

	# Get package ID
	local pkg_id
	if [ "$(eval echo \$${1}_ID_${ARCHIVE#ARCHIVE_})" ]; then
		pkg_id="$(eval echo \$${1}_ID_${ARCHIVE#ARCHIVE_})"
	elif [ "$(eval echo \$${1}_ID)" ]; then
		pkg_id="$(eval echo \$${1}_ID)"
	else
		pkg_id="$GAME_ID"
	fi
	export ${1}_ID="$pkg_id"

	# Get package version
	local pkg_version
	if [ -n "$(eval echo \$${1}_VERSION)" ]; then
		pkg_version="$(eval echo \$${1}_VERSION)+$script_version"
	elif [ "$PKG_VERSION" ]; then
		pkg_version="$PKG_VERSION"
	else
		pkg_version='1.0-1+$script_version'
	fi

	# Get package architecture
	local pkg_architecture
	set_architecture "$1"

	# Set $PKG_PATH
	if [ "$PACKAGE_TYPE" = 'arch' ] && [ "$(eval echo \$${1}_ARCH)" = '32' ]; then
		pkg_id="lib32-$pkg_id"
	fi
	export ${1}_PATH="$PLAYIT_WORKDIR/${pkg_id}_${pkg_version}_${pkg_architecture}"
}

# display an error if set_temp_directories() is called before setting $ARCHIVE_SIZE
# USAGE: set_temp_directories_error_no_size
# NEEDED VARS: (LANG)
# CALLS: print_error
# CALLED BY: set_temp_directories
set_temp_directories_error_no_size() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='$ARCHIVE_SIZE doit être défini avant tout appel à set_temp_directories().\n'
		;;
		('en'|*)
			string='$ARCHIVE_SIZE must be set before any call to set_temp_directories().\n'
		;;
	esac
	printf "$string"
	return 1
}

# display an error if there is not enough free space to work in any of the tested directories
# USAGE: set_temp_directories_error_not_enough_space
# NEEDED VARS: (LANG)
# CALLS: print_error
# CALLED BY: set_temp_directories
set_temp_directories_error_not_enough_space() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='Il n’y a pas assez d’espace libre dans les différents répertoires testés :\n'
		;;
		('en'|*)
			string='There is not enough free space in the tested directories:\n'
		;;
	esac
	printf "$string"
	for path in "$XDG_RUNTIME_DIR" '/tmp' "$XDG_CACHE_HOME" "$PWD"; do
		printf '%s\n' "$path"
	done
	return 1
}

# Check library version against script target version

library_version_major=${library_version%.*}
target_version_major=${target_version%.*}

library_version_minor=$(echo $library_version | cut -d'.' -f2)
target_version_minor=$(echo $target_version | cut -d'.' -f2)

if [ $library_version_major -ne $target_version_major ] || [ $library_version_minor -lt $target_version_minor ]; then
	print_error
	case "${LANG%_*}" in
		('fr')
			string1='Mauvaise version de libplayit2.sh\n'
			string2='La version cible est : %s\n'
		;;
		('en'|*)
			string1='Wrong version of libplayit2.sh\n'
			string2='Target version is: %s\n'
		;;
	esac
	printf "$string1"
	printf "$string2" "$target_version"
	exit 1
fi

# Set default values for common vars

DEFAULT_CHECKSUM_METHOD='md5'
DEFAULT_COMPRESSION_METHOD='none'
DEFAULT_INSTALL_PREFIX='/usr/local'
DEFAULT_PACKAGE_TYPE='deb'
unset winecfg_desktop
unset winecfg_launcher

# Try to detect the host distribution through lsb_release

if which lsb_release >/dev/null 2>&1; then
	case "$(lsb_release --id --short)" in
		('Debian'|'Ubuntu')
			DEFAULT_PACKAGE_TYPE='deb'
		;;
		('Arch')
			DEFAULT_PACKAGE_TYPE='arch'
		;;
	esac
fi

# Parse arguments given to the script

unset CHECKSUM_METHOD
unset COMPRESSION_METHOD
unset INSTALL_PREFIX
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
		('--prefix='*)
			export INSTALL_PREFIX="${arg#*=}"
		;;
		('--package='*)
			export PACKAGE_TYPE="${arg#*=}"
		;;
		('--'*)
			return 1
		;;
		(*)
			export SOURCE_ARCHIVE="$arg"
		;;
	esac
done

# Set global variables not already set by script arguments

for var in 'CHECKSUM_METHOD' 'COMPRESSION_METHOD' 'INSTALL_PREFIX' 'PACKAGE_TYPE'; do
	value="$(eval echo \$$var)"
	if [ -z "$value" ]; then
		value_default="$(eval echo \$DEFAULT_$var)"
		if [ -n "$value_default" ]; then
			export $var="$value_default"
		fi
	fi
done
unset value
unset value_default

# Check script dependencies

check_deps

# Set package paths

case $PACKAGE_TYPE in
	('arch')
		PATH_BIN="$INSTALL_PREFIX/bin"
		PATH_DESK='/usr/local/share/applications'
		PATH_DOC="$INSTALL_PREFIX/share/doc/$GAME_ID"
		PATH_GAME="$INSTALL_PREFIX/share/$GAME_ID"
		PATH_ICON_BASE='/usr/local/share/icons/hicolor'
	;;
	('deb')
		PATH_BIN="$INSTALL_PREFIX/games"
		PATH_DESK='/usr/local/share/applications'
		PATH_DOC="$INSTALL_PREFIX/share/doc/$GAME_ID"
		PATH_GAME="$INSTALL_PREFIX/share/games/$GAME_ID"
		PATH_ICON_BASE='/usr/local/share/icons/hicolor'
	;;
	(*)
		liberror 'PACKAGE_TYPE' "$0"
	;;
esac

# Set source archive

set_source_archive $ARCHIVES_LIST

# Set working directories

set_temp_directories $PACKAGES_LIST


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
				set_standard_permissions "$destination"
			;;
			('mojosetup_unzip')
				unzip -o -d "$destination" "$file" 1>/dev/null 2>&1 || true
				set_standard_permissions "$destination"
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

# put files from archive in the right package directories
# USAGE: organize_data $id $path
# NEEDED VARS: (PLAYIT_WORKDIR) (PKG) (PKG_PATH)
organize_data() {
	[ $# = 2 ] || return 1
	[ "$PLAYIT_WORKDIR" ] || return 1
	[ $PKG ] || return 1
	[ -n "$(eval echo \$${PKG}_PATH)" ] || return 1

	local archive_path
	if [ -n "$(eval echo \"\$ARCHIVE_${1}_PATH_${ARCHIVE#ARCHIVE_}\")" ]; then
		archive_path="$(eval echo \"\$ARCHIVE_${1}_PATH_${ARCHIVE#ARCHIVE_}\")"
	elif [ -n "$(eval echo \"\$ARCHIVE_${1}_PATH\")" ]; then
		archive_path="$(eval echo \"\$ARCHIVE_${1}_PATH\")"
	else
		unset archive_path
	fi

	local archive_files
	if [ -n "$(eval echo \"\$ARCHIVE_${1}_FILES_${ARCHIVE#ARCHIVE_}\")" ]; then
		archive_files="$(eval echo \"\$ARCHIVE_${1}_FILES_${ARCHIVE#ARCHIVE_}\")"
	elif [ -n "$(eval echo \"\$ARCHIVE_${1}_FILES\")" ]; then
		archive_files="$(eval echo \"\$ARCHIVE_${1}_FILES\")"
	else
		unset archive_files
	fi

	if [ "$archive_path" ] && [ "$archive_files" ] && [ -d "$PLAYIT_WORKDIR/gamedata/$archive_path" ]; then
		local pkg_path="$(eval echo \$${PKG}_PATH)${2}"
		mkdir --parents "$pkg_path"
		(
			cd "$PLAYIT_WORKDIR/gamedata/$archive_path"
			for file in $archive_files; do
				if [ -e "$file" ]; then
					cp --recursive --force --link --parents "$file" "$pkg_path"
					rm --recursive "$file"
				fi
			done
		)
	fi
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
		path_icon="${PATH_ICON_BASE}/${res}x${res}/apps"
		mkdir -p "${pkg_path}${path_icon}"
		for file in "${PLAYIT_WORKDIR}"/icons/*${res}x${res}x*.png; do
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
		path_icon="${PATH_ICON_BASE}/${res}x${res}/apps"
		mkdir -p "${pkg_path}${path_icon}"
		for file in "${PLAYIT_WORKDIR}"/icons/*${res}x${res}x*.png; do
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
		if [ "$ARCHIVE" ] && [ -n "$(eval echo \$${app}_ICON_${ARCHIVE#ARCHIVE_})" ]; then
			app_icon="$(eval echo \$${app}_ICON_${ARCHIVE#ARCHIVE_})"
			export ${app}_ICON="$app_icon"
		else
			app_icon="$(eval echo \$${app}_ICON)"
		fi
		extract_icon_from "${pkg_path}${PATH_GAME}/$app_icon"
		if [ "${app_icon##*.}" = 'exe' ]; then
			extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
		fi
		sort_icons "$app"
		rm --recursive "$PLAYIT_WORKDIR/icons"
	done
}

# print installation instructions
# USAGE: print_instructions $pkg[…]
# NEEDED VARS: (GAME_NAME) (PACKAGE_TYPE) (PACKAGES_LIST)
print_instructions() {
	[ "$GAME_NAME" ] || return 1
	if [ $# = 0 ]; then
		print_instructions $PACKAGES_LIST
		return 0
	fi
	case "${LANG%_*}" in
		('fr')
			string='\nInstallez %s en lançant la série de commandes suivantes en root :\n'
		;;
		('en'|*)
			string='\nInstall %s by running the following commands as root:\n'
		;;
	esac
	printf "$string" "$GAME_NAME"
	case $PACKAGE_TYPE in
		('arch')
			printf 'pacman -U'
			for pkg in $@; do
				printf ' %s' "$(eval echo \$${pkg}_PKG)"
			done
			printf '\n'
		;;
		('deb')
			printf 'dpkg -i'
			for pkg in $@; do
				printf ' %s' "$(eval echo \$${pkg}_PKG)"
			done
			printf '\n'
			printf 'apt-get install -f\n'
		;;
		(*)
			liberror 'PACKAGE_TYPE' 'print_instructions'
		;;
	esac
	printf '\n'
}

# alias calling write_bin() and write_desktop()
# USAGE: write_launcher $app[…]
# CALLS: write_bin write_dekstop
write_launcher() {
	write_bin $@
	write_desktop $@
}

# write launcher script
# USAGE: write_bin $app
# NEEDED VARS: $PKG $APP_ID $APP_TYPE $PATH_BIN $APP_EXE $APP_OPTIONS $APP_LIBS
#  $APP_PRERUN
# CALLS: liberror write_bin_set_vars write_bin_set_exe write_bin_set_prefix
#  write_bin_build_userdirs write_bin_build_prefix write_bin_run
write_bin() {
	PKG_PATH="$(eval echo \$${PKG}_PATH)"
	local app
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'write_bin'

		# Get app-specific variables
		local app_id="$(eval echo \$${app}_ID)"
		local app_type="$(eval echo \$${app}_TYPE)"
		[ "$app_id" ] || app_id="$GAME_ID"
		if [ "$app_type" != 'scummvm' ]; then
			local app_exe="$(eval echo \$${app}_EXE)"
			local app_libs="$(eval echo \$${app}_LIBS)"
			local app_options="$(eval echo \$${app}_OPTIONS)"
			local app_prerun="$(eval echo \$${app}_PRERUN)"
			local app_postrun="$(eval echo \$${app}_POSTRUN)"
			[ "$app_exe" ]  || app_exe="$(eval echo \"\$${app}_EXE_${PKG#PKG_}\")"
			[ "$app_libs" ] || app_libs="$(eval echo \"\$${app}_LIBS_${PKG#PKG_}\")"
			if [ "$app_type" = 'native' ]; then
				chmod +x "${PKG_PATH}${PATH_GAME}/$app_exe"
			fi
		fi

		# Write winecfg launcher for WINE games
		if [ "$app_type" = 'wine' ]; then
			write_bin_winecfg
		fi

		local file="${PKG_PATH}${PATH_BIN}/$app_id"
		mkdir --parents "${file%/*}"

		# Write launcher headers
		cat > "$file" <<- EOF
		#!/bin/sh
		# script generated by ./play.it $library_version - http://wiki.dotslashplay.it/
		set -o errexit

		EOF

		# Write launcher
		if [ "$app_type" = 'scummvm' ]; then
			write_bin_set_scummvm
		else
			if [ "$app_id" != "${GAME_ID}_winecfg" ]; then
				write_bin_set_exe
			fi
			write_bin_set
			write_bin_build
		fi
		write_bin_run
		sed -i 's/  /\t/g' "$file"
		chmod 755 "$file"

	done
}

# write launcher script - set target binary/script to run the game
# USAGE: write_bin_set_exe
# CALLED BY: write_bin
write_bin_set_exe() {
	cat >> "$file" <<- EOF

	# Set executable file

	APP_EXE='$app_exe'
	APP_OPTIONS='$app_options'
	export LD_LIBRARY_PATH="$app_libs:\$LD_LIBRARY_PATH"
	EOF
}

# write launcher script - set common vars
# USAGE: write_bin_set_vars
# CALLED BY: write_bin
write_bin_set() {
	cat >> "$file" <<- EOF

	# Set game-specific variables

	GAME_ID='$GAME_ID'
	PATH_GAME='$PATH_GAME'

	CACHE_DIRS='$CACHE_DIRS'
	CACHE_FILES='$CACHE_FILES'

	CONFIG_DIRS='$CONFIG_DIRS'
	CONFIG_FILES='$CONFIG_FILES'

	DATA_DIRS='$DATA_DIRS'
	DATA_FILES='$DATA_FILES'

	EOF
	cat >> "$file" <<- 'EOF'
	# Set prefix name

	[ "$PREFIX_ID" ] || PREFIX_ID="$GAME_ID"

	# Set prefix-specific variables

	[ "$XDG_CACHE_HOME" ] || XDG_CACHE_HOME="$HOME/.cache"
	[ "$XDG_CONFIG_HOME" ] || XDG_CONFIG_HOME="$HOME/.config"
	[ "$XDG_DATA_HOME" ] || XDG_DATA_HOME="$HOME/.local/share"

	PATH_CACHE="$XDG_CACHE_HOME/$PREFIX_ID"
	PATH_CONFIG="$XDG_CONFIG_HOME/$PREFIX_ID"
	PATH_DATA="$XDG_DATA_HOME/games/$PREFIX_ID"
	EOF
	if [ "$app_type" = 'wine' ]; then
		write_bin_set_wine
	else
		cat >> "$file" <<- 'EOF'
		PATH_PREFIX="$XDG_DATA_HOME/play.it/prefixes/$PREFIX_ID"
		EOF
	fi
	cat >> "$file" <<- 'EOF'

	# Set ./play.it functions

	clean_userdir() {
	  cd "$PATH_PREFIX"
	  for file in $2; do
	    if [ -f "$file" ] && [ ! -f "$1/$file" ]; then
	      cp --parents "$file" "$1"
	      rm "$file"
	      ln --symbolic "$(readlink -e "$1/$file")" "$file"
	    fi
	  done
	}

	init_prefix_dirs() {
	  (
	    cd "$1"
	    for dir in $2; do
	      rm --force --recursive "$PATH_PREFIX/$dir"
	      mkdir --parents "$PATH_PREFIX/${dir%/*}"
	      ln --symbolic "$(readlink -e "$dir")" "$PATH_PREFIX/$dir"
	    done
	  )
	}

	init_prefix_files() {
	  (
	    cd "$1"
	    find . -type f | while read file; do
	      local file_prefix="$(readlink -e "$PATH_PREFIX/$file")"
	      local file_real="$(readlink -e "$file")"
	      if [ "$file_real" != "$file_prefix" ]; then
	        rm --force "$PATH_PREFIX/$file"
	        mkdir --parents "$PATH_PREFIX/${file%/*}"
	        ln --symbolic "$file_real" "$PATH_PREFIX/$file"
	      fi
	    done
	  )
	}

	init_userdir_dirs() {
	  (
	    cd "$PATH_GAME"
	    for dir in $2; do
	      if [ ! -e "$1/$dir" ] && [ -e "$dir" ]; then
	        cp --parents --recursive "$dir" "$1"
	      else
	        mkdir --parents "$1/$dir"
	      fi
	    done
	  )
	}

	init_userdir_files() {
	  (
	    cd "$PATH_GAME"
	    for file in $2; do
	      if [ ! -e "$1/$file" ] && [ -e "$file" ]; then
	        cp --parents "$file" "$1"
	      fi
	    done
	  )
	}
		EOF
}

# write launcher script - build game prefix
# USAGE: write_bin_build
write_bin_build() {
	cat >> "$file" <<- 'EOF'

	# Build user-writable directories

	if [ ! -e "$PATH_CACHE" ]; then
	  mkdir --parents "$PATH_CACHE"
	  init_userdir_dirs "$PATH_CACHE" "$CACHE_DIRS"
	  init_userdir_files "$PATH_CACHE" "$CACHE_FILES"
	fi

	if [ ! -e "$PATH_CONFIG" ]; then
	  mkdir --parents "$PATH_CONFIG"
	  init_userdir_dirs "$PATH_CONFIG" "$CONFIG_DIRS"
	  init_userdir_files "$PATH_CONFIG" "$CONFIG_FILES"
	fi

	if [ ! -e "$PATH_DATA" ]; then
	  mkdir --parents "$PATH_DATA"
	  init_userdir_dirs "$PATH_DATA" "$DATA_DIRS"
	  init_userdir_files "$PATH_DATA" "$DATA_FILES"
	fi

	# Build prefix

	EOF

	if [ "$app_type" = 'wine' ]; then
		write_bin_build_wine
	fi
	cat >> "$file" <<- 'EOF'
	if [ ! -e "$PATH_PREFIX" ]; then
	  mkdir --parents "$PATH_PREFIX"
	  cp --force --recursive --symbolic-link --update "$PATH_GAME"/* "$PATH_PREFIX"
	fi
	init_prefix_files "$PATH_CACHE"
	init_prefix_files "$PATH_CONFIG"
	init_prefix_files "$PATH_DATA"
	init_prefix_dirs "$PATH_CACHE" "$CACHE_DIRS"
	init_prefix_dirs "$PATH_CONFIG" "$CONFIG_DIRS"
	init_prefix_dirs "$PATH_DATA" "$DATA_DIRS"
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
		cat >> "$file" <<- 'EOF'
		clean_userdir "$PATH_CACHE" "$CACHE_FILES"
		clean_userdir "$PATH_CONFIG" "$CONFIG_FILES"
		clean_userdir "$PATH_DATA" "$DATA_FILES"
		EOF
	fi

	cat >> "$file" <<- EOF

	exit 0
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

# write launcher script - run the DOSBox game
# USAGE: write_bin_run_dosbox
# CALLED BY: write_bin_run
write_bin_run_dosbox() {
	cat >> "$file" <<- 'EOF'
	cd "$PATH_PREFIX"
	dosbox -c "mount c .
	c:
	EOF

	if [ "$GAME_IMAGE" ]; then
		case "$GAME_IMAGE_TYPE" in
			('cdrom')
				cat >> "$file" <<- EOF
				mount d $GAME_IMAGE -t cdrom
				EOF
			;;
			('iso'|*)
				cat >> "$file" <<- EOF
				imgmount d $GAME_IMAGE -t iso -fs iso
				EOF
			;;
		esac
	fi

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	$APP_EXE $APP_OPTIONS $@
	EOF

	if [ "$app_postrun" ]; then
		cat >> "$file" <<- EOF
		$app_postrun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	exit"
	EOF
}

# write launcher script - run the native game
# USAGE: write_bin_run_native
# CALLED BY: write_bin_run
write_bin_run_native() {
	cat >> "$file" <<- 'EOF'
	cd "$PATH_PREFIX"
	rm --force "$APP_EXE"
	if [ -e "$PATH_DATA/$APP_EXE" ]; then
	  source_dir="$PATH_DATA"
	else
	  source_dir="$PATH_GAME"
	fi
	mkdir --parents "$(dirname $APP_EXE)"
	cp "$source_dir/$APP_EXE" "$APP_EXE"
	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	"./$APP_EXE" $APP_OPTIONS $@
	EOF
}

# write launcher script - set ScummVM-specific common vars
# USAGE: write_bin_set_scummvm
write_bin_set_scummvm() {
	cat >> "$file" <<- EOF
	# Set game-specific variables

	GAME_ID='$GAME_ID'
	PATH_GAME='$PATH_GAME'
	SCUMMVM_ID='$(eval echo \$${app}_SCUMMID)'

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

	cat >> "$file" <<- 'EOF'
	scummvm -p "$PATH_GAME" $APP_OPTIONS $@ $SCUMMVM_ID
	EOF
}

# write winecfg launcher script
# USAGE: write_bin_winecfg
# NEEDED VARS: GAME_ID
# CALLS: write_bin
write_bin_winecfg() {
	if [ "$winecfg_launcher" != '1' ]; then
		winecfg_launcher='1'
		APP_WINECFG_ID="${GAME_ID}_winecfg"
		APP_WINECFG_TYPE='wine'
		APP_WINECFG_EXE='winecfg'
		write_bin 'APP_WINECFG'
		local target="${PKG_PATH}${PATH_BIN}/$APP_WINECFG_ID"
		sed --in-place 's/# Run the game/# Run WINE configuration/' "$target"
		sed --in-place 's/cd "$PATH_PREFIX"//' "$target"
		sed --in-place 's/wine "$APP_EXE" $APP_OPTIONS $@/winecfg/' "$target"
	fi
}

# write launcher script - set WINE-specific prefix-specific vars
# USAGE: write_bin_set_wine
# CALLED BY: write_bin_set
write_bin_set_wine() {
	cat >> "$file" <<- 'EOF'
	WINEPREFIX="$XDG_DATA_HOME/play.it/prefixes/$PREFIX_ID"
	PATH_PREFIX="$WINEPREFIX/drive_c/$GAME_ID"
	WINEARCH='win32'
	WINEDEBUG='-all'
	WINEDLLOVERRIDES='winemenubuilder.exe,mscoree,mshtml=d'

	EOF
}

# write launcher script - set WINE-specific user-writables directories
# USAGE: write_bin_build_wine
# CALLED BY: write_bin_build
write_bin_build_wine() {
	cat >> "$file" <<- 'EOF'
	export WINEPREFIX WINEARCH WINEDEBUG WINEDLLOVERRIDES
	if ! [ -e "$WINEPREFIX" ]; then
	  mkdir --parents "$WINEPREFIX"
	  wineboot --init 2>/dev/null
	  rm "$WINEPREFIX/dosdevices/z:"
	fi
	EOF

	if [ "$APP_WINETRICKS" ]; then
		cat >> "$file" <<- EOF
		winetricks $APP_WINETRICKS
		EOF
	fi
}

# write launcher script - run the WINE game
# USAGE: write_bin_run_wine
# CALLED BY: write_bin_run
write_bin_run_wine() {
	cat >> "$file" <<- 'EOF'
	cd "$PATH_PREFIX"
	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	wine "$APP_EXE" $APP_OPTIONS $@
	EOF
}

# write package meta-data
# USAGE: write_metadata $pkg
# NEEDED VARS: $PKG_ARCH $PKG_DEPS $PKG_DESCRIPTION $PKG_ID $PKG_PATH
#  $PKG_PROVIDE $PKG_VERSION $PACKAGE_TYPE
# CALLS: testvar liberror pkg_write_arch pkg_write_deb
write_metadata() {
	if [ $# = 0 ]; then
		write_metadata $PACKAGES_LIST
		return 0
	fi
	for pkg in $@; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'write_metadata'

		# Set package-specific variables
		local pkg_architecture
		set_architecture "$pkg"
		local pkg_id="$(eval echo \$${pkg}_ID)"
		local pkg_maint="$(whoami)@$(hostname)"
		local pkg_path="$(eval echo \$${pkg}_PATH)"
		local pkg_provide="$(eval echo \$${pkg}_PROVIDE)"
		local pkg_version="$(eval echo \$${pkg}_VERSION)"
	        if [ "$(eval echo \$${pkg}_DESCRIPTION_${ARCHIVE#ARCHIVE_})" ]; then
	                pkg_description="$(eval echo \$${pkg}_DESCRIPTION_${ARCHIVE#ARCHIVE_})"
	        else
			pkg_description="$(eval echo \$${pkg}_DESCRIPTION)"
	        fi
		[ "$pkg_version" ] || pkg_version="$PKG_VERSION"

		case $PACKAGE_TYPE in
			('arch')
				pkg_write_arch
			;;
			('deb')
				pkg_write_deb
			;;
		esac

	done
}

# build .pkg.tar or .deb package
# USAGE: build_pkg $pkg[…]
# NEEDED VARS: $PKG_PATH $PACKAGE_TYPE
# CALLS: testvar liberror pkg_build_arch pkg_build_deb
build_pkg() {
	if [ $# = 0 ]; then
		build_pkg $PACKAGES_LIST
		return 0
	fi
	for pkg in $@; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'build_pkg'
		local pkg_path="$(eval echo \$${pkg}_PATH)"
		case $PACKAGE_TYPE in
			('arch')
				pkg_build_arch
			;;
			('deb')
				pkg_build_deb
			;;
			(*)
				liberror 'PACKAGE_TYPE' 'build_pkg'
			;;
		esac
	done
}

# print package building message
# USAGE: pkg_print
# CALLED BY: pkg_build_arch pkg_build_deb
pkg_print() {
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

# write .pkg.tar package meta-data
# USAGE: pkg_write_arch
# CALLED BY: write_metadata
pkg_write_arch() {
	local pkg_deps
	if [ "$(eval echo \$${pkg}_DEPS_ARCH_${ARCHIVE#ARCHIVE_})" ]; then
		pkg_deps="$(eval echo \$${pkg}_DEPS_ARCH_${ARCHIVE#ARCHIVE_})"
	else
		pkg_deps="$(eval echo \$${pkg}_DEPS_ARCH)"
	fi
	local pkg_size=$(du --total --block-size=1 --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
	local target="$pkg_path/.PKGINFO"

	mkdir --parents "${target%/*}"

	cat > "$target" <<- EOF
	pkgname = $pkg_id
	pkgver = $pkg_version
	packager = $pkg_maint
	builddate = $(date +"%m%d%Y")
	size = $pkg_size
	arch = $pkg_architecture
	EOF

	if [ "$pkg_description" ]; then
		cat >> "$target" <<- EOF
		pkgdesc = $GAME_NAME - $pkg_description - ./play.it script version $script_version
		EOF
	else
		cat >> "$target" <<- EOF
		pkgdesc = $GAME_NAME - ./play.it script version $script_version
		EOF
	fi

	for dep in $pkg_deps; do
		cat >> "$target" <<- EOF
		depend = $dep
		EOF
	done

	if [ $pkg_provide ]; then
		cat >> "$target" <<- EOF
		conflict = $pkg_provide
		provides = $pkg_provide
		EOF
	fi

	target="$pkg_path/.INSTALL"

	if [ -e "$postinst" ]; then
		cat >> "$target" <<- EOF
		post_install() {
		$(cat "$postinst")
		}

		post_upgrade() {
		post_install
		}
		EOF
	fi

	if [ -e "$prerm" ]; then
		cat >> "$target" <<- EOF
		pre_remove() {
		$(cat "$prerm")
		}

		pre_upgrade() {
		pre_remove
		}
		EOF
	fi
}

# build .pkg.tar package
# USAGE: pkg_build_arch
# NEEDED VARS: $PLAYIT_WORKDIR $COMPRESSION_METHOD
# CALLS: pkg_print
# CALLED BY: build_pkg
pkg_build_arch() {
	local pkg_filename="$PWD/${pkg_path##*/}.pkg.tar"
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
	pkg_print
	(
		cd "$pkg_path"
		local files='.PKGINFO *'
		if [ -e '.INSTALL' ]; then
			files=".INSTALL $files"
		fi
		tar $tar_options --file "$pkg_filename" $files
	)
	export ${pkg}_PKG="$pkg_filename"
}

# write .deb package meta-data
# USAGE: pkg_write_deb
# CALLED BY: write_metadata
pkg_write_deb() {
	local pkg_deps="$(eval echo \$${pkg}_DEPS_DEB)"
	local pkg_size=$(du --total --block-size=1K --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
	local target="$pkg_path/DEBIAN/control"

	mkdir --parents "${target%/*}"

	cat > "$target" <<- EOF
	Package: $pkg_id
	Version: $pkg_version
	Architecture: $pkg_architecture
	Maintainer: $pkg_maint
	Installed-Size: $pkg_size
	Section: non-free/games
	EOF

	if [ "$pkg_provide" ]; then
		cat >> "$target" <<- EOF
		Conflicts: $pkg_provide
		Provides: $pkg_provide
		Replaces: $pkg_provide
		EOF
	fi

	if [ "$pkg_deps" ]; then
		cat >> "$target" <<- EOF
		Depends: $pkg_deps
		EOF
	fi

	if [ "$pkg_description" ]; then
		cat >> "$target" <<- EOF
		Description: $GAME_NAME - $pkg_description
		 ./play.it script version $script_version
		EOF
	else
		cat >> "$target" <<- EOF
		Description: $GAME_NAME
		 ./play.it script version $script_version
		EOF
	fi

	if [ "$pkg_architecture" = 'all' ]; then
		sed -i 's/Architecture: all/&\nMulti-Arch: foreign/' "$target"
	fi

	if [ -e "$postinst" ]; then
		target="$pkg_path/DEBIAN/postinst"
		cat > "$target" <<- EOF
		#!/bin/sh -e

		$(cat "$postinst")

		exit 0
		EOF
		chmod 755 "$target"
	fi

	if [ -e "$prerm" ]; then
		target="$pkg_path/DEBIAN/prerm"
		cat > "$target" <<- EOF
		#!/bin/sh -e

		$(cat "$prerm")

		exit 0
		EOF
		chmod 755 "$target"
	fi
}

# build .deb package
# USAGE: pkg_build_deb
# NEEDED VARS: $PLAYIT_WORKDIR $COMPRESSION_METHOD
# CALLS: pkg_print
# CALLED BY: build_pkg
pkg_build_deb() {
	local pkg_filename="$PWD/${pkg_path##*/}.deb"
	local dpkg_options="-Z$COMPRESSION_METHOD"
	pkg_print
	TMPDIR="$PLAYIT_WORKDIR" fakeroot -- dpkg-deb $dpkg_options --build "$pkg_path" "$pkg_filename" 1>/dev/null
	export ${pkg}_PKG="$pkg_filename"
}

