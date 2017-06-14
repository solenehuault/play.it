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
# The Night of the Rabbit
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170613.1

# Set game-specific variables

GAME_ID='the-night-of-the-rabbit'
GAME_NAME='The Night of the Rabbit'

ARCHIVES_LIST='ARCHIVE_GOG'


ARCHIVE_GOG='setup_the_night_of_the_rabbit_2.1.0.5-1.bin'
ARCHIVE_GOG_MD5='565c8c59266eced8483ad579ecf3c454'
ARCHIVE_GOG_VERSION='1.2.3.0389-gog2.1.0.5'
ARCHIVE_GOG_SIZE='6200000'
ARCHIVE_GOG_TYPE='rar'
ARCHIVE_GOG_GOGID='1207659218'
ARCHIVE_GOG_PART1='setup_the_night_of_the_rabbit_2.1.0.5-2.bin'
ARCHIVE_GOG_PART1_MD5='403e06a8e8aef71989bf550369244373'
ARCHIVE_GOG_PART1_TYPE='rar'

ARCHIVE_DOC_PATH='game'
ARCHIVE_DOC_FILES='./documents'

ARCHIVE_GAME_BIN1_PATH='game'
ARCHIVE_GAME_BIN1_FILES='./avcodec-54.dll ./avformat-54.dll ./avutil-52.dll ./libsndfile-1.dll ./lua ./openal32.dll ./rabbit.exe ./sdl2.dll ./swresample-0.dll ./swscale-2.dll ./visionaireconfigurationtool.exe ./zlib1.dll'
ARCHIVE_GAME_BIN2_PATH='support/app/'
ARCHIVE_GAME_BIN2_FILES='./config.ini'

ARCHIVE_GAME_VIDEO_PATH='game'
ARCHIVE_GAME_VIDEO_FILES='./videos'

ARCHIVE_GAME_DATA_PATH='game'
ARCHIVE_GAME_DATA_FILES=' ./banner.jpg ./characters ./data.vis ./folder.jpg ./languages.xml ./scenes'

CONFIG_FILES='./config.ini'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='./rabbit.exe'
APP_MAIN_ICON='./rabbit.exe'
APP_MAIN_ICON_RES='16 24 32 48 256'

PACKAGES_LIST='PKG_VIDEO PKG_DATA PKG_BIN'

PKG_VIDEO_ID="${GAME_ID}-videos"
PKG_VIDEO_DESCRIPTION='videos'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_VIDEO_ID, $PKG_DATA_ID, wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386"
PKG_BIN_DEPS_ARCH="$PKG_VIDEO_ID $PKG_DATA_ID wine"

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

# Check that all parts of the installer are present

set_archive 'ARCHIVE_PART1' 'ARCHIVE_GOG_PART1'
[ "$ARCHIVE_PART1" ] || set_archive_error_not_found 'ARCHIVE_GOG_PART1'
ARCHIVE='ARCHIVE_GOG'

# Extract game data

ln --symbolic "$(readlink --canonicalize $SOURCE_ARCHIVE)" "$PLAYIT_WORKDIR/$GAME_ID.r00"
ln --symbolic "$(readlink --canonicalize $ARCHIVE_PART1)"  "$PLAYIT_WORKDIR/$GAME_ID.r01"
extract_data_from "$PLAYIT_WORKDIR/$GAME_ID.r00"
tolower "$PLAYIT_WORKDIR/gamedata"

PKG='PKG_BIN'
organize_data 'GAME_BIN1' "$PATH_GAME"
organize_data 'GAME_BIN2' "$PATH_GAME"

PKG='PKG_VIDEO'
organize_data 'GAME_VIDEO' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC'      "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

PKG='PKG_BIN'
extract_and_sort_icons_from 'APP_MAIN'
move_icons_to 'PKG_DATA'

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

write_launcher 'APP_MAIN'

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
