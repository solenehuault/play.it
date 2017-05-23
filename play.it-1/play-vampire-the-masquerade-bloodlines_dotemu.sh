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
# conversion script for the Vampire the Masquerade: Bloodlines installer formerly sold on DotEmu
# build a .deb package from the Windows installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20160427.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unar unzip'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='vampire-the-masquerade-bloodlines'
GAME_ID_SHORT='bloodlines'
GAME_NAME='Vampire: The Masquerade - Bloodlines'

GAME_ARCHIVE1='vampire_the_masquerade_bloodlines_v1.2.exe'
GAME_ARCHIVE1_MD5='8981da5fa644475583b2888a67fdd741'
GAME_ARCHIVE_FULLSIZE='3000000'
PKG_REVISION='dotemu1'

INSTALLER_JUNK='en/docs/help/tech?help/customer?support/customer_support.htm de/docs/help/_borders/top_files en/docs/help/_borders/top_files fr/docs/help/_borders/top_files de/docs/help/readme fr/docs/help/readme'
INSTALLER_DOC_PKG1='common2/docs/* en/docs/help/readme/*'
INSTALLER_DOC_PKG2='de/docs/* de/*.pdf'
INSTALLER_DOC_PKG3='en/docs/* en/*.pdf'
INSTALLER_DOC_PKG4='fr/docs/* fr/*.pdf'
INSTALLER_GAME_PKG1='common1/* common2/*'
INSTALLER_GAME_PKG2='de/*'
INSTALLER_GAME_PKG3='en/*'
INSTALLER_GAME_PKG4='fr/*'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST='vampire/*.tmp'
GAME_CONFIG_DIRS='vampire/cfg'
GAME_CONFIG_FILES=''
GAME_CONFIG_FILES_POST='vampire/vidcfg.bin'
GAME_DATA_DIRS='vampire/maps/graphs vampire/python vampire/save'
GAME_DATA_FILES=''
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./vampire.exe'
APP1_ICON='./vampire.exe'
APP1_ICON_RES='32x32'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG_VERSION='1.2'

PKG1_ID="${GAME_ID}"
PKG1_VERSION="${PKG_VERSION}"
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from DotEmu.com Windows installer
 ./play.it script version ${script_version}"

PKG2_ID="${GAME_ID}-l10n-de"
PKG2_VERSION="${PKG_VERSION}"
PKG2_ARCH='all'
PKG2_CONFLICTS=''
PKG2_DEPS=''
PKG2_RECS=''
PKG2_DESC="${GAME_NAME} (German files)
 package built from DotEmu.com Windows installer
 ./play.it script version ${script_version}"

PKG3_ID="${GAME_ID}-l10n-en"
PKG3_VERSION="${PKG_VERSION}"
PKG3_ARCH='all'
PKG3_CONFLICTS=''
PKG3_DEPS=''
PKG3_RECS=''
PKG3_DESC="${GAME_NAME} (English files)
 package built from DotEmu.com Windows installer
 ./play.it script version ${script_version}"

PKG4_ID="${GAME_ID}-l10n-fr"
PKG4_VERSION="${PKG_VERSION}"
PKG4_ARCH='all'
PKG4_CONFLICTS=''
PKG4_DEPS=''
PKG4_RECS=''
PKG4_DESC="${GAME_NAME} (French files)
 package built from DotEmu.com Windows installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG2_ID} (= ${PKG_VERSION}-${PKG_REVISION}) | ${PKG3_ID} (= ${PKG_VERSION}-${PKG_REVISION}) | ${PKG4_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG1_DEPS}"
PKG2_CONFLICTS="${PKG3_ID}, ${PKG4_ID}"
PKG3_CONFLICTS="${PKG2_ID}, ${PKG4_ID}"
PKG4_CONFLICTS="${PKG2_ID}, ${PKG3_ID}"

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
game_mkdir 'PKG3_DIR' "${PKG3_ID}_${PKG3_VERSION}-${PKG_REVISION}_${PKG3_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG4_DIR' "${PKG4_ID}_${PKG4_VERSION}-${PKG_REVISION}_${PKG4_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

printf '\n'
set_target '1' 'dotemu.com'
printf '\n'

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}"
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_GAME}"
for dir in "${PKG2_DIR}" "${PKG3_DIR}" "${PKG4_DIR}"; do
	rm -rf "${dir}"
	mkdir -p "${dir}/DEBIAN" "${dir}/${PATH_DOC}" "${dir}/${PATH_GAME}"
done
print wait

extract_data 'unar_passwd' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'
for archive in "${PKG_TMPDIR}"/*.zip; do
	extract_data 'zip' "${archive}" "${archive%.zip}" 'quiet'
	rm "${archive}"
done

cd "${PKG_TMPDIR}"
tolower .

for file in ${INSTALLER_JUNK}; do
	rm -rf "${file}"
done

for file in ${INSTALLER_DOC_PKG1}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done
rmdir 'en/docs/help/readme'
for file in ${INSTALLER_DOC_PKG2}; do
	mv "${file}" "${PKG2_DIR}${PATH_DOC}"
done
for file in ${INSTALLER_DOC_PKG3}; do
	mv "${file}" "${PKG3_DIR}${PATH_DOC}"
done
for file in ${INSTALLER_DOC_PKG4}; do
	mv "${file}" "${PKG4_DIR}${PATH_DOC}"
done

rmdir */docs

for file in ${INSTALLER_GAME_PKG1}; do
	cp -rl "${file}" "${PKG1_DIR}${PATH_GAME}"
	rm -rf "${file}"
done
for file in ${INSTALLER_GAME_PKG2}; do
	mv "${file}" "${PKG2_DIR}${PATH_GAME}"
done
for file in ${INSTALLER_GAME_PKG3}; do
	mv "${file}" "${PKG3_DIR}${PATH_GAME}"
done
for file in ${INSTALLER_GAME_PKG4}; do
	mv "${file}" "${PKG4_DIR}${PATH_GAME}"
done

cd - 1>/dev/null

if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
fi

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
write_pkg_debian "${PKG3_DIR}" "${PKG3_ID}" "${PKG3_VERSION}-${PKG_REVISION}" "${PKG3_ARCH}" "${PKG3_CONFLICTS}" "${PKG3_DEPS}" "${PKG3_RECS}" "${PKG3_DESC}"
write_pkg_debian "${PKG4_DIR}" "${PKG4_ID}" "${PKG4_VERSION}-${PKG_REVISION}" "${PKG4_ARCH}" "${PKG4_CONFLICTS}" "${PKG4_DEPS}" "${PKG4_RECS}" "${PKG4_DESC}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG3_DIR}" "${PKG3_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG4_DIR}" "${PKG4_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "$(printf '%s' "${PKG1_DESC}" | head -n1) (German)" "${PKG2_DIR}" "${PKG1_DIR}"
printf '\n'
print_instructions "$(printf '%s' "${PKG1_DESC}" | head -n1) (English)" "${PKG3_DIR}" "${PKG1_DIR}"
printf '\n'
print_instructions "$(printf '%s' "${PKG1_DESC}" | head -n1) (French)" "${PKG4_DIR}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
