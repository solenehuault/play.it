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
# conversion script for the Dungeon Keeper 2 installer sold on GOG.com
# build a .deb package from the Windows installer
# tested on Debian, should work on any .deb-based distribution
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

script_version=20160225.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot innoextract realpath'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='dungeon-keeper-2'
GAME_ID_SHORT='dkeeper2'
GAME_NAME='Dungeon Keeper 2'

GAME_ARCHIVE1='setup_dungeon_keeper2_2.0.0.32.exe'
GAME_ARCHIVE1_MD5='92d04f84dd870d9624cd18449d3622a5'
GAME_ARCHIVE_FULLSIZE='510000'
PKG_REVISION='gog2.0.0.32'

INSTALLER_DOC='app/*.pdf app/*.txt tmp/eula.txt tmp/gog_eula.txt'
INSTALLER_GAME='app/aweman32.dll app/data app/dk2texturecache app/dkii*.exe app/patch.dll app/qmixer.dll app/sfman32.dll app/weanetr.dll'

TRADFR_URL='http://wiki.dotslashplay.it/fr/traductions/dungeon-keeper-2'
TRADFR_ARCHIVE1='dk2fr.7z'
TRADFR_ARCHIVE1_MD5='14faef5d2db04965710f5cfa15533505'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS='./data/settings'
GAME_CONFIG_FILES=''
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./data/save'
GAME_DATA_FILES=''
GAME_DATA_FILES_POST='./MESSAGE.LOG'

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./dkii-dx.exe'
APP1_ICON='./dkii.exe'
APP1_ICON_RES='16x16 32x32 48x48'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG1_ID="${GAME_ID}"
PKG1_VERSION='1.7'
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
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
set_lang

if [ "${GAME_LANG}" = 'fr' ]; then
	SCRIPT_DEPS_HARD="${SCRIPT_DEPS_HARD} 7z"
fi

check_deps_hard ${SCRIPT_DEPS_HARD}
check_deps_soft ${SCRIPT_DEPS_SOFT}

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE="/usr/local/share/icons/hicolor"

printf '\n'

set_target '1' 'gog.com'

if [ "${GAME_LANG}" = 'fr' ]; then
	set_target_extra 'TRADFR_ARCHIVE' "${TRADFR_URL}" "${TRADFR_ARCHIVE1}"
fi

printf '\n'

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then

	printf '%s…\n' "$(l10n 'checksum_multiple')"

	print wait

	checksum "${GAME_ARCHIVE}" 'quiet' "${GAME_ARCHIVE1_MD5}"

	if [ "${GAME_LANG}" = 'fr' ]; then
		checksum "${TRADFR_ARCHIVE}" 'quiet' "${TRADFR_ARCHIVE1_MD5}"
	fi

	print done
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_GAME}"

print wait

extract_data 'inno' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'

if [ "${GAME_LANG}" = 'fr' ]; then
	extract_data '7z' "${TRADFR_ARCHIVE}" "${PKG_TMPDIR}/app" 'force,quiet'
fi

for file in ${INSTALLER_DOC}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_GAME}"
done

if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
fi

rm -rf "${PKG_TMPDIR}"

print done

# Write launchers

write_bin_wine_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"

write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'wine'

printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}"

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"

printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
