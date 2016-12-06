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
# conversion script for the Neverwinter Nights installer sold on GOG.com
# build a .deb package from the InnoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161206.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unar'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='neverwinter-nights'
GAME_ID_SHORT='nwn'
GAME_NAME='Neverwinter Nights'

GAME_ARCHIVE1='setup_nwn_diamond_2.1.0.21-1.bin'
GAME_ARCHIVE1_MD5='ce60bf104cc6082fe79d6f0bd7b48f51'
GAME_ARCHIVE1_FULLSIZE='5100000'
GAME_ARCHIVE1_VERSION='1.69.8109-gog2.1.0.21'

GAME_ARCHIVE2='setup_nwn_diamond_french_2.1.0.21-1.bin'
GAME_ARCHIVE2_MD5='aeb4b99635bdc046560477b2b11307e3'
GAME_ARCHIVE2_FULLSIZE='4300000'
GAME_ARCHIVE2_VERSION='1.68.8099-gog2.1.0.21'

GAME_ARCHIVE3='setup_nwn_diamond_polish_2.1.0.21-1.bin'
GAME_ARCHIVE3_MD5='540c20cd68079c7a214af65296b4a8b1'
GAME_ARCHIVE3_FULLSIZE='4400000'
GAME_ARCHIVE3_VERSION='1.68.8099-gog2.1.0.21'

GAME_ARCHIVE4='setup_nwn_diamond_spanish_2.1.0.21-1.bin'
GAME_ARCHIVE4_MD5='3b6dee19655a1280273c5d0652f74ab5'
GAME_ARCHIVE4_FULLSIZE='4400000'
GAME_ARCHIVE4_VERSION='1.68.8099-gog2.1.0.21'

GAME_ARCHIVE5='setup_nwn_diamond_german_2.1.0.21-1.bin'
GAME_ARCHIVE5_MD5='e6c50d030b046c05ccf87601844ccc23'
GAME_ARCHIVE5_FULLSIZE='4400000'
GAME_ARCHIVE5_VERSION='1.68.8099-gog2.1.0.21'

ARCHIVE_TYPE='unar_passwd'

CLIENT_ARCHIVE_COMMON='nwn-linux-common.tar.gz'
CLIENT_ARCHIVE_COMMON_MD5='e32cf6720463763ef9f2b28eec50d3d6'

CLIENT_ARCHIVE_169='nwn-linux-1.69.tar.gz'
CLIENT_ARCHIVE_169_MD5='b703f017446440e386ae142c1aa74a71'

CLIENT_ARCHIVE_168='nwn-linux-1.68.tar.gz'
CLIENT_ARCHIVE_168_MD5='7d46737ff2d25470f8d6b389bb53cd1a'

CLIENT_ARCHIVE_MOVIES='nwmovies-mpv.tar.gz'
CLIENT_ARCHIVE_MOVIES_URL='https://sites.google.com/site/gogdownloader/nwmovies-mpv.tar.gz'
CLIENT_ARCHIVE_MOVIES_MD5='71f3d88db1cd75665b62b77f7604dce1'

INSTALLER_DOC_PATH='game/docs'
INSTALLER_DOC_FILES='./*'
INSTALLER_GAME1_PATH='game'
INSTALLER_GAME1_FILES='./ambient ./data ./dmvault ./hak ./localvault ./modules ./movies ./music ./nwm ./override ./texturepacks ./nwn.exe ./*.key ./*.tlk ./*.TLK'
INSTALLER_GAME2_PATH='support/app'
INSTALLER_GAME2_FILES='./nwncdkey.ini'

NWMOVIES_BUILD_REQ_32='gcc libelf-dev:i386 libsdl1.2-dev'
NWMOVIES_BUILD_REQ_64="${NWMOVIES_BUILD_REQ_32} gcc-multilib"

GAME_CACHE_DIRS='/temp ./tempclient'
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./nwncdkey.ini ./nwn.ini ./nwnplayer.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./portraits ./saves ./servervault'
GAME_DATA_FILES='./nwn'
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

