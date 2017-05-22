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
# conversion script for the Wasteland 2 installer sold on GOG.com
# build a .deb package from the MojoSetup installer
# tested on Debian, should work on any .deb-based distribution
#
# script version 20151127.1
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

# Set game-specific variables

GAME_ID='wasteland-2'
GAME_ID_SHORT='wl2'
GAME_NAME='Wasteland 2'

GAME_ARCHIVE1='gog_wasteland_2_2.9.0.14.sh'
GAME_ARCHIVE1_MD5='8421db3519ed0074ff2647f5ea53f6f6'
GAME_ARCHIVE_FULLSIZE='20000000'
PKG_ORIGIN='gog'
PKG_REVISION='2.9.0.14'

APP1_ID="${GAME_ID}"
APP1_EXE='./WL2'
APP1_ICON='WL2_Data/Resources/UnityPlayer.png'
APP1_ICON_RES='128x128'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG1_ID="${GAME_ID}"
PKG1_VERSION='1.6.65562'
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}"

PKG2_ID="${GAME_ID}-scenes-az"
PKG2_VERSION="${PKG1_VERSION}"
PKG2_ARCH="${PKG1_ARCH}"
PKG2_CONFLICTS=''
PKG2_RECS=''
PKG2_DESC="${GAME_NAME} (scenes AZ)"

PKG3_ID="${GAME_ID}-scenes-ca"
PKG3_VERSION="${PKG1_VERSION}"
PKG3_ARCH="${PKG1_ARCH}"
PKG3_CONFLICTS=''
PKG3_RECS=''
PKG3_DESC="${GAME_NAME} (scenes CA)"

PKG1_DEPS="${PKG2_ID} (= ${PKG2_VERSION}-${PKG_ORIGIN}${PKG_REVISION}), ${PKG3_ID} (= ${PKG3_VERSION}-${PKG_ORIGIN}${PKG_REVISION}), libasound2, libglu1-mesa | libglu1, libxcursor1, libxrandr2"
PKG2_DEPS=''
PKG3_DEPS=''

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
game_mkdir 'PKG3_DIR' "${PKG3_ID}_${PKG3_VERSION}-${PKG_ORIGIN}${PKG_REVISION}_${PKG3_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
fetch_args "$@"
check_deps 'fakeroot realpath unzip'
printf '\n'
set_checksum
set_compression
set_prefix

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON="/usr/local/share/icons/hicolor/${APP1_ICON_RES}/apps"

printf '\n'
set_target '1' 'gog.com'
printf '\n'

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}"
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC}" "${PATH_GAME}" "${PATH_ICON}"
for dir in "${PKG2_DIR}" "${PKG3_DIR}"; do
	rm -rf "${dir}"
	mkdir -p "${dir}${PATH_GAME}/WL2_Data/Streaming/Scenes" "${dir}/DEBIAN"
done
print wait
extract_data 'mojo' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'fix_rights,quiet'
mv "${PKG_TMPDIR}/data/noarch/docs"/* "${PKG1_DIR}${PATH_DOC}"
mv "${PKG_TMPDIR}/data/noarch/game/WL2_Data/Streaming/Scenes"/AZ* "${PKG2_DIR}${PATH_GAME}/WL2_Data/Streaming/Scenes"
mv "${PKG_TMPDIR}/data/noarch/game/WL2_Data/Streaming/Scenes"/CA* "${PKG3_DIR}${PATH_GAME}/WL2_Data/Streaming/Scenes"
mv "${PKG_TMPDIR}/data/noarch/game"/* "${PKG1_DIR}${PATH_GAME}"
chmod 755 "${PKG1_DIR}${PATH_GAME}"/${APP1_EXE}
ln -s "${PATH_GAME}/${APP1_ICON}" "${PKG1_DIR}${PATH_ICON}/${APP1_ID}.png"
rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' '' "${APP1_NAME}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}"
printf '\n'

# Build package

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait
write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}"
write_pkg_debian "${PKG3_DIR}" "${PKG3_ID}" "${PKG3_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG3_ARCH}" "${PKG3_CONFLICTS}" "${PKG3_DEPS}" "${PKG3_RECS}" "${PKG3_DESC}"
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG3_DIR}" "${PKG3_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done
print_instructions "${PKG1_DESC}" "${PKG2_DIR}" "${PKG3_DIR}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
