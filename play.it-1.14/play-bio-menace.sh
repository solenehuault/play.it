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
# conversion script for the Bio Menace installer sold on GOG.com
# build a .deb package from the MojoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161111.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'
SCRIPT_DEPS_SOFT='icotool'

GAME_ID='bio-menace'
GAME_ID_SHORT='bmenace'
GAME_NAME='Bio Menace'

GAME_ARCHIVE1='gog_bio_menace_2.0.0.2.sh'
GAME_ARCHIVE1_MD5='75167ee3594dd44ec8535b29b90fe4eb'
GAME_ARCHIVE_FULLSIZE='14000'
ARCHIVE_TYPE='mojo'
PKG_REVISION='gog2.0.0.2'

INSTALLER_PATH='data/noarch/data'
INSTALLER_JUNK='../docs/dosbox-0.74.tar.gz ./file_id.diz'
INSTALLER_DOC='../docs/* ./*.txt'
INSTALLER_GAME='./*'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.conf ./config.*'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS=''
GAME_DATA_FILES=''
GAME_DATA_FILES_POST='./SAVEGAM*'

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

MENU_NAME="${GAME_NAME}"
MENU_NAME_FR="${GAME_NAME}"
MENU_CAT='Games'

APP1_ID="${GAME_ID}-part1"
APP1_EXE='./bmenace1.exe'
APP1_ICON='data/noarch/support/icon.png'
APP1_ICON_RES='256x256'
APP1_NAME="${GAME_NAME} Part 1"
APP1_NAME_FR="${APP1_NAME}"

APP2_ID="${GAME_ID}-part2"
APP2_EXE='./bmenace2.exe'
APP2_NAME="${GAME_NAME} Part 2"
APP2_NAME_FR="${APP2_NAME}"

APP3_ID="${GAME_ID}-part3"
APP3_EXE='./bmenace3.exe'
APP3_NAME="${GAME_NAME} Part 3"
APP3_NAME_FR="${APP3_NAME}"

PKG1_ID="${GAME_ID}"
PKG1_VERSION='1.1'
PKG1_ARCH='all'
PKG1_CONFLICTS=''
PKG1_DEPS='dosbox'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

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
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DESK_DIR='/usr/local/share/desktop-directories'
PATH_DESK_MERGED='/etc/xdg/menus/applications-merged'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON="/usr/local/share/icons/hicolor/${APP1_ICON_RES}/apps"

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}"
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_DESK_DIR}" "${PATH_DESK_MERGED}" "${PATH_GAME}" "${PATH_ICON}"
print wait

extract_data "${ARCHIVE_TYPE}" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet,tolower,fix_rights'

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"

for file in ${INSTALLER_JUNK}; do
	rm -Rf "${file}"
done

for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME}; do
	mv "${file}" "${PKG1_DIR}${PATH_GAME}"
done

cd - > /dev/null

mv "${PKG_TMPDIR}/${APP1_ICON}" "${PKG1_DIR}${PATH_ICON}/${APP1_ID}.png"

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_dosbox_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_dosbox "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_bin_dosbox "${PKG1_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE}" '' '' "${APP2_NAME}"
write_bin_dosbox "${PKG1_DIR}${PATH_BIN}/${APP3_ID}" "${APP3_EXE}" '' '' "${APP3_NAME}"

write_menu "${GAME_ID}" "${MENU_NAME}" "${MENU_NAME_FR}" "${MENU_CAT}" "${PKG1_DIR}${PATH_DESK_DIR}/${GAME_ID}.directory" "${PKG1_DIR}${PATH_DESK_MERGED}/${GAME_ID}.menu" 'dosbox' "${APP1_ID}" "${APP2_ID}" "${APP3_ID}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" '' 'dosbox'
write_desktop "${APP2_ID}" "${APP2_NAME}" "${APP2_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP2_ID}.desktop" '' 'dosbox'
write_desktop "${APP3_ID}" "${APP3_NAME}" "${APP3_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP3_ID}.desktop" '' 'dosbox'

printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"

if [ "${NO_ICON}" = '0' ]; then
	file="${PKG1_DIR}/DEBIAN/postinst"
	cat > "${file}" <<- EOF
	#!/bin/sh -e
  ln -s "./${APP1_ID}.png" "${PATH_ICON}/${APP2_ID}.png"
  ln -s "./${APP1_ID}.png" "${PATH_ICON}/${APP3_ID}.png"
	exit 0
	EOF
	chmod 755 "${file}"
	
	file="${PKG1_DIR}/DEBIAN/prerm"
	cat > "${file}" <<- EOF
	#!/bin/sh -e
  rm -f "${PATH_ICON}/${APP2_ID}.png"
  rm -f "${PATH_ICON}/${APP3_ID}.png"
	exit 0
	EOF
	chmod 755 "${file}"
fi

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'defaults'

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
