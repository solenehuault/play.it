#!/bin/sh -e
set -o errexit

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
# Anna's Quest
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170204.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='annas-quest'
GAME_NAME='Anna’s Quest'

ARCHIVE_GOG='gog_anna_s_quest_2.1.0.3.sh'
ARCHIVE_GOG_MD5='cb4cf167a13413b6df8238397393298a'
ARCHIVE_GOG_TYPE='mojo'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='1100000'
ARCHIVE_GOG_VERSION='1.0.0202-gog2.1.0.3'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'
ARCHIVE_DOC2_PATH='data/noarch/game/documents/licenses'
ARCHIVE_DOC2_FILES='./*'
ARCHIVE_GAME_PATH='data/noarch/game'
ARCHIVE_GAME_FILES='./anna ./characters ./config.ini ./data.vis ./libs64 ./lua ./scenes ./videos'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./config.ini'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS=''
GAME_DATA_FILES=''
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID}_common"

APP_MAIN_EXE='./anna'
APP_MAIN_LIBS='libs64'
APP_MAIN_ICON='data/noarch/support/icon.png'
APP_MAIN_ICON_RES='256x256'
APP_MAIN_CAT='Game'

PKG_MAIN_ARCH='amd64'
PKG_MAIN_DEPS='libavcodec56 | libavcodec-extra-56, libavformat56, libavutil54, libswscale3, zlib1g, libc6, libgl1-mesa-glx | libgl1, libopenal1, libstdc++6, libgcc1, libx11-6, libxext6, libxcb1, libxau6, libxdmcp6'
PKG_MAIN_DESC="$GAME_NAME
 package built from GOG.com installer
 ./play.it script version $script_version"

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

game_mkdir 'PKG_TMPDIR'   "$(mktemp -u $GAME_ID.XXXXX)"                "$(( $ARCHIVE_GOG_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG_MAIN_DIR' "${GAME_ID}_${PKG_VERSION}_${PKG_MAIN_ARCH}" "$(( $ARCHIVE_GOG_UNCOMPRESSED_SIZE * 2 ))"

# Check target files integrity

if [ "$GAME_ARCHIVE_CHECKSUM" = 'md5sum' ]; then
	checksum "$GAME_ARCHIVE" 'defaults' "$ARCHIVE_GOG_MD5"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"
print wait
rm -rf "$PKG_MAIN_DIR"
for dir in '/DEBIAN' "$PATH_BIN" "$PATH_DESK"; do
	mkdir -p "${PKG_MAIN_DIR}${dir}"
done

extract_data "$ARCHIVE_TYPE" "$GAME_ARCHIVE" "$PKG_TMPDIR" 'fix_rights,quiet'

(
	cd "$PKG_TMPDIR/$ARCHIVE_DOC1_PATH"
	for file in $ARCHIVE_DOC1_FILES; do
		mkdir -p   "${PKG_MAIN_DIR}${PATH_DOC}/${file%/*}"
		mv "$file" "${PKG_MAIN_DIR}${PATH_DOC}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_DOC2_PATH"
	for file in $ARCHIVE_DOC2_FILES; do
		mkdir -p   "${PKG_MAIN_DIR}${PATH_DOC}/${file%/*}"
		mv "$file" "${PKG_MAIN_DIR}${PATH_DOC}/$file"
	done
)

(
	cd "$PKG_TMPDIR/$ARCHIVE_GAME_PATH"
	for file in $ARCHIVE_GAME_FILES; do
		mkdir -p   "${PKG_MAIN_DIR}${PATH_GAME}/${file%/*}"
		mv "$file" "${PKG_MAIN_DIR}${PATH_GAME}/$file"
	done
)

PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
mkdir -p "${PKG_MAIN_DIR}${PATH_ICON}"
mv "$PKG_TMPDIR/$APP_MAIN_ICON" "${PKG_MAIN_DIR}${PATH_ICON}/$GAME_ID.png"

chmod 755 "${PKG_MAIN_DIR}${PATH_GAME}/$APP_MAIN_EXE"

rm -rf "$PKG_TMPDIR"
print done

# Write launchers

write_bin_native_prefix_common "${PKG_MAIN_DIR}${PATH_BIN}/$APP_COMMON_ID"
write_bin_native_prefix        "${PKG_MAIN_DIR}${PATH_BIN}/$GAME_ID" "$APP_MAIN_EXE" '' "$APP_MAIN_LIBS" '' "$GAME_NAME"

write_desktop "$GAME_ID" "$GAME_NAME" "$GAME_NAME" "${PKG_MAIN_DIR}${PATH_DESK}/$APP_MAIN_ID.desktop" "$APP_MAIN_CAT"
printf '\n'

# Build packages

write_pkg_debian "$PKG_MAIN_DIR" "$GAME_ID" "$PKG_VERSION" "$PKG_MAIN_ARCH" '' "$PKG_MAIN_DEPS" '' "$PKG_MAIN_DESC"
build_pkg        "$PKG_MAIN_DIR" "$PKG_MAIN_DESC" "$PKG_COMPRESSION"

print_instructions "$PKG_MAIN_DESC" "$PKG_MAIN_DIR"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
