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
# conversion script for the Icewind Dale installer sold on GOG.com
# build a .deb package from the Windows installer
# tested on Debian, should work on any .deb-based distribution
#
# script version 20160304.1
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

# Set game-specific variables

GAME_ID='icewind-dale'
GAME_ID_SHORT='iwd1'
GAME_NAME='Icewind Dale'
GAME_NAME_PKG='Icewind Dale + Heart of Winter'

GAME_ARCHIVE1='setup_icewind_dale_complete_2.0.0.11.exe'
GAME_ARCHIVE1_MD5='b1395109232aac8d7f8455dad418b084'
GAME_ARCHIVE_FULLSIZE='2100000'
PKG_ORIGIN='gog'
PKG_REVISION='2.0.0.11'

TRADFR_URL='http://www.dotslashplay.it/ressources/icewind-dale/'
TRADFR_ARCHIVE1='iwd1fr-full.7z'
TRADFR_ARCHIVE1_MD5='26db385def6b4a3a5bd207d0610c4fd5'
TRADFR_ARCHIVE2='iwd1fr-light.7z'
TRADFR_ARCHIVE2_MD5='76659378ad94988a75187ec6db16a845'
TRADFR_ARCHIVE3='iwd1fr-ultralight.7z'
TRADFR_ARCHIVE3_MD5='b3727aedc1a9eb678e1cf43777b447fd'

GAME_CACHE_DIRS='./cache ./temp'
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./characters ./mpsave ./override ./portraits ./scripts'
GAME_DATA_FILES='./chitin.key ./*.tlk'
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./idmain.exe'
APP1_ICON="${APP1_EXE}"
APP1_ICON_RES='16x16 32x32'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

APP2_ID="${GAME_ID}_config"
APP2_EXE='./config.exe'
APP2_ICON="${APP2_EXE}"
APP2_ICON_RES='16x16 32x32'
APP2_NAME="${GAME_NAME} (settings)"
APP2_NAME_FR="${GAME_NAME} (réglages)"
APP2_CAT='Settings'

PKG1_ID="${GAME_ID}"
PKG1_VERSION='1.42.062714'
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME_PKG}"

# Load common functions

TARGET_LIB_VERSION='1.13'
if [ -z "${PLAYIT_LIB}" ]; then
	PLAYIT_LIB='./play-anything.sh'
fi
if ! [ -e "${PLAYIT_LIB}" ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'play-anything.sh not found.\n'
	printf 'It must be placed in the same directory than this script.\n\n'
	exit 1
fi
LIB_VERSION="$(grep '^# library version' "${PLAYIT_LIB}" | cut -d' ' -f4 | cut -d'.' -f1,2)"
if [ ${LIB_VERSION%.*} -ne ${TARGET_LIB_VERSION%.*} ] || [ ${LIB_VERSION#*.} -lt ${TARGET_LIB_VERSION#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'Wrong version of play-anything.\n'
	printf 'It must be at least %s ' "${TARGET_LIB_VERSION}"
	printf 'but lower than %s.\n\n' "$((${TARGET_LIB_VERSION%.*}+1)).0"
	exit 1
fi
. "${PLAYIT_LIB}"

# Set extra variables

PKG_PREFIX_DEFAULT='/usr/local'
PKG_COMPRESSION_DEFAULT='none'
GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
GAME_LANG_DEFAULT='en'
WITH_MOVIES_DEFAULT=''

printf '\n'
game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_ORIGIN}${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
fetch_args "$@"
check_deps 'fakeroot innoextract realpath' 'icotool wrestool'
printf '\n'
set_checksum
set_compression
set_prefix
set_lang
if [ "${GAME_LANG}" = 'fr' ]; then
	check_deps_7z
fi

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

printf '\n'
set_target '1' 'gog.com'
if [ "${GAME_LANG}" = 'fr' ]; then
	set_target_extra 'TRADFR_ARCHIVE' "${TRADFR_URL}" "${TRADFR_ARCHIVE1}" "${TRADFR_ARCHIVE2}" "${TRADFR_ARCHIVE3}"
fi
printf '\n'

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	printf '%s…\n' "$(l10n 'checksum_multiple')"
	print wait
	checksum "${GAME_ARCHIVE}" 'quiet' "${GAME_ARCHIVE1_MD5}" "${GAME_ARCHIVE2_MD5}"
	if [ "${GAME_LANG}" = 'fr' ]; then
		checksum "${TRADFR_ARCHIVE}" 'quiet' "${TRADFR_ARCHIVE1_MD5}" "${TRADFR_ARCHIVE2_MD5}" "${TRADFR_ARCHIVE3_MD5}"
	fi
	print done
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC}" "${PATH_GAME}"
print wait
extract_data 'inno' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'
if [ "${GAME_LANG}" = 'fr' ]; then
	rm -r "${PKG_TMPDIR}/app/characters"
	rm -r "${PKG_TMPDIR}/app/scripts"
	if [ "${TRADFR_ARCHIVE##*/}" = "${TRADFR_ARCHIVE1}" ] || [ "${TRADFR_ARCHIVE##*/}" = "${TRADFR_ARCHIVE2}" ]; then
		rm -r "${PKG_TMPDIR}/app/sounds"
	fi
	extract_data '7z' "${TRADFR_ARCHIVE}" "${PKG_TMPDIR}/app" 'force,quiet'
fi
for file in 'tmp/gog_eula.txt' 'app/manual.pdf' 'app/*.txt' ; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_DOC}"
done
mv "${PKG_TMPDIR}/app"/* "${PKG1_DIR}${PATH_GAME}"
ini_file="${PKG1_DIR}${PATH_GAME}/icewind.ini"
for drive in 'HD0' 'CD1'; do
	sed -i "s/${drive}:=.\+/${drive}:=C:\\\\${GAME_ID}\\\\/" "${ini_file}"
done
sed -i "s/CD2:=.\+/CD2:=C:\\\\${GAME_ID}\\\\cd2\\\\/" "${ini_file}"
sed -i "s/CD3:=.\+/CD3:=C:\\\\${GAME_ID}\\\\cd3\\\\/" "${ini_file}"
if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
	extract_icons "${APP2_ID}" "${APP2_ICON}" "${APP2_ICON_RES}" "${PKG_TMPDIR}"
fi
rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_wine_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE}" '' '' "${APP2_NAME}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'wine'
write_desktop "${APP2_ID}" "${APP2_NAME}" "${APP2_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP2_ID}.desktop" "${APP2_CAT}" 'wine'
printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'defaults'
print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
