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
# Ascendant
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170610.1

# Set game-specific variables

GAME_ID='ascendant'
GAME_NAME='Ascendant'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='gog_ascendant_2.2.0.7.sh'
ARCHIVE_GOG_MD5='8cdcd59a2f8363b7237e9cbe2675adda'
ARCHIVE_GOG_SIZE='2400000'
ARCHIVE_GOG_VERSION='1.2.2-gog2.2.0.7'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'

ARCHIVE_GAME_32_PATH='data/noarch/game'
ARCHIVE_GAME_32_FILES='./*.x86 ./Ascendant_Data'

ARCHIVE_GAME_64_PATH='data/noarch/game'
ARCHIVE_GAME_64_FILES='./*.x86_64 ./Ascendant_64_Data'

DATA_DIRS='./logs'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_32='Ascendant.x86'
APP_MAIN_EXE_64='Ascendant_64.x86_64'
APP_MAIN_OPTIONS='-logFile ./logs/$(date +%%F-%%R).log'
APP_MAIN_ICON='*_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128'

PACKAGES_LIST='PKG_32 PKG_64'

PKG_32_ARCH='32'
PKG_32_DEPS_DEB='libglu1-mesa | libglu1, libxcursor1, libxrandr2'
PKG_32_DEPS_ARCH='lib32-glu lib32-libxcursor lib32-libxrandr'

PKG_64_ARCH='64'
PKG_64_DEPS_DEB="$PKG_32_DEPS_DEB"
PKG_64_DEPS_ARCH='glu libxcursor libxrandr'

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

PKG='PKG_32'
organize_data 'GAME_32' "$PATH_GAME"

PKG='PKG_64'
organize_data 'DOC'     "$PATH_DOC"
organize_data 'GAME_64' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_32'
write_launcher 'APP_MAIN'

PKG='PKG_64'
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

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n'
printf '32-bit:'
print_instructions 'PKG_32'
printf '64-bit:'
print_instructions 'PKG_64'

exit 0
