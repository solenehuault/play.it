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
# conversion script for the Afterlife installer sold on GOG.com
# build a .deb package from the Windows installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161125.2

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='afterlife'
GAME_ID_SHORT='alife'
GAME_NAME='Afterlife'

GAME_ARCHIVE_GOG_EN='gog_afterlife_2.2.0.8.sh'
GAME_ARCHIVE_GOG_EN_MD5='3aca0fac1b93adec5aff39d395d995ab'
GAME_ARCHIVE_GOG_FR='gog_afterlife_french_2.2.0.8.sh'
GAME_ARCHIVE_GOG_FR_MD5='56b3efee60bc490c68f8040587fc1878'
GAME_ARCHIVE_GOG_FULLSIZE='250000'
GAME_ARCHIVE_GOG_TYPE='mojo'
GAME_ARCHIVE_GOG_VERSION='1.1-gog2.2.0.8'

INSTALLER_DOC1_PATH='data/noarch/docs'
INSTALLER_DOC1_FILES_MAIN='./*.pdf'
INSTALLER_DOC1_FILES_L10N='./*.txt'
INSTALLER_DOC2_PATH='data/noarch/data'
INSTALLER_DOC2_FILES='./*.txt'
INSTALLER_GAME_PATH='data/noarch/data'
INSTALLER_GAME_FILES_MAIN='./*.ini alife/*.ini alife/install.bat alife/dos4gw.exe alife/uvconfig.exe'
INSTALLER_GAME_FILES_L10N='./*'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.ini */*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./saves'
GAME_DATA_FILES=''
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP_MAIN_ID="${GAME_ID}"
APP_MAIN_EXE='alife/afterdos.bat'
APP_MAIN_ICON='data/noarch/support/icon.png'
APP_MAIN_ICON_RES='256x256'
APP_MAIN_NAME="${GAME_NAME}"
APP_MAIN_NAME_FR="${GAME_NAME}"
APP_MAIN_CAT='Game'

PKG_MAIN_ID="${GAME_ID}"
PKG_MAIN_ARCH='all'
PKG_MAIN_CONFLICTS=''
PKG_MAIN_DEPS='dosbox'
PKG_MAIN_RECS=''
PKG_MAIN_DESC="${GAME_NAME}
 package built from GOG.com installer
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

PKG_MAIN_DEPS="${PKG_L10N_ID_EN} | ${PKG_L10N_ID_FR}, ${PKG_MAIN_DEPS}"

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

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard ${SCRIPT_DEPS_HARD}

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
game_mkdir 'PKG_MAIN_DIR' "${PKG_MAIN_ID}_${PKG_VERSION}_${PKG_MAIN_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG_L10N_DIR' "${PKG_L10N_ID}_${PKG_VERSION}_${PKG_L10N_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON="/usr/local/share/icons/hicolor/${APP_MAIN_ICON_RES}/apps"

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE_MD5}"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"

for pkg_dir in "${PKG_MAIN_DIR}" "${PKG_L10N_DIR}"; do
	rm -Rf "${pkg_dir}"
	mkdir -p "${pkg_dir}/DEBIAN"
	mkdir -p "${pkg_dir}${PATH_DOC}"
	mkdir -p "${pkg_dir}${PATH_GAME}"
done

mkdir -p "${PKG_MAIN_DIR}${PATH_BIN}"
mkdir -p "${PKG_MAIN_DIR}${PATH_DESK}"
mkdir -p "${PKG_MAIN_DIR}${PATH_ICON}"

print wait

extract_data "${GAME_ARCHIVE_TYPE}" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet,tolower'

cd "${PKG_TMPDIR}/${INSTALLER_DOC1_PATH}"
for file in ${INSTALLER_DOC1_FILES}; do
	mv "${file}" "${PKG_MAIN_DIR}${PATH_DOC}"
done
cd - > /dev/null

cd "${PKG_TMPDIR}/${INSTALLER_DOC2_PATH}"
for file in ${INSTALLER_DOC2_FILES}; do
	mv "${file}" "${PKG_MAIN_DIR}${PATH_DOC}"
done
cd - > /dev/null

cd "${PKG_TMPDIR}/${INSTALLER_GAME_PATH}"
for file in ${INSTALLER_GAME_FILES_MAIN}; do
	mkdir -p "${PKG_MAIN_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG_MAIN_DIR}${PATH_GAME}/${file}"
done
for file in ${INSTALLER_GAME_FILES_L10N}; do
	mkdir -p "${PKG_L10N_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG_L10N_DIR}${PATH_GAME}/${file}"
done
cd - > /dev/null

mv "${PKG_TMPDIR}/${APP_MAIN_ICON}" "${PKG_MAIN_DIR}${PATH_ICON}/${APP_MAIN_ID}.png"

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_dosbox_common "${PKG_MAIN_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_dosbox "${PKG_MAIN_DIR}${PATH_BIN}/${APP_MAIN_ID}" "${APP_MAIN_EXE}" '' '' "${APP_MAIN_NAME}"

file="${PKG_MAIN_DIR}${PATH_BIN}/${APP_MAIN_ID}"
sed -i 's/GAME_IMAGE=.\+//' "${file}"
sed -i 's/imgmount .\+//' "${file}"
sed -i 's|${GAME_EXE##\*/}|cd ${GAME_EXE%/\*}\n&|' "${file}"

write_desktop "${APP_MAIN_ID}" "${APP_MAIN_NAME}" "${APP_MAIN_NAME_FR}" "${PKG_MAIN_DIR}${PATH_DESK}/${APP_MAIN_ID}.desktop" "${APP_MAIN_CAT}" 'dosbox'

printf '\n'

# Build package

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG_MAIN_DIR}" "${PKG_MAIN_ID}" "${PKG_VERSION}" "${PKG_MAIN_ARCH}" "${PKG_MAIN_CONFLICTS}" "${PKG_MAIN_DEPS}" "${PKG_MAIN_RECS}" "${PKG_MAIN_DESC}"
write_pkg_debian "${PKG_L10N_DIR}" "${PKG_L10N_ID}" "${PKG_VERSION}" "${PKG_L10N_ARCH}" "${PKG_L10N_CONFLICTS}" "${PKG_L10N_DEPS}" "${PKG_L10N_RECS}" "${PKG_L10N_DESC}"

build_pkg "${PKG_MAIN_DIR}" "${PKG_MAIN_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG_L10N_DIR}" "${PKG_L10N_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG_MAIN_DESC}" "${PKG_L10N_DIR}" "${PKG_MAIN_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
