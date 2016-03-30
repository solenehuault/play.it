#!/bin/sh -e

###
# Copyright (c) 2015-2016, Antoine Le Gonidec
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
# conversion script for the Neverwinter Nights installer sold on GOG.com
# build a .deb package from the Windows installer
# tested on Debian, should work on any .deb-based distribution
#
# script version 20160121.1
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unar'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='neverwinter-nights'
GAME_ID_SHORT='nwn'
GAME_NAME='Neverwinter Nights'

GAME_ARCHIVE1='setup_nwn_diamond_french_2.1.0.19.exe'
GAME_ARCHIVE2='setup_nwn_diamond_french_2.1.0.19.bin'
GAME_ARCHIVE2_MD5='ec4444d6eec0f8ac8503fccf327af3c6'
GAME_GOGID='1207658890'
CLIENT_ARCHIVE1='nwclientgold.tar.gz'
CLIENT_ARCHIVE1_URL='http://nwdownloads.bioware.com/neverwinternights/linux/gold/nwclientgold.tar.gz'
CLIENT_ARCHIVE1_MD5='0a059d55225fc32f905e86191d88a11f'
CLIENT_ARCHIVE2='nwclienthotuintl.tar.gz'
CLIENT_ARCHIVE2_URL='http://files.bioware.com/neverwinternights/updates/linux/nwclienthotuintl.tar.gz'
CLIENT_ARCHIVE2_MD5='cc63d00327ea5426c5a2322075cafba7'
CLIENT_ARCHIVE3='French_linuxclient168_xp2.tar.gz'
CLIENT_ARCHIVE3_URL='http://files.bioware.com/neverwinternights/updates/linux/168/French_linuxclient168_xp2.tar.gz'
CLIENT_ARCHIVE3_MD5='83af9f06cc1bbe38d5cb90fe2da6a1a6'
CLIENT_ARCHIVE_MOVIES='nwmovies-mpv.tar.gz'
CLIENT_ARCHIVE_MOVIES_URL='https://sites.google.com/site/nwmoviesmpv/'
CLIENT_ARCHIVE_MOVIES_MD5='71f3d88db1cd75665b62b77f7604dce1'
GAME_ARCHIVE_FULLSIZE='4800000'
PKG_REVISION='gog2.1.0.19'

INSTALLER_DOC='game/docs'
INSTALLER_GAME='game/nwn.exe game/ambient game/data game/dmvault game/hak game/localvault game/modules game/movies game/music game/nwm game/override game/texturepacks game/*.key game/*.tlk game/*.TLK'

NWMOVIES_BUILD_REQ_32="gcc libelf-dev:i386 libsdl1.2-dev"
NWMOVIES_BUILD_REQ_64="${NWMOVIES_BUILD_REQ_32} gcc-multilib"

GAME_CACHE_DIRS='/temp ./tempclient'
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./nwncdkey.ini ./nwn.ini ./nwnplayer.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS=''
GAME_DATA_FILES='./nwn'

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./nwn'
APP1_ICON='./nwn.exe'
APP1_ICON_RES='32x32'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG1_ID="${GAME_ID}"
PKG1_VERSION='1.68.8099'
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='libglu1-mesa | ligblu1, libsdl1.2debian'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version 20160121.1"

# Load common functions

