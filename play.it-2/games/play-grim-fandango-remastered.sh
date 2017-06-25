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
# Grim Fandango Remastered
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170625.1

# Set game-specific variables

GAME_ID='grim-fandango'
GAME_NAME='Grim Fandango Remastered'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='gog_grim_fandango_remastered_2.3.0.7.sh'
ARCHIVE_GOG_MD5='9c5d124c89521d254b0dc259635b2abe'
ARCHIVE_GOG_SIZE='6100000'
ARCHIVE_GOG_VERSION='1.4-gog2.3.0.7'
ARCHIVE_GOG_TYPE='mojosetup_unzip'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'

ARCHIVE_DOC2_PATH='data/noarch/game/bin'
ARCHIVE_DOC2_FILES='./*License.txt ./common-licenses'

ARCHIVE_GAME_BIN_PATH='data/noarch/game/bin'
ARCHIVE_GAME_BIN_FILES='./GrimFandango ./*.so ./libSDL2-2.0.so.1 ./x86'

ARCHIVE_GAME_MOVIES_PATH='data/noarch/game/bin'
ARCHIVE_GAME_MOVIES_FILES='./MoviesHD'

ARCHIVE_GAME_DATA_PATH='data/noarch/game/bin'
ARCHIVE_GAME_DATA_FILES='./*.lab ./*.LAB ./controllerdef.txt ./en_gagl088.lip ./FontsHD ./*.tab ./icon.png ./patch_v2_or_v3_to_v4.bin ./patch_v4_to_v5.bin'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='./GrimFandango'
APP_MAIN_ICON='./icon.png'
APP_MAIN_ICON_RES='128x128'

PACKAGES_LIST='PKG_DATA PKG_MOVIES PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_MOVIES_ID="${GAME_ID}-movies"
PKG_MOVIES_DESCRIPTION='movies'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_MOVIES_ID, $PKG_DATA_ID, libc6, libstdc++6, libglu1-mesa | libglu1, libsdl2-2.0-0"
PKG_BIN_DEPS_ARCH="$PKG_MOVIES_ID $PKG_DATA_ID lib32-glu lib32-sdl2"

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

PKG='PKG_MOVIES'
organize_data 'GAME_MOVIES' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC1'      "$PATH_DOC"
organize_data 'DOC2'      "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"

cat > "$postinst" << EOF
mkdir --parents "$PATH_ICON"
ln --symbolic "$PATH_GAME"/$APP_MAIN_ICON "$PATH_ICON/$GAME_ID.png"
EOF

cat > "$prerm" << EOF
rm "$PATH_ICON/$GAME_ID.png"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON"
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_MOVIES' 'PKG_BIN'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
