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
# conversion script for the Pillars of Eternity installer sold on GOG.com
# build a .deb package from the .sh MojoSetup installer
# tested on Debian, should work on any .deb-based distribution
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

script_version=20160324.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='pillars-of-eternity'
GAME_ID_SHORT='poe'
GAME_NAME='Pillars of Eternity'

GAME_ARCHIVE1='gog_pillars_of_eternity_2.12.0.16.sh'
GAME_ARCHIVE1_MD5='5cdeae373f182ad4cc83fd51e8e09e60'
GAME_DLC_ARCHIVE1='gog_pillars_of_eternity_kickstarter_item_dlc_2.0.0.2.sh'
GAME_DLC_ARCHIVE1_MD5='b4c29ae17c87956471f2d76d8931a4e5'
GAME_DLC_ARCHIVE2='gog_pillars_of_eternity_kickstarter_pet_dlc_2.0.0.2.sh'
GAME_DLC_ARCHIVE2_MD5='3653fc2a98ef578335f89b607f0b7968'
GAME_DLC_ARCHIVE3='gog_pillars_of_eternity_preorder_item_and_pet_dlc_2.0.0.2.sh'
GAME_DLC_ARCHIVE3_MD5='b86ad866acb62937d2127407e4beab19'
GAME_ARCHIVE_FULLSIZE='15000000'
PKG_REVISION='gog2.12.0.16'

INSTALLER_DOC='data/noarch/game/Docs data/noarch/game/Links data/noarch/docs/*'
INSTALLER_GAME_PKG1='data/noarch/game/*'
INSTALLER_GAME_PKG2='data/noarch/game/PillarsOfEternity_Data/assetbundles/st_*'

APP1_ID="${GAME_ID}"
APP1_EXE='./PillarsOfEternity'
APP1_ICON1='./PillarsOfEternity.png'
APP1_ICON1_RES='512x512'
APP1_ICON2='./PillarsOfEternity_Data/Resources/UnityPlayer.png'
APP1_ICON2_RES='128x128'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG_ARCH='amd64'
PKG_VERSION='3.02.1008'

PKG1_ID="${GAME_ID}"
PKG1_ARCH="${PKG_ARCH}"
PKG1_VERSION="${PKG_VERSION}"
PKG1_CONFLICTS="${GAME_ID}-px1 (<< ${PKG_VERSION}), ${GAME_ID}-px2 (<< ${PKG_VERSION})"
PKG1_DEPS='libglu1-mesa | libglu1, libxcursor1, libxrandr2'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG2_ID="${GAME_ID}-data"
PKG2_ARCH="${PKG_ARCH}"
PKG2_VERSION="${PKG_VERSION}"
PKG2_CONFLICTS=''
PKG2_DEPS=''
PKG2_RECS=''
PKG2_DESC="${GAME_NAME} - data
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

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard ${SCRIPT_DEPS_HARD}

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG2_VERSION}-${PKG_REVISION}_${PKG2_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

printf '\n'
set_target '1' 'gog.com'
set_target_optional 'DLC1_ARCHIVE' "${GAME_DLC_ARCHIVE1}"
set_target_optional 'DLC2_ARCHIVE' "${GAME_DLC_ARCHIVE2}"
set_target_optional 'DLC3_ARCHIVE' "${GAME_DLC_ARCHIVE3}"
printf '\n'

# Check target files integrity

if [ "$GAME_ARCHIVE_CHECKSUM" = 'md5sum' ]; then
	printf '%s…\n' "$(l10n 'checksum_multiple')"
	print wait

	checksum "${GAME_ARCHIVE}" 'quiet' "${GAME_ARCHIVE1_MD5}"

	[ -n "${DLC1_ARCHIVE}" ] && checksum "${DLC1_ARCHIVE}" 'quiet' "${GAME_DLC_ARCHIVE1_MD5}"
	[ -n "${DLC2_ARCHIVE}" ] && checksum "${DLC2_ARCHIVE}" 'quiet' "${GAME_DLC_ARCHIVE2_MD5}"
	[ -n "${DLC3_ARCHIVE}" ] && checksum "${DLC3_ARCHIVE}" 'quiet' "${GAME_DLC_ARCHIVE3_MD5}"

	print done
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC}" "${PATH_GAME}" "${PATH_ICON}"
mkdir -p "${PKG2_DIR}${PATH_GAME}/PillarsOfEternity_Data/assetbundles" "${PKG2_DIR}/DEBIAN"

printf '\n%s…\n' "$(l10n 'extract_data_generic')"
print wait

extract_data 'mojo' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'

[ -n "${DLC1_ARCHIVE}" ] && extract_data 'mojo' "${DLC1_ARCHIVE}" "${PKG_TMPDIR}" 'force,quiet'
[ -n "${DLC2_ARCHIVE}" ] && extract_data 'mojo' "${DLC2_ARCHIVE}" "${PKG_TMPDIR}" 'force,quiet'
[ -n "${DLC3_ARCHIVE}" ] && extract_data 'mojo' "${DLC3_ARCHIVE}" "${PKG_TMPDIR}" 'force,quiet'

for file in ${INSTALLER_DOC}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME_PKG2}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG2_DIR}${PATH_GAME}/PillarsOfEternity_Data/assetbundles"
done

for file in ${INSTALLER_GAME_PKG1}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_GAME}"
done

fix_rights "${PKG1_DIR}${PATH_DOC}" "${PKG1_DIR}${PATH_GAME}" "${PKG2_DIR}${PATH_GAME}"

chmod 755 "${PKG1_DIR}${PATH_GAME}/${APP1_EXE}"

PATH_ICON1="${PATH_ICON_BASE}/${APP1_ICON1_RES}/apps"
PATH_ICON2="${PATH_ICON_BASE}/${APP1_ICON2_RES}/apps"
mkdir -p "${PKG1_DIR}${PATH_ICON1}" "${PKG1_DIR}${PATH_ICON2}"

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

file="${PKG1_DIR}/DEBIAN/postinst"
cat > "${file}" <<- EOF
#!/bin/sh -e
ln -s "${PATH_GAME}/${APP1_ICON1}" "${PATH_ICON1}/${GAME_ID}.png"
ln -s "${PATH_GAME}/${APP1_ICON2}" "${PATH_ICON2}/${GAME_ID}.png"
exit 0
EOF
chmod 755 "${file}"

file="${PKG1_DIR}/DEBIAN/prerm"
cat > "${file}" <<- EOF
#!/bin/sh -e
rm "${PATH_ICON1}/${GAME_ID}.png"
rm "${PATH_ICON2}/${GAME_ID}.png"
exit 0
EOF
chmod 755 "${file}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG1_DESC}" "${PKG2_DIR}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
