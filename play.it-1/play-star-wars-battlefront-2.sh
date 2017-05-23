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
# conversion script for the Star Wars: Battlefront II installer sold on GOG.com
# build a .deb package from the InnoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161109.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath'

GAME_ID='star-wars-battlefront-2'
GAME_ID_SHORT='swbf2'
GAME_NAME='Star Wars: Battlefront 2'

GAME_ARCHIVE1='setup_sw_battlefront2_2.0.0.5-1.bin'
GAME_ARCHIVE1_MD5='dc36b03c9c43fb8d3cb9b92c947daaa4'
GAME_ARCHIVE2='setup_sw_battlefront2_2.0.0.5-2.bin'
GAME_ARCHIVE2_MD5='5d4000fd480a80b6e7c7b73c5a745368'
GAME_ARCHIVE_TYPE='unar_passwd'
SCRIPT_DEPS_HARD="${SCRIPTS_DEPS_HARD} unar"
GAME_FULLSIZE='9100000'
GAME_VERSION='1.1-gog2.0.0.5'

INSTALLER_PATH_DOC='game'
INSTALLER_DOC='./*.pdf'
INSTALLER_PATH_GAME='game/gamedata'
INSTALLER_BIN='./*.exe ./binkw32.dll ./eax.dll ./unicows.dll'
INSTALLER_MOVIES='./data/_lvl_pc/movies'
INSTALLER_SOUND='./data/_lvl_pc/sound'
INSTALLER_DATA='./data'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES=''
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./savegames'
GAME_DATA_FILES=''
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./battlefrontii.exe'
APP1_ICON='./battlefrontii.exe'
SCRIPT_DEPS_SOFT="${SCRIPT_DEPS_SOFT} icotool wrestool"
APP1_ICON_RES='16x16 32x32'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${APP1_NAME}"
APP1_CAT='Game'

PKG_BIN_ID="${GAME_ID}"
PKG_BIN_ARCH='i386'
PKG_BIN_CONFLICTS=''
PKG_BIN_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG_BIN_RECS=''
PKG_BIN_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG_MOVIES_ID="${GAME_ID}-movies"
PKG_MOVIES_ARCH='all'
PKG_MOVIES_CONFLICTS=''
PKG_MOVIES_DEPS=''
PKG_MOVIES_RECS=''
PKG_MOVIES_DESC="${GAME_NAME} - movies
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG_BIN_DEPS="${PKG_MOVIES_ID} (= ${GAME_VERSION}), ${PKG_BIN_DEPS}"

PKG_SOUND_ID="${GAME_ID}-sound"
PKG_SOUND_ARCH='all'
PKG_SOUND_CONFLICTS=''
PKG_SOUND_DEPS=''
PKG_SOUND_RECS=''
PKG_SOUND_DESC="${GAME_NAME} - sounds
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG_BIN_DEPS="${PKG_SOUND_ID} (= ${GAME_VERSION}), ${PKG_BIN_DEPS}"

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_VERSION="${PKG_VERSION}"
PKG_DATA_ARCH='all'
PKG_DATA_CONFLICTS=''
PKG_DATA_DEPS=''
PKG_DATA_RECS=''
PKG_DATA_DESC="${GAME_NAME} - data
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG_BIN_DEPS="${PKG_DATA_ID} (= ${GAME_VERSION}), ${PKG_BIN_DEPS}"

# Load common functions

TARGET_LIB_VERSION='1.14'

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

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard ${SCRIPT_DEPS_HARD}
check_deps_soft ${SCRIPT_DEPS_SOFT}

printf '\n'
set_target '1' 'gog.com'
set_target_extra 'GAME_ARCHIVE2' '' "${GAME_ARCHIVE2}"
printf '\n'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_FULLSIZE}*2))"
game_mkdir 'PKG_BIN_DIR' "${PKG_BIN_ID}_${GAME_VERSION}_${PKG_BIN_ARCH}" "$((${GAME_FULLSIZE}*2))"
game_mkdir 'PKG_MOVIES_DIR' "${PKG_MOVIES_ID}_${GAME_VERSION}_${PKG_MOVIES_ARCH}" "$((${GAME_FULLSIZE}*2))"
game_mkdir 'PKG_SOUND_DIR' "${PKG_SOUND_ID}_${GAME_VERSION}_${PKG_SOUND_ARCH}" "$((${GAME_FULLSIZE}*2))"
game_mkdir 'PKG_DATA_DIR' "${PKG_DATA_ID}_${GAME_VERSION}_${PKG_DATA_ARCH}" "$((${GAME_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE="/usr/local/share/icons/hicolor"

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	printf '%s…\n' "$(l10n 'checksum_multiple')"
	print wait
	checksum "${GAME_ARCHIVE}" 'quiet' "${GAME_ARCHIVE1_MD5}"
	checksum "${GAME_ARCHIVE2}" 'quiet' "${GAME_ARCHIVE2_MD5}"
	print done
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"
print wait
rm -rf "${PKG_BIN_DIR}"
rm -rf "${PKG_MOVIES_DIR}"
rm -rf "${PKG_SOUND_DIR}"
rm -rf "${PKG_DATA_DIR}"
for dir in '/DEBIAN' "${PATH_GAME}"; do
	mkdir -p "${PKG_BIN_DIR}/${dir}"
	mkdir -p "${PKG_MOVIES_DIR}/${dir}"
	mkdir -p "${PKG_SOUND_DIR}/${dir}"
	mkdir -p "${PKG_DATA_DIR}/${dir}"
