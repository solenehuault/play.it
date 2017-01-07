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
# conversion script for the Sunless Sea installers sold on HumbleBundle.com & GOG.com
# build .deb packages from the MojoSetup installers
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161213.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='sunless-sea'
GAME_ID_SHORT='sunless'
GAME_NAME='Sunless Sea'

GAME_ARCHIVE1='gog_sunless_sea_2.7.0.10.sh'
GAME_ARCHIVE1_MD5='b1a7ae780bf3202895ba6fdcdaaf69b2'
GAME_ARCHIVE1_VERSION='2.2.2.3125'
GAME_ARCHIVE1_REVISION='gog2.7.0.10'
GAME_ARCHIVE1_FULLSIZE='700000'
GAME_ARCHIVE1_TYPE='mojo'

GAME_ARCHIVE2='Sunless_Sea_Setup_V2.2.2.3125_LINUX.zip'
GAME_ARCHIVE2_MD5='14466839a2232b72700421262d398ba6'
GAME_ARCHIVE2_VERSION='2.2.2.3125'
GAME_ARCHIVE2_REVISION='humble161006'
GAME_ARCHIVE2_FULLSIZE='690000'
GAME_ARCHIVE2_TYPE='zip'

GAME_ARCHIVE1_INSTALLER_PATH='data/noarch/game'
GAME_ARCHIVE1_INSTALLER_DOC='../docs/* ./README.linux'
GAME_ARCHIVE1_INSTALLER_GAME_PKG1='./*.x86 ./*_Data/Plugins/x86 ./*_Data/Mono/x86'
GAME_ARCHIVE1_INSTALLER_GAME_PKG2='./*.x86_64 ./*_Data/Plugins/x86_64 ./*_Data/Mono/x86_64'
GAME_ARCHIVE1_INSTALLER_GAME_PKG3='./*'

GAME_ARCHIVE2_INSTALLER_PATH='data'
GAME_ARCHIVE2_INSTALLER_DOC='noarch/README.linux'
GAME_ARCHIVE2_INSTALLER_GAME_PKG1='x86/* noarch/*_Data/Plugins/x86 noarch/*_Data/Mono/x86'
GAME_ARCHIVE2_INSTALLER_GAME_PKG2='x86_64/* noarch/*_Data/Plugins/x86_64 noarch/*_Data/Mono/x86_64'
GAME_ARCHIVE2_INSTALLER_GAME_PKG3='noarch/*'

APP1_ID="${GAME_ID}"
APP1_EXE_PKG1='./Sunless Sea.x86'
APP1_EXE_PKG2='./Sunless Sea.x86_64'
APP1_ICON1='Sunless Sea_Data/Resources/UnityPlayer.png'
APP1_ICON1_RES='128x128'
APP1_ICON2='./Icon.png'
APP1_ICON2_RES='256x256'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG_ID="${GAME_ID}"
PKG_DEPS='libc6, libglu1-mesa | libglu1, libxcursor1'
GAME_ARCHIVE1_PKG_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"
GAME_ARCHIVE2_PKG_DESC="${GAME_NAME}
 package built from HumbleBundle.com installer
 ./play.it script version ${script_version}"

PKG1_ID="${PKG_ID}"
PKG1_ARCH='i386'
PKG1_DEPS="${PKG_DEPS}"
PKG1_RECS=''

PKG2_ID="${PKG_ID}"
PKG2_ARCH='amd64'
PKG2_DEPS="${PKG_DEPS}"
PKG2_RECS=''

PKG3_ID="${GAME_ID}-common"
PKG3_ARCH='all'
PKG3_CONFLICTS=''
PKG3_DEPS=''
PKG3_RECS=''
GAME_ARCHIVE1_PKG3_DESC="${GAME_NAME} - arch-independant data
 package built from GOG.com installer
 ./play.it script version ${script_version}"
GAME_ARCHIVE2_PKG3_DESC="${GAME_NAME} - arch-independant data
 package built from HumbleBundle.com installer
 ./play.it script version ${script_version}"

PKG1_CONFLICTS="${PKG2_ID}:${PKG2_ARCH}"
PKG2_CONFLICTS="${PKG1_ID}:${PKG1_ARCH}"

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
set_target '2' 'gog.com & humblebundle.com'
case "${GAME_ARCHIVE##*/}" in
	"${GAME_ARCHIVE1}")
		ARCHIVE_TYPE="$GAME_ARCHIVE1_TYPE"
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE1_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE1_FULLSIZE}"
		PKG_VERSION="${GAME_ARCHIVE1_VERSION}"
		PKG_REVISION="${GAME_ARCHIVE1_REVISION}"
		PKG_DESC="${GAME_ARCHIVE1_PKG_DESC}"
		PKG3_DESC="${GAME_ARCHIVE1_PKG3_DESC}"
		INSTALLER_PATH="${GAME_ARCHIVE1_INSTALLER_PATH}"
		INSTALLER_DOC="${GAME_ARCHIVE1_INSTALLER_DOC}"
		INSTALLER_GAME_PKG1="${GAME_ARCHIVE1_INSTALLER_GAME_PKG1}"
		INSTALLER_GAME_PKG2="${GAME_ARCHIVE1_INSTALLER_GAME_PKG2}"
		INSTALLER_GAME_PKG3="${GAME_ARCHIVE1_INSTALLER_GAME_PKG3}"
	;;
	"${GAME_ARCHIVE2}")
		ARCHIVE_TYPE="$GAME_ARCHIVE2_TYPE"
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE2_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE2_FULLSIZE}"
		PKG_VERSION="${GAME_ARCHIVE2_VERSION}"
		PKG_REVISION="${GAME_ARCHIVE2_REVISION}"
		PKG_DESC="${GAME_ARCHIVE2_PKG_DESC}"
		PKG3_DESC="${GAME_ARCHIVE2_PKG3_DESC}"
		INSTALLER_PATH="${GAME_ARCHIVE2_INSTALLER_PATH}"
		INSTALLER_DOC="${GAME_ARCHIVE2_INSTALLER_DOC}"
		INSTALLER_GAME_PKG1="${GAME_ARCHIVE2_INSTALLER_GAME_PKG1}"
		INSTALLER_GAME_PKG2="${GAME_ARCHIVE2_INSTALLER_GAME_PKG2}"
		INSTALLER_GAME_PKG3="${GAME_ARCHIVE2_INSTALLER_GAME_PKG3}"
	;;
