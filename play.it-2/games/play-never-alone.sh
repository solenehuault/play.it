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
# Never Alone
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170517.1

# Set game-specific variables

GAME_ID='never-alone'
GAME_NAME='Never Alone'

ARCHIVES_LIST='ARCHIVE_HUMBLE'

ARCHIVE_HUMBLE='NeverAlone_ArcticCollection_Linux.1.04.tar.gz'
ARCHIVE_HUMBLE_MD5='3da062abaaa9e3e6ff97d4c82c8ea3c3'
ARCHIVE_HUMBLE_SIZE='4900000'
ARCHIVE_HUMBLE_VERSION='1.04-humble161008'

ARCHIVE_GAME_BIN_PATH='NeverAlone_ArcticCollection_Linux.1.04'
ARCHIVE_GAME_BIN_FILES='./Never_Alone.x64 ./Never_Alone_Data/*/x86_64'

ARCHIVE_GAME_VIDEOS_PATH='NeverAlone_ArcticCollection_Linux.1.04'
ARCHIVE_GAME_VIDEOS_FILES='./Never_Alone_Data/StreamingAssets/Videos'

ARCHIVE_GAME_DATA_PATH='NeverAlone_ArcticCollection_Linux.1.04'
ARCHIVE_GAME_DATA_FILES='./Never_Alone_Data'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='Never_Alone.x64'
APP_MAIN_ICON='Never_Alone_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128'

PACKAGES_LIST='PKG_VIDEOS PKG_DATA PKG_BIN'

PKG_VIDEOS_ID="$GAME_ID-videos"
PKG_VIDEOS_DESCRIPTION='videos'

PKG_DATA_ID="$GAME_ID-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='64'
PKG_BIN_DEPS_DEB="$PKG_VIDEOS_ID, $PKG_DATA_ID, libc6, libstdc++6, libglu1-mesa | libglu1, libxcursor1"
PKG_BIN_DEPS_ARCH="$PKG_VIDEOS_ID $PKG_DATA_ID glu libxcursor"

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
fix_rights "$PLAYIT_WORKDIR/gamedata"

PKG='PKG_BIN'
organize_data 'GAME_BIN' "$PATH_GAME"

PKG='PKG_VIDEOS'
organize_data 'GAME_VIDEOS' "$PATH_GAME"

PKG='PKG_DATA'
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
ln --symbolic "$PATH_GAME/$APP_MAIN_ICON" "$PATH_ICON/$GAME_ID.png"
EOF

cat > "$prerm" << EOF
rm "$PATH_ICON/$GAME_ID.png"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON"
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_BIN' 'PKG_VIDEOS'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_DATA_PKG" "$PKG_VIDEOS_PKG" "$PKG_BIN_PKG"

exit 0
