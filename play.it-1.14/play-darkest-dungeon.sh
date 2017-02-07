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
# Darkest Dungeon
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170107.2

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='darkest-dungeon'
GAME_NAME='Darkest Dungeon'

ARCHIVE_GOG='gog_darkest_dungeon_2.7.0.7.sh'
ARCHIVE_GOG_MD5='22deb2c91a659725f1dbc5d8021ee1e8'
ARCHIVE_GOG_TYPE='mojo'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='2000000'
ARCHIVE_GOG_VERSION='16707-gog2.7.0.7'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'
ARCHIVE_GAME_BIN32_PATH='data/noarch/game'
ARCHIVE_GAME_BIN32_FILES='./lib ./darkest.bin.x86'
ARCHIVE_GAME_BIN64_PATH='data/noarch/game'
ARCHIVE_GAME_BIN64_FILES='./lib64 ./darkest.bin.x86_64'
ARCHIVE_GAME_AUDIO_PATH='data/noarch/game'
ARCHIVE_GAME_AUDIO_FILES='./audio'
ARCHIVE_GAME_VIDEO_PATH='data/noarch/game'
ARCHIVE_GAME_VIDEO_FILES='./video'
ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./*'

APP_COMMON_ID="${GAME_ID}_common"

APP_MAIN_EXE_32='./darkest.bin.x86'
APP_MAIN_EXE_64='./darkest.bin.x86_64'
APP_MAIN_ICON1='Icon.bmp'
APP_MAIN_ICON1_RES='128x128'
APP_MAIN_ICON2='data/noarch/support/icon.png'
APP_MAIN_ICON2_RES='256x256'

PKG_AUDIO_ID="${GAME_ID}-audio"
PKG_AUDIO_ARCH='all'
PKG_AUDIO_DESC="$GAME_NAME - audio
 package built from GOG.com installer
 ./play.it script version $script_version"

PKG_VIDEO_ID="${GAME_ID}-video"
PKG_VIDEO_ARCH='all'
PKG_VIDEO_DESC="$GAME_NAME - video
 package built from GOG.com installer
 ./play.it script version $script_version"

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_ARCH='all'
PKG_DATA_DESC="$GAME_NAME - data
 package built from GOG.com installer
 ./play.it script version $script_version"

PKG_BIN32_ARCH='i386'
PKG_BIN32_CONFLICTS="$GAME_ID"
PKG_BIN32_DEPS="$PKG_AUDIO_ID, $PKG_VIDEO_ID, $PKG_DATA_ID, libc6, libstdc++6, libsdl2-2.0-0"
PKG_BIN32_DESC="$GAME_NAME
 package built from GOG.com installer
 ./play.it script version $script_version"

PKG_BIN64_ARCH='amd64'
PKG_BIN64_CONFLICTS="$GAME_ID"
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

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard $SCRIPT_DEPS_HARD

printf '\n'
GAME_ARCHIVE1="$ARCHIVE_GOG"
set_target '1' 'gog.com'
ARCHIVE_TYPE="$ARCHIVE_GOG_TYPE"
PKG_VERSION="$ARCHIVE_GOG_VERSION"
printf '\n'

PATH_BIN="$PKG_PREFIX/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/$GAME_ID"
PATH_GAME="$PKG_PREFIX/share/games/$GAME_ID"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

game_mkdir 'PKG_TMPDIR'    "$(mktemp -u $GAME_ID.XXXXX)"                      "$(( $ARCHIVE_GOG_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_AUDIO_DIR' "${PKG_AUDIO_ID}_${PKG_VERSION}_${PKG_AUDIO_ARCH}" "$(( $ARCHIVE_GOG_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_VIDEO_DIR' "${PKG_VIDEO_ID}_${PKG_VERSION}_${PKG_VIDEO_ARCH}" "$(( $ARCHIVE_GOG_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_DATA_DIR'  "${PKG_DATA_ID}_${PKG_VERSION}_${PKG_DATA_ARCH}"   "$(( $ARCHIVE_GOG_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_BIN32_DIR' "${GAME_ID}_${PKG_VERSION}_${PKG_BIN32_ARCH}"      "$(( $ARCHIVE_GOG_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_BIN64_DIR' "${GAME_ID}_${PKG_VERSION}_${PKG_BIN64_ARCH}"      "$(( $ARCHIVE_GOG_UNCOMPRESSED_SIZE * 2 ))"

# Check target files integrity

if [ "$GAME_ARCHIVE_CHECKSUM" = 'md5sum' ]; then
	checksum "$GAME_ARCHIVE" 'defaults' "$ARCHIVE_GOG_MD5"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"
print wait
mkdir -p "${PKG_AUDIO_DIR}/DEBIAN"
mkdir -p "${PKG_VIDEO_DIR}/DEBIAN"
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
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_AUDIO_PATH"
	for file in $ARCHIVE_GAME_AUDIO_FILES; do
		mkdir -p   "${PKG_AUDIO_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_AUDIO_DIR}${PATH_GAME}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_VIDEO_PATH"
	for file in $ARCHIVE_GAME_VIDEO_FILES; do
		mkdir -p   "${PKG_VIDEO_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_VIDEO_DIR}${PATH_GAME}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_DATA_PATH"
	rm --force --recursive 'localization/ps4' 'localization/psv'
	rm --force --recursive 'shaders_ps4' 'shaders_psv'
	rm --force --recursive 'video_ps4' 'video_psv'
	for file in $ARCHIVE_GAME_DATA_FILES; do
		mkdir -p   "${PKG_DATA_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_DATA_DIR}${PATH_GAME}/$file"
	done
)

if [ "${NO_ICON}" = '0' ]; then
	PKG1_DIR="$PKG_DATA_DIR"
	extract_icons "$GAME_ID" "$APP_MAIN_ICON1" "$APP_MAIN_ICON1_RES" "$PKG_TMPDIR"
	PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON1_RES/apps"
	mkdir -p "${PKG_DATA_DIR}${PATH_ICON}"
	mv "$PKG_TMPDIR/$GAME_ID.png" "${PKG_DATA_DIR}${PATH_ICON}"
fi

PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON2_RES/apps"
mkdir -p "${PKG_DATA_DIR}${PATH_ICON}"
mv "$PKG_TMPDIR/$APP_MAIN_ICON2" "${PKG_DATA_DIR}${PATH_ICON}/$GAME_ID.png"

chmod 755 "${PKG_BIN32_DIR}${PATH_GAME}/$APP_MAIN_EXE_32"
chmod 755 "${PKG_BIN64_DIR}${PATH_GAME}/$APP_MAIN_EXE_64"

rm -rf "$PKG_TMPDIR"
print done

# Write launchers

write_bin_native_prefix_common "${PKG_BIN32_DIR}${PATH_BIN}/$APP_COMMON_ID"
cp -l "${PKG_BIN32_DIR}${PATH_BIN}/$APP_COMMON_ID" "${PKG_BIN64_DIR}${PATH_BIN}"

write_bin_native_prefix "${PKG_BIN32_DIR}${PATH_BIN}/$GAME_ID" "$APP_MAIN_EXE_32" '' '' '' "$GAME_NAME ($PKG_BIN32_ARCH)"
write_bin_native_prefix "${PKG_BIN64_DIR}${PATH_BIN}/$GAME_ID" "$APP_MAIN_EXE_64" '' '' '' "$GAME_NAME ($PKG_BIN64_ARCH)"

write_desktop "$GAME_ID" "$GAME_NAME" "$GAME_NAME" "${PKG_BIN32_DIR}${PATH_DESK}/$GAME_ID.desktop" "$APP_MAIN_CAT"
cp -l "${PKG_BIN32_DIR}${PATH_DESK}/$GAME_ID.desktop" "${PKG_BIN64_DIR}${PATH_DESK}"

printf '\n'

# Build packages

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "$PKG_AUDIO_DIR" "$PKG_AUDIO_ID" "$PKG_VERSION" "$PKG_AUDIO_ARCH" ''                     ''                '' "$PKG_AUDIO_DESC"
write_pkg_debian "$PKG_VIDEO_DIR" "$PKG_VIDEO_ID" "$PKG_VERSION" "$PKG_VIDEO_ARCH" ''                     ''                '' "$PKG_VIDEO_DESC"
write_pkg_debian "$PKG_DATA_DIR"  "$PKG_DATA_ID"  "$PKG_VERSION" "$PKG_DATA_ARCH"  ''                     ''                '' "$PKG_DATA_DESC"
write_pkg_debian "$PKG_BIN32_DIR" "$GAME_ID"      "$PKG_VERSION" "$PKG_BIN32_ARCH" "$PKG_BIN32_CONFLICTS" "$PKG_BIN32_DEPS" '' "$PKG_BIN32_DESC" 'arch'
write_pkg_debian "$PKG_BIN64_DIR" "$GAME_ID"      "$PKG_VERSION" "$PKG_BIN64_ARCH" "$PKG_BIN64_CONFLICTS" "$PKG_BIN64_DEPS" '' "$PKG_BIN64_DESC" 'arch'

build_pkg "$PKG_AUDIO_DIR" "$PKG_AUDIO_DESC" "$PKG_COMPRESSION" 'quiet'
build_pkg "$PKG_VIDEO_DIR" "$PKG_VIDEO_DESC" "$PKG_COMPRESSION" 'quiet'
build_pkg "$PKG_DATA_DIR"  "$PKG_DATA_DESC"  "$PKG_COMPRESSION" 'quiet'
build_pkg "$PKG_BIN32_DIR" "$PKG_BIN32_DESC" "$PKG_COMPRESSION" 'quiet' "$PKG_BIN32_ARCH"
build_pkg "$PKG_BIN64_DIR" "$PKG_BIN64_DESC" "$PKG_COMPRESSION" 'quiet' "$PKG_BIN64_ARCH"
print done

print_instructions "$(printf '%s' "$PKG_BIN32_DESC" | head -n1) ($PKG_BIN32_ARCH)" "$PKG_AUDIO_DIR" "$PKG_VIDEO_DIR" "$PKG_DATA_DIR" "$PKG_BIN32_DIR"
printf '\n'
print_instructions "$(printf '%s' "$PKG_BIN64_DESC" | head -n1) ($PKG_BIN64_ARCH)" "$PKG_AUDIO_DIR" "$PKG_VIDEO_DIR" "$PKG_DATA_DIR" "$PKG_BIN64_DIR"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
