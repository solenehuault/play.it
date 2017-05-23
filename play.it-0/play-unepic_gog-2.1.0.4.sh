#!/bin/sh -e

###
# Copyright (c) 2015, Antoine Le Gonidec
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
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
###

###
# conversion script for the Unepic installer sold on GOG.com
# build a .deb package from the .sh MojoSetup installer
# tested on Debian, should work on any .deb-based distribution
#
# script version 20150815.1
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

# Setting game-specific variables
GAME_ID='unepic'
GAME_ARCHIVE1='gog_unepic_2.1.0.4.sh'
GAME_ARCHIVE1_MD5='341556e144d5d17ae23d2b0805c646a1'
GAME_FULL_SIZE='358380'
APP1_ID="${GAME_ID}"
APP1_EXE_ARCH1='./unepic32gog'
APP1_EXE_ARCH2='./unepic64gog'
APP1_ICON='./unepic.png'
APP1_ICON_RES='32x32'
APP1_NAME='unEpic'
APP1_NAME_FR="${APP1_NAME}"
APP1_CAT='Game'
PKG_ORIGIN='gog'
PKG_REVISION='2.1.0.4'
PKG1_ID="${GAME_ID}"
PKG1_ARCH='i386'
PKG1_VERSION='1.50.05'
PKG1_DEPS='libglu1-mesa | libglu1, libxcursor1, libxrandr2'
PKG1_RECS=''
PKG1_DESC='unEpic'
PKG2_ID="${PKG1_ID}"
PKG2_VERSION="${PKG1_VERSION}"
PKG2_ARCH='amd64'
PKG2_DEPS="${PKG1_DEPS}"
PKG2_RECS="${PKG1_RECS}"
PKG2_DESC="${PKG1_DESC}"
PKG1_CONFLICTS="${PKG2_ID}:${PKG2_ARCH}"
PKG2_CONFLICTS="${PKG1_ID}:${PKG1_ARCH}"

# Loading common functions
if ! [ -e './play-anything.sh' ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'play-anything.sh not found.\nIt must be placed in the same directory than this script.\n\n'
	exit 1
else
	. './play-anything.sh'
fi

# Setting extra variables
PKG_PREFIX_DEFAULT='/usr/local'
PKG_COMPRESSION_DEFAULT='none'
GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
set_workdir2
fetch_args "$*"
printf '\n'
check_deps 'unzip fakeroot' ''
printf '\n'
set_checksum
set_compression
set_prefix
PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON="/usr/local/share/icons/hicolor/${APP1_ICON_RES}/apps"
printf '\n'
set_target1 'gog.com'
printf '\n'

# Checking target files integrity
if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum1 "${GAME_ARCHIVE}" "${GAME_ARCHIVE1_MD5}"
fi

# Building package directories
printf '%s…\n' "$(l10n 'Construction de l’arborescence du paquet' 'Building package directories')"
rm -rf "${PKG1_DIR}" "${PKG2_DIR}"
for dir in "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC}" "${PATH_GAME}" "${PATH_ICON}" '/DEBIAN'; do
	mkdir -p "${PKG1_DIR}${dir}"
	mkdir -p "${PKG2_DIR}${dir}"
done
printf '\n'

# Extracting game data
extract_gamedata_mojo "${GAME_ARCHIVE}" "${PKG_TMPDIR}"
find "${PKG_TMPDIR}" -type f -exec chmod 644 '{}' +
mv "${PKG_TMPDIR}"/data/noarch/docs/* "${PKG1_DIR}${PATH_DOC}"
cp -rl "${PKG1_DIR}${PATH_DOC}"/* "${PKG2_DIR}${PATH_DOC}"
mv "${PKG_TMPDIR}"/data/noarch/game/data "${PKG1_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}"/data/noarch/game/image "${PKG1_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}"/data/noarch/game/save "${PKG1_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}"/data/noarch/game/sound "${PKG1_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}"/data/noarch/game/voices "${PKG1_DIR}${PATH_GAME}"
cp -rl "${PKG1_DIR}${PATH_GAME}"/* "${PKG2_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}"/data/noarch/game/unepic.png "${PKG1_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}"/data/noarch/game/lib32 "${PKG1_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}"/data/noarch/game/unepic32gog "${PKG1_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}"/data/noarch/game/lib64 "${PKG2_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}"/data/noarch/game/unepic64gog "${PKG2_DIR}${PATH_GAME}"
mv "${PKG1_DIR}${PATH_GAME}/${APP1_ICON}" "${PKG1_DIR}${PATH_ICON}/${GAME_ID}.png"
cp -l "${PKG1_DIR}${PATH_ICON}/${GAME_ID}.png" "${PKG2_DIR}${PATH_ICON}"
chmod 755 "${PKG1_DIR}${PATH_GAME}/${APP1_EXE_ARCH1}"
chmod 755 "${PKG2_DIR}${PATH_GAME}/${APP1_EXE_ARCH2}"


# Writing scripts (game launcher)
write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_ARCH1}"
write_bin_native "${PKG2_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_ARCH2}"
printf '\n'

# Writing menu entries
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}"
cp -l "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${PKG2_DIR}${PATH_DESK}/${APP1_ID}.desktop"
printf '\n'

# Writing package meta-data
write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}" 'arch'
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}" 'arch'
printf '\n'

# Building package
printf '%s…\n' "$(l10n 'Construction des paquets' 'Building packages')"
print_wait
rm -rf "${PKG_TMPDIR}"
mkdir "${PKG_TMPDIR}"
build_package "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" "${PKG1_ARCH}" 'quiet'
build_package "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" "${PKG2_ARCH}" 'quiet'
rm -rf "${PKG_TMPDIR}"
print_done
print_instructions "${PKG1_DESC} (${PKG1_ARCH})" "${PKG1_DIR}"
printf '\n'
print_instructions "${PKG2_DESC} (${PKG2_ARCH})" "${PKG2_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'Bon jeu' 'Have fun')"

exit 0
