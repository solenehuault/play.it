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
# conversion script for the Goblins 3 installer sold on GOG.com
# build a .deb package from the Windows installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170405.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot innoextract fakeroot'
SCRIPT_DEPS_SOFT='icotool'

GAME_ID='goblins-3'
GAME_ID_PKG1="${GAME_ID}-floppy"
GAME_ID_PKG2="${GAME_ID}-cd"
GAME_ID_SHORT='gob3'
GAME_NAME='Goblins Quest 3'
GAME_NAME_PKG1="${GAME_NAME} - floppy version"
GAME_NAME_PKG2="${GAME_NAME} - CD version"

GAME_ARCHIVE1='setup_gobliiins3_2.1.0.64.exe'
GAME_ARCHIVE1_MD5='d5d287d784a33ec5fed9372ba451e25a'
GAME_ARCHIVE2='setup_gobliiins3_french_2.1.0.64.exe'
GAME_ARCHIVE2_MD5='e830430896de19f11d7cfcc92c5669b9'
GAME_ARCHIVE_FULLSIZE='210000'
PKG_REVISION='gog2.1.0.64'

INSTALLER_DOC='app/*.pdf tmp/gog_eula.txt'
INSTALLER_GAME_PKG1='app/goggame-1207662313.ico app/fdd/*'
INSTALLER_GAME_PKG2='app/mus_gob3.lic app/track1.mp3 app/*.itk app/*.stk'

APP1_ID_PKG1="${GAME_ID_PKG1}"
APP1_ID_PKG2="${GAME_ID_PKG2}"
APP1_SCUMMID='gob'
APP1_ICON='./goggame-1207662313.ico'
APP1_ICON_RES='16x16 32x32 48x48 256x256'
APP1_NAME_PKG1="${GAME_NAME_PKG1}"
APP1_NAME_FR_PKG1="${GAME_NAME} - version disquette"
APP1_NAME_PKG2="${GAME_NAME_PKG2}"
APP1_NAME_FR_PKG2="${GAME_NAME} - version CD"
APP1_CAT='Game'

PKG_ARCH='all'
PKG_VERSION='1.0'
PKG_DEPS='scummvm'

PKG1_ID="${GAME_ID_PKG1}"
PKG1_ARCH="${PKG_ARCH}"
PKG1_VERSION="${PKG_VERSION}"
PKG1_CONFLICTS=''
PKG1_DEPS="${PKG_DEPS}"
PKG1_RECS=''
PKG1_DESC="${GAME_NAME_PKG1}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG2_ID="${GAME_ID_PKG2}"
PKG2_ARCH="${PKG_ARCH}"
PKG2_VERSION="${PKG_VERSION}"
PKG2_CONFLICTS=''
PKG2_DEPS="${PKG_DEPS}"
PKG2_RECS=''
PKG2_DESC="${GAME_NAME_PKG2}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

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

NO_ICON=0

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'
GAME_LANG_DEFAULT='en'

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard ${SCRIPT_DEPS_HARD}
check_deps_soft ${SCRIPT_DEPS_SOFT}

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG2_VERSION}-${PKG_REVISION}_${PKG2_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC_PKG1="${PKG_PREFIX}/share/doc/${GAME_ID_PKG1}"
PATH_DOC_PKG2="${PKG_PREFIX}/share/doc/${GAME_ID_PKG2}"
PATH_GAME_PKG1="${PKG_PREFIX}/share/games/${GAME_ID_PKG1}"
PATH_GAME_PKG2="${PKG_PREFIX}/share/games/${GAME_ID_PKG2}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

printf '\n'
set_target '2' 'gog.com'
case "${GAME_ARCHIVE##*/}" in
	${GAME_ARCHIVE2}) GAME_LANG_DEFAULT='fr' ;;
	${GAME_ARCHIVE1}|*) GAME_LANG_DEFAULT='en' ;;
esac
set_lang
printf '\n'

# Checking target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}" "${GAME_ARCHIVE2_MD5}"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"
rm -rf "${PKG1_DIR}" "${PKG2_DIR}"
for dir in "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC_PKG1}" "${PATH_GAME_PKG1}" "${PATH_ICON_BASE}" '/DEBIAN/'; do
	mkdir -p "${PKG1_DIR}${dir}"
done
for dir in "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC_PKG2}" "${PATH_GAME_PKG2}" "${PATH_ICON_BASE}" '/DEBIAN/'; do
	mkdir -p "${PKG2_DIR}${dir}"
done
print wait

extract_data 'inno' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'

for file in ${INSTALLER_DOC}; do
	cp -rl "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_DOC_PKG1}"
	cp -rl "${PKG_TMPDIR}"/${file} "${PKG2_DIR}${PATH_DOC_PKG2}"
done

for file in ${INSTALLER_GAME_PKG1}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_GAME_PKG1}"
done

for file in ${INSTALLER_GAME_PKG2}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG2_DIR}${PATH_GAME_PKG2}"
done

if [ "${NO_ICON}" = '0' ]; then
	PATH_GAME="${PATH_GAME_PKG1}"
	extract_icons "${APP1_ID_PKG1}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
	cp -rl "${PKG1_DIR}${PATH_ICON_BASE}"/* "${PKG2_DIR}${PATH_ICON_BASE}"
	find "${PKG2_DIR}${PATH_ICON_BASE}" -name "${APP1_ID_PKG1}.png" | while read file; do
		mv "${file}" "${file%/*}/${APP1_ID_PKG2}.png"
	done
fi

rm "${PKG1_DIR}${PATH_GAME_PKG1}/${APP1_ICON}"

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

PATH_GAME="${PATH_GAME_PKG1}"
write_bin_scummvm "${PKG1_DIR}${PATH_BIN}/${APP1_ID_PKG1}" "${APP1_SCUMMID}" '' '' "${APP1_NAME_PKG1}"
PATH_GAME="${PATH_GAME_PKG2}"
case ${GAME_LANG} in
	fr) LAUNCHER_OPTIONS='--language=fr' ;;
	en|*) LAUNCHER_OPTIONS='' ;;
esac
write_bin_scummvm "${PKG2_DIR}${PATH_BIN}/${APP1_ID_PKG2}" "${APP1_SCUMMID}" "${LAUNCHER_OPTIONS}" '' "${APP1_NAME_PKG2}"

write_desktop "${APP1_ID_PKG1}" "${APP1_NAME_PKG1}" "${APP1_NAME_FR_PKG1}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID_PKG1}.desktop" "${APP1_CAT}" 'scummvm'
write_desktop "${APP1_ID_PKG2}" "${APP1_NAME_PKG2}" "${APP1_NAME_FR_PKG2}" "${PKG2_DIR}${PATH_DESK}/${APP1_ID_PKG2}.desktop" "${APP1_CAT}" 'scummvm'
printf '\n'

# Build packages

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n'
print_instructions "${PKG2_DESC}" "${PKG2_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
