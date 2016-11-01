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
# conversion script for the Unreal Tournament installer sold on GOG.com
# build a .deb package from the Windows installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161001.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='unreal-tournament'
GAME_ID_SHORT='ut99'
GAME_NAME='Unreal Tournament'

GAME_ARCHIVE1='setup_ut_goty_2.0.0.5.exe'
GAME_ARCHIVE1_MD5='0d25ec835648710a098aff7106187f38'
GAME_ARCHIVE2='ut99v451-linux.tar.gz'
GAME_ARCHIVE2_MD5='d645b0ea2d093e68afc8f1b5288496e5'
GAME_ARCHIVE_FULLSIZE='640000'
PKG_REVISION='gog2.0.0.5'

INSTALLER_PATH='app'
INSTALLER_JUNK='System/*.dll System/GotoHeat.exe System/mplaynow.exe System/nglide_config.exe System/Setup.exe System/UCC.exe System/UnrealEd.exe'
INSTALLER_DOC='./Help/* ./Manual/Manual.pdf'
INSTALLER_GAME='./Maps ./Music ./Sounds ./System ./Textures ./Web'

APP1_ID="${GAME_ID}"
APP1_EXE='System/ut-bin'
APP1_ICON='System/UnrealTournament.exe'
APP1_ICON_RES='32x32'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${APP1_NAME}"
APP1_CAT='Game'

PKG1_ID="${GAME_ID}"
PKG1_VERSION='451'
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='libc6, libstdc++6, libsdl1.2debian'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

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

# Define script-specific functions

extract_data_inno() {
	local archive="$1"
	local target="$2"
	printf '%s %s…\n' "$(l10n 'extract_data')" "${archive##*/}"
	mkdir -p "${target}"
	innoextract -se -p1 -d "${target}" "${archive}"
}

# Set extra variables

NO_ICON=0

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

printf '\n'
set_target '1' 'gog.com'
set_target_extra 'CLIENT_ARCHIVE' '' "${GAME_ARCHIVE2}"
printf '\n'

check_deps_hard ${SCRIPT_DEPS_HARD}

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE="/usr/local/share/icons/hicolor"

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	printf '%s…\n' "$(l10n 'checksum_multiple')"
	print wait
	checksum "${GAME_ARCHIVE}" 'quiet' "${GAME_ARCHIVE1_MD5}"
	checksum "${CLIENT_ARCHIVE}" 'quiet' "${GAME_ARCHIVE2_MD5}"
	print done
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC}" "${PATH_GAME}"
print wait

extract_data_inno "${GAME_ARCHIVE}" "${PKG_TMPDIR}"
extract_data 'tar' "${CLIENT_ARCHIVE}" "${PKG_TMPDIR}/app" 'quiet'

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"
for file in ${INSTALLER_JUNK}; do
	rm -rf "${file}"
done

for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done
rmdir 'Help' 'Manual'

for file in ${INSTALLER_GAME}; do
	mv "${file}" "${PKG1_DIR}${PATH_GAME}"
done
cd - > /dev/null

if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
fi
rm "${PKG1_DIR}${PATH_GAME}/${APP1_ICON}"

rm -Rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' '' "${APP1_NAME}"
sed -i 's|./"${GAME_EXE_PATH##\*/}"|mkdir -p "${HOME}/.loki/ut/System"\n&|' "${PKG1_DIR}${PATH_BIN}/${APP1_ID}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'alpha-centauri'
printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}"

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
