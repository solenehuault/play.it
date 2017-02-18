#!/bin/sh -e
set -o errexit

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
# Dust: An Elysian Tale
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170218.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='dust-an-elysian-tale'
GAME_NAME='Dust: An Elysian Tale'

ARCHIVE_HUMBLE='dustaet_05042016-bin'
ARCHIVE_HUMBLE_MD5='6844c82f233b47417620be0bef8b140c'
ARCHIVE_HUMBLE_UNCOMPRESSED_SIZE='1500000'
ARCHIVE_HUMBLE_VERSION='1.04-humble160504'
ARCHIVE_HUMBLE_TYPE='mojo'

ARCHIVE_DOC_PATH='data'
ARCHIVE_DOC_FILES='./Linux.README'
ARCHIVE_GAME_BIN32_PATH='data'
ARCHIVE_GAME_BIN32_FILES='./*.x86 ./lib'
ARCHIVE_GAME_BIN64_PATH='data'
ARCHIVE_GAME_BIN64_FILES='./*.x86_64 ./lib64'
ARCHIVE_GAME_DATA_PATH='data'
ARCHIVE_GAME_DATA_FILES='./*'

APP_MAIN_ID="$GAME_ID"
APP_MAIN_EXE_BIN32='./DustAET.bin.x86'
APP_MAIN_EXE_BIN64='./DustAET.bin.x86_64'
APP_MAIN_ICON='Dust An Elysian Tail.bmp'
APP_MAIN_ICON_RES='64x64'
APP_MAIN_NAME="$GAME_NAME"
APP_MAIN_CAT='Game'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_ARCH='all'
PKG_DATA_DESC="$GAME_NAME - data
 package built from GOG.com installer
 ./play.it script version $script_version"

PKG_BIN32_ID="$GAME_ID"
PKG_BIN32_ARCH='i386'
PKG_BIN32_DEPS="$PKG_DATA_ID, libc6, libstdc++6, libogg0, libopenal1, libsdl2-2.0-0, libtheora0, libvorbisfile3, libvorbis0a"
PKG_BIN32_DESC="$GAME_NAME
 package built from GOG.com installer
 ./play.it script version $script_version"

PKG_BIN64_ID="$PKG_BIN32_ID"
PKG_BIN64_ARCH='amd64'
PKG_BIN64_DEPS="$PKG_BIN32_DEPS"
PKG_BIN64_DESC="$PKG_BIN32_DESC"

# Load common functions

TARGET_LIB_VERSION='1.14'

if [ -z "$PLAYIT_LIB" ]; then
	PLAYIT_LIB='./play-anything.sh'
fi

