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
# Crypt Of The Necrodancer
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170508.1

# Set game-specific variables

GAME_ID='crypt-of-the-necrodancer'
GAME_NAME='Crypt Of The Necrodancer'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='gog_crypt_of_the_necrodancer_2.3.0.5.sh'
ARCHIVE_GOG_MD5='8a6e7c3d26461aa2fa959b8607e676f7'
ARCHIVE_GOG_SIZE='1500000'
ARCHIVE_GOG_VERSION='1.27-gog2.3.0.5'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'

ARCHIVE_DOC2_PATH='data/noarch/game/'
ARCHIVE_DOC2_FILES='./license.txt'

ARCHIVE_GAME_BIN_PATH='data/noarch/game'
ARCHIVE_GAME_BIN_FILES='./*.so.* ./fmod ./NecroDancer ./essentia*'

ARCHIVE_GAME_MUSIC_PATH='data/noarch/game'
ARCHIVE_GAME_MUSIC_FILES='./data/music'

ARCHIVE_GAME_VIDEO_PATH='data/noarch/game'
ARCHIVE_GAME_VIDEO_FILES='./data/video'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./data'

DATA_DIRS='./downloaded_dungeons ./downloaded_mods ./logs ./mods'
DATA_FILES='./NecroDancer'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='NecroDancer'
APP_MAIN_ICON='data/noarch/support/icon.png'
APP_MAIN_ICON_RES='256'

PACKAGES_LIST='PKG_MUSIC PKG_VIDEO PKG_DATA PKG_BIN'

PKG_MUSIC_ID="${GAME_ID}-music"
PKG_MUSIC_DESCRIPTION='music'

PKG_VIDEO_ID="${GAME_ID}-video"
PKG_VIDEO_DESCRIPTION='video'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_MUSIC_ID, $PKG_VIDEO_ID, $PKG_DATA_ID, libglu1-mesa | libglu1, libopenal1, libfftw3-single3, libglfw2, libgsm1, libsamplerate0, libschroedinger-1.0-0, libtag1v5-vanilla | libtag1-vanilla, libyaml-0-2, libvorbis0a"
PKG_BIN_DEPS_ARCH="$PKG_MUSIC_ID $PKG_VIDEO_ID $PKG_DATA_ID lib32-glibc lib32-libogg lib32-libvorbis lib32-libx11 lib32-libxau lib32-libxcb lib32-libxdmcp lib32-libxext lib32-libgl lib32-openal"

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

PKG='PKG_BIN'
organize_data 'GAME_BIN' "$PATH_GAME"

PKG='PKG_MUSIC'
organize_data 'GAME_MUSIC' "$PATH_GAME"

PKG='PKG_VIDEO'
organize_data 'GAME_VIDEO' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC1'      "$PATH_DOC"
organize_data 'DOC2'      "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"
mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
mv "$PLAYIT_WORKDIR/gamedata/$APP_MAIN_ICON" "$PKG_DATA_PATH/$PATH_ICON/$GAME_ID.png"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_MUSIC_PKG" "$PKG_VIDEO_PKG" "$PKG_DATA_PKG" "$PKG_BIN_PKG"

exit 0
