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

script_version=20170214.3

# Set game-specific variables

SCRIPT_DEPS='find'

GAME_ID='the-swapper'
GAME_NAME='The Swapper'

ARCHIVE_HUMBLE='the-swapper-linux-1.24_1409159048.sh'
ARCHIVE_HUMBLE_MD5='4f9627d245388edc320f61fae7cbd29f'
ARCHIVE_HUMBLE_UNCOMPRESSED_SIZE='980000'
ARCHIVE_HUMBLE_VERSION='1.24-humble140404'
ARCHIVE_HUMBLE_TYPE='mojosetup'

ARCHIVE_ICONS='the-swapper_icons.tar.gz'
ARCHIVE_ICONS_MD5='cddcf271fb6eb10fba870aa91c30c410'
ARCHIVE_ICONS_TYPE='tar.gz'

ARCHIVE_DOC_PATH='data/noarch'
ARCHIVE_DOC_FILES='./README* ./Licences'

ARCHIVE_GAME_32_PATH='data/noarch'
ARCHIVE_GAME_32_FILES='./TheSwapper.bin.x86 ./lib'

ARCHIVE_GAME_64_PATH='data/noarch'
ARCHIVE_GAME_64_FILES='./TheSwapper.bin.x86_64 ./lib64'

ARCHIVE_GAME_MAIN_PATH='data/noarch'
ARCHIVE_GAME_MAIN_FILES='./*'

ARCHIVE_ICONS_PATH='.'
ARCHIVE_ICONS_FILES='./16x16 ./32x32 ./48x48 ./128x128'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_32='TheSwapper.bin.x86'
APP_MAIN_EXE_64='TheSwapper.bin.x86_64'

PKG_MAIN_ID="${GAME_ID}-common"
PKG_MAIN_DESCRIPTION='arch-independant data'

PKG_32_ARCH='32'
PKG_32_CONFLICTS_DEB="$GAME_ID"
PKG_32_DEPS_DEB="$PKG_MAIN_ID, libc6, libstdc++6, libsdl2-2.0-0, libsdl2-image-2.0-0"
PKG_32_DEPS_ARCH="$PKG_MAIN_ID glu sdl2 sdl2_image"

PKG_64_ARCH='64'
PKG_64_CONFLICTS_DEB="$GAME_ID"
PKG_64_DEPS_DEB="$PKG_32_DEPS_DEB"
PKG_64_DEPS_ARCH="$PKG_32_DEPS_ARCH"

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

set_source_archive 'ARCHIVE_HUMBLE'
set_archive 'ICONS_PACK' "$ARCHIVE_ICONS"
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE"
if [ "$ICONS_PACK" ]; then
	ARCHIVE_REAL="$ARCHIVE"
	ARCHIVE='ARCHIVE_ICONS'
	file_checksum "$ICONS_PACK"
	ARCHIVE="$ARCHIVE_REAL"
fi

# Extract game data

set_workdir 'PKG_MAIN' 'PKG_32' 'PKG_64'
extract_data_from "$SOURCE_ARCHIVE"
if [ "$ICONS_PACK" ]; then
	ARCHIVE='ARCHIVE_ICONS'
	extract_data_from "$ICONS_PACK"
fi

find "$PLAYIT_WORKDIR/gamedata" -name '*:com.dropbox.attributes:$DATA' -delete

PKG='PKG_32'
organize_data_generic 'GAME_32' "$PATH_GAME"

PKG='PKG_64'
organize_data_generic 'GAME_64' "$PATH_GAME"

PKG='PKG_MAIN'
organize_data_generic 'GAME_MAIN' "$PATH_GAME"
organize_data_generic 'DOC'       "$PATH_DOC"
if [ "$ICONS_PACK" ]; then
	organize_data_generic 'ICONS' "$PATH_ICON_BASE"
fi

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_32'
APP_MAIN_EXE="$APP_MAIN_EXE_32"
write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

PKG='PKG_64'
APP_MAIN_EXE="$APP_MAIN_EXE_64"
write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

write_metadata 'PKG_MAIN'
write_metadata 'PKG_32' 'PKG_64'
build_pkg 'PKG_MAIN' 'PKG_32' 'PKG_64'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n32-bit:'
print_instructions "$PKG_MAIN_PKG" "$PKG_32_PKG"
printf '\n64-bit:'
print_instructions "$PKG_MAIN_PKG" "$PKG_64_PKG"

exit 0
