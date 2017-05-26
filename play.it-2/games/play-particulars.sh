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
# Particulars
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170526.1

# Set game-specific variables

GAME_ID='particulars'
GAME_NAME='Particulars'

ARCHIVES_LIST='ARCHIVE_HUMBLE'

ARCHIVE_HUMBLE='particulars_lin_latest1416421559.zip'
ARCHIVE_HUMBLE_MD5='b7b269b8e33d682a2fca5c548928dabf'
ARCHIVE_HUMBLE_SIZE='1400000'
ARCHIVE_HUMBLE_VERSION='1.0-humble141119'

ARCHIVE_DOC1_PATH='particulars_1.0.0.2_lin/licenses'
ARCHIVE_DOC1_FILES='./*'

ARCHIVE_DOC2_PATH='particulars_1.0.0.2_lin'
ARCHIVE_DOC2_FILES='./readme.txt ./release_notes.txt'

ARCHIVE_GAME_BIN32_PATH='particulars_1.0.0.2_lin'
ARCHIVE_GAME_BIN32_FILES='./p_1-0-0-2 ./*_Data/*/x86'

ARCHIVE_GAME_DATA_PATH='particulars_1.0.0.2_lin'
ARCHIVE_GAME_DATA_FILES='./*_Data ./libsteam_api.so ./libSteamworksNative.so'

DATA_DIRS='./logs'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN32='p_1-0-0-2'
APP_MAIN_OPTIONS='-logFile ./logs/$(date +%F-%R).log'
APP_MAIN_ICON='*_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128'

PACKAGES_LIST='PKG_DATA PKG_BIN32'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libgl1-mesa-glx | libgl1, libx11-6, libxcursor1, libxrandr2, libxau6 libglu1-mesa | libglu1"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-glibc lib32-libgl lib32-libx11 lib32-libxcursor lib32-libxrandr lib32-gcc-libs lib32-libxext lib32-libxcb lib32-libxrender lib32-libxfixes lib32-libxau lib32-libxdmcp lib32-glu"

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

PKG='PKG_BIN32'
organize_data 'GAME_BIN32' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC1' "$PATH_DOC1"
organize_data 'DOC2' "$PATH_DOC2"
organize_data 'GAME_DATA' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN32'
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
write_metadata 'PKG_BIN32'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0
