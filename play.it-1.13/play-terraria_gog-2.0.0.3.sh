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
# conversion script for the Terraria installer sold on GOG.com
# build a .deb package from the .sh MojoSetup installer
# tested on Debian, should work on any .deb-based distribution
#
# script version 20160110.5
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='terraria'
GAME_ID_SHORT='terraria'
GAME_NAME='Terraria'

GAME_ARCHIVE1='gog_terraria_2.0.0.3.sh'
GAME_ARCHIVE1_MD5='6fd74fb8b762d1176e46ae17372a53ab'
GAME_ARCHIVE_FULLSIZE='300000'
PKG_REVISION='gog2.0.0.3'

INSTALLER_DOC='data/noarch/docs/* data/noarch/game/changelog.txt'
INSTALLER_GAME_ARCH1='data/noarch/game/lib data/noarch/game/Terraria.bin.x86 data/noarch/game/TerrariaServer.bin.x86'
INSTALLER_GAME_ARCH2='data/noarch/game/lib64 data/noarch/game/Terraria.bin.x86_64 data/noarch/game/TerrariaServer.bin.x86_64'
INSTALLER_GAME='data/noarch/game/*'

MENU_NAME="${GAME_NAME}"
MENU_NAME_FR="${GAME_NAME}"
MENU_CAT='Games'

APP1_ID="${GAME_ID}"
APP1_EXE_ARCH1='./Terraria.bin.x86'
APP1_EXE_ARCH2='./Terraria.bin.x86_64'
APP1_ICON='./Terraria.png'
APP1_ICON_RES='512x512'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"

APP2_ID="${GAME_ID}_server"
APP2_EXE_ARCH1='./TerrariaServer.bin.x86'
APP2_EXE_ARCH2='./TerrariaServer.bin.x86_64'
APP2_ICON="${APP1_ICON}"
APP2_ICON_RES='512x512'
APP2_NAME="${GAME_NAME}: server"
APP2_NAME_FR="${GAME_NAME} : serveur"

PKG_ID="${GAME_ID}"
PKG_VERSION='1.3.0.8'
PKG_DEPS='libglu1-mesa | libglu1, libxcursor1, libxrandr2'
PKG_RECS=''
PKG_DESC="${GAME_NAME}
 package built from GOG.com installer
   ./play.it script version 20160110.5"

PKG1_ID="${PKG_ID}"
PKG1_ARCH='i386'
PKG1_VERSION="${PKG_VERSION}"
PKG1_DEPS="${PKG_DEPS}"
PKG1_RECS="${PKG_RECS}"
PKG1_DESC="${PKG_DESC}"

PKG2_ID="${PKG_ID}"
PKG2_ARCH='amd64'
PKG2_VERSION="${PKG_VERSION}"
PKG2_DEPS="${PKG_DEPS}"
PKG2_RECS="${PKG_RECS}"
PKG2_DESC="${PKG_DESC}"

PKG1_CONFLICTS="${PKG2_ID}:${PKG2_ARCH}"
PKG2_CONFLICTS="${PKG1_ID}:${PKG1_ARCH}"

# Load common functions

TARGET_LIB_VERSION='1.13'
if ! [ -e './play-anything.sh' ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'play-anything.sh not found.\nIt must be placed in the same directory than this script.\n\n'
	exit 1
fi
LIB_VERSION="$(grep '^# library version' './play-anything.sh' | cut -d' ' -f4 | cut -d'.' -f1,2)"
if [ ${LIB_VERSION%.*} -ne ${TARGET_LIB_VERSION%.*} ] || [ ${LIB_VERSION#*.} -lt ${TARGET_LIB_VERSION#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'Wrong version of play-anything.\nIt must be at least %s but lower than %s.\n\n' "${TARGET_LIB_VERSION}" "$((${TARGET_LIB_VERSION%.*}+1)).0"
	exit 1
fi
. './play-anything.sh'

# Set extra variables

PKG_PREFIX_DEFAULT='/usr/local'
PKG_COMPRESSION_DEFAULT='none'
GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
GAME_LANG_DEFAULT=''
WITH_MOVIES_DEFAULT=''

printf '\n'
game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG2_VERSION}-${PKG_REVISION}_${PKG2_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
fetch_args "$@"
check_deps "${SCRIPT_DEP_HARDS}"
printf '\n'
set_checksum
set_compression
set_prefix

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DESK_DIR='/usr/local/share/desktop-directories'
PATH_DESK_MERGED='/etc/xdg/menus/applications-merged'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON="/usr/local/share/icons/hicolor/${APP1_ICON_RES}/apps"

printf '\n'
set_target '1' 'gog.com'
printf '\n'

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}"
fi

# Extract game data
build_pkg_dirs '2' "${PATH_BIN}" "${PATH_DESK}" "${PATH_DESK_DIR}" "${PATH_DESK_MERGED}" "${PATH_DOC}" "${PATH_GAME}" "${PATH_ICON}"
extract_data 'mojo' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'fix_rights,quiet'
for file in ${INSTALLER_DOC}; do
	cp -rl "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_DOC}"
	cp -rl "${PKG_TMPDIR}"/${file} "${PKG2_DIR}${PATH_DOC}"
done
for file in ${INSTALLER_GAME_ARCH1}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_GAME}"
done
for file in ${INSTALLER_GAME_ARCH2}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG2_DIR}${PATH_GAME}"
done
for file in ${INSTALLER_GAME}; do
	cp -rl "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_GAME}"
	cp -rl "${PKG_TMPDIR}"/${file} "${PKG2_DIR}${PATH_GAME}"
