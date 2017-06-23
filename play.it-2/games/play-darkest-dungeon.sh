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

script_version=20170623.1

# Set game-specific variables

GAME_ID='darkest-dungeon'
GAME_NAME='Darkest Dungeon'

ARCHIVES_LIST='ARCHIVE_GOG ARCHIVE_GOG_OLD'

ARCHIVE_GOG='gog_darkest_dungeon_2.11.0.11.sh'
ARCHIVE_GOG_MD5='6e59b1b59e1b4c5444c87a46d93c8308'
ARCHIVE_GOG_SIZE='2100000'
ARCHIVE_GOG_VERSION='19990-gog2.11.0.11'

ARCHIVE_GOG_OLD='gog_darkest_dungeon_2.10.0.10.sh'
ARCHIVE_GOG_OLD_MD5='f8fa42b354731886f9b69e1d0e78b3b7'
ARCHIVE_GOG_OLD_SIZE='2000000'
ARCHIVE_GOG_OLD_VERSION='17687-gog2.10.0.10'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'

ARCHIVE_DOC2_PATH='data/noarch/game'
ARCHIVE_DOC2_FILES='./README.linux'

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
APP_MAIN_EXE_BIN32='darkest.bin.x86'
APP_MAIN_EXE_BIN64='darkest.bin.x86_64'
APP_MAIN_ICON='Icon.bmp'
APP_MAIN_ICON_RES='128'

PACKAGES_LIST='PKG_AUDIO PKG_VIDEO PKG_DATA PKG_BIN32 PKG_BIN64'

PKG_AUDIO_ID="${GAME_ID}-audio"
PKG_AUDIO_DESCRIPTION='audio'

PKG_VIDEO_ID="${GAME_ID}-video"
PKG_VIDEO_DESCRIPTION='video'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_AUDIO_ID, $PKG_VIDEO_ID, $PKG_DATA_ID, libc6, libstdc++6, libsdl2-2.0-0"
PKG_BIN32_DEPS_ARCH="$PKG_AUDIO_ID $PKG_VIDEO_ID $PKG_DATA_ID lib32-sdl2"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_AUDIO_ID $PKG_VIDEO_ID $PKG_DATA_ID sdl2"

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

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"

(
	cd "$PLAYIT_WORKDIR/gamedata/data/noarch/game"
	rm --force --recursive 'localization/ps4' 'localization/psv'
	rm --force --recursive 'shaders_ps4' 'shaders_psv'
	rm --force --recursive 'video_ps4' 'video_psv'
)

PKG='PKG_BIN32'
organize_data 'GAME_BIN32' "$PATH_GAME"

PKG='PKG_BIN64'
organize_data 'GAME_BIN64' "$PATH_GAME"

PKG='PKG_AUDIO'
organize_data 'GAME_AUDIO' "$PATH_GAME"

PKG='PKG_VIDEO'
organize_data 'GAME_VIDEO' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC1'      "$PATH_DOC"
organize_data 'DOC2'      "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"
extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON"
mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
mv "$PLAYIT_WORKDIR/icons/${APP_MAIN_ICON%.bmp}.png" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

for PKG in 'PKG_BIN32' 'PKG_BIN64'; do
	write_launcher 'APP_MAIN'
done

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n'
printf '32-bit:'
print_instructions 'PKG_AUDIO' 'PKG_VIDEO' 'PKG_DATA' 'PKG_BIN32'
printf '64-bit:'
print_instructions 'PKG_AUDIO' 'PKG_VIDEO' 'PKG_DATA' 'PKG_BIN64'

exit 0
