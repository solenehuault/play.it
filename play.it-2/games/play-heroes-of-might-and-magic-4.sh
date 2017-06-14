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
# Heroes of Might and Magic IV
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170614.1

# Set game-specific variables

GAME_ID='heroes-of-might-and-magic-4'
GAME_NAME='Heroes of Might and Magic IV'

ARCHIVES_LIST='ARCHIVE_GOG_EN ARCHIVE_GOG_FR'

ARCHIVE_GOG_EN='setup_homm4_complete_2.0.0.12.exe'
ARCHIVE_GOG_EN_MD5='74de66eb408bb2916dd0227781ba96dc'
ARCHIVE_GOG_EN_VERSION='3.0-gog2.0.0.12'
ARCHIVE_GOG_EN_SIZE='1100000'

ARCHIVE_GOG_FR='setup_homm4_complete_french_2.1.0.14.exe'
ARCHIVE_GOG_FR_MD5='2af96eb28226e563bbbcd62771f3a319'
ARCHIVE_GOG_FR_VERSION='3.0-gog2.1.0.14'
ARCHIVE_GOG_FR_SIZE='1100000'

ARCHIVE_DOC1_PATH='tmp'
ARCHIVE_DOC1_FILES='./*eula.txt'

ARCHIVE_DOC2_PATH='app'
ARCHIVE_DOC2_FILES='./*.chm ./*.pdf ./*.txt'

ARCHIVE_GAME_BIN_PATH='app'
ARCHIVE_GAME_BIN_FILES='./*.exe ./binkw32.dll ./drvmgt.dll ./mss32.dll ./mp3dec.asi data/*.dll'

ARCHIVE_GAME_DATA_PATH='app'
ARCHIVE_GAME_DATA_FILES='./data ./maps'

DATA_DIRS='./games ./maps'
DATA_FILES='./data/high_scores.dat ./*.log'

APP_WINETRICKS='vd=1280x1024'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='./heroes4.exe'
APP_MAIN_ICON='./heroes4.exe'
APP_MAIN_ICON_RES='16 32'

APP_EDITOR_TYPE='wine'
APP_EDITOR_ID="${GAME_ID}_edit"
APP_EDITOR_EXE='./campaign_editor.exe'
APP_EDITOR_ICON='./campaign_editor.exe'
APP_EDITOR_ICON_RES='48 64'
APP_EDITOR_NAME="$GAME_NAME - campaign editor"

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, winetricks, wine:amd64 | wine, wine32 | wine-bin | wine-i386 | wine-staging-i386"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID winetricks wine"

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

PKG='PKG_BIN'
extract_and_sort_icons_from 'APP_MAIN' 'APP_EDITOR'
move_icons_to 'PKG_DATA'

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN' 'APP_EDITOR'

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
