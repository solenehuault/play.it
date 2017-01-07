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

script_version=20161230.2

# Set game-specific variables

GAME_ID='darkest-dungeon'
GAME_NAME='Darkest Dungeon'

ARCHIVE_GOG='gog_darkest_dungeon_2.7.0.7.sh'
ARCHIVE_GOG_MD5='22deb2c91a659725f1dbc5d8021ee1e8'
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

APP_MAIN_TYPE='native'
APP_MAIN_EXE_32='darkest.bin.x86'
APP_MAIN_EXE_64='darkest.bin.x86_64'
APP_MAIN_ICON1='Icon.bmp'
APP_MAIN_ICON1_RES='128x128'
APP_MAIN_ICON2='data/noarch/support/icon.png'
APP_MAIN_ICON2_RES='256x256'

PKG_AUDIO_ID="${GAME_ID}-audio"
PKG_AUDIO_DESCRIPTION='audio'

PKG_VIDEO_ID="${GAME_ID}-video"
PKG_VIDEO_DESCRIPTION='video'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_CONFLICTS_DEB="$GAME_ID"
PKG_BIN32_DEPS_DEB="$PKG_AUDIO_ID, $PKG_VIDEO_ID, $PKG_DATA_ID, libc6, libstdc++6, libsdl2-2.0-0"
PKG_BIN32_DEPS_ARCH="$PKG_AUDIO_ID $PKG_VIDEO_ID $PKG_DATA_ID sdl2"

PKG_BIN64_ARCH='64'
PKG_BIN64_CONFLICTS_DEB="$GAME_ID"
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_BIN32_DEPS_ARCH"

# Load common functions

target_version='2.0'

if [ -z "$PLAYIT_LIB2" ]; then
	[ -n "$XDG_DATA_HOME" ] || XDG_DATA_HOME="$HOME/.local/share"
	if [ -e "$XDG_DATA_HOME/play.it/libplayit2.sh" ]; then
		PLAYIT_LIB2="$XDG_DATA_HOME/play.it/libplayit2.sh"
	elif [ -e './libplayit2.sh' ]; then
		PLAYIT_LIB2='./libplayit2.sh'
	else
		printf '\n\033[1;31mError:\033[0m\n'
		printf 'libplayit2.sh not found.\n'
		return 1
	fi
fi
. "$PLAYIT_LIB2"

if [ ${library_version%.*} -ne ${target_version%.*} ] || [ ${library_version#*.} -lt ${target_version#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'wrong version of libplayit2.sh\n'
	printf 'target version is: %s\n' "$target_version"
	return 1
fi

# Set extra variables

set_common_defaults
fetch_args "$@"

# Set source archive

set_source_archive 'ARCHIVE_GOG'
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG'
check_deps

# Extract game data

set_workdir 'PKG_AUDIO' 'PKG_VIDEO' 'PKG_DATA' 'PKG_BIN32' 'PKG_BIN64'
extract_data_from "$SOURCE_ARCHIVE"

(
	cd "$PLAYIT_WORKDIR/gamedata"
	rm --force --recursive 'localization/ps4' 'localization/psv'
	rm --force --recursive 'shaders_ps4' 'shaders_psv'
	rm --force --recursive 'video_ps4' 'video_psv'
)

PKG='PKG_BIN32'
organize_data_generic 'GAME_BIN32' "$PATH_GAME"
PKG='PKG_BIN64'
organize_data_generic 'GAME_BIN64' "$PATH_GAME"
PKG='PKG_AUDIO'
organize_data_generic 'GAME_AUDIO' "$PATH_GAME"
PKG='PKG_VIDEO'
organize_data_generic 'GAME_VIDEO' "$PATH_GAME"
PKG='PKG_DATA'
organize_data_generic 'GAME_DATA' "$PATH_GAME"
organize_data_generic 'DOC' "$PATH_DOC"

if [ "$NO_ICON" = '0' ]; then
	PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON1_RES/apps"
	extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON1"
	mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
	mv "$PLAYIT_WORKDIR/icons/${APP_MAIN_ICON1%.bmp}.png" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"
fi
PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON2_RES/apps"
mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
mv "$PLAYIT_WORKDIR/gamedata/$APP_MAIN_ICON2" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN32'
APP_MAIN_EXE="$APP_MAIN_EXE_32"
write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

PKG='PKG_BIN64'
APP_MAIN_EXE="$APP_MAIN_EXE_64"
write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

write_metadata 'PKG_AUDIO' 'PKG_VIDEO' 'PKG_DATA' 'PKG_BIN32' 'PKG_BIN64'
build_pkg 'PKG_AUDIO' 'PKG_VIDEO' 'PKG_DATA' 'PKG_BIN32' 'PKG_BIN64'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n'
printf '32-bit:'
print_instructions "$PKG_AUDIO_PKG" "$PKG_VIDEO_PKG" "$PKG_DATA_PKG" "$PKG_BIN32_PKG"
printf '64-bit:'
print_instructions "$PKG_AUDIO_PKG" "$PKG_VIDEO_PKG" "$PKG_DATA_PKG" "$PKG_BIN64_PKG"

exit 0