APP1_ID="${GAME_ID}"
APP1_EXE='./nwn'
APP1_ICON='./nwn.exe'
APP1_ICON_RES='32x32'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG1_ID="${GAME_ID}"
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='libc6, libstdc++6, libglu1-mesa | ligblu1, libsdl1.2debian'
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

# Set script-specific functions

set_nwmovies() {
if [ -z "${WITH_MOVIES}" ]; then
	WITH_NWMOVIE="${WITH_MOVIES_DEFAULT}"
fi
if [ "${WITH_MOVIES}" = '1' ]; then
	printf '%s.\n' "$(l10n 'movies_enabled')"
	if [ "$(uname -m)" = 'x86_64' ]; then
		NWMOVIES_BUILD_REQ="${NWMOVIES_BUILD_REQ_64}"
	else
		NWMOVIES_BUILD_REQ="${NWMOVIES_BUILD_REQ_32}"
	fi
	for pkg in ${NWMOVIES_BUILD_REQ}; do
	if ! dpkg -s "${pkg}" > /dev/null 2>&1; then
		print error
		printf "%s:\n%s\n" "$(l10n 'movies_build_deps')" "${NWMOVIES_BUILD_REQ}"
		exit 1
	fi
	done
else
	print warning
	printf '%s.\n' "$(l10n 'movies_disabled')"
fi
}

# Set extra variables

NO_ICON=0

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'
WITH_MOVIES_DEFAULT='0'

fetch_args "$@"

set_checksum
set_compression
set_prefix
set_nwmovies

check_deps_hard ${SCRIPT_DEPS_HARD}

printf '\n'
set_target '4' 'gog.com'
set_target_extra 'CLIENT_ARCHIVE_COMMON' '' "${CLIENT_ARCHIVE_COMMON}"
case "${GAME_ARCHIVE##*/}" in
	("${GAME_ARCHIVE1}")
		CLIENT_ARCHIVE_MD5="${CLIENT_ARCHIVE_169_MD5}"
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE1_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE1_FULLSIZE}"
		PKG_VERSION="${GAME_ARCHIVE1_VERSION}"
		set_target_extra 'CLIENT_ARCHIVE' '' "${CLIENT_ARCHIVE_169}"
	;;
	("${GAME_ARCHIVE2}")
		CLIENT_ARCHIVE_MD5="${CLIENT_ARCHIVE_168_MD5}"
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE2_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE2_FULLSIZE}"
		PKG_VERSION="${GAME_ARCHIVE2_VERSION}"
		set_target_extra 'CLIENT_ARCHIVE' '' "${CLIENT_ARCHIVE_168}"
	;;
	("${GAME_ARCHIVE3}")
		CLIENT_ARCHIVE_MD5="${CLIENT_ARCHIVE_168_MD5}"
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE3_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE3_FULLSIZE}"
		PKG_VERSION="${GAME_ARCHIVE3_VERSION}"
		set_target_extra 'CLIENT_ARCHIVE' '' "${CLIENT_ARCHIVE_168}"
	;;
	("${GAME_ARCHIVE4}")
		CLIENT_ARCHIVE_MD5="${CLIENT_ARCHIVE_168_MD5}"
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE4_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE4_FULLSIZE}"
		PKG_VERSION="${GAME_ARCHIVE4_VERSION}"
		set_target_extra 'CLIENT_ARCHIVE' '' "${CLIENT_ARCHIVE_168}"
	;;
	("${GAME_ARCHIVE5}")
		CLIENT_ARCHIVE_MD5="${CLIENT_ARCHIVE_168_MD5}"
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE5_MD5}"
		GAME_ARCHIVE_FULLSIZE="${GAME_ARCHIVE5_FULLSIZE}"
		PKG_VERSION="${GAME_ARCHIVE5_VERSION}"
		set_target_extra 'CLIENT_ARCHIVE' '' "${CLIENT_ARCHIVE_168}"
	;;
