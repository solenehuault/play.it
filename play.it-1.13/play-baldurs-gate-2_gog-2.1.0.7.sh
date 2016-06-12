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
# conversion script for the Baldur’s Gate 2 installer sold on GOG.com
# build a .deb package from the .sh MojoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20160612.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='baldurs-gate-2'
GAME_ID_SHORT='bg2'
GAME_NAME='Baldur’s Gate II'

GAME_ARCHIVE1='gog_baldur_s_gate_2_complete_2.1.0.7.sh'
GAME_ARCHIVE1_MD5='e92161d7fc0a2eea234b2c93760c9cdb'
GAME_ARCHIVE2='gog_baldur_s_gate_2_complete_french_2.1.0.7.sh'
GAME_ARCHIVE2_MD5='6551bda3d8c7330b7ad66842ac1d4ed4'
GAME_ARCHIVE_FULLSIZE='3200000'
PKG_REVISION='gog2.1.0.7'

INSTALLER_DOC_PATH='data/noarch/docs'
INSTALLER_DOC='*'
INSTALLER_GAME_PATH='data/noarch/prefix/drive_c/gog?games/*'
INSTALLER_GAME_JUNK='mpsave temp'
INSTALLER_GAME_PKG1='./autorun.ini ./baldur.ini ./bgconfig.exe ./language.txt ./*.tlk ./characters ./override ./sounds ./chitin.key data/25npcso.bif data/areas.bif data/chasound.bif data/cresound.bif data/desound.bif data/missound.bif data/npchd0so.bif data/npcsocd2.bif data/npcsocd3.bif data/npcsocd4.bif data/npcsound.bif data/objanim.bif data/scripts.bif data/movies/25movies.bif data/movies/movend.bif data/movies/movintro.bif'
INSTALLER_GAME_PKG2='*'

GAME_CACHE_DIRS='./cache ./temp'
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./characters ./mpsave ./override ./portraits ./save ./scripts'
GAME_DATA_FILES='./baldur.err ./baldur.log ./chitin.key'
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./bgmain.exe'
APP1_ICON='./baldur.exe'
APP1_ICON_RES='32x32 48x48'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

APP2_ID="${GAME_ID}_config"
APP2_EXE='./bgconfig.exe'
APP2_ICON='./bgconfig.exe'
APP2_ICON_RES='32x32 48x48'
APP2_NAME="${GAME_NAME} - settings"
APP2_NAME_FR="${GAME_NAME} - réglages"
APP2_CAT='Settings'

PKG_VERSION='2.5.26498'

PKG1_ID="${GAME_ID}"
PKG1_VERSION="${PKG_VERSION}"
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG2_ID="${GAME_ID}-common"
PKG2_VERSION="${PKG_VERSION}"
PKG2_ARCH='all'
PKG2_CONFLICTS=''
PKG2_DEPS=''
PKG2_RECS=''
PKG2_DESC="${GAME_NAME} - common data
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

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

printf '\n'
set_target '2' 'gog.com'
case "$(basename ${GAME_ARCHIVE})" in
	"${GAME_ARCHIVE1}") PKG1_DIR="${PKG1_DIR%/*}/${PKG1_ID}-en_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" ;;
	"${GAME_ARCHIVE2}") PKG1_DIR="${PKG1_DIR%/*}/${PKG1_ID}-fr_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" ;;
esac
printf '\n'

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}" "${GAME_ARCHIVE2_MD5}"
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC}" "${PATH_GAME}"
rm -Rf "${PKG2_DIR}"
mkdir -p "${PKG2_DIR}/DEBIAN" "${PKG2_DIR}${PATH_GAME}"
print wait

extract_data 'mojo' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'fix_rights,quiet,tolower'

cd "${PKG_TMPDIR}/${INSTALLER_DOC_PATH}"
for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done
cd - > /dev/null

cd "${PKG_TMPDIR}"/${INSTALLER_GAME_PATH}
mv data/data/* data/
rmdir data/data/

for file in ${INSTALLER_GAME_JUNK}; do
	rm -rf "${file}"
done

for file in ${INSTALLER_GAME_PKG1}; do
	if [ -e "${file}" ]; then
		mkdir -p "${PKG1_DIR}${PATH_GAME}/${file%/*}"
		mv "${file}" "${PKG1_DIR}${PATH_GAME}/${file}"
	fi
done

for file in ${INSTALLER_GAME_PKG2}; do
	mv "${file}" "${PKG2_DIR}${PATH_GAME}"
done
cd - > /dev/null

sed -i "s/HD0:=.\+/HD0:=C:\\\\${GAME_ID}\\\\/" "${PKG1_DIR}${PATH_GAME}/baldur.ini"
for drive in 'CD1' 'CD2' 'CD3' 'CD4' 'CD5' 'CD6'; do
	sed -i "s/${drive}:=.\+/${drive}:=C:\\\\${GAME_ID}\\\\data\\\\/" "${PKG1_DIR}${PATH_GAME}/baldur.ini"
done

if [ "${NO_ICON}" = '0' ]; then
	PKG1_DIR_REAL="${PKG1_DIR}"
	PKG1_DIR="${PKG2_DIR}"
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
	PKG1_DIR="${PKG1_DIR_REAL}"
	extract_icons "${APP2_ID}" "${APP2_ICON}" "${APP2_ICON_RES}" "${PKG_TMPDIR}"
fi

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_wine_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE}" '' '' "${APP2_NAME}"

write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'wine'
write_desktop "${APP2_ID}" "${APP2_NAME}" "${APP2_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP2_ID}.desktop" "${APP2_CAT}" 'wine'
printf '\n'

# Build package

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}"

file="${PKG1_DIR}/DEBIAN/postinst"
cat > "${file}" << EOF
#!/bin/sh -e
ln -s ../data "${PATH_GAME}/data"
exit 0
EOF
chmod 755 "${file}"

file="${PKG1_DIR}/DEBIAN/prerm"
cat > "${file}" << EOF
#!/bin/sh -e
rm "${PATH_GAME}/data/data"
exit 0
EOF
chmod 755 "${file}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet'
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "${PKG1_DESC}" "${PKG2_DIR}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