done
mkdir -p "${PKG_BIN_DIR}/${PATH_BIN}"
mkdir -p "${PKG_BIN_DIR}/${PATH_DESK}"
mkdir -p "${PKG_DATA_DIR}/${PATH_DOC}"

mkdir --parents "${PKG_TMPDIR}"
ln --symbolic "$(realpath ${GAME_ARCHIVE})" "${PKG_TMPDIR}/${GAME_ID_SHORT}.r01"
ln --symbolic "$(realpath ${GAME_ARCHIVE2})" "${PKG_TMPDIR}/${GAME_ID_SHORT}.r02"
GAME_ARCHIVE="${PKG_TMPDIR}/${GAME_ID_SHORT}.r01"

extract_data "${GAME_ARCHIVE_TYPE}" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet,tolower'

cd "${PKG_TMPDIR}/${INSTALLER_PATH_DOC}"

for file in ${INSTALLER_DOC}; do
	mkdir -p "${PKG_DATA_DIR}${PATH_DOC}/${file%/*}"
	mv "${file}" "${PKG_DATA_DIR}${PATH_DOC}/${file}"
done

cd - > /dev/null
cd "${PKG_TMPDIR}/${INSTALLER_PATH_GAME}"

for file in ${INSTALLER_BIN}; do
	mkdir -p "${PKG_BIN_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG_BIN_DIR}${PATH_GAME}/${file}"
done

for file in ${INSTALLER_MOVIES}; do
	mkdir -p "${PKG_MOVIES_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG_MOVIES_DIR}${PATH_GAME}/${file}"
done

for file in ${INSTALLER_SOUND}; do
	mkdir -p "${PKG_SOUND_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG_SOUND_DIR}${PATH_GAME}/${file}"
done

for file in ${INSTALLER_DATA}; do
	mkdir -p "${PKG_DATA_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG_DATA_DIR}${PATH_GAME}/${file}"
done

cd - > /dev/null

if [ "${NO_ICON}" = '0' ]; then
	PKG1_DIR="${PKG_BIN_DIR}"
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
fi

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_wine_common "${PKG_BIN_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG_BIN_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG_BIN_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"

write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG_BIN_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'wine'

printf '\n'

# Build package

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG_BIN_DIR}" "${PKG_BIN_ID}" "${GAME_VERSION}" "${PKG_BIN_ARCH}" "${PKG_BIN_CONFLICTS}" "${PKG_BIN_DEPS}" "${PKG_BIN_RECS}" "${PKG_BIN_DESC}"
write_pkg_debian "${PKG_MOVIES_DIR}" "${PKG_MOVIES_ID}" "${GAME_VERSION}" "${PKG_MOVIES_ARCH}" "${PKG_MOVIES_CONFLICTS}" "${PKG_MOVIES_DEPS}" "${PKG_MOVIES_RECS}" "${PKG_MOVIES_DESC}"
write_pkg_debian "${PKG_SOUND_DIR}" "${PKG_SOUND_ID}" "${GAME_VERSION}" "${PKG_SOUND_ARCH}" "${PKG_SOUND_CONFLICTS}" "${PKG_SOUND_DEPS}" "${PKG_SOUND_RECS}" "${PKG_SOUND_DESC}"
write_pkg_debian "${PKG_DATA_DIR}" "${PKG_DATA_ID}" "${GAME_VERSION}" "${PKG_DATA_ARCH}" "${PKG_DATA_CONFLICTS}" "${PKG_DATA_DEPS}" "${PKG_DATA_RECS}" "${PKG_DATA_DESC}"

build_pkg "${PKG_BIN_DIR}" "${PKG_BIN_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG_MOVIES_DIR}" "${PKG_MOVIES_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG_SOUND_DIR}" "${PKG_SOUND_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG_DATA_DIR}" "${PKG_DATA_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG_BIN_DESC}" "${PKG_MOVIES_DIR}" "${PKG_SOUND_DIR}" "${PKG_DATA_DIR}" "${PKG_BIN_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