esac
if [ "$WITH_MOVIES" = '1' ]; then
	set_target_extra 'CLIENT_ARCHIVE_MOVIES' "${CLIENT_ARCHIVE_MOVIES_URL}" "${CLIENT_ARCHIVE_MOVIES}"
fi
printf '\n'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG_VERSION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE="/usr/local/share/icons/hicolor"

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	printf '%s…\n' "$(l10n 'checksum_multiple')"
	print wait
	checksum "${GAME_ARCHIVE}" 'quiet' "${GAME_ARCHIVE_MD5}"
	checksum "${CLIENT_ARCHIVE_COMMON}" 'quiet' "${CLIENT_ARCHIVE_COMMON_MD5}"
	checksum "${CLIENT_ARCHIVE}" 'quiet' "${CLIENT_ARCHIVE_MD5}"
	[ "$WITH_MOVIES" = '1' ] && checksum "${CLIENT_ARCHIVE_MOVIES}" 'quiet' "${CLIENT_ARCHIVE_MOVIES_MD5}"
	print done
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DESK}" "${PATH_DOC}" "${PATH_GAME}"
print wait

extract_data "${ARCHIVE_TYPE}" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'

cd "${PKG_TMPDIR}/${INSTALLER_DOC_PATH}"
for file in ${INSTALLER_DOC_FILES}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done
cd - > /dev/null

cd "${PKG_TMPDIR}/${INSTALLER_GAME1_PATH}"
for file in ${INSTALLER_GAME1_FILES}; do
	if [ -e "${file}" ]; then
		mv "${file}" "${PKG1_DIR}${PATH_GAME}"
	fi
done
cd - > /dev/null

cd "${PKG_TMPDIR}/${INSTALLER_GAME2_PATH}"
for file in ${INSTALLER_GAME2_FILES}; do
	mv "${file}" "${PKG1_DIR}${PATH_GAME}"
done
cd - > /dev/null

for archive in "${CLIENT_ARCHIVE_COMMON}" "${CLIENT_ARCHIVE}"; do
	extract_data 'tar' "${archive}" "${PKG1_DIR}${PATH_GAME}" 'quiet'
done

mv "${PKG1_DIR}${PATH_GAME}"/*.txt "${PKG1_DIR}${PATH_DOC}"

if [ -e "${PKG1_DIR}${PATH_GAME}/dialogF.TLK" ]; then
	mv "${PKG1_DIR}${PATH_GAME}/dialogF.TLK" "${PKG1_DIR}${PATH_GAME}/dialogf.tlk"
fi

if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
fi
rm "${PKG1_DIR}${PATH_GAME}/${APP1_ICON}"

# Building nwmovies

if [ "${WITH_MOVIES}" = '1' ]; then
	extract_data 'tar' "${CLIENT_ARCHIVE_MOVIES}" "${PKG1_DIR}${PATH_GAME}" 'quiet'
	cd "${PKG1_DIR}${PATH_GAME}"

	# Build nwmovies
	printf '%s NWMovies…\n' "$(l10n 'build_generic')"
	./nwmovies_install.pl build > /dev/null 2>&1
	sed -i 's/mpv /mpv --fs --no-osc /' ./nwmovies/nwplaymovie

	# Cleanup what is no longer required
	for file in '*.c' '*.h' '*.S' '*.pl' '*.map'; do
		rm -f ./${file} nwmovies/${file} nwmovies/libdis/${file}
	done

	# Patch the launcher
	mv ./nwn ./nwn.real
	sed 's|./nwmain $@|export LD_PRELOAD=./nwmovies.so\n./nwmain $@|' ./nwn.real > ./nwn.nwmovies
	chmod 755 ./nwn.nwmovies
	ln -s ./nwn.nwmovies ./nwn

	cd - > /dev/null
	PKG1_DEPS="${PKG1_DEPS}, mpv:amd64|mpv"
fi

rm -Rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_native_prefix_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_native_prefix "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' '' "${GAME_NAME}"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}" 'neverwinter-nights'
printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG_VERSION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}"

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