done
chmod 755 "${PKG1_DIR}${PATH_GAME}/${APP1_EXE_ARCH1}"
chmod 755 "${PKG2_DIR}${PATH_GAME}/${APP1_EXE_ARCH2}"
chmod 755 "${PKG1_DIR}${PATH_GAME}/${APP2_EXE_ARCH1}"
chmod 755 "${PKG2_DIR}${PATH_GAME}/${APP2_EXE_ARCH2}"
chmod 755 "${PKG1_DIR}${PATH_GAME}"/Terraria
chmod 755 "${PKG2_DIR}${PATH_GAME}"/TerrariaServer
chmod 755 "${PKG1_DIR}${PATH_GAME}"/Terraria
chmod 755 "${PKG2_DIR}${PATH_GAME}"/TerrariaServer
rm -rf "${PKG_TMPDIR}"

print done

# Write launchers

write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_ARCH1}" '' '' '' "${APP1_NAME} (${PKG1_ARCH})"
write_bin_native "${PKG2_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_ARCH2}" '' '' '' "${APP1_NAME} (${PKG2_ARCH})"
write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE_ARCH1}" '' '' '' "${APP2_NAME} (${PKG1_ARCH})"
write_bin_native "${PKG2_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE_ARCH2}" '' '' '' "${APP2_NAME} (${PKG2_ARCH})"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" '' ''
write_desktop "${APP2_ID}" "${APP2_NAME}" "${APP2_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP2_ID}.desktop" '' ''
write_menu "${GAME_ID}" "${MENU_NAME}" "${MENU_NAME_FR}" "${MENU_CAT}" "${PKG1_DIR}${PATH_DESK_DIR}/${GAME_ID}.directory" "${PKG1_DIR}${PATH_DESK_MERGED}/${GAME_ID}.menu" '' "${APP1_ID}" "${APP2_ID}"
cp -l "${PKG1_DIR}${PATH_DESK}"/*.desktop "${PKG2_DIR}${PATH_DESK}"
cp -l "${PKG1_DIR}${PATH_DESK_DIR}/${GAME_ID}.directory" "${PKG2_DIR}${PATH_DESK_DIR}"
cp -l "${PKG1_DIR}${PATH_DESK_MERGED}/${GAME_ID}.menu" "${PKG2_DIR}${PATH_DESK_MERGED}"
printf '\n'

# Build packages

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait
for pkg in "${PKG1_DIR}" "${PKG2_DIR}"; do
	file="${pkg}/DEBIAN/postinst"
	cat > "${file}" <<- EOF
	#!/bin/sh -e
	ln -s "${PATH_GAME}/${APP1_ICON}" "${PATH_ICON}/${APP1_ID}.png"
	ln -s "${PATH_GAME}/${APP2_ICON}" "${PATH_ICON}/${APP2_ID}.png"
	exit 0
	EOF
	chmod 755 "${file}"
	file="${pkg}/DEBIAN/prerm"
	cat > "${file}" <<- EOF
	#!/bin/sh -e
	rm "${PATH_ICON}/${APP1_ID}.png"
	rm "${PATH_ICON}/${APP2_ID}.png"
	exit 0
	EOF
	chmod 755 "${file}"
done
write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}" 'arch'
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}" 'arch'
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet' "${PKG1_ARCH}"
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet' "${PKG2_ARCH}"
print done
print_instructions "${PKG1_DESC} (${PKG1_ARCH})" "${PKG1_DIR}"
printf '\n'
print_instructions "${PKG2_DESC} (${PKG2_ARCH})" "${PKG2_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