esac
PKG1_VERSION="${PKG_VERSION}"
PKG2_VERSION="${PKG_VERSION}"
PKG3_VERSION="${PKG_VERSION}"
PKG1_DESC="${PKG_DESC}"
PKG2_DESC="${PKG_DESC}"
PKG1_DEPS="${PKG3_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG1_DEPS}"
PKG2_DEPS="${PKG3_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG2_DEPS}"
printf '\n'

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG2_VERSION}-${PKG_REVISION}_${PKG2_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG3_DIR' "${PKG3_ID}_${PKG3_VERSION}-${PKG_REVISION}_${PKG3_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE_MD5}"
fi

# Extract game data

build_pkg_dirs '2' "${PATH_BIN}" "${PATH_DESK}" "${PATH_GAME}"
rm -rf "${PKG3_DIR}"
mkdir -p "${PKG3_DIR}/DEBIAN" "${PKG3_DIR}${PATH_DOC}" "${PKG3_DIR}${PATH_GAME}"
print wait

extract_data "${ARCHIVE_TYPE}" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'fix_rights,quiet'
if [ "${GAME_ARCHIVE##*/}" = "$GAME_ARCHIVE2" ]; then
	extract_data 'mojo' "${PKG_TMPDIR}"/*.sh "${PKG_TMPDIR}" 'fix_rights,quiet'
fi

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"
for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG3_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME_PKG1}; do
	target_file="./${file#*/}"
	mkdir -p "${PKG1_DIR}${PATH_GAME}/${target_file%/*}"
	mv "${file}" "${PKG1_DIR}${PATH_GAME}/${target_file}"
done

for file in ${INSTALLER_GAME_PKG2}; do
	target_file="./${file#*/}"
	mkdir -p "${PKG2_DIR}${PATH_GAME}/${target_file%/*}"
	mv "${file}" "${PKG2_DIR}${PATH_GAME}/${target_file}"
done

rm --recursive --force noarch/*_Data/Mono ./*_Data/Mono
rm --recursive --force noarch/*_Data/Plugins ./*_Data/Plugins

for file in ${INSTALLER_GAME_PKG3}; do
	mv "${file}" "${PKG3_DIR}${PATH_GAME}"
done
cd - > /dev/null

chmod 755 "${PKG1_DIR}${PATH_GAME}/${APP1_EXE_PKG1}"
chmod 755 "${PKG2_DIR}${PATH_GAME}/${APP1_EXE_PKG2}"

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_PKG1}" '' '' '' "${APP1_NAME} (${PKG1_ARCH})"
write_bin_native "${PKG2_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_PKG2}" '' '' '' "${APP1_NAME} (${PKG2_ARCH})"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}"
cp -l "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${PKG2_DIR}${PATH_DESK}/${APP1_ID}.desktop"
printf '\n'

# Build packages

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}" 'arch'
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}" 'arch'
write_pkg_debian "${PKG3_DIR}" "${PKG3_ID}" "${PKG3_VERSION}-${PKG_REVISION}" "${PKG3_ARCH}" "${PKG3_CONFLICTS}" "${PKG3_DEPS}" "${PKG3_RECS}" "${PKG3_DESC}"

file="${PKG3_DIR}/DEBIAN/postinst"
cat > "${file}" << EOF
#!/bin/sh -e
mkdir --parents "${PATH_ICON_BASE}/${APP1_ICON1_RES}/apps"
mkdir --parents "${PATH_ICON_BASE}/${APP1_ICON2_RES}/apps"
ln --symbolic "${PATH_GAME}/${APP1_ICON1}" "${PATH_ICON_BASE}/${APP1_ICON1_RES}/apps/${GAME_ID}.png"
ln --symbolic "${PATH_GAME}/${APP1_ICON2}" "${PATH_ICON_BASE}/${APP1_ICON2_RES}/apps/${GAME_ID}.png"
exit 0
EOF
chmod 755 "${file}"

file="${PKG3_DIR}/DEBIAN/prerm"
cat > "${file}" << EOF
#!/bin/sh -e
rm "${PATH_ICON_BASE}/${APP1_ICON1_RES}/apps/${GAME_ID}.png"
rm "${PATH_ICON_BASE}/${APP1_ICON2_RES}/apps/${GAME_ID}.png"
rmdir --parents --ignore-fail-on-non-empty "${PATH_ICON_BASE}/${APP1_ICON1_RES}/apps"
rmdir --parents --ignore-fail-on-non-empty "${PATH_ICON_BASE}/${APP1_ICON2_RES}/apps"
exit 0
EOF
chmod 755 "${file}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet' "${PKG1_ARCH}"
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet' "${PKG2_ARCH}"
build_pkg "${PKG3_DIR}" "${PKG3_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "$(printf '%s' "${PKG1_DESC}" | head -n1) (${PKG1_ARCH})" "${PKG3_DIR}" "${PKG1_DIR}"
printf '\n'
print_instructions "$(printf '%s' "${PKG2_DESC}" | head -n1) (${PKG2_ARCH})" "${PKG3_DIR}" "${PKG2_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
