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
# Desperados: Wanted Dead or Alive
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170512.2

# Set game-specific variables

GAME_ID='desperados'
GAME_NAME='Desperados: Wanted Dead or Alive'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='setup_desperados_wanted_dead_or_alive_2.0.0.6.exe'
ARCHIVE_GOG_MD5='8e2f4e2ade9e641fdd35a9dd36d55d00'
ARCHIVE_GOG_VERSION='1.01-gog2.0.0.6'
ARCHIVE_GOG_SIZE='810000'

ARCHIVE_DOC1_PATH='app'
ARCHIVE_DOC1_FILES='./manual.pdf ./readme.txt'

ARCHIVE_DOC2_PATH='tmp'
ARCHIVE_DOC2_FILES='./gog_eula.txt'

ARCHIVE_GAME_BIN_PATH='app/game'
ARCHIVE_GAME_BIN_FILES='./*.dll ./*.exe'

ARCHIVE_GAME_DATA_PATH='app/game'
ARCHIVE_GAME_DATA_FILES='./data'

CONFIG_DIRS='data/configuration'
DATA_DIRS='data/savegame'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='game.exe'
APP_MAIN_ICON='./game.exe'
APP_MAIN_ICON_RES='16 32'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID wine"

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
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

PKG='PKG_BIN'
extract_and_sort_icons_from 'APP_MAIN'
(
	cd "$PKG_BIN_PATH"
	cp --link --parents --recursive "./$PATH_ICON_BASE" "$PKG_DATA_PATH"
	rm --recursive "./$PATH_ICON_BASE"
	rmdir --ignore-fail-on-non-empty --parents "./${PATH_ICON_BASE%/*}"
)

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

write_launcher 'APP_MAIN'

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_DATA_PKG" "$PKG_BIN_PKG"

exit 0
