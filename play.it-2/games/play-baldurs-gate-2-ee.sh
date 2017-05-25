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
# Baldur’s Gate 2 - Enhanced Edition
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170523.1

# Set game-specific variables

GAME_ID='baldurs-gate-2-ee'
GAME_NAME='Baldur’s Gate 2 - Enhanced Edition'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='gog_baldur_s_gate_2_enhanced_edition_2.6.0.11.sh'
ARCHIVE_GOG_MD5='b9ee856a29238d4aec65367377d88ac4'
ARCHIVE_GOG_SIZE='2700000'
ARCHIVE_GOG_VERSION='2.3.67.3-gog2.6.0.11'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'

ARCHIVE_GAME_BIN_PATH='data/noarch/game'
ARCHIVE_GAME_BIN_FILES='./BaldursGateII ./engine.lua'

ARCHIVE_GAME_AREAS_PATH='data/noarch/game'
ARCHIVE_GAME_AREAS_FILES='./data/AREA*.bif ./data/Areas.bif ./data/25Areas.bif ./data/ARMisc.bif ./data/25ArMisc.bif'

ARCHIVE_GAME_MOVIES_PATH='data/noarch/game'
ARCHIVE_GAME_MOVIES_FILES='./movies'

ARCHIVE_GAME_MUSIC_PATH='data/noarch/game'
ARCHIVE_GAME_MUSIC_FILES='./music'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./*'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='BaldursGateII'
APP_MAIN_ICON='data/noarch/support/icon.png'
APP_MAIN_ICON_RES='256'

PACKAGES_LIST='PKG_AREAS PKG_MOVIES PKG_MUSIC PKG_DATA PKG_BIN'

PKG_AREAS_ID="${GAME_ID}-areas"
PKG_AREAS_DESCRIPTION='areas'

PKG_MOVIES_ID="${GAME_ID}-movies"
PKG_MOVIES_DESCRIPTION='movies'

PKG_MUSIC_ID="${GAME_ID}-music"
PKG_MUSIC_DESCRIPTION='music'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_AREAS_ID, $PKG_MOVIES_ID, $PKG_MUSIC_ID, $PKG_DATA_ID, libc6, libstdc++6, libgl1-mesa-glx | libgl1, libjson0, libopenal1, libssl1.0.0"
PKG_BIN_DEPS_ARCH="$PKG_AREAS_ID $PKG_MOVIES_ID $PKG_MUSIC_ID $PKG_DATA_ID lib32-libgl lib32-openal lib32-json-c lib32-openssl"

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

PKG='PKG_AREAS'
organize_data 'GAME_AREAS' "$PATH_GAME"

PKG='PKG_MOVIES'
organize_data 'GAME_MOVIES' "$PATH_GAME"

PKG='PKG_MUSIC'
organize_data 'GAME_MUSIC' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"
mkdir --parents "$PKG_DATA_PATH/$PATH_ICON"
mv "$PLAYIT_WORKDIR/gamedata/$APP_MAIN_ICON" "$PKG_DATA_PATH/$PATH_ICON/$GAME_ID.png"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

cat > "$postinst" << EOF
if [ ! -e /usr/lib32/libjson.so.0 ] && [ -e /usr/lib32/libjson-c.so ] ; then
	ln --symbolic libjson-c.so /usr/lib32/libjson.so.0
fi
EOF

write_metadata 'PKG_BIN'
rm "$postinst"
write_metadata 'PKG_AREAS' 'PKG_MOVIES' 'PKG_MUSIC' 'PKG_DATA'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
