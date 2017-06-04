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
# Ori and the Blind Forest
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170604.2

# Set game-specific variables

GAME_ID='ori-and-the-blind-forest'
GAME_NAME='Ori and the Blind Forest'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='setup_ori_and_the_blind_forest_de_2.0.0.2-1.bin'
ARCHIVE_GOG_MD5='d5ec4ea264c372a4fdd52b5ecbd9efe6'
ARCHIVE_GOG_SIZE='11000000'
ARCHIVE_GOG_VERSION='1.0-gog2.0.0.2'
ARCHIVE_GOG_TYPE='rar'
ARCHIVE_GOG_PART2='setup_ori_and_the_blind_forest_de_2.0.0.2-2.bin'
ARCHIVE_GOG_PART2_MD5='94c3d33701eadca15df9520de55f6f03'
ARCHIVE_GOG_PART2_TYPE='rar'

DATA_FILES='./oride_data/output_log.txt'

ARCHIVE_GAME_ASSETS_PATH='game'
ARCHIVE_GAME_ASSETS_FILES='./oride_data/*.assets ./oride_data/*.assets.ress'

ARCHIVE_GAME_DATA_PATH='game'
ARCHIVE_GAME_DATA_FILES='./oride_data'

ARCHIVE_GAME_BIN_PATH='game'
ARCHIVE_GAME_BIN_FILES='./oride.exe ./oride_data/managed ./oride_data/mono ./oride_data/plugins'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='./oride.exe'
APP_MAIN_ICON='./oride.exe'
APP_MAIN_ICON_RES='16 24 32 48 64 96 128 192 256'

PACKAGES_LIST='PKG_ASSETS PKG_DATA PKG_BIN'

PKG_ASSETS_ID="${GAME_ID}-assets"
PKG_ASSETS_DESCRIPTION='assets'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_ASSETS_ID, $PKG_DATA_ID, wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386"
PKG_BIN_DEPS_ARCH="$PKG_ASSETS_ID $PKG_DATA_ID wine"

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

set_archive 'ARCHIVE_PART2' 'ARCHIVE_GOG_PART2'
[ "$ARCHIVE_PART2" ] || set_archive_error_not_found 'ARCHIVE_GOG_PART2'
ARCHIVE='ARCHIVE_GOG'

# Extract game data

ln --symbolic "$(readlink --canonicalize $SOURCE_ARCHIVE)" "$PLAYIT_WORKDIR/$GAME_ID.r00"
ln --symbolic "$(readlink --canonicalize $ARCHIVE_PART2)"  "$PLAYIT_WORKDIR/$GAME_ID.r01"
extract_data_from "$PLAYIT_WORKDIR/$GAME_ID.r00"
tolower "$PLAYIT_WORKDIR/gamedata"

PKG='PKG_BIN'
organize_data 'GAME_BIN' "$PATH_GAME"

PKG='PKG_ASSETS'
organize_data 'GAME_ASSETS' "$PATH_GAME"

PKG='PKG_DATA'
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
