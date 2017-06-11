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
# Torment: Tides of Numenera
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170530.1

# Set game-specific variables

GAME_ID='torment-tides-of-numenera'
GAME_NAME='Torment: Tides of Numenera'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='gog_torment_tides_of_numenera_2.3.0.4.sh'
ARCHIVE_GOG_MD5='839337b42a1618f3b445f363eca210d3'
ARCHIVE_GOG_SIZE='9300000'
ARCHIVE_GOG_VERSION='1.1.0-gog2.3.0.4'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'

ARCHIVE_GAME_BIN_PATH='data/noarch/game'
ARCHIVE_GAME_BIN_FILES='./TidesOfNumenera ./TidesOfNumenera_Data/Mono/x86_64 ./TidesOfNumenera_Data/Plugins'

ARCHIVE_GAME_AUDIO_PATH='data/noarch/game'
ARCHIVE_GAME_AUDIO_FILES='./TidesOfNumenera_Data/StreamingAssets/Audio'

ARCHIVE_GAME_RESOURCES_PATH='data/noarch/game'
ARCHIVE_GAME_RESOURCES_FILES='./TidesOfNumenera_Data/resources.assets*'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./TidesOfNumenera_Data'

DATA_DIRS='./logs'

APP_MAIN_TYPE='native'
APP_MAIN_PRERUN='pulseaudio --start\nexport LANG="en_US.UTF-8"'
APP_MAIN_EXE='TidesOfNumenera'
APP_MAIN_OPTIONS='-logFile ./logs/$(date +%F-%R).log'
APP_MAIN_ICON='TidesOfNumenera_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128'

PACKAGES_LIST='PKG_AUDIO PKG_RESOURCES PKG_DATA PKG_BIN'

PKG_AUDIO_ID="${GAME_ID}-audio"
PKG_AUDIO_DESCRIPTION='audio'

PKG_RESOURCES_ID="${GAME_ID}-resources"
PKG_RESOURCES_DESCRIPTION='resources'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='64'
PKG_BIN_DEPS_DEB="$PKG_AUDIO_ID, $PKG_RESOURCES_ID, $PKG_DATA_ID, libgl1-mesa-glx | libgl1, libsdl2-2.0-0, pulseaudio"
PKG_BIN_DEPS_ARCH="$PKG_AUDIO_ID $PKG_RESOURCES_ID $PKG_DATA_ID libgl sdl2 pulseaudio"

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

PKG='PKG_AUDIO'
organize_data 'GAME_AUDIO' "$PATH_GAME"

PKG='PKG_RESOURCES'
organize_data 'GAME_RESOURCES' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

PKG='PKG_BIN'
organize_data 'GAME_BIN' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

write_launcher 'APP_MAIN'

# Build package

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"

cat > "$postinst" << EOF
mkdir --parents "$PATH_ICON"
ln --symbolic "$PATH_GAME/$APP_MAIN_ICON" "$PATH_ICON/$GAME_ID.png"
EOF

cat > "$prerm" << EOF
rm "$PATH_ICON/$GAME_ID.png"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON"
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_BIN' 'PKG_AUDIO' 'PKG_RESOURCES'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
