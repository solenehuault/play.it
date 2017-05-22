#!/bin/sh
set -e

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
# conversion script for the Star Wars: Galactic Battlegrounds installer sold on GOG.com
# build a .deb package from the InnoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161126.2

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath'

GAME_ID='star-wars-galactic-battlegrounds'
GAME_ID_SHORT='swgb'
GAME_NAME='Star Wars: Galactic Battlegrounds'

GAME_ARCHIVE1='setup_sw_galactic_battlegrounds_saga_2.0.0.4.exe'
GAME_ARCHIVE1_MD5='6af25835c5f240914cb04f7b4f741813'
GAME_ARCHIVE1_FULLSIZE='830000'
GAME_ARCHIVE1_PKG_L10N_ID="${GAME_ID}-l10n-en"
GAME_ARCHIVE1_PKG_L10N_DESC="${GAME_NAME} - English localization
 package built from GOG.com installer
 ./play.it script version ${script_version}"
GAME_ARCHIVE2='setup_sw_galactic_battlegrounds_saga_french_2.0.0.4.exe'
GAME_ARCHIVE2_MD5='b30458033e825ad252e2d5b3dc8a7845'
GAME_ARCHIVE2_FULLSIZE='820000'
GAME_ARCHIVE2_PKG_L10N_ID="${GAME_ID}-l10n-fr"
GAME_ARCHIVE2_PKG_L10N_DESC="${GAME_NAME} - French localization
 package built from GOG.com installer
 ./play.it script version ${script_version}"
GAME_ARCHIVE_TYPE='inno'
SCRIPT_DEPS_HARD="${SCRIPTS_DEPS_HARD} innoextract"
GAME_VERSION='1.0-gog2.0.0.4'

INSTALLER_PATH_DOC='app'
INSTALLER_DOC='./*.pdf'
INSTALLER_PATH_GAME='app/game'
INSTALLER_BIN='./*.exe ./libogg-0.dll ./libvorbis-0.dll ./libvorbisfile-3.dll ./win32.dll'
INSTALLER_L10N='./language*.dll ./campaign/media/1c2s6_end.mm ./data/gamedata_x1.drs ./data/genie*.dat ./data/list*.crx ./data/sounds.*drs ./history ./sound/campaign ./sound/scenario ./scenario/default0.scx ./taunt'
INSTALLER_DATA='./ai ./campaign ./data ./extras ./music ./random ./savegame ./scenario ./sound ./*.avi'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES=''
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./ai ./campaign ./random ./savegame ./scenario'
GAME_DATA_FILES=''
GAME_DATA_FILES_POST='./player.nf*'

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./battlegrounds.exe'
APP1_ICON='./battlegrounds.exe'
SCRIPT_DEPS_SOFT="${SCRIPT_DEPS_SOFT} icotool wrestool"
APP1_ICON_RES='16x16 32x32'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${APP1_NAME}"
APP1_CAT='Game'

APP2_ID="${GAME_ID}-x1"
APP2_EXE='./battlegrounds_x1.exe'
APP2_ICON='./battlegrounds_x1.exe'
APP2_ICON_RES='16x16 32x32'
APP2_NAME="${GAME_NAME} - Clone Campaigns"
APP2_NAME_FR="${APP2_NAME}"
APP2_CAT='Game'

PKG_BIN_ID="${GAME_ID}"
PKG_BIN_ARCH='i386'
PKG_BIN_CONFLICTS=''
PKG_BIN_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG_BIN_RECS=''
PKG_BIN_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG_L10N_ARCH='all'
PKG_L10N_CONFLICTS=''
PKG_L10N_DEPS=''
PKG_L10N_RECS=''