TARGET_LIB_VERSION='1.13'
if ! [ -e './play-anything.sh' ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'play-anything.sh not found.\nIt must be placed in the same directory than this script.\n\n'
	exit 1
fi
LIB_VERSION="$(grep '^# library version' './play-anything.sh' | cut -d' ' -f4 | cut -d'.' -f1,2)"
if [ ${LIB_VERSION%.*} -ne ${TARGET_LIB_VERSION%.*} ] || [ ${LIB_VERSION#*.} -lt ${TARGET_LIB_VERSION#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'Wrong version of play-anything.\nIt must be at least %s but lower than %s.\n\n' "${TARGET_LIB_VERSION}" "$((${TARGET_LIB_VERSION%.*}+1)).0"
	exit 1
fi
. './play-anything.sh'

# Define script-specific functions

set_nwmovies() {
if [ -z "${WITH_MOVIES}" ]; then
	export WITH_NWMOVIE="${WITH_MOVIES_DEFAULT}"
fi
if [ "${WITH_MOVIES}" = '1' ]; then
	printf '%s.\n' "$(l10n 'movies_enabled')"
	if [ "$(uname -m)" = 'x86_64' ]; then
		NWMOVIES_BUILD_REQ="${NWMOVIES_BUILD_REQ_64}"
	else
		NWMOVIES_BUILD_REQ="${NWMOVIES_BUILD_REQ_32}"
	fi
	for pkg in ${NWMOVIES_BUILD_REQ}; do
		if ! dpkg -s "${pkg}" > /dev/null 2>&1; then
			print error
			printf "%s:\n%s\n" "$(l10n 'movies_build_deps')" "${NWMOVIES_BUILD_REQ}"
			exit 1
		fi
	done
else
	print warning
	printf '%s.\n' "$(l10n 'movies_disabled')"
fi
}

# Set extra variables

PKG_PREFIX_DEFAULT='/usr/local'
PKG_COMPRESSION_DEFAULT='none'
GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
GAME_LANG_DEFAULT=''
WITH_MOVIES_DEFAULT='0'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
fetch_args "$@"
printf '\n'
check_deps "${SCRIPT_DEPS_HARD}" "${SCRIPT_DEPS_SOFT}"
printf '\n'
set_checksum
set_compression
set_prefix
set_nwmovies

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

printf '\n'
set_target '1' 'gog.com'
set_target_extra 'GAME_ARCHIVE' '' "${GAME_ARCHIVE2}" 
set_target_extra 'CLIENT_ARCHIVE1' "${CLIENT_ARCHIVE1_URL}" "${CLIENT_ARCHIVE1}"
set_target_extra 'CLIENT_ARCHIVE2' "${CLIENT_ARCHIVE2_URL}" "${CLIENT_ARCHIVE2}"
set_target_extra 'CLIENT_ARCHIVE3' "${CLIENT_ARCHIVE3_URL}" "${CLIENT_ARCHIVE3}"
if [ "$WITH_MOVIES" = '1' ]; then
	set_target_extra 'CLIENT_ARCHIVE_MOVIES' "${CLIENT_ARCHIVE_MOVIES_URL}" "${CLIENT_ARCHIVE_MOVIES}" 
fi
printf '\n'

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	printf '%s…\n' "$(l10n 'checksum_multiple')"
	print wait
	checksum "${GAME_ARCHIVE}" 'quiet' "${GAME_ARCHIVE2_MD5}"
	checksum "${CLIENT_ARCHIVE1}" 'quiet' "${CLIENT_ARCHIVE1_MD5}"
	checksum "${CLIENT_ARCHIVE2}" 'quiet' "${CLIENT_ARCHIVE2_MD5}"
	checksum "${CLIENT_ARCHIVE3}" 'quiet' "${CLIENT_ARCHIVE3_MD5}"
	if [ "$WITH_MOVIES" = '1' ]; then
		checksum "${CLIENT_ARCHIVE_MOVIES}" 'quiet' "${CLIENT_ARCHIVE_MOVIES_MD5}"
	fi
	print done
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC}" "${PATH_GAME}"
print wait
extract_data 'unar_passwd' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet' "$(printf "${GAME_GOGID}" | md5sum | cut -d' ' -f1)"
for file in ${INSTALLER_DOC}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_DOC}"
done
for file in ${INSTALLER_GAME}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_GAME}"
done
for dir in 'portraits' 'saves' 'servervault'; do
	mkdir "${PKG1_DIR}${PATH_GAME}/${dir}"
done
mv "${PKG1_DIR}${PATH_GAME}/dialogF.TLK" "${PKG1_DIR}${PATH_GAME}/dialogf.tlk"
extract_data 'tar' "${CLIENT_ARCHIVE1}" "${PKG1_DIR}${PATH_GAME}" 'quiet,fix_rights'
extract_data 'tar' "${CLIENT_ARCHIVE2}" "${PKG1_DIR}${PATH_GAME}" 'quiet,fix_rights'
extract_data 'tar' "${CLIENT_ARCHIVE3}" "${PKG1_DIR}${PATH_GAME}" 'quiet,fix_rights'
rm "${PKG1_DIR}${PATH_GAME}/lib"/*
mv "${PKG1_DIR}${PATH_GAME}"/*.txt "${PKG1_DIR}${PATH_DOC}"
mv "${PKG_TMPDIR}/support/app/nwncdkey.ini" "${PKG1_DIR}${PATH_GAME}"
touch "${PKG1_DIR}${PATH_GAME}/lib/libtxc_dxtn.so"
for file in 'nwmain' 'dmclient' 'nwn' 'nwserver' 'fixinstall'; do
	chmod 755 "${PKG1_DIR}${PATH_GAME}/${file}"
done
if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
fi
rm "${PKG1_DIR}${PATH_GAME}/${APP1_ICON}"
rm -Rf "${PKG_TMPDIR}"

# Building nwmovies

if [ "${WITH_MOVIES}" = '1' ]; then
	extract_data 'tar' "${CLIENT_ARCHIVE_MOVIES}" "${PKG1_DIR}${PATH_GAME}" 'quiet'
	cd "${PKG1_DIR}${PATH_GAME}"
	# Build nwmovies
	printf '%s NWMovies…\n' "$(l10n 'build_generic')"
	./nwmovies_install.pl build > /dev/null 2>&1
	sed -i 's/mpv /mpv --fs --no-osc /' ./nwmovies/nwplaymovie
	# Cleanup what is no longer required
	for file in '*.c' '*.h' '*.S' '*.pl' '*.map'; do
		rm -f ./${file} nwmovies/${file} nwmovies/libdis/${file}
	done
	# Patch the launcher
	mv ./nwn ./nwn.real
	sed 's#./nwmain $@#export LD_PRELOAD=./nwmovies.so\n./nwmain $@#' ./nwn.real > ./nwn.nwmovies
	chmod 755 ./nwn.nwmovies
	ln -s ./nwn.nwmovies ./nwn
	cd - > /dev/null
	PKG1_DEPS="${PKG1_DEPS}, mpv:amd64|mpv"
fi
print done

# Write launchers

write_bin_native_prefix_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_native_prefix "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' '' "${GAME_NAME}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'neverwinter-nights'
printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}"
print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
