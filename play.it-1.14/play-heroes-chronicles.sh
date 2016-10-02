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
# conversion script for the Heroes Chronicles installers sold on GOG.com
# build a .deb package from the Innosetup installers
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161002.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='heroes-chronicles'
GAME_ID_SHORT='hchronicles'
GAME_NAME_SHORT='Heroes Chronicles'

GAME_ARCHIVE1='setup_heroes_chronicles_chapter1_2.1.0.42.exe'
GAME_ARCHIVE1_MD5='f584d6e11ed47d1d40e973a691adca5d'
GAME_ARCHIVE1_REVISION='gog2.1.0.42'
GAME_ARCHIVE1_FULLSIZE='500000'
GAME_ARCHIVE1_NAME='Warlords of the Wasteland'

GAME_ARCHIVE2='setup_heroes_chronicles_chapter2_2.1.0.43.exe'
GAME_ARCHIVE2_MD5='0d240bc0309814ba251c2d9b557cf69f'
GAME_ARCHIVE2_REVISION='gog2.1.0.43'
GAME_ARCHIVE2_FULLSIZE='510000'
GAME_ARCHIVE2_NAME='Conquest of the Underworld'

GAME_ARCHIVE3='setup_heroes_chronicles_chapter3_2.1.0.41.exe'
GAME_ARCHIVE3_MD5='cb21751572960d47a259efc17b92c88c'
GAME_ARCHIVE3_REVISION='gog2.1.0.41'
GAME_ARCHIVE3_FULLSIZE='490000'
GAME_ARCHIVE3_NAME='Master of the Elements'

GAME_ARCHIVE4='setup_heroes_chronicles_chapter4_2.1.0.42.exe'
GAME_ARCHIVE4_MD5='922291e16176cb4bd37ca88eb5f3a19e'
GAME_ARCHIVE4_REVISION='gog2.1.0.42'
GAME_ARCHIVE4_FULLSIZE='490000'
GAME_ARCHIVE4_NAME='Clash of the Dragons'

GAME_ARCHIVE5='setup_heroes_chronicles_chapter5_2.1.0.42.exe'
GAME_ARCHIVE5_MD5='57b3ec588e627a2da30d3bc80ede5b1d'
GAME_ARCHIVE5_REVISION='gog2.1.0.42'
GAME_ARCHIVE5_FULLSIZE='470000'
GAME_ARCHIVE5_NAME='The World Tree'

GAME_ARCHIVE6='setup_heroes_chronicles_chapter6_2.1.0.42.exe'
GAME_ARCHIVE6_MD5='64becfde1882eecd93fb02bf215eff11'
GAME_ARCHIVE6_REVISION='gog2.1.0.42'
GAME_ARCHIVE6_FULLSIZE='470000'
GAME_ARCHIVE6_NAME='The Fiery Moon'

GAME_ARCHIVE7='setup_heroes_chronicles_chapter7_2.1.0.42.exe'
GAME_ARCHIVE7_MD5='07c189a731886b2d3891ac1c65581d40'
GAME_ARCHIVE7_REVISION='gog2.1.0.42'
GAME_ARCHIVE7_FULLSIZE='500000'
GAME_ARCHIVE7_NAME='Revolt of the Beastmasters'

GAME_ARCHIVE8='setup_heroes_chronicles_chapter8_2.1.0.42.exe'
GAME_ARCHIVE8_MD5='2b3e4c366db0f7e3e8b15b0935aad528'
GAME_ARCHIVE8_REVISION='gog2.1.0.42'
GAME_ARCHIVE8_FULLSIZE='480000'
GAME_ARCHIVE8_NAME='The Sword of Frost'

ARCHIVE_TYPE='inno'

INSTALLER_PATH='app'
INSTALLER_JUNK='*/goggame-*.dll */games */map'
INSTALLER_DOC='*/readme.txt ../tmp/*eula.txt'
INSTALLER_GAME_PKG1='./*/'
INSTALLER_GAME_PKG2='./data ./mp3'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES=''
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='*/games */map'
GAME_DATA_FILES='*/data/*.lod'
GAME_DATA_FILES_POST=''

APP1_EXE='*/*.exe'
APP1_ICON='*/*.exe'
APP1_ICON_RES='16x16 32x32 48x48 64x64'
APP1_CAT='Game'

PKG_VERSION='1.0'

PKG1_VERSION="${PKG_VERSION}"
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com Windows installer
 ./play.it script version ${script_version}"

PKG2_ID="${GAME_ID}-common"
PKG2_VERSION="${PKG_VERSION}"
PKG2_ARCH='all'
PKG2_CONFLICTS=''
PKG2_DEPS=''
PKG2_RECS=''
PKG2_DESC="${GAME_NAME_SHORT} - common files
 package built from GOG.com Windows installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG2_ID}, ${PKG1_DEPS}"

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

