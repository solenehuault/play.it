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
# conversion script for the Heroes of Might and Magic installer sold on GOG.com
# build a .deb package from the Windows installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20160625.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract'
SCRIPT_DEPS_SOFT='icotool'

GAME_ID='heroes-of-might-and-magic'
GAME_ID_SHORT='homm1'
GAME_NAME='Heroes of Might and Magic'
GAME_NAME_SHORT='HoMM'

GAME_ARCHIVE1='setup_heroes_of_might_and_magic_2.3.0.45.exe'
GAME_ARCHIVE1_MD5='2cae1821085090e30e128cd0a76b0d21'
GAME_ARCHIVE2='setup_heroes_of_might_and_magic_french_2.3.0.45.exe'
GAME_ARCHIVE2_MD5='9ec736a2a1b97dc36257f583f42864ac'
GAME_ARCHIVE_FULLSIZE='530000'
PKG_REVISION='gog2.3.0.45'

INSTALLER_PATH='app'
INSTALLER_DOC='help *.pdf *.txt ../tmp/gog_eula.txt ../tmp/eula.txt'
INSTALLER_GAME_PKG1='data/campaign.hs data/heroes.agg data/standard.hs ./*.exe ./games ./maps'
INSTALLER_GAME_PKG2='data goggame-1207658748.ico heroes.cfg homm1.gog wail32.dll ../sys/wing32.dll'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.cfg'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./games ./maps'
GAME_DATA_FILES=''
GAME_DATA_FILES_POST=''

GAME_IMAGE='./homm1.gog'

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

MENU_NAME="${GAME_NAME}"
MENU_NAME_FR="${GAME_NAME}"
MENU_CAT='Games'

APP1_ID="${GAME_ID}"
APP1_EXE='./heroes.exe'
APP1_ICON='./goggame-1207658748.ico'
APP1_ICON_RES='16x16 32x32 48x48 256x256'
APP1_NAME="${GAME_NAME_SHORT} - A Strategic Quest"
APP1_NAME_FR="${APP1_NAME}"

APP2_ID="${GAME_ID}_editor"
APP2_EXE='./editor.exe'
APP2_NAME="${GAME_NAME_SHORT} - editor"
APP2_NAME_FR="${GAME_NAME_SHORT} - éditeur"

PKG_VERSION='1.0'
PKG_ARCH='all'

PKG1_ID="${GAME_ID}"
PKG1_VERSION="${PKG_VERSION}"
PKG1_ARCH="${PKG_ARCH}"
PKG1_CONFLICTS=''
PKG1_DEPS='dosbox'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG2_ID="${GAME_ID}-common"
PKG2_VERSION="${PKG_VERSION}"
PKG2_ARCH="${PKG_ARCH}"
PKG2_CONFLICTS=''
PKG2_DEPS=''
PKG2_RECS=''
PKG2_DESC="${GAME_NAME} - common data
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG2_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG1_DEPS}"

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
PATH_DESK_DIR='/usr/local/share/desktop-directories'
PATH_DESK_MERGED='/etc/xdg/menus/applications-merged'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

printf '\n'
set_target '2' 'gog.com'
case "$(basename ${GAME_ARCHIVE})" in
	"${GAME_ARCHIVE1}") PKG1_DIR="${PKG1_DIR%/*}/${PKG1_ID}-en_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" ;;
	"${GAME_ARCHIVE2}") PKG1_DIR="${PKG1_DIR%/*}/${PKG1_ID}-fr_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" ;;
esac
printf '\n'

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}" "${GAME_ARCHIVE2_MD5}"
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_DESK_DIR}" "${PATH_DESK_MERGED}" "${PATH_GAME}"
rm -rf "${PKG2_DIR}"
mkdir -p "${PKG2_DIR}/DEBIAN" "${PKG2_DIR}${PATH_GAME}" "${PKG2_DIR}${PATH_ICON_BASE}"
print wait

extract_data 'inno' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"
for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME_PKG1}; do
	mkdir -p "${PKG1_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG1_DIR}${PATH_GAME}/${file}"
done

for file in ${INSTALLER_GAME_PKG2}; do
	mv "${file}" "${PKG2_DIR}${PATH_GAME}"
done
cd - > /dev/null

if [ "${NO_ICON}" = '0' ]; then
	PKG1_DIR_REAL="${PKG1_DIR}"
	PKG1_DIR="${PKG2_DIR}"
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
	PKG1_DIR="${PKG1_DIR_REAL}"
fi

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_dosbox_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_dosbox "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_bin_dosbox "${PKG1_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE}" '' '' "${APP2_NAME}"

write_menu "${GAME_ID}" "${MENU_NAME}" "${MENU_NAME_FR}" "${MENU_CAT}" "${PKG1_DIR}${PATH_DESK_DIR}/${GAME_ID}.directory" "${PKG1_DIR}${PATH_DESK_MERGED}/${GAME_ID}.menu" 'dosbox' "${APP1_ID}" "${APP2_ID}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" '' 'dosbox'
write_desktop "${APP2_ID}" "${APP2_NAME}" "${APP2_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP2_ID}.desktop" '' 'dosbox'
printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}"

if [ "${NO_ICON}" = '0' ]; then

	file="${PKG2_DIR}/DEBIAN/postinst"
	cat > "${file}" <<- EOF
	#!/bin/sh -e
	for res in ${APP1_ICON_RES}; do
	  path_icon="${PATH_ICON_BASE}/\${res}/apps"
	  ln -s "./${APP1_ID}.png" "\${path_icon}/${APP2_ID}.png"
	done
	exit 0
	EOF

	sed -i 's/  /\t/' "${file}"
	chmod 755 "${file}"

	file="${PKG2_DIR}/DEBIAN/prerm"
	cat > "${file}" <<- EOF
	#!/bin/sh -e
	for res in ${APP1_ICON_RES}; do
	  path_icon="${PATH_ICON_BASE}/\${res}/apps"
	  rm -f "\${path_icon}/${APP2_ID}.png"
	done
	exit 0
	EOF

	sed -i 's/  /\t/' "${file}"
	chmod 755 "${file}"

fi

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG1_DESC}" "${PKG2_DIR}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
