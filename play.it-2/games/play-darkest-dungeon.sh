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
# Darkest Dungeon
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161223.1

# Set game-specific variables

GAME_ID='darkest-dungeon'
GAME_NAME='Darkest Dungeon'

ARCHIVE_GOG='gog_darkest_dungeon_2.6.0.6.sh'
ARCHIVE_GOG_MD5='38b4feb26883534120bb0ec198afa9d8'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='880000'
ARCHIVE_GOG_VERSION='15015-gog2.6.0.6'

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
APP_MAIN_ICON='Icon.bmp'
APP_MAIN_ICON_RES='128x128'

PKG_AUDIO_ID="${GAME_ID}-audio"
PKG_AUDIO_ARCH_DEB='all'
PKG_AUDIO_ARCH_ARCH='any'
PKG_AUDIO_DESC_DEB="$GAME_NAME - audio\n
 ./play.it script version $script_version"
PKG_AUDIO_DESC_ARCH="$GAME_NAME - audio - ./play.it script version $script_version"

PKG_VIDEO_ID="${GAME_ID}-video"
PKG_VIDEO_ARCH_DEB='all'
PKG_VIDEO_ARCH_ARCH='any'
PKG_VIDEO_DESC_DEB="$GAME_NAME - video\n
 ./play.it script version $script_version"
PKG_VIDEO_DESC_ARCH="$GAME_NAME - video - ./play.it script version $script_version"

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_ARCH_DEB='all'
PKG_DATA_ARCH_ARCH='any'
PKG_DATA_DESC_DEB="$GAME_NAME - arch-independant data\n
 ./play.it script version $script_version"
PKG_DATA_DESC_ARCH="$GAME_NAME - arch-independant data - ./play.it script version $script_version"

PKG_BIN32_ARCH_DEB='i386'
PKG_BIN32_ARCH_ARCH='i686'
PKG_BIN32_DEPS_DEB="$PKG_AUDIO_ID, $PKG_VIDEO_ID, $PKG_DATA_ID, libc6, libstdc++6, libsdl2-2.0-0"
PKG_BIN32_DEPS_ARCH="$PKG_AUDIO_ID $PKG_VIDEO_ID $PKG_DATA_ID sdl2"
PKG_BIN32_DESC_DEB="$GAME_NAME\n
 ./play.it script version $script_version"
PKG_BIN32_DESC_ARCH="$GAME_NAME - ./play.it script version $script_version"

PKG_BIN64_ARCH_DEB='amd64'
PKG_BIN64_ARCH_ARCH='x86_64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_BIN32_DEPS_ARCH"
PKG_BIN64_DESC_DEB="$PKG_BIN32_DESC_DEB"
PKG_BIN64_DESC_ARCH="$PKG_BIN32_DESC_ARCH"

PKG_BIN32_CONFLICTS_DEB="${GAME_ID}:${PKG_BIN64_ARCH_DEB}"
PKG_BIN64_CONFLICTS_DEB="${GAME_ID}:${PKG_BIN32_ARCH_DEB}"
 
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
PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG'
check_deps

# Extract game data

set_workdir 'PKG_AUDIO' 'PKG_VIDEO' 'PKG_DATA' 'PKG_BIN32' 'PKG_BIN64'
extract_data_from "$SOURCE_ARCHIVE"

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
	extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON"
	mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
	mv "$PLAYIT_WORKDIR/icons/${APP_MAIN_ICON%.bmp}.png" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"
fi

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

printf '\n32-bit:'
print_instructions "$PKG_AUDIO_PKG" "$PKG_VIDEO_PKG" "$PKG_DATA_PKG" "$PKG_BIN32_PKG"
printf '\n64-bit:'
print_instructions "$PKG_AUDIO_PKG" "$PKG_VIDEO_PKG" "$PKG_DATA_PKG" "$PKG_BIN64_PKG"

exit 0
