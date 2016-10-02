#!/bin/sh -e

printf '\033[1;31mBroken script!\033[0m\n'
exit 1

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
# conversion script for the Pillars of Eternity installer sold on GOG.com
# build a .deb package from the .sh MojoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161002.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='victor-vran'
GAME_ID_SHORT='vvran'
GAME_NAME='Victor Vran'

GAME_ARCHIVE1='gog_victor_vran_2.10.0.12.sh'
GAME_ARCHIVE1_MD5='72509634a112cb4c7208f31777e5fb24'
GAME_ARCHIVE_FULLSIZE='4300000'
GAME_ARCHIVE_TYPE='mojo'
PKG_REVISION='gog2.10.0.12'

INSTALLER_PATH='data/noarch/game'
INSTALLER_JUNK='i386/lib/i386-linux-gnu/libcom_err.so.2* i386/lib/i386-linux-gnu/libcrypt-2.15.so i386/lib/i386-linux-gnu/libcrypt.so.1 i386/lib/i386-linux-gnu/libgpg-error.so.0* i386/lib/i386-linux-gnu/libkeyutils.so.1* i386/lib/i386-linux-gnu/libuuid.so.1* i386/lib/i386-linux-gnu/libz.so.1* i386/usr'
INSTALLER_DOC='../docs/*'
INSTALLER_GAME_PKG1='./VictorVranGOG ./i386'
INSTALLER_GAME_PKG2='./Movies'
INSTALLER_GAME_PKG3='./Packs/Maps'
INSTALLER_GAME_PKG4='./Packs/Textures*.hpk'
INSTALLER_GAME_PKG5='./*'

APP1_ID="${GAME_ID}"
APP1_EXE='./VictorVranGOG'
APP1_ICON='data/noarch/support/icon.png'
APP1_ICON_RES='256x256'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG_VERSION='2.07'

PKG1_ID="${GAME_ID}"
PKG1_ARCH='i386'
PKG1_VERSION="${PKG_VERSION}"
PKG1_CONFLICTS=''
PKG1_DEPS='libc6, libstdc++6, libsdl2-2.0-0, libopenal1, libasound2-plugins, libgl1-mesa-glx | libgl1, libcurl3-gnutls, libxt6, libheimntlm0-heimdal'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG2_ID="${GAME_ID}-movies"
PKG2_ARCH='all'
PKG2_VERSION="${PKG_VERSION}"
PKG2_CONFLICTS=''
PKG2_DEPS=''
PKG2_RECS=''
PKG2_DESC="${GAME_NAME} - movies
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG2_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG1_DEPS}"

PKG3_ID="${GAME_ID}-maps"
PKG3_ARCH='all'
PKG3_VERSION="${PKG_VERSION}"
PKG3_CONFLICTS=''
PKG3_DEPS=''
PKG3_RECS=''
PKG3_DESC="${GAME_NAME} - maps
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG3_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG1_DEPS}"

PKG4_ID="${GAME_ID}-textures"
PKG4_ARCH='all'
PKG4_VERSION="${PKG_VERSION}"
PKG4_CONFLICTS=''
PKG4_DEPS=''
PKG4_RECS=''
PKG4_DESC="${GAME_NAME} - textures
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG4_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG1_DEPS}"

PKG5_ID="${GAME_ID}-data"
PKG5_ARCH='all'
PKG5_VERSION="${PKG_VERSION}"
PKG5_CONFLICTS=''
PKG5_DEPS=''
PKG5_RECS=''
PKG5_DESC="${GAME_NAME} - common data
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG5_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG1_DEPS}"

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
set_target '1' 'gog.com'
printf '\n'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG2_VERSION}-${PKG_REVISION}_${PKG2_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG3_DIR' "${PKG3_ID}_${PKG3_VERSION}-${PKG_REVISION}_${PKG3_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG4_DIR' "${PKG4_ID}_${PKG4_VERSION}-${PKG_REVISION}_${PKG4_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG5_DIR' "${PKG5_ID}_${PKG5_VERSION}-${PKG_REVISION}_${PKG5_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

# Check target files integrity

if [ "$GAME_ARCHIVE_CHECKSUM" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}"
fi

# Extract game data

PATH_ICON="${PATH_ICON_BASE}/${APP1_ICON_RES}/apps"

build_pkg_dirs '5' "${PATH_GAME}"
mkdir -p "${PKG1_DIR}${PATH_BIN}" "${PKG1_DIR}${PATH_DESK}"
mkdir -p "${PKG5_DIR}${PATH_DOC}" "${PKG5_DIR}${PATH_ICON}"
print wait

extract_data 'mojo' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'fix_rights,quiet'

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"
for file in ${INSTALLER_JUNK}; do
	rm -rf "${file}"
done

for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG5_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME_PKG1}; do
	mv "${file}" "${PKG1_DIR}${PATH_GAME}"
done

for file in ${INSTALLER_GAME_PKG2}; do
	mv "${file}" "${PKG2_DIR}${PATH_GAME}"
done

for file in ${INSTALLER_GAME_PKG3}; do
	mkdir -p "${PKG3_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG3_DIR}${PATH_GAME}/${file}"
done

for file in ${INSTALLER_GAME_PKG4}; do
	mkdir -p "${PKG4_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG4_DIR}${PATH_GAME}/${file}"
done

for file in ${INSTALLER_GAME_PKG5}; do
	mv "${file}" "${PKG5_DIR}${PATH_GAME}"
done
cd - > /dev/null

chmod 755 "${PKG1_DIR}${PATH_GAME}/${APP1_EXE}"

mv "${PKG_TMPDIR}/${APP1_ICON}" "${PKG5_DIR}${PATH_ICON}/${APP1_ID}.png"

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' '' "${APP1_NAME}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}"
printf '\n'

# Build packages

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}"
write_pkg_debian "${PKG3_DIR}" "${PKG3_ID}" "${PKG3_VERSION}-${PKG_REVISION}" "${PKG3_ARCH}" "${PKG3_CONFLICTS}" "${PKG3_DEPS}" "${PKG3_RECS}" "${PKG3_DESC}"
write_pkg_debian "${PKG4_DIR}" "${PKG4_ID}" "${PKG4_VERSION}-${PKG_REVISION}" "${PKG4_ARCH}" "${PKG4_CONFLICTS}" "${PKG4_DEPS}" "${PKG4_RECS}" "${PKG4_DESC}"
write_pkg_debian "${PKG5_DIR}" "${PKG5_ID}" "${PKG5_VERSION}-${PKG_REVISION}" "${PKG5_ARCH}" "${PKG5_CONFLICTS}" "${PKG5_DEPS}" "${PKG5_RECS}" "${PKG5_DESC}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG3_DIR}" "${PKG3_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG4_DIR}" "${PKG4_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG5_DIR}" "${PKG5_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG1_DESC}" "${PKG5_DIR}" "${PKG4_DIR}" "${PKG3_DIR}" "${PKG2_DIR}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
