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
# conversion script for the Hitman: Codename 47 installer sold on GOG.com
# build a .deb package from the InnoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161101.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='hitman'
GAME_ID_SHORT='hitman'
GAME_NAME='Hitman: Codename 47'

GAME_ARCHIVE1='setup_hitman_codename47_2.0.0.13.exe'
GAME_ARCHIVE1_MD5='6a1f8e9507639f39e6ff737ab7f7ce79'
GAME_ARCHIVE_FULLSIZE='340000'
ARCHIVE_TYPE='inno'
PKG_REVISION='gog2.0.0.13'

INSTALLER_PATH='app'
INSTALLER_JUNK='./gameuxinstallhelper.dll ./gfw_high.ico ./goggame.dll ./gog.ico ./nglideeula.txt ./support.ico'
INSTALLER_DOC='../tmp/gog_eula.txt ../tmp/nglideeula.txt ./nglide_readme.txt'
INSTALLER_BIN='./*.dll ./*.exe'
INSTALLER_DATA='./*'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS=''
GAME_DATA_FILES=''
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./hitman.exe'
APP1_ICON='./hitman.exe'
APP1_ICON_RES='32x32'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${APP1_NAME}"
APP1_CAT='Game'

PKG_VERSION='1.2'

PKG_BIN_ID="${GAME_ID}"
PKG_BIN_VERSION="${PKG_VERSION}"
PKG_BIN_ARCH='i386'
PKG_BIN_CONFLICTS=''
PKG_BIN_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG_BIN_RECS=''
PKG_BIN_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_VERSION="${PKG_VERSION}"
PKG_DATA_ARCH='all'
PKG_DATA_CONFLICTS=''
PKG_DATA_DEPS=''
PKG_DATA_RECS=''
PKG_DATA_DESC="${GAME_NAME} - data
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG_BIN_DEPS="${PKG_DATA_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG_BIN_DEPS}"

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
printf '\n'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG_BIN_DIR' "${PKG_BIN_ID}_${PKG_BIN_VERSION}-${PKG_REVISION}_${PKG_BIN_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG_DATA_DIR' "${PKG_DATA_ID}_${PKG_DATA_VERSION}-${PKG_REVISION}_${PKG_DATA_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE="/usr/local/share/icons/hicolor"

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"
print wait
rm -rf "${PKG_BIN_DIR}"
rm -rf "${PKG_DATA_DIR}"
for dir in '/DEBIAN' "${PATH_BIN}" "${PATH_DESK}" "${PATH_GAME}"; do
	mkdir -p "${PKG_BIN_DIR}/${dir}"
done
for dir in for dir in '/DEBIAN' "${PATH_DOC}" "${PATH_GAME}"; do
	mkdir -p "${PKG_DATA_DIR}/${dir}"
done

extract_data "${ARCHIVE_TYPE}" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"
for file in ${INSTALLER_JUNK}; do
	rm -rf "${file}"
done

for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG_DATA_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_BIN}; do
	mv "${file}" "${PKG_BIN_DIR}${PATH_GAME}"
done

for file in ${INSTALLER_DATA}; do
	mv "${file}" "${PKG_DATA_DIR}${PATH_GAME}"
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

write_pkg_debian "${PKG_BIN_DIR}" "${PKG_BIN_ID}" "${PKG_BIN_VERSION}-${PKG_REVISION}" "${PKG_BIN_ARCH}" "${PKG_BIN_CONFLICTS}" "${PKG_BIN_DEPS}" "${PKG_BIN_RECS}" "${PKG_BIN_DESC}"
write_pkg_debian "${PKG_DATA_DIR}" "${PKG_DATA_ID}" "${PKG_DATA_VERSION}-${PKG_REVISION}" "${PKG_DATA_ARCH}" "${PKG_DATA_CONFLICTS}" "${PKG_DATA_DEPS}" "${PKG_DATA_RECS}" "${PKG_DATA_DESC}"

build_pkg "${PKG_BIN_DIR}" "${PKG_BIN_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG_DATA_DIR}" "${PKG_DATA_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG_BIN_DESC}" "${PKG_DATA_DIR}" "${PKG_BIN_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
