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
# conversion script for the Alpha Centauri installer sold on GOG.com
# build a .deb package from the Windows installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20160424.2

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract dos2unix'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='alpha-centauri'
GAME_ID_SHORT='smac'
GAME_NAME='Alpha Centauri'
GAME_NAME_SHORT='SMAC'

GAME_ARCHIVE1='setup_sid_meiers_alpha_centauri_2.0.2.23.exe'
GAME_ARCHIVE1_MD5='6c9bd7e1cf88fdbfa0e75f694bf8b0e5'
GAME_ARCHIVE2='smac-linux-client.tar.gz'
GAME_ARCHIVE2_MD5='2e7c2ea8ffef7b73d9ac9aec22fdb82c'
GAME_ARCHIVE3='smac-movies-en.7z'
GAME_ARCHIVE3_MD5='0e408f73da0dafcf6c62b5284c756e8c'
GAME_ARCHIVE_FULLSIZE='1100000'
PKG_REVISION='gog2.0.2.23'

INSTALLER_JUNK='app/alternative_art app/color_blind_palette app/movies app/saves app/*.016 app/*.256 app/*.dll app/*.fot app/*.hlp app/*.icd app/*.ico app/*.ini app/*.sdb app/*.tmp app/axstart.exe app/facedit.exe app/ip.exe'
INSTALLER_DOC='app/*.pdf app/*readme*.txt tmp/*eula.txt'
INSTALLER_GAME='app/*'

APP1_ID="${GAME_ID}"
APP1_EXE='./smac.dynamic'
APP1_ICON='data/terran.exe'
APP1_ICON_RES='16x16 32x32'
APP1_NAME="${GAME_NAME_SHORT} - ${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME_SHORT} - ${GAME_NAME}"
APP1_CAT='Game'

APP2_ID="${GAME_ID}_smacx"
APP2_EXE='./smacx.dynamic'
APP2_ICON='data/terranx.exe'
APP2_ICON_RES='16x16 32x32 48x48'
APP2_NAME="${GAME_NAME_SHORT} - Alien Crossfire"
APP2_NAME_FR="${GAME_NAME_SHORT} - Alien Crossfire"
APP2_CAT='Game'

PKG1_ID="${GAME_ID}"
PKG1_VERSION='6.0b'
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='loki-compat-libs (>= 1.5)'
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

# Define script-specific functions

remove_spaces() {
find "$1" -depth | while read file; do
	newfile="$(dirname "${file}")/$(basename "${file}" | tr ' ' '_')"
	if [ "${newfile}" != "${file}" -a "${file}" != "${dir}" ]; then
		mv "${file}" "${newfile}"
	fi
done
}

# Set extra variables

NO_ICON=0

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

printf '\n'
set_target '1' 'gog.com'
set_target_extra 'CLIENT_ARCHIVE' '' "${GAME_ARCHIVE2}"
set_target_optional 'MOVIES_ARCHIVE' "${GAME_ARCHIVE3}"
if [ -n "${MOVIES_ARCHIVE}" ]; then
	SCRIPT_DEPS_HARD="${SCRIPT_DEPS_HARD} 7z"
fi
printf '\n'

check_deps_hard ${SCRIPT_DEPS_HARD}

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

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
	checksum "${CLIENT_ARCHIVE}" 'quiet' "${GAME_ARCHIVE2_MD5}"
	[ -n "${MOVIES_ARCHIVE}" ] && checksum "${MOVIES_ARCHIVE}" 'quiet' "${GAME_ARCHIVE3_MD5}"
	print done
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC}" "${PATH_GAME}/data"
print wait

extract_data 'inno' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'
remove_spaces "${PKG_TMPDIR}"
find "${PKG_TMPDIR}" -type f -name '*.txt' -execdir dos2unix {} + 1>/dev/null 2>/dev/null

for file in ${INSTALLER_JUNK}; do
	rm -rf "${PKG_TMPDIR}"/${file}
done

for file in ${INSTALLER_DOC}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_GAME}/data"
done

mkdir "${PKG1_DIR}${PATH_GAME}/data/fonts"
mv "${PKG1_DIR}${PATH_GAME}/data"/*.ttf "${PKG1_DIR}${PATH_GAME}/data/fonts"

extract_data 'tar' "${CLIENT_ARCHIVE}" "${PKG1_DIR}${PATH_GAME}" 'quiet'

if [ -n "${MOVIES_ARCHIVE}" ]; then
	extract_data '7z' "${MOVIES_ARCHIVE}" "${PKG1_DIR}${PATH_GAME}/data" 'quiet'
fi

if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
	extract_icons "${APP2_ID}" "${APP2_ICON}" "${APP2_ICON_RES}" "${PKG_TMPDIR}"
fi
rm "${PKG1_DIR}${PATH_GAME}/${APP1_ICON}"
rm "${PKG1_DIR}${PATH_GAME}/${APP2_ICON}"

rm -Rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '/usr/local/lib/loki-compat-libs' '' "${APP1_NAME}"
write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE}" '' '/usr/local/lib/loki-compat-libs' '' "${APP2_NAME}"

sed -i 's|./"${GAME_EXE_PATH##\*/}"|/usr/local/lib/loki-compat-libs/ld-linux.so.2 &|' "${PKG1_DIR}${PATH_BIN}/${APP1_ID}"
sed -i 's|./"${GAME_EXE_PATH##\*/}"|/usr/local/lib/loki-compat-libs/ld-linux.so.2 &|' "${PKG1_DIR}${PATH_BIN}/${APP2_ID}"

write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'alpha-centauri'
write_desktop "${APP2_ID}" "${APP2_NAME}" "${APP2_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP2_ID}.desktop" "${APP2_CAT}" 'alpha-centauri'
printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}"

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
