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
# The Swapper
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170523.1

# Set game-specific variables

SCRIPT_DEPS='find'

GAME_ID='the-swapper'
GAME_NAME='The Swapper'

ARCHIVES_LIST='ARCHIVE_HUMBLE'

ARCHIVE_HUMBLE='the-swapper-linux-1.24_1409159048.sh'
ARCHIVE_HUMBLE_MD5='4f9627d245388edc320f61fae7cbd29f'
ARCHIVE_HUMBLE_SIZE='980000'
ARCHIVE_HUMBLE_VERSION='1.24-humble140404'
ARCHIVE_HUMBLE_TYPE='mojosetup'

ARCHIVE_ICONS='the-swapper_icons.tar.gz'
ARCHIVE_ICONS_MD5='cddcf271fb6eb10fba870aa91c30c410'

ARCHIVE_DOC_PATH='data/noarch'
ARCHIVE_DOC_FILES='./README* ./Licences'

ARCHIVE_GAME_BIN32_PATH='data/noarch'
ARCHIVE_GAME_BIN32_FILES='./TheSwapper.bin.x86 ./lib'

ARCHIVE_GAME_BIN64_PATH='data/noarch'
ARCHIVE_GAME_BIN64_FILES='./TheSwapper.bin.x86_64 ./lib64'

ARCHIVE_GAME_DATA_PATH='data/noarch'
ARCHIVE_GAME_DATA_FILES='./*'

ARCHIVE_ICONS_PATH='.'
ARCHIVE_ICONS_FILES='./16x16 ./32x32 ./48x48 ./128x128'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN32='TheSwapper.bin.x86'
APP_MAIN_EXE_BIN64='TheSwapper.bin.x86_64'

PACKAGES_LIST='PKG_DATA PKG_BIN32 PKG_BIN64'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6, libsdl2-2.0-0, libsdl2-image-2.0-0"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-glu lib32-sdl2 lib32-sdl2_image"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_DATA_ID glu sdl2 sdl2_image"

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

# Try to load icons archive

ARCHIVE_MAIN="$ARCHIVE"
set_archive 'ICONS_PACK' 'ARCHIVE_ICONS'
ARCHIVE="$ARCHIVE_MAIN"

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"
(
	if [ "$ICONS_PACK" ]; then
		ARCHIVE='ICONS_PACK'
		extract_data_from "$ICONS_PACK"
	fi
)

find "$PLAYIT_WORKDIR/gamedata" -name '*:com.dropbox.attributes:$DATA' -delete

PKG='PKG_BIN32'
organize_data 'GAME_BIN32' "$PATH_GAME"

PKG='PKG_BIN64'
organize_data 'GAME_BIN64' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"
if [ "$ICONS_PACK" ]; then
	organize_data 'ICONS' "$PATH_ICON_BASE"
fi

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

for PKG in 'PKG_BIN32' 'PKG_BIN64'; do
	write_launcher 'APP_MAIN'
done

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n'
printf '32-bit:'
print_instructions 'PKG_DATA' 'PKG_BIN32'
printf '64-bit:'
print_instructions 'PKG_DATA' 'PKG_BIN64'

exit 0
