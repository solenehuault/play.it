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
# Beyond Zork: The Coconut of Quendor
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170523.1

# Set game-specific variables

GAME_ID='beyond-zork'
GAME_NAME='Beyond Zork: The Coconut of Quendor'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='setup_beyond_zork_2.1.0.17.exe'
ARCHIVE_GOG_MD5='8a5168d7340af5b1b4df708f467785c0'
ARCHIVE_GOG_SIZE='21000'
ARCHIVE_GOG_VERSION='1.0-gog2.1.0.17'

ARCHIVE_DOC1_PATH='app'
ARCHIVE_DOC1_FILES='./*.pdf'

ARCHIVE_DOC2_PATH='tmp'
ARCHIVE_DOC2_FILES='./gog_eula.txt ./eula.txt'

ARCHIVE_GAME_BIN_PATH='app'
ARCHIVE_GAME_BIN_FILES='./*.exe'

ARCHIVE_GAME_DATA_PATH='app'
ARCHIVE_GAME_DATA_FILES='./beyondzo.mg1 ./goggame-*.ico ./data'

DATA_FILES='./*.SAV'

APP_MAIN_TYPE='dosbox'
APP_MAIN_EXE='frotz.exe'
APP_MAIN_OPTIONS='data\\beyondzo.dat'
APP_MAIN_ICON='goggame-1207661533.ico'
APP_MAIN_ICON_RES='16 32 48 256'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, dosbox"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID dosbox"

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

PKG='PKG_DATA'
organize_data 'DOC1'      "$PATH_DOC"
organize_data 'DOC2'      "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

extract_and_sort_icons_from 'APP_MAIN'
rm "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON"

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

print_instructions

exit 0