printf '\n'
set_target '8' 'gog.com'
PATH_GAME_COMMON="${PKG_PREFIX}/share/games/${GAME_ID}"
case "$(basename ${GAME_ARCHIVE})" in
	"${GAME_ARCHIVE1}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE1_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE1_FULLSIZE}"
		GAME_NAME="${GAME_NAME_SHORT} 1 - ${GAME_ARCHIVE1_NAME}"
		PKG_REVISION="${GAME_ARCHIVE1_REVISION}"
		GAME_ID="${GAME_ID}-1"
		GAME_ID_SHORT="${GAME_ID_SHORT}1"
	;;
	"${GAME_ARCHIVE2}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE2_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE2_FULLSIZE}"
		GAME_NAME="${GAME_NAME_SHORT} 2 - ${GAME_ARCHIVE2_NAME}"
		PKG_REVISION="${GAME_ARCHIVE2_REVISION}"
		GAME_ID="${GAME_ID}-2"
		GAME_ID_SHORT="${GAME_ID_SHORT}2"
	;;
	"${GAME_ARCHIVE3}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE3_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE3_FULLSIZE}"
		GAME_NAME="${GAME_NAME_SHORT} 3 - ${GAME_ARCHIVE3_NAME}"
		PKG_REVISION="${GAME_ARCHIVE3_REVISION}"
		GAME_ID="${GAME_ID}-3"
		GAME_ID_SHORT="${GAME_ID_SHORT}3"
	;;
	"${GAME_ARCHIVE4}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE4_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE4_FULLSIZE}"
		GAME_NAME="${GAME_NAME_SHORT} 4 - ${GAME_ARCHIVE4_NAME}"
		PKG_REVISION="${GAME_ARCHIVE4_REVISION}"
		GAME_ID="${GAME_ID}-4"
		GAME_ID_SHORT="${GAME_ID_SHORT}4"
	;;
	"${GAME_ARCHIVE5}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE5_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE5_FULLSIZE}"
		GAME_NAME="${GAME_NAME_SHORT} 5 - ${GAME_ARCHIVE5_NAME}"
		PKG_REVISION="${GAME_ARCHIVE5_REVISION}"
		GAME_ID="${GAME_ID}-5"
		GAME_ID_SHORT="${GAME_ID_SHORT}5"
	;;
	"${GAME_ARCHIVE6}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE6_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE6_FULLSIZE}"
		GAME_NAME="${GAME_NAME_SHORT} 6 - ${GAME_ARCHIVE6_NAME}"
		PKG_REVISION="${GAME_ARCHIVE6_REVISION}"
		GAME_ID="${GAME_ID}-6"
		GAME_ID_SHORT="${GAME_ID_SHORT}6"
	;;
	"${GAME_ARCHIVE7}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE7_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE7_FULLSIZE}"
		GAME_NAME="${GAME_NAME_SHORT} 7 - ${GAME_ARCHIVE7_NAME}"
		PKG_REVISION="${GAME_ARCHIVE7_REVISION}"
		GAME_ID="${GAME_ID}-7"
		GAME_ID_SHORT="${GAME_ID_SHORT}7"
	;;
	"${GAME_ARCHIVE8}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE8_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE8_FULLSIZE}"
		GAME_NAME="${GAME_NAME_SHORT} 8 - ${GAME_ARCHIVE8_NAME}"
		PKG_REVISION="${GAME_ARCHIVE8_REVISION}"
		GAME_ID="${GAME_ID}-8"
		GAME_ID_SHORT="${GAME_ID_SHORT}8"
	;;
esac
APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"
APP1_ID="${GAME_ID}"
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${APP1_NAME}"
PKG1_ID="${GAME_ID}"
PKG1_DESC="${GAME_NAME}
 package built from GOG.com Windows installer
 ./play.it script version ${script_version}"
printf '\n'

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DESK_DIR='/usr/local/share/desktop-directories'
PATH_DESK_MERGED='/etc/xdg/menus/applications-merged'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG2_VERSION}-${PKG_REVISION}_${PKG2_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE_MD5}"
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_DESK_DIR}" "${PATH_DESK_MERGED}" "${PATH_GAME}"
rm -Rf "${PKG2_DIR}"
mkdir -p "${PKG2_DIR}/DEBIAN" "${PKG2_DIR}${PATH_GAME_COMMON}"
print wait

extract_data "${ARCHIVE_TYPE}" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"
for file in ${INSTALLER_JUNK}; do
	rm -rf "${file}"
done

for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME_PKG2}; do
	mv "${file}" "${PKG2_DIR}${PATH_GAME_COMMON}"
done

for file in ${INSTALLER_GAME_PKG1}; do
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
sed 's|cp -surf "${GAME_PATH}"/\* "${WINE_GAME_PATH}"|cp -surf "${GAME_COMMON_PATH}"/\* "${WINE_GAME_PATH}"|' -i "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
sed "s|GAME_PATH=.\+|&\nGAME_COMMON_PATH=${PATH_GAME_COMMON}|" -i "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
sed "s|GAME_PATH=.\+|&\nGAME_COMMON_PATH=${PATH_GAME_COMMON}|" -i "${PKG1_DIR}${PATH_BIN}/${APP1_ID}"

write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'wine'
printf '\n'

# Build package

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG1_DESC}" "${PKG2_DIR}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
