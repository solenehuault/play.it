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
# conversion script for the 140 archive sold on Humble Bundle
# build .deb packages from the .zip archive
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161125.2

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='140-game'
GAME_ID_SHORT='140'
GAME_NAME='140'

GAME_ARCHIVE_HUMBLE='140_Linux_1389820765.zip'
GAME_ARCHIVE_HUMBLE_MD5='e78c09a2a9f47d89a4bb1e4e97911e79'
GAME_ARCHIVE_HUMBLE_FULLSIZE='92000'
GAME_ARCHIVE_HUMBLE_VERSION='1.0-humble1389820765'
GAME_ARCHIVE_HUMBLE_TYPE='zip'

INSTALLER_GAME_PKG_32='./140.x86 140_Data/Mono/x86 140_Data/Plugins/x86'
INSTALLER_GAME_PKG_64='./140.x86_64 140_Data/Mono/x86_64 140_Data/Plugins/x86_64'
INSTALLER_GAME_PKG_COMMON='./140_Data'

APP_MAIN_ID="${GAME_ID}"
APP_MAIN_EXE_32='./140.x86'
APP_MAIN_EXE_64='./140.x86_64'
APP_MAIN_ICON='./140_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128x128'
APP_MAIN_NAME="${GAME_NAME}"
APP_MAIN_NAME_FR="${GAME_NAME}"
APP_MAIN_CAT='Game'

PKG_ID="${GAME_ID}"
PKG_DEPS='libglu1-mesa | libglu1, libasound2-plugins, libxcursor1'
PKG_DESC="${GAME_NAME}
 package built from HumbleBundle.com .zip archive
 ./play.it script version ${script_version}"

PKG_32_ID="${PKG_ID}"
PKG_32_ARCH='i386'
PKG_VERSION="${PKG_VERSION}"
PKG_32_DEPS="${PKG_DEPS}"
PKG_32_RECS=''
PKG_32_DESC="${PKG_DESC}"

PKG_64_ID="${PKG_ID}"
PKG_64_ARCH='amd64'
PKG_VERSION="${PKG_VERSION}"
PKG_64_DEPS="${PKG_DEPS}"
PKG_64_RECS=''
PKG_64_DESC="${PKG_DESC}"

PKG_COMMON_ID="${GAME_ID}-common"
PKG_COMMON_ARCH='all'
PKG_VERSION="${PKG_VERSION}"
PKG_COMMON_CONFLICTS=''
PKG_COMMON_DEPS=''
PKG_COMMON_RECS=''
PKG_COMMON_DESC="${GAME_NAME} - arch-independant data
 package built from HumbleBundle.com .zip archive
 ./play.it script version ${script_version}"

PKG_32_CONFLICTS="${PKG_64_ID}:${PKG_64_ARCH}"
PKG_64_CONFLICTS="${PKG_32_ID}:${PKG_32_ARCH}"

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
GAME_ARCHIVE1="${GAME_ARCHIVE_HUMBLE}"
set_target '1' 'humblebundle.com'
GAME_ARCHIVE_MD5="${GAME_ARCHIVE_HUMBLE_MD5}"
GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE_HUMBLE_FULLSIZE}"
GAME_ARCHIVE_TYPE="${GAME_ARCHIVE_HUMBLE_TYPE}"
PKG_VERSION="${GAME_ARCHIVE_HUMBLE_VERSION}"
PKG_32_DEPS="${PKG_COMMON_ID} (= ${PKG_VERSION}), ${PKG_32_DEPS}"
PKG_64_DEPS="${PKG_COMMON_ID} (= ${PKG_VERSION}), ${PKG_64_DEPS}"
printf '\n'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG_32_DIR' "${PKG_32_ID}_${PKG_VERSION}_${PKG_32_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG_64_DIR' "${PKG_64_ID}_${PKG_VERSION}_${PKG_64_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG_COMMON_DIR' "${PKG_COMMON_ID}_${PKG_VERSION}_${PKG_COMMON_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON="/usr/local/share/icons/hicolor/${APP_MAIN_ICON_RES}/apps"

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE_MD5}"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"

for pkg_dir in "${PKG_32_DIR}" "${PKG_64_DIR}" "${PKG_COMMON_DIR}"; do
	rm -Rf "${pkg_dir}"
	mkdir -p "${pkg_dir}/DEBIAN"
	mkdir -p "${pkg_dir}/${PATH_GAME}"
done

