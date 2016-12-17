#!/bin/sh -e
set -o errexit

###
# Copyright (c) 2015-2016, Antoine Le Gonidec
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
# Kingdom Rush
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161217.1

# Set game-specific variables

GAME_ID='kingdom-rush'
GAME_NAME='Kingdom Rush'

ARCHIVE_GOG='gog_kingdom_rush_2.0.0.5.sh'
ARCHIVE_GOG_MD5='a505372a8b3b0c98e0968301679e6781'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='2100000'
ARCHIVE_GOG_VERSION='2.1-gog2.0.0.5'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'
ARCHIVE_GAME_PATH='data/noarch/game'
ARCHIVE_GAME_FILES_BIN='./*.x86 ./*_Data/Mono/x86 ./*_Data/Plugins/x86'
ARCHIVE_GAME_FILES_DATA='./*'

DATA_FILES='./slot*.data'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='./Kingdom Rush.x86'
APP_MAIN_ICON='./Kingdom Rush_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128x128'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_ARCH_DEB='all'
PKG_DATA_ARCH_ARCH='any'
PKG_DATA_DESC_DEB="$GAME_NAME - data\n
 ./play.it script version $script_version"
PKG_DATA_DESC_ARCH="$GAME_NAME - data - ./play.it script version $script_version"

PKG_BIN_ARCH_DEB='i386'
PKG_BIN_ARCH_ARCH='x86_64'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6, libglu1-mesa | libglu1, libxcursor1"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID lib32-glu lib32-libxcursor"
PKG_BIN_DESC_DEB="$GAME_NAME\n
 ./play.it script version $script_version"
PKG_BIN_DESC_ARCH="$GAME_NAME - ./play.it script version $script_version"

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

if [ ${library_version%.*} -ne ${target_version%.*} ] || [ ${library_version#*.} -lt ${target_version#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'wrong version of libplayit2.sh\n'
	printf 'target version is: %s\n' "$target_version"
	return 1
fi

# Set extra variables

set_common_defaults
fetch_args "$@"

# Set source archive

set_source_archive 'ARCHIVE_GOG'
check_deps
set_common_paths
PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG'
check_deps

# Extract game data

set_workdir 'PKG_BIN' 'PKG_DATA'
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_BIN'
ARCHIVE_GAME_FILES="$ARCHIVE_GAME_FILES_BIN"
organize_data_generic 'GAME' "$PATH_GAME"
PKG='PKG_DATA'
ARCHIVE_GAME_FILES="$ARCHIVE_GAME_FILES_DATA"
organize_data

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

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

build_pkg 'PKG_BIN' 'PKG_DATA'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_DATA_PKG" "$PKG_BIN_PKG"

exit 0
