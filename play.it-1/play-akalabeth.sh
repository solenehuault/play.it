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
# conversion script for the Akalabeth installers sold on GOG.com
# build .deb packages from the MojoSetup installer and the bonus .tar.gz archive
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161030.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ARCHIVE1_GAME_ID='akalabeth'
GAME_ARCHIVE1_GAME_ID_SHORT='ak'
GAME_ARCHIVE1_GAME_NAME='Akalabeth: World of Doom'

GAME_ARCHIVE2_GAME_ID='akalabeth-1998'
GAME_ARCHIVE2_GAME_ID_SHORT='ak98'
GAME_ARCHIVE2_GAME_NAME='Akalabeth (1998 version)'

GAME_ARCHIVE1='gog_akalabeth_world_of_doom_2.0.0.3.sh'
GAME_ARCHIVE1_MD5='11a770db592af2ac463e6cdc453b555b'
GAME_ARCHIVE1_FULLSIZE='13000'
GAME_ARCHIVE1_PKG_REVISION='gog2.0.0.3'
GAME_ARCHIVE2='akalabeth_1998_linux.zip'
GAME_ARCHIVE2_MD5='9c549339b300c3bfe73f8430d8fc74af'
GAME_ARCHIVE2_FULLSIZE='12000'
GAME_ARCHIVE2_PKG_REVISION='gog1.0.0.1'

GAME_ARCHIVE1_INSTALLER_PATH='data/noarch/data'
GAME_ARCHIVE2_INSTALLER_PATH='*/data'
INSTALLER_JUNK='../docs/dosbox-0.74.tar.gz'
INSTALLER_DOC='../docs/*'
INSTALLER_GAME='./*'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES=''
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS=''
GAME_DATA_FILES=''
GAME_DATA_FILES_POST=''

GAME_ARCHIVE1_APP1_EXE='./aklabeth.exe'
GAME_ARCHIVE2_APP1_EXE='./ak.exe'
GAME_ARCHIVE1_APP1_ICON='data/noarch/support/icon.png'
GAME_ARCHIVE2_APP1_ICON='*/support/gog-akalabeth-bonus-1998.png'
APP1_ICON_RES='256x256'
APP1_CAT='Game'

PKG1_VERSION='1.0'
PKG1_ARCH='all'
PKG1_CONFLICTS=''
PKG1_DEPS='dosbox'
PKG1_RECS=''

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
check_deps_soft ${SCRIPT_DEPS_SOFT}

printf '\n'
set_target '2' 'gog.com'
case "${GAME_ARCHIVE##*/}" in
	"${GAME_ARCHIVE1}")
		GAME_ID="${GAME_ARCHIVE1_GAME_ID}"
		GAME_ID_SHORT="${GAME_ARCHIVE1_GAME_ID_SHORT}"
		GAME_NAME="${GAME_ARCHIVE1_GAME_NAME}"
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE1_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE1_FULLSIZE}"
		PKG_REVISION="${GAME_ARCHIVE1_PKG_REVISION}"
		INSTALLER_PATH="${GAME_ARCHIVE1_INSTALLER_PATH}"
		APP1_EXE="${GAME_ARCHIVE1_APP1_EXE}"
		APP1_ICON="${GAME_ARCHIVE1_APP1_ICON}"
	;;
	"${GAME_ARCHIVE2}")
		GAME_ID="${GAME_ARCHIVE2_GAME_ID}"
		GAME_ID_SHORT="${GAME_ARCHIVE2_GAME_ID_SHORT}"
		GAME_NAME="${GAME_ARCHIVE2_GAME_NAME}"
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE2_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE2_FULLSIZE}"
		PKG_REVISION="${GAME_ARCHIVE2_PKG_REVISION}"
		INSTALLER_PATH="${GAME_ARCHIVE2_INSTALLER_PATH}"
		APP1_EXE="${GAME_ARCHIVE2_APP1_EXE}"
		APP1_ICON="${GAME_ARCHIVE2_APP1_ICON}"
	;;
esac
APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"
APP1_ID="${GAME_ID}"
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
PKG1_ID="${GAME_ID}"
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"
printf '\n'

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}" "${GAME_ARCHIVE2_MD5}"
fi

# Extract game data

PATH_ICON="${PATH_ICON_BASE}/${APP1_ICON_RES}/apps"

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_GAME}" "${PATH_ICON}"
print wait

case "${GAME_ARCHIVE##*/}" in
	"${GAME_ARCHIVE1}")
		extract_data 'mojo' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet,fix_rights,tolower'
	;;
	"${GAME_ARCHIVE2}")
		extract_data 'zip' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'
		extract_data 'tar' "${PKG_TMPDIR}"/*.tar.gz "${PKG_TMPDIR}" 'quiet,fix_rights,tolower'
		rm "${PKG_TMPDIR}"/*.tar.gz
	;;
esac

cd "${PKG_TMPDIR}"/${INSTALLER_PATH}
for file in ${INSTALLER_JUNK}; do
	rm -rf "${file}"
done

for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME}; do
	mv "${file}" "${PKG1_DIR}${PATH_GAME}"
done
cd - > /dev/null

mv "${PKG_TMPDIR}"/${APP1_ICON} "${PKG1_DIR}${PATH_ICON}/${APP1_ID}.png"

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_dosbox_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_dosbox "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'dosbox'
printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}"

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