for pkg_dir in "${PKG_32_DIR}" "${PKG_64_DIR}"; do
	mkdir -p "${pkg_dir}/${PATH_BIN}"
	mkdir -p "${pkg_dir}/${PATH_DESK}"
done

mkdir -p "${PKG_COMMON_DIR}${PATH_ICON}"

print wait

extract_data "${GAME_ARCHIVE_TYPE}" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'fix_rights,quiet'

cd "${PKG_TMPDIR}"

for file in ${INSTALLER_GAME_PKG_32}; do
	mkdir -p "${PKG_32_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG_32_DIR}${PATH_GAME}/${file%/*}"
done

for file in ${INSTALLER_GAME_PKG_64}; do
	mkdir -p "${PKG_64_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG_64_DIR}${PATH_GAME}/${file%/*}"
done

for file in ${INSTALLER_GAME_PKG_COMMON}; do
	mkdir -p "${PKG_COMMON_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG_COMMON_DIR}${PATH_GAME}/${file%/*}"
done

cd - > /dev/null

chmod 755 "${PKG_32_DIR}${PATH_GAME}/${APP_MAIN_EXE_32}"
chmod 755 "${PKG_64_DIR}${PATH_GAME}/${APP_MAIN_EXE_64}"

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_native "${PKG_32_DIR}${PATH_BIN}/${APP_MAIN_ID}" "${APP_MAIN_EXE_32}" '' '' '' "${APP_MAIN_NAME} (${PKG_32_ARCH})"
write_bin_native "${PKG_64_DIR}${PATH_BIN}/${APP_MAIN_ID}" "${APP_MAIN_EXE_64}" '' '' '' "${APP_MAIN_NAME} (${PKG_64_ARCH})"

write_desktop "${APP_MAIN_ID}" "${APP_MAIN_NAME}" "${APP_MAIN_NAME_FR}" "${PKG_32_DIR}${PATH_DESK}/${APP_MAIN_ID}.desktop" "${APP_MAIN_CAT}"
write_desktop "${APP_MAIN_ID}" "${APP_MAIN_NAME}" "${APP_MAIN_NAME_FR}" "${PKG_64_DIR}${PATH_DESK}/${APP_MAIN_ID}.desktop" "${APP_MAIN_CAT}"

printf '\n'

# Build packages

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG_32_DIR}" "${PKG_32_ID}" "${PKG_VERSION}" "${PKG_32_ARCH}" "${PKG_32_CONFLICTS}" "${PKG_32_DEPS}" "${PKG_32_RECS}" "${PKG_32_DESC}" 'arch'
write_pkg_debian "${PKG_64_DIR}" "${PKG_64_ID}" "${PKG_VERSION}" "${PKG_64_ARCH}" "${PKG_64_CONFLICTS}" "${PKG_64_DEPS}" "${PKG_64_RECS}" "${PKG_64_DESC}" 'arch'
write_pkg_debian "${PKG_COMMON_DIR}" "${PKG_COMMON_ID}" "${PKG_VERSION}" "${PKG_COMMON_ARCH}" "${PKG_COMMON_CONFLICTS}" "${PKG_COMMON_DEPS}" "${PKG_COMMON_RECS}" "${PKG_COMMON_DESC}"

file="${PKG_COMMON_DIR}/DEBIAN/postinst"
cat > "${file}" << EOF
#!/bin/sh -e
ln -s "${PATH_GAME}/${APP_MAIN_ICON}" "${PATH_ICON}/${GAME_ID}.png"
exit 0
EOF
chmod 755 "${file}"

file="${PKG_COMMON_DIR}/DEBIAN/prerm"
cat > "${file}" << EOF
#!/bin/sh -e
rm "${PATH_ICON}/${GAME_ID}.png"
exit 0
EOF
chmod 755 "${file}"

build_pkg "${PKG_32_DIR}" "${PKG_32_DESC}" "${PKG_COMPRESSION}" 'quiet' "${PKG_32_ARCH}"
build_pkg "${PKG_64_DIR}" "${PKG_64_DESC}" "${PKG_COMPRESSION}" 'quiet' "${PKG_64_ARCH}"
build_pkg "${PKG_COMMON_DIR}" "${PKG_COMMON_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "$(printf '%s' "${PKG_32_DESC}" | head -n1) (${PKG_32_ARCH})" "${PKG_COMMON_DIR}" "${PKG_32_DIR}"
printf '\n'
print_instructions "$(printf '%s' "${PKG_64_DESC}" | head -n1) (${PKG_64_ARCH})" "${PKG_COMMON_DIR}" "${PKG_64_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