PKG_BIN_DEPS="${GAME_ARCHIVE1_PKG_L10N_ID} (= ${GAME_VERSION}) | ${GAME_ARCHIVE2_PKG_L10N_ID} (= ${GAME_VERSION}), ${PKG_BIN_DEPS}"

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
set_target '2' 'gog.com'
case "${GAME_ARCHIVE##*/}" in
	("${GAME_ARCHIVE1}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE1_MD5}"
		GAME_FULLSIZE="${GAME_ARCHIVE1_FULLSIZE}"
		PKG_L10N_ID="${GAME_ARCHIVE1_PKG_L10N_ID}"
		PKG_L10N_DESC="${GAME_ARCHIVE1_PKG_L10N_DESC}"
	;;
	("${GAME_ARCHIVE2}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE2_MD5}"
		GAME_FULLSIZE="${GAME_ARCHIVE2_FULLSIZE}"
		PKG_L10N_ID="${GAME_ARCHIVE2_PKG_L10N_ID}"
		PKG_L10N_DESC="${GAME_ARCHIVE2_PKG_L10N_DESC}"
	;;
esac
printf '\n'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_FULLSIZE}*2))"
game_mkdir 'PKG_BIN_DIR' "${PKG_BIN_ID}_${GAME_VERSION}_${PKG_BIN_ARCH}" "$((${GAME_FULLSIZE}*2))"
game_mkdir 'PKG_L10N_DIR' "${PKG_L10N_ID}_${GAME_VERSION}_${PKG_L10N_ARCH}" "$((${GAME_FULLSIZE}*2))"
game_mkdir 'PKG_DATA_DIR' "${PKG_DATA_ID}_${GAME_VERSION}_${PKG_DATA_ARCH}" "$((${GAME_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE="/usr/local/share/icons/hicolor"

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE_MD5}"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"
print wait
rm -rf "${PKG_BIN_DIR}"
rm -rf "${PKG_L10N_DIR}"
rm -rf "${PKG_DATA_DIR}"
for dir in '/DEBIAN' "${PATH_GAME}"; do
	mkdir -p "${PKG_BIN_DIR}/${dir}"
	mkdir -p "${PKG_L10N_DIR}/${dir}"
	mkdir -p "${PKG_DATA_DIR}/${dir}"
done
mkdir -p "${PKG_BIN_DIR}/${PATH_BIN}"
mkdir -p "${PKG_BIN_DIR}/${PATH_DESK}"
mkdir -p "${PKG_DATA_DIR}/${PATH_DOC}"

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

for file in ${INSTALLER_L10N}; do
	if [ -e "${file}" ]; then
		mkdir -p "${PKG_L10N_DIR}${PATH_GAME}/${file%/*}"
		mv "${file}" "${PKG_L10N_DIR}${PATH_GAME}/${file}"
	fi
done

for file in ${INSTALLER_DATA}; do
	mkdir -p "${PKG_DATA_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG_DATA_DIR}${PATH_GAME}/${file}"
done

cd - > /dev/null

if [ "${NO_ICON}" = '0' ]; then
	PKG1_DIR="${PKG_BIN_DIR}"
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
	extract_icons "${APP2_ID}" "${APP2_ICON}" "${APP2_ICON_RES}" "${PKG_TMPDIR}"
fi

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_wine_common "${PKG_BIN_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG_BIN_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG_BIN_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_bin_wine "${PKG_BIN_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE}" '' '' "${APP2_NAME}"

write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG_BIN_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'wine'
write_desktop "${APP2_ID}" "${APP2_NAME}" "${APP2_NAME_FR}" "${PKG_BIN_DIR}${PATH_DESK}/${APP2_ID}.desktop" "${APP2_CAT}" 'wine'

printf '\n'

# Build package

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG_BIN_DIR}" "${PKG_BIN_ID}" "${GAME_VERSION}" "${PKG_BIN_ARCH}" "${PKG_BIN_CONFLICTS}" "${PKG_BIN_DEPS}" "${PKG_BIN_RECS}" "${PKG_BIN_DESC}"
write_pkg_debian "${PKG_L10N_DIR}" "${PKG_L10N_ID}" "${GAME_VERSION}" "${PKG_L10N_ARCH}" "${PKG_L10N_CONFLICTS}" "${PKG_L10N_DEPS}" "${PKG_L10N_RECS}" "${PKG_L10N_DESC}"
write_pkg_debian "${PKG_DATA_DIR}" "${PKG_DATA_ID}" "${GAME_VERSION}" "${PKG_DATA_ARCH}" "${PKG_DATA_CONFLICTS}" "${PKG_DATA_DEPS}" "${PKG_DATA_RECS}" "${PKG_DATA_DESC}"

build_pkg "${PKG_BIN_DIR}" "${PKG_BIN_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG_L10N_DIR}" "${PKG_L10N_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG_DATA_DIR}" "${PKG_DATA_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG_BIN_DESC}" "${PKG_L10N_DIR}" "${PKG_DATA_DIR}" "${PKG_BIN_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
