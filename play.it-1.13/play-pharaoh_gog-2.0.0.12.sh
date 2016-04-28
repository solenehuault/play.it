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
# conversion script for the Pharaoh + Cleopatra installer sold on GOG.com
# build a .deb package from the Windows installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20160428.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='pharaoh'
GAME_ID_SHORT='pharaoh'
GAME_NAME='Pharaoh'

GAME_ARCHIVE1='setup_pharaoh_gold_2.0.0.12.exe'
GAME_ARCHIVE1_MD5='04631d3942f7e16fd5d96bf2238c0528'
GAME_ARCHIVE_FULLSIZE='810000'
PKG_REVISION='gog2.0.0.12'

GAME_TRADFR_ARCHIVE1='pharaonfr-textes.7z'
GAME_TRADFR_ARCHIVE1_MD5='609fd40b7cb7202583698478deb320c8'
GAME_TRADFR_ARCHIVE2='pharaonfr-voix.7z'
GAME_TRADFR_ARCHIVE2_MD5='0eed85eeebf06e7d62a371d1f4dd9a59'
GAME_TRADFR_ARCHIVE3='pharaonfr-videos.7z'
GAME_TRADFR_ARCHIVE3_MD5='561954174d2a4e918babf4a4d12cad1b'

INSTALLER_DOC='app/mission?editor?guide.txt app/readme.txt app/*.pdf tmp/gog_eula.txt tmp/eula.txt'
INSTALLER_GAME='app/*'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./save'
GAME_DATA_FILES='./*.inf ./*.txt'
GAME_DATA_FILES_POST='./status.txt'

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./pharaoh.exe'
APP1_ICON='./pharaoh.exe'
APP1_ICON_RES='16x16 32x32'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR='Pharaon'
APP1_CAT='Game'

PKG1_ID="${GAME_ID}"
PKG1_VERSION='2.1'
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

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
GAME_LANG_DEFAULT='en'

fetch_args "$@"

set_checksum
set_compression
set_prefix
set_lang

if [ "${GAME_LANG}" = 'fr' ]; then
	SCRIPT_DEPS_HARD="${SCRIPT_DEPS_HARD} 7z"
fi

check_deps_hard ${SCRIPT_DEPS_HARD}
check_deps_soft ${SCRIPT_DEPS_SOFT}

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE="/usr/local/share/icons/hicolor"

printf '\n'
set_target '1' 'gog.com'
if [ "${GAME_LANG}" = 'fr' ]; then
	set_target_optional 'TRADFR_ARCHIVE1' "${GAME_TRADFR_ARCHIVE1}"
	set_target_optional 'TRADFR_ARCHIVE2' "${GAME_TRADFR_ARCHIVE2}"
	set_target_optional 'TRADFR_ARCHIVE3' "${GAME_TRADFR_ARCHIVE3}"
fi
printf '\n'

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	printf '%s…\n' "$(l10n 'checksum_multiple')"
	print wait
	checksum "${GAME_ARCHIVE}" 'quiet' "${GAME_ARCHIVE1_MD5}"
	if [ "${GAME_LANG}" = 'fr' ]; then
		[ -n "${TRADFR_ARCHIVE1}" ] && checksum "${TRADFR_ARCHIVE1}" 'quiet' "${GAME_TRADFR_ARCHIVE1_MD5}"
		[ -n "${TRADFR_ARCHIVE2}" ] && checksum "${TRADFR_ARCHIVE2}" 'quiet' "${GAME_TRADFR_ARCHIVE2_MD5}"
		[ -n "${TRADFR_ARCHIVE3}" ] && checksum "${TRADFR_ARCHIVE3}" 'quiet' "${GAME_TRADFR_ARCHIVE3_MD5}"
	fi
	print done
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_GAME}"
print wait

extract_data 'inno' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'

if [ "${GAME_LANG}" = 'fr' ]; then
	[ -n "${TRADFR_ARCHIVE1}" ] && extract_data '7z' "${TRADFR_ARCHIVE1}" "${PKG_TMPDIR}/app" 'force,quiet'
	[ -n "${TRADFR_ARCHIVE2}" ] && extract_data '7z' "${TRADFR_ARCHIVE2}" "${PKG_TMPDIR}/app" 'force,quiet'
	[ -n "${TRADFR_ARCHIVE3}" ] && extract_data '7z' "${TRADFR_ARCHIVE3}" "${PKG_TMPDIR}/app" 'force,quiet'
fi

cd "${PKG_TMPDIR}"
for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME}; do
	mv "${file}" "${PKG1_DIR}${PATH_GAME}"
done
cd - > /dev/null

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

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}"

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
