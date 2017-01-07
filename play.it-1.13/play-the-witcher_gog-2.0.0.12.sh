#!/bin/sh -e

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
# conversion script for The Witcher: Enhanced Edition installer sold on GOG.com
# build a .deb package from the Windows installer
# tested on Debian, should work on any .deb-based distribution
#
# script version 20161113.1
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

# Set game-specific variables

GAME_ID='the-witcher'
GAME_ID_SHORT='witcher1'
GAME_NAME='The Witcher'
GAME_NAME_LONG='The Witcher: Enhanced Edition'

GAME_ARCHIVE1='setup_the_witcher_enhanced_edition_2.0.0.12.exe'
GAME_ARCHIVE1_MD5='66ffe865f34e71ef2beb961748873459'
GAME_ARCHIVE1_FILE2='setup_the_witcher_enhanced_edition_2.0.0.12-1.bin'
GAME_ARCHIVE1_FILE2_MD5='6d24dcb24f4776889e03715044ca8da0'
GAME_ARCHIVE1_FILE3='setup_the_witcher_enhanced_edition_2.0.0.12-2.bin'
GAME_ARCHIVE1_FILE3_MD5='3060962cd3ef2ec68a9c02fdeb5ce839'
GAME_ARCHIVE1_FILE4='setup_the_witcher_enhanced_edition_2.0.0.12-3.bin'
GAME_ARCHIVE1_FILE4_MD5='602a920d5e2c05437f70c5600911aca8'
GAME_ARCHIVE1_FILE5='setup_the_witcher_enhanced_edition_2.0.0.12-4.bin'
GAME_ARCHIVE1_FILE5_MD5='296605a9b5e7acba6a59cd17b98a84c6'
GAME_ARCHIVE1_FILE6='setup_the_witcher_enhanced_edition_2.0.0.12-5.bin'
GAME_ARCHIVE1_FILE6_MD5='a820dc0f09afefead9e06a9c37491c1b'
GAME_ARCHIVE1_FILE7='setup_the_witcher_enhanced_edition_2.0.0.12-6.bin'
GAME_ARCHIVE1_FILE7_MD5='e5261e0eff49b83f48a384ece3050106'
GAME_ARCHIVE_FULLSIZE='15000000'
PKG_ORIGIN='gog'
PKG_REVISION='2.0.0.12'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='system/*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS=''
GAME_DATA_FILES=''
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./system/witcher.exe'
APP1_ICON='./system/witcher.exe'
APP1_ICON_RES='16x16 32x32 48x48'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG1_ID="${GAME_ID}"
PKG1_VERSION='1.5.726'
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_RECS=''
PKG1_DESC="${GAME_NAME_LONG}"

PKG2_ID="${GAME_ID}-data"
PKG2_VERSION="${PKG1_VERSION}"
PKG2_ARCH="${PKG1_ARCH}"
PKG2_CONFLICTS=''
PKG2_RECS=''
PKG2_DESC="${GAME_NAME_LONG} (data)"

PKG1_DEPS="${PKG2_ID} (= ${PKG2_VERSION}-${PKG_ORIGIN}${PKG_REVISION}), wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386, winetricks"
PKG2_DEPS=''

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
GAME_LANG_DEFAULT=''
WITH_MOVIES_DEFAULT=''

printf '\n'
game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_ORIGIN}${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG2_VERSION}-${PKG_ORIGIN}${PKG_REVISION}_${PKG2_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
fetch_args "$@"
check_deps 'fakeroot innoextract' 'icotool wrestool'
printf '\n'
set_checksum
set_compression
set_prefix

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

printf '\n'
set_target '1' 'gog.com'
set_target_extra 'GAME_ARCHIVE1_FILE2' '' "${GAME_ARCHIVE1_FILE2}"
set_target_extra 'GAME_ARCHIVE1_FILE3' '' "${GAME_ARCHIVE1_FILE3}"
set_target_extra 'GAME_ARCHIVE1_FILE4' '' "${GAME_ARCHIVE1_FILE4}"
set_target_extra 'GAME_ARCHIVE1_FILE5' '' "${GAME_ARCHIVE1_FILE5}"
set_target_extra 'GAME_ARCHIVE1_FILE6' '' "${GAME_ARCHIVE1_FILE6}"
set_target_extra 'GAME_ARCHIVE1_FILE7' '' "${GAME_ARCHIVE1_FILE7}"
printf '\n'

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	printf '%s…\n' "$(l10n 'checksum_multiple')"
	print wait
	checksum "${GAME_ARCHIVE}" 'quiet' "${GAME_ARCHIVE1_MD5}" "${GAME_ARCHIVE2_MD5}"
	checksum "${GAME_ARCHIVE1_FILE2}" 'quiet' "${GAME_ARCHIVE1_FILE2_MD5}"
	checksum "${GAME_ARCHIVE1_FILE3}" 'quiet' "${GAME_ARCHIVE1_FILE3_MD5}"
	checksum "${GAME_ARCHIVE1_FILE4}" 'quiet' "${GAME_ARCHIVE1_FILE4_MD5}"
	checksum "${GAME_ARCHIVE1_FILE5}" 'quiet' "${GAME_ARCHIVE1_FILE5_MD5}"
	checksum "${GAME_ARCHIVE1_FILE6}" 'quiet' "${GAME_ARCHIVE1_FILE6_MD5}"
	checksum "${GAME_ARCHIVE1_FILE7}" 'quiet' "${GAME_ARCHIVE1_FILE7_MD5}"
	print done
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC}" "${PATH_GAME}"
rm -rf "${PKG2_DIR}"
mkdir -p "${PKG2_DIR}${PATH_GAME}/data" "${PKG2_DIR}/DEBIAN"
print wait
extract_data 'inno' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'
for file in 'manual.pdf' 'readme.rtf' 'release.txt'; do
	mv "${PKG_TMPDIR}/app"/${file} "${PKG1_DIR}${PATH_DOC}"
done
for file in 'meshes*' 'textures*' 'movies/'; do
	mv "${PKG_TMPDIR}/app/data"/${file} "${PKG2_DIR}${PATH_GAME}/data"
done
mv "${PKG_TMPDIR}/app"/* "${PKG1_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}/commondocs" "${PKG1_DIR}${PATH_GAME}"
if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
fi
rm -rf "${PKG_TMPDIR}"
cat > "${PKG1_DIR}${PATH_GAME}/witcher1.reg" << EOF
REGEDIT 4

[HKEY_LOCAL_MACHINE\Software\CD Projekt Red\The Witcher]
"InstallFolder"="C:\\the-witcher\\"
"IsDjinniInstalled"=dword:00000001
"Language"="3"
"RegionVersion"="WE"
EOF
print done

# Write launchers

write_bin_wine_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
sed -i 's#cp -surf "${GAME_PATH}"/\* "${WINE_GAME_PATH}"#&\n\tcp -surf "${GAME_PATH}"/commondocs/* "${WINEPREFIX}/drive_c/users/Public/Documents/"\n\tregedit "${WINE_GAME_PATH}/witcher1.reg" 2>/dev/null\n\trm -r "${WINE_GAME_PATH}/commondocs" "${WINE_GAME_PATH}/witcher1.reg"\n\twinetricks d3dx9_35\n\twinetricks d3dx9_36#' "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'wine'
printf '\n'

# Build package

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait
write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}"
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done
print_instructions "${PKG1_DESC}" "${PKG2_DIR}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
