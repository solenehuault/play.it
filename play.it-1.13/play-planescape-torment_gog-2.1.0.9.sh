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
# conversion script for the Planescape: Torment installer sold on GOG.com
# build a .deb package from the .sh MojoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20160627.1

# Setting game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath'
SCRIPT_DEPS_HARD_LINUX='unzip'
SCRIPT_DEPS_HARD_WIN='innoextract'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='planescape-torment'
GAME_ID_SHORT='pstorment'
GAME_NAME='Planescape: Torment'
PKG_REVISION='gog2.1.0.9'

GAME_ARCHIVE1='gog_planescape_torment_2.1.0.9.sh'
GAME_ARCHIVE1_MD5='a48bb772f60da3b5b2cac804b6e92670'
GAME_ARCHIVE2='gog_planescape_torment_french_2.1.0.9.sh'
GAME_ARCHIVE2_MD5='c3af554300a90297d4fca0b591d9c3fd'
GAME_ARCHIVE3='setup_planescape_torment_russian_2.1.0.9.exe'
GAME_ARCHIVE3_MD5='19dfa72ab89d1fe599015f382c42708c'
GAME_ARCHIVE_FULLSIZE='2400000'

LINUX_INSTALLER_DOC_PATH='data/noarch/docs'
LINUX_INSTALLER_DOC='*'
LINUX_INSTALLER_GAME_PATH='data/noarch/prefix/drive_c/gog?games/*'
LINUX_INSTALLER_GAME_JUNK='*ddraw* gog_planescape_torment.sdb torment.err torment.log'
LINUX_INSTALLER_GAME_PKG1='./*.tlk ./cachemos.bif ./chitin.key ./crefiles.bif ./cs_0404.bif ./interface.bif ./sound.bif ./torment.ini ./voice.bif data/genmova.bif data/movies2.bif data/movies4.bif'
LINUX_INSTALLER_GAME_PKG2='*'

WIN_INSTALLER_DOC_PATH='.'
WIN_INSTALLER_DOC='tmp/gog_eula.txt app/*.txt'
WIN_INSTALLER_GAME_PATH='app'
WIN_INSTALLER_GAME_JUNK='/gameuxinstallhelper.dll ./goggame-1207658887ru.* ./goggame.sdb ./__support'
WIN_INSTALLER_GAME_PKG1='./*.tlk ./cachemos.bif ./chitin.key ./crefiles.bif ./cs_0404.bif ./interface.bif ./sound.bif ./torment.ini ./voice.bif data/genmova.bif data/movies2.bif data/movies4.bif'
WIN_INSTALLER_GAME_PKG2='*'

GAME_CACHE_DIRS='./cache'
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./override ./save'
GAME_DATA_FILES='./*.key ./torment.err ./torment.log'
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./torment.exe'
APP1_ICON='./torment.exe'
APP1_ICON_RES='16x16 32x32'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG_VERSION='1.1'

PKG1_ID="${GAME_ID}"
PKG1_VERSION="${PKG_VERSION}"
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG2_ID="${GAME_ID}-common"
PKG2_VERSION="${PKG_VERSION}"
PKG2_ARCH='all'
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
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

printf '\n'
set_target '3' 'gog.com'
case "$(basename ${GAME_ARCHIVE})" in
	"${GAME_ARCHIVE1}") PKG1_DIR="${PKG1_DIR%/*}/${PKG1_ID}-en_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" ;;
	"${GAME_ARCHIVE2}") PKG1_DIR="${PKG1_DIR%/*}/${PKG1_ID}-fr_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" ;;
	"${GAME_ARCHIVE3}") PKG1_DIR="${PKG1_DIR%/*}/${PKG1_ID}-ru_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" ;;
esac
if [ "$(basename ${GAME_ARCHIVE})" = "${GAME_ARCHIVE3}" ]; then
	INSTALLER_DOC_PATH="${WIN_INSTALLER_DOC_PATH}"
	INSTALLER_DOC="${WIN_INSTALLER_DOC}"
	INSTALLER_GAME_PATH="${WIN_INSTALLER_GAME_PATH}"
	INSTALLER_GAME_JUNK="${WIN_INSTALLER_GAME_JUNK}"
	INSTALLER_GAME_PKG1="${WIN_INSTALLER_GAME_PKG1}"
	INSTALLER_GAME_PKG2="${WIN_INSTALLER_GAME_PKG2}"
	check_deps_hard ${SCRIPT_DEPS_HARD_WIN}
else
	INSTALLER_DOC_PATH="${LINUX_INSTALLER_DOC_PATH}"
	INSTALLER_DOC="${LINUX_INSTALLER_DOC}"
	INSTALLER_GAME_PATH="${LINUX_INSTALLER_GAME_PATH}"
	INSTALLER_GAME_JUNK="${LINUX_INSTALLER_GAME_JUNK}"
	INSTALLER_GAME_PKG1="${LINUX_INSTALLER_GAME_PKG1}"
	INSTALLER_GAME_PKG2="${LINUX_INSTALLER_GAME_PKG2}"
	check_deps_hard ${SCRIPT_DEPS_HARD_LINUX}
fi
printf '\n'

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}" "${GAME_ARCHIVE2_MD5}" "${GAME_ARCHIVE3_MD5}"
fi

# Extract game data

build_pkg_dirs '2' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_GAME}"
print wait

if [ "$(basename ${GAME_ARCHIVE})" = "${GAME_ARCHIVE3}" ]; then
	extract_data 'inno' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'
else
	extract_data 'mojo' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'fix_rights,quiet,tolower'
fi

cd "${PKG_TMPDIR}/${INSTALLER_DOC_PATH}"
for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG2_DIR}${PATH_DOC}"
done
cd - > /dev/null

cd "${PKG_TMPDIR}"/${INSTALLER_GAME_PATH}
for file in ${INSTALLER_GAME_JUNK}; do
	rm -rf "${file}"
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

file="${PKG1_DIR}${PATH_GAME}/torment.ini"
sed -i 's/HD0:=.\+/HD0:=C:\\planescape-torment\\/' "${file}"
sed -i 's/CD\([1-5]\):=.\+/CD\1:=C:\\planescape-torment\\data\\/' "${file}"

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_wine_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'wine'
printf '\n'

# Build package

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG1_DESC}" "${PKG2_DIR}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
