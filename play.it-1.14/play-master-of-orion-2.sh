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
# conversion script for the master of Orion 2 installer sold on GOG.com
# build a .deb package from the .sh MojoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20160911.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='master-of-orion-2'
GAME_ID_SHORT='moo2'
GAME_NAME='Master of Orion II: Battle at Antares'

GAME_ARCHIVE1='gog_master_of_orion_2_2.0.0.6.sh'
GAME_ARCHIVE1_MD5='51529fd6734bc12f1ac36fea5fc547f8'
GAME_ARCHIVE1_FULLSIZE='350000'
GAME_ARCHIVE2='gog_master_of_orion_2_french_2.0.0.6.sh'
GAME_ARCHIVE2_MD5='06d643ee04387914738707d435e8f7a6'
GAME_ARCHIVE2_FULLSIZE='370000'
PKG_REVISION='gog2.0.0.6'

INSTALLER_PATH='data/noarch/data'
INSTALLER_JUNK='../docs/dosbox-0.74.tar.gz'
INSTALLER_DOC='../docs/* ./readme.txt'
INSTALLER_GAME_PKG1='./*.exe ./anwinfin.lbx ./cmbtshp.lbx ./connect.bat ./council.lbx ./diplomat.lbx ./diplomsf.lbx ./diplomsg.lbx ./diplomsi.lbx ./diplomss.lbx ./estrfren.lbx ./estrgerm.lbx ./estrital.lbx ./estrpoli.lbx ./estrspan.lbx ./eventmsf.lbx ./eventmsg.lbx ./eventmsi.lbx ./eventmss.lbx ./filedata.lbx ./fontsf.lbx ./fontsg.lbx ./fontsi.lbx ./fontss.lbx ./frecrdts.lbx ./fre_help.lbx ./fresklls.lbx ./fretecd.lbx ./gercrdts.lbx ./ger_help.lbx ./gersklls.lbx ./gertecd.lbx ./help.lbx ./herodatf.lbx ./herodatg.lbx ./herodati.lbx ./herodats.lbx ./hestrngs.lbx ./hfstrngs.lbx ./hgstrngs.lbx ./histrngs.lbx ./hsstrngs.lbx ./ifonts.lbx ./install.lbx ./itacrdts.lbx ./ita_help.lbx ./itasklls.lbx ./itatecd.lbx ./language.ini ./loserfin.lbx ./mainfren.lbx ./maingerm.lbx ./mainital.lbx ./mainspan.lbx ./mox.set ./rkernel.com ./rstring1.lbx ./rstring2.lbx ./rstring3.lbx ./rstring4.lbx ./rstrings.lbx ./simtex.lbx ./smackw32.dll ./spacrdts.lbx ./spa_help.lbx ./spasklls.lbx ./spatecd.lbx ./streamhd.lbx ./tanm_114.lbx ./warning.lbx'
INSTALLER_GAME_PKG2='./*'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS=''
GAME_DATA_FILES='./mox.set ./sound.lbx'
GAME_DATA_FILES_POST='./mox.set ./*.GAM'

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./orion2.exe'
APP1_ICON='data/noarch/support/icon.png'
APP1_ICON_RES='256x256'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG_VERSION='1.31'
PKG_ARCH='all'

PKG1_ID="${GAME_ID}"
PKG1_VERSION="${PKG_VERSION}"
PKG1_ARCH="${PKG_ARCH}"
PKG1_CONFLICTS=''
PKG1_DEPS='dosbox'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG2_ID="${GAME_ID}-common"
PKG2_VERSION="${PKG_VERSION}"
PKG2_ARCH="${PKG_ARCH}"
PKG2_CONFLICTS=''
PKG2_DEPS=''
PKG2_RECS=''
PKG2_DESC="${GAME_NAME} - common data
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_DEPS="${PKG2_ID} (= ${PKG2_VERSION}-${PKG_REVISION}), ${PKG1_DEPS}"

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
check_deps_soft ${SCRIPT_DEPS_SOFT}

printf '\n'
set_target '2' 'gog.com'
case "$(basename ${GAME_ARCHIVE})" in
	"${GAME_ARCHIVE1}")
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE1_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE1_FULLSIZE}"
		PKG1_NAME="${PKG1_ID}_english_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}"
	;;
	"${GAME_ARCHIVE2}") 
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE2_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE2_FULLSIZE}"
		PKG1_NAME="${PKG1_ID}_french_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}"
	;;
esac
printf '\n'

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_NAME}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE_MD5}"
fi

# Extract game data

PATH_ICON="${PATH_ICON_BASE}/${APP1_ICON_RES}/apps"

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_GAME}"
rm -rf "${PKG2_DIR}"
mkdir -p "${PKG2_DIR}/DEBIAN" "${PKG2_DIR}${PATH_GAME}" "${PKG2_DIR}${PATH_ICON}"
print wait

extract_data 'mojo' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet,fix_rights,tolower'

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"
for file in ${INSTALLER_JUNK}; do
	rm -rf "${file}"
done

for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME_PKG1}; do
	[ -e "${file}" ] && mv "${file}" "${PKG1_DIR}${PATH_GAME}"
done

for file in ${INSTALLER_GAME_PKG2}; do
	mv "${file}" "${PKG2_DIR}${PATH_GAME}"
done
cd - > /dev/null

mv "${PKG_TMPDIR}/${APP1_ICON}" "${PKG2_DIR}${PATH_ICON}/${APP1_ID}.png"

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_dosbox_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_dosbox "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'dosbox'
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