if ! [ -e "$PLAYIT_LIB" ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'play-anything.sh not found.\n'
	printf 'It must be placed in the same directory than this script.\n\n'
	exit 1
fi

LIB_VERSION="$(grep '^# library version' "${PLAYIT_LIB}" | cut -d' ' -f4 | cut -d'.' -f1,2)"

if [ ${LIB_VERSION%.*} -ne ${TARGET_LIB_VERSION%.*} ] || [ ${LIB_VERSION#*.} -lt ${TARGET_LIB_VERSION#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'Wrong version of play-anything.\n'
	printf 'It must be at least %s ' "$TARGET_LIB_VERSION"
	printf 'but lower than %s.\n\n' "$(( ${TARGET_LIB_VERSION%.*} + 1 )).0"
	exit 1
fi

. "$PLAYIT_LIB"

# Set extra variables

NO_ICON=0

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard $SCRIPT_DEPS_HARD

printf '\n'
GAME_ARCHIVE1="$ARCHIVE_HUMBLE"
set_target '1' 'humblebundle.com'
ARCHIVE_MD5="$ARCHIVE_HUMBLE_MD5"
ARCHIVE_TYPE="$ARCHIVE_HUMBLE_TYPE"
ARCHIVE_UNCOMPRESSED_SIZE="$ARCHIVE_HUMBLE_UNCOMPRESSED_SIZE"
PKG_VERSION="$ARCHIVE_HUMBLE_VERSION"
printf '\n'

PATH_BIN="$PKG_PREFIX/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/$GAME_ID"
PATH_GAME="$PKG_PREFIX/share/games/$GAME_ID"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

game_mkdir 'PKG_TMPDIR'    "$(mktemp -u $GAME_ID.XXXXX)"                    "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_DATA_DIR'  "${PKG_DATA_ID}_${PKG_VERSION}_${PKG_DATA_ARCH}" "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_BIN32_DIR' "${GAME_ID}_${PKG_VERSION}_${PKG_BIN32_ARCH}"    "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_BIN64_DIR' "${GAME_ID}_${PKG_VERSION}_${PKG_BIN64_ARCH}"    "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"

# Check target files integrity

if [ "$GAME_ARCHIVE_CHECKSUM" = 'md5sum' ]; then
	checksum "$GAME_ARCHIVE" 'defaults' "$ARCHIVE_MD5"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"
print wait
mkdir -p "${PKG_DATA_DIR}/DEBIAN"
mkdir -p "${PKG_BIN32_DIR}/DEBIAN" "${PKG_BIN32_DIR}${PATH_BIN}" "${PKG_BIN32_DIR}${PATH_DESK}"
mkdir -p "${PKG_BIN64_DIR}/DEBIAN" "${PKG_BIN64_DIR}${PATH_BIN}" "${PKG_BIN64_DIR}${PATH_DESK}"

extract_data "$ARCHIVE_TYPE" "$GAME_ARCHIVE" "$PKG_TMPDIR" 'fix_rights,quiet'

(
	cd "$PKG_TMPDIR/$ARCHIVE_DOC_PATH"
	for file in $ARCHIVE_DOC_FILES; do
		mkdir -p   "${PKG_DATA_DIR}${PATH_DOC}/${file%/*}"
		mv "$file" "${PKG_DATA_DIR}${PATH_DOC}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_BIN32_PATH"
	for file in $ARCHIVE_GAME_BIN32_FILES; do
		mkdir -p   "${PKG_BIN32_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_BIN32_DIR}${PATH_GAME}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_BIN64_PATH"
	for file in $ARCHIVE_GAME_BIN64_FILES; do
		mkdir -p   "${PKG_BIN64_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_BIN64_DIR}${PATH_GAME}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_DATA_PATH"
	for file in $ARCHIVE_GAME_DATA_FILES; do
		mkdir -p   "${PKG_DATA_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_DATA_DIR}${PATH_GAME}/$file"
	done
)

if [ "${NO_ICON}" = '0' ]; then
	PKG1_DIR="$PKG_DATA_DIR"
	extract_icons "$APP_MAIN_ID" "$APP_MAIN_ICON" "$APP_MAIN_ICON_RES" "$PKG_TMPDIR"
	PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
	mkdir -p "${PKG_DATA_DIR}${PATH_ICON}"
	mv "$PKG_TMPDIR/$APP_MAIN_ID.png" "${PKG_DATA_DIR}${PATH_ICON}"
fi

chmod 755 "${PKG_BIN32_DIR}${PATH_GAME}/$APP_MAIN_EXE_BIN32"
chmod 755 "${PKG_BIN64_DIR}${PATH_GAME}/$APP_MAIN_EXE_BIN64"

rm -rf "$PKG_TMPDIR"
print done

# Write launchers

write_bin_native "${PKG_BIN32_DIR}${PATH_BIN}/$GAME_ID" "$APP_MAIN_EXE_BIN32" '' '' '' "$GAME_NAME ($PKG_BIN32_ARCH)"
write_bin_native "${PKG_BIN64_DIR}${PATH_BIN}/$GAME_ID" "$APP_MAIN_EXE_BIN64" '' '' '' "$GAME_NAME ($PKG_BIN64_ARCH)"

write_desktop "$APP_MAIN_ID" "$APP_MAIN_NAME" "$APP_MAIN_NAME" "${PKG_BIN32_DIR}${PATH_DESK}/$GAME_ID.desktop" "$APP_MAIN_CAT"
cp -l "${PKG_BIN32_DIR}${PATH_DESK}/$APP_MAIN_ID.desktop" "${PKG_BIN64_DIR}${PATH_DESK}"

printf '\n'

# Build packages

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "$PKG_DATA_DIR"  "$PKG_DATA_ID"  "$PKG_VERSION" "$PKG_DATA_ARCH"  '' ''                '' "$PKG_DATA_DESC"
write_pkg_debian "$PKG_BIN32_DIR" "$PKG_BIN32_ID" "$PKG_VERSION" "$PKG_BIN32_ARCH" '' "$PKG_BIN32_DEPS" '' "$PKG_BIN32_DESC" 'arch'
write_pkg_debian "$PKG_BIN64_DIR" "$PKG_BIN64_ID" "$PKG_VERSION" "$PKG_BIN64_ARCH" '' "$PKG_BIN64_DEPS" '' "$PKG_BIN64_DESC" 'arch'

build_pkg "$PKG_DATA_DIR"  "$PKG_DATA_DESC"  "$PKG_COMPRESSION" 'quiet'
build_pkg "$PKG_BIN32_DIR" "$PKG_BIN32_DESC" "$PKG_COMPRESSION" 'quiet' "$PKG_BIN32_ARCH"
build_pkg "$PKG_BIN64_DIR" "$PKG_BIN64_DESC" "$PKG_COMPRESSION" 'quiet' "$PKG_BIN64_ARCH"
print done

print_instructions "$(printf '%s' "$PKG_BIN32_DESC" | head -n1) ($PKG_BIN32_ARCH)" "$PKG_DATA_DIR" "$PKG_BIN32_DIR"
printf '\n'
print_instructions "$(printf '%s' "$PKG_BIN64_DESC" | head -n1) ($PKG_BIN64_ARCH)" "$PKG_DATA_DIR" "$PKG_BIN64_DIR"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
