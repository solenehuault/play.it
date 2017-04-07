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
# Anna's Quest
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170407.1

# Set game-specific variables

GAME_ID='annas-quest'
GAME_NAME='Anna’s Quest'

ARCHIVE_GOG='gog_anna_s_quest_2.1.0.3.sh'
ARCHIVE_GOG_MD5='cb4cf167a13413b6df8238397393298a'
ARCHIVE_GOG_SIZE='1100000'
ARCHIVE_GOG_VERSION='1.0.0202-gog2.1.0.3'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'

ARCHIVE_DOC2_PATH='data/noarch/game/documents/licenses'
ARCHIVE_DOC2_FILES='./*'

ARCHIVE_GAME_PATH='data/noarch/game'
ARCHIVE_GAME_FILES='./anna ./characters ./config.ini ./data.vis ./libs64 ./lua ./scenes ./videos'

CONFIG_FILES='./config.ini'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='anna'
APP_MAIN_LIBS='libs64'
APP_MAIN_ICON='data/noarch/support/icon.png'
APP_MAIN_ICON_RES='256x256'

PKG_MAIN_ARCH='64'
PKG_MAIN_DEPS_DEB='libavcodec56 | libavcodec-extra-56, libavformat56, libavutil54, libswscale3, zlib1g, libc6, libgl1-mesa-glx | libgl1, libopenal1, libstdc++6, libgcc1, libx11-6, libxext6, libxcb1, libxau6, libxdmcp6'
PKG_MAIN_DEPS_ARCH='ffmpeg zlib glibc libgl openal gcc libx11 libxext libxcb libxau libxdmcp'

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
file_checksum "$SOURCE_ARCHIVE"

# Extract game data

set_workdir 'PKG_MAIN'
extract_data_from "$SOURCE_ARCHIVE"

organize_data 'DOC1' "$PATH_DOC"
organize_data 'DOC2' "$PATH_DOC"
organize_data 'GAME' "$PATH_GAME"

PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
mkdir --parents "$PKG_MAIN_PATH/$PATH_ICON"
mv "$PLAYIT_WORKDIR/gamedata/$APP_MAIN_ICON" "$PKG_MAIN_PATH/$PATH_ICON/$GAME_ID.png"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_MAIN'
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

write_metadata 'PKG_MAIN'
build_pkg      'PKG_MAIN'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_MAIN_PKG"

exit 0
