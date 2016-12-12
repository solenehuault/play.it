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
# conversion script for the Icewind Dale 2 installer sold on GOG.com
# build a .deb package from the InnoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161212.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='icewind-dale-2'
GAME_ID_SHORT='iwd2'
GAME_NAME='Icewind Dale II'

GAME_ARCHIVE_GOG_EN='setup_icewind_dale2_2.1.0.13.exe'
GAME_ARCHIVE_GOG_EN_MD5='9a68fdabdaff58bebc67092d47d4174e'
GAME_ARCHIVE_GOG_FR='setup_icewind_dale2_french_2.1.0.13.exe'
GAME_ARCHIVE_GOG_FR_MD5='04f25433d405671a8975be6540dd55fa'
GAME_ARCHIVE_GOG_FULLSIZE='1500000'
GAME_ARCHIVE_GOG_TYPE='inno'
GAME_ARCHIVE_GOG_VERSION='2.01.101615-gog2.1.0.12'


INSTALLER_DOC1_PATH='tmp'
INSTALLER_DOC1_FILES='./gog_eula.txt'
INSTALLER_DOC2_PATH='app'
INSTALLER_DOC2_FILES='./manual.pdf ./patch.txt ./readme.htm'
INSTALLER_GAME_PATH='app'
INSTALLER_GAME_FILES_BIN='./binkw32.dll ./config.exe ./iwd2.exe'
INSTALLER_GAME_FILES_L10N='./characters ./sounds ./*.tlk ./icewind2.ini ./language.ini ./party.ini ./override/narr002.wav ./override/guiinv.chu ./override/charstr.2da ./override/00bpak0.bcs ./data/guimos.bif ./cd2/data/intro.mve ./cd2/data/middle.mve ./cd2/data/sndvo.bif ./cd2/data/end.mve'
INSTALLER_GAME_FILES_DATA='./cd2 ./chitin.key ./data ./keymap.ini ./music ./override ./scripts'

GAME_CACHE_DIRS='./cache ./temp ./tempsave'
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./characters ./mpsave ./override ./portraits ./scripts'
GAME_DATA_FILES='./chitin.key ./dialog*.tlk'
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP_MAIN_ID="${GAME_ID}"
APP_MAIN_EXE='./iwd2.exe'
APP_MAIN_ICON='./iwd2.exe'
APP_MAIN_ICON_RES='16x16 32x32 48x48'
APP_MAIN_NAME="${GAME_NAME}"
APP_MAIN_NAME_FR="${GAME_NAME}"
APP_MAIN_CAT='Game'

APP_CONF_ID="${GAME_ID}_config"
APP_CONF_EXE='./config.exe'
APP_CONF_ICON='./config.exe'
APP_CONF_ICON_RES='16x16 32x32 48x48'
APP_CONF_NAME="${GAME_NAME} - settings"
APP_CONF_NAME_FR="${GAME_NAME} - réglages"
APP_CONF_CAT='Settings'

PKG_BIN_ID="${GAME_ID}"
PKG_BIN_ARCH='i386'
PKG_BIN_CONFLICTS=''
PKG_BIN_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG_BIN_RECS=''
PKG_BIN_DESC="${GAME_NAME}
 package built from GOG.com Windows installer
 ./play.it script version ${script_version}"

PKG_L10N_ID_EN="${GAME_ID}-l10n-en"
PKG_L10N_ID_FR="${GAME_ID}-l10n-fr"
PKG_L10N_ARCH='all'
PKG_L10N_CONFLICTS_EN="${PKG_L10N_ID_FR}"
PKG_L10N_CONFLICTS_FR="${PKG_L10N_ID_EN}"
PKG_L10N_DEPS=''
PKG_L10N_RECS=''
PKG_L10N_DESC_EN="${GAME_NAME} - English files
 package built from GOG.com installer
 ./play.it script version ${script_version}"
PKG_L10N_DESC_FR="${GAME_NAME} - French files
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG_BIN_DEPS="${PKG_L10N_ID_EN} | ${PKG_L10N_ID_FR}, ${PKG_BIN_DEPS}"

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_ARCH='all'
PKG_DATA_CONFLICTS=''
PKG_DATA_DEPS=''
PKG_DATA_RECS=''
PKG_DATA_DESC="${GAME_NAME} - data
 package built from GOG.com Windows installer
 ./play.it script version ${script_version}"

