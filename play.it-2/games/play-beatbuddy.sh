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
# Beatbuddy: Tale of the Guardians
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170425.2

# Set game-specific variables

GAME_ID='beatbuddy'
GAME_NAME='Beatbuddy: Tale of the Guardians'

ARCHIVE_HUMBLE='BeatbuddyLinux1439603370.zip'
ARCHIVE_HUMBLE_MD5='156d19b327a02ac4a277f6f6ad4e188e'
ARCHIVE_HUMBLE_SIZE='1100000'
ARCHIVE_HUMBLE_VERSION='1.0-humble150815'

ARCHIVE_GAME_BIN_PATH='Beatbuddy'
ARCHIVE_GAME_BIN_FILES='./Beatbuddy.x86 ./Beatbuddy_Data/Mono ./Beatbuddy_Data/Plugins'

ARCHIVE_GAME_DATA_PATH='Beatbuddy'
ARCHIVE_GAME_DATA_FILES='./Beatbuddy_Data'

DATA_DIRS='./logs'
DATA_FILES='./Beatbuddy.x86'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='Beatbuddy.x86'
APP_MAIN_OPTIONS='-logFile ./logs/$(date +%F-%R).log'
APP_MAIN_ICON='Beatbuddy_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTIOn='data'

PKG_BIN_ARCH='32'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, libglu1-mesa | libglu1, libxcursor1, libasound2-plugins"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID lib32-glu lib32-libxcursor lib32-alsa-plugins"

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

# Set extra variables

set_common_defaults
fetch_args "$@"

# Set source archive

set_source_archive 'ARCHIVE_HUMBLE'
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE"

# Extract game data

set_workdir 'PKG_DATA' 'PKG_BIN'
extract_data_from "$SOURCE_ARCHIVE"
fix_rights "$PLAYIT_WORKDIR/gamedata"

PKG='PKG_BIN'
organize_data 'GAME_BIN' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'GAME_DATA' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

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
write_metadata 'PKG_BIN'
build_pkg      'PKG_BIN' 'PKG_DATA'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_DATA_PKG" "$PKG_BIN_PKG"

exit 0
