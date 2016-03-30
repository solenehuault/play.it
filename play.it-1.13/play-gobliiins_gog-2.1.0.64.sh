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
# conversion script for the Gobliiins installer sold on GOG.com
# build a .deb package from the Windows installer
# tested on Debian, should work on any .deb-based distribution
#
# script version 20151127.1
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

# Set game-specific variables

GAME_ID='gobliiins'
GAME_ID_SHOR='gob1'
SCUMMVM_ID='gob'
GAME_NAME='Gobliiins'

GAME_ARCHIVE1='setup_gobliiins_2.1.0.64.exe'
GAME_ARCHIVE1_MD5='e587f246c7dedb84b30ee09e6f1c5462'
GAME_ARCHIVE_FULLSIZE='94000'
PKG_ORIGIN='gog'
PKG_REVISION='2.1.0.64'

#APP1_ICON='./goggame-1207662273.ico'
#APP1_ICON_RES='16x16 32x32 48x48 256x256'
APP1_CAT='Game'

PKG1_ID="${GAME_ID}-floppy"
PKG2_ID="${GAME_ID}-cd"

PKG1_APP1_ID="${PKG1_ID}"
PKG1_APP1_NAME="${GAME_NAME} (floppy version)"
PKG1_APP1_NAME_FR="${GAME_NAME} (version disquette)"

PKG2_APP1_ID="${PKG2_ID}"
PKG2_APP1_NAME="${GAME_NAME} (CD version)"
PKG2_APP1_NAME_FR="${GAME_NAME} (version CD)"

PKG1_VERSION='1.0'
PKG1_ARCH='all'
PKG1_CONFLICTS=''
PKG1_DEPS='scummvm'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME} (floppy version)"

PKG2_VERSION="${PKG1_VERSION}"
PKG2_ARCH="${PKG1_ARCH}"
PKG2_CONFLICTS="${PKG1_CONFLICTS}"
PKG2_DEPS="${PKG1_DEPS}"
PKG2_RECS="${PKG1_RECS}"
PKG2_DESC="${GAME_NAME} (CD version)"

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
game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG2_VERSION}-${PKG_ORIGIN}${PKG_REVISION}_${PKG2_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
fetch_args "$@"
check_deps 'fakeroot innoextract'
NO_ICON='1'
printf '\n'
set_checksum
set_compression
set_prefix
set_lang

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_ICON_BASE='/usr/local/share/icons/hicolor'
PKG1_PATH_DOC="${PKG_PREFIX}/share/doc/${PKG1_ID}"
PKG2_PATH_DOC="${PKG_PREFIX}/share/doc/${PKG2_ID}"
PKG1_PATH_GAME="${PKG_PREFIX}/share/games/${PKG1_ID}"
PKG2_PATH_GAME="${PKG_PREFIX}/share/games/${PKG2_ID}"


printf '\n'
set_target '1' 'gog.com'
printf '\n'

# Checking target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}"
fi

# Extract game data

for dir in "${PATH_BIN}" "${PATH_DESK}" "${PKG1_PATH_DOC}" "${PKG1_PATH_GAME}" '/DEBIAN/'; do
	mkdir -p "${PKG1_DIR}${dir}"
done
for dir in "${PATH_BIN}" "${PATH_DESK}" "${PKG2_PATH_DOC}" "${PKG2_PATH_GAME}" '/DEBIAN/'; do
	mkdir -p "${PKG2_DIR}${dir}"
done
extract_data 'inno' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'defaults'
for file in 'app/*.pdf' 'tmp/gog_eula.txt'; do
	cp -l "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PKG1_PATH_DOC}"
	cp -l "${PKG_TMPDIR}"/${file} "${PKG2_DIR}${PKG2_PATH_DOC}"
done
mv "${PKG_TMPDIR}/app/fdd"/* "${PKG1_DIR}${PKG1_PATH_GAME}"
for file in './gob.lic' './intro.stk' './track1.mp3'; do
	mv "${PKG_TMPDIR}/app"/${file} "${PKG2_DIR}${PKG2_PATH_GAME}"
done
rm -rf "${PKG_TMPDIR}"

# Write launchers
PATH_GAME="${PKG1_PATH_GAME}"
write_bin_scummvm "${PKG1_DIR}${PATH_BIN}/${PKG1_APP1_ID}" "${SCUMMVM_ID}" '' '' "${PKG1_APP1_NAME}"
PATH_GAME="${PKG2_PATH_GAME}"
write_bin_scummvm "${PKG2_DIR}${PATH_BIN}/${PKG2_APP1_ID}" "${SCUMMVM_ID}" '' '' "${PKG2_APP1_NAME}"
write_desktop "${PKG1_APP1_ID}" "${PKG1_APP1_NAME}" "${PKG1_APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${PKG1_APP1_ID}.desktop" "${APP1_CAT}" 'scummvm'
write_desktop "${PKG2_APP1_ID}" "${PKG2_APP1_NAME}" "${PKG2_APP1_NAME_FR}" "${PKG2_DIR}${PATH_DESK}/${PKG2_APP1_ID}.desktop" "${APP1_CAT}" 'scummvm'
if [ "${GAME_LANG}" = 'fr' ]; then
	sed -i 's/Exec=.\+/& -q fr/' "${PKG2_DIR}${PATH_DESK}/${PKG2_APP1_ID}.desktop"
fi
printf '\n'

# Build packages
write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}"
printf '%s…\n' "$(l10n 'build_pkgs')"
print wait
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done
print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n'
print_instructions "${PKG2_DESC}" "${PKG2_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