PKG_BIN_DEPS="${PKG_DATA_ID}, ${PKG_BIN_DEPS}"

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
GAME_ARCHIVE1="${GAME_ARCHIVE_GOG_EN}"
GAME_ARCHIVE2="${GAME_ARCHIVE_GOG_FR}"
set_target '2' 'gog.com'
case "${GAME_ARCHIVE##*/}" in
	("${GAME_ARCHIVE_GOG_EN}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE_GOG_EN_MD5}"
		PKG_L10N_ID="${PKG_L10N_ID_EN}"
		PKG_L10N_CONFLICTS="${PKG_L10N_CONFLICTS_EN}"
		PKG_L10N_DESC="${PKG_L10N_DESC_EN}"
	;;
	("${GAME_ARCHIVE_GOG_FR}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE_GOG_FR_MD5}"
		PKG_L10N_ID="${PKG_L10N_ID_FR}"
		PKG_L10N_CONFLICTS="${PKG_L10N_CONFLICTS_FR}"
		PKG_L10N_DESC="${PKG_L10N_DESC_FR}"
	;;
esac
GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE_GOG_FULLSIZE}"
GAME_ARCHIVE_TYPE="${GAME_ARCHIVE_GOG_TYPE}"
PKG_VERSION="${GAME_ARCHIVE_GOG_VERSION}"
printf '\n'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG_BIN_DIR' "${PKG_BIN_ID}_${PKG_VERSION}_${PKG_BIN_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG_L10N_DIR' "${PKG_L10N_ID}_${PKG_VERSION}_${PKG_L10N_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG_DATA_DIR' "${PKG_DATA_ID}_${PKG_VERSION}_${PKG_DATA_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE_MD5}"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"

for pkg_dir in "${PKG_BIN_DIR}" "${PKG_L10N_DIR}" "${PKG_DATA_DIR}"; do
	rm -Rf "${pkg_dir}"
	mkdir -p "${pkg_dir}/DEBIAN"
	mkdir -p "${pkg_dir}${PATH_GAME}"
done

mkdir -p "${PKG_BIN_DIR}${PATH_BIN}"
mkdir -p "${PKG_BIN_DIR}${PATH_DESK}"
mkdir -p "${PKG_L10N_DIR}${PATH_DOC}"
mkdir -p "${PKG_DATA_DIR}${PATH_DOC}"

print wait

extract_data "${GAME_ARCHIVE_TYPE}" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet,tolower'

cd "${PKG_TMPDIR}/${INSTALLER_DOC1_PATH}"
for file in ${INSTALLER_DOC1_FILES}; do
	mv "${file}" "${PKG_DATA_DIR}${PATH_DOC}"
done
cd - > /dev/null

cd "${PKG_TMPDIR}/${INSTALLER_DOC2_PATH}"
for file in ${INSTALLER_DOC2_FILES}; do
	mv "${file}" "${PKG_L10N_DIR}${PATH_DOC}"
done
cd - > /dev/null

cd "${PKG_TMPDIR}/${INSTALLER_GAME_PATH}"
for file in ${INSTALLER_GAME_FILES_BIN}; do
	mv "${file}" "${PKG_BIN_DIR}${PATH_GAME}"
done
for file in ${INSTALLER_GAME_FILES_L10N}; do
	if [ -e "$file" ]; then
		mkdir -p "${PKG_L10N_DIR}${PATH_GAME}/${file%/*}"
		mv "${file}" "${PKG_L10N_DIR}${PATH_GAME}/${file}"
	fi
done
for file in ${INSTALLER_GAME_FILES_DATA}; do
	mv "${file}" "${PKG_DATA_DIR}${PATH_GAME}"
done
cd - > /dev/null

ini_file="${PKG_L10N_DIR}${PATH_GAME}/icewind2.ini"
sed -i "s/HD0:=.\+/HD0:=C:\\\\${GAME_ID}\\\\/" "${ini_file}"
sed -i "s/CD1:=.\+/CD1:=C:\\\\${GAME_ID}\\\\data\\\\/" "${ini_file}"
sed -i "s/CD2:=.\+/CD2:=C:\\\\${GAME_ID}\\\\cd2\\\\/" "${ini_file}"

if [ "${NO_ICON}" = '0' ]; then
	PKG1_DIR="$PKG_BIN_DIR"
	extract_icons "${APP_MAIN_ID}" "${APP_MAIN_ICON}" "${APP_MAIN_ICON_RES}" "${PKG_TMPDIR}"
	extract_icons "${APP_CONF_ID}" "${APP_CONF_ICON}" "${APP_CONF_ICON_RES}" "${PKG_TMPDIR}"
fi

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_wine_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP_MAIN_ID}" "${APP_MAIN_EXE}" '' '' "${APP_MAIN_NAME}"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP_CONF_ID}" "${APP_CONF_EXE}" '' '' "${APP_CONF_NAME}"

write_desktop "${APP_MAIN_ID}" "${APP_MAIN_NAME}" "${APP_MAIN_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP_MAIN_ID}.desktop" "${APP_MAIN_CAT}" 'wine'
write_desktop "${APP_CONF_ID}" "${APP_CONF_NAME}" "${APP_CONF_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP_CONF_ID}.desktop" "${APP_CONF_CAT}" 'wine'
printf '\n'

# Build package

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG_BIN_DIR}" "${PKG_BIN_ID}" "${PKG_VERSION}" "${PKG_BIN_ARCH}" "${PKG_BIN_CONFLICTS}" "${PKG_BIN_DEPS}" "${PKG_BIN_RECS}" "${PKG_BIN_DESC}"
write_pkg_debian "${PKG_L10N_DIR}" "${PKG_L10N_ID}" "${PKG_VERSION}" "${PKG_L10N_ARCH}" "${PKG_L10N_CONFLICTS}" "${PKG_L10N_DEPS}" "${PKG_L10N_RECS}" "${PKG_L10N_DESC}"
write_pkg_debian "${PKG_DATA_DIR}" "${PKG_DATA_ID}" "${PKG_VERSION}" "${PKG_DATA_ARCH}" "${PKG_DATA_CONFLICTS}" "${PKG_DATA_DEPS}" "${PKG_DATA_RECS}" "${PKG_DATA_DESC}"

build_pkg "${PKG_BIN_DIR}" "${PKG_BIN_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG_L10N_DIR}" "${PKG_L10N_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG_DATA_DIR}" "${PKG_DATA_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
