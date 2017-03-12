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
# Dust: An Elysian Tale
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170312.1

# Set game-specific variables

GAME_ID='dust-an-elysian-tale'
GAME_NAME='Dust: An Elysian Tale'

ARCHIVE_HUMBLE='dustaet_05042016-bin'
ARCHIVE_HUMBLE_MD5='6844c82f233b47417620be0bef8b140c'
ARCHIVE_HUMBLE_UNCOMPRESSED_SIZE='1500000'
ARCHIVE_HUMBLE_VERSION='1.04-humble160504'
ARCHIVE_HUMBLE_TYPE='mojosetup'

ARCHIVE_DOC_PATH='data'
ARCHIVE_DOC_FILES='./Linux.README'
ARCHIVE_GAME_32_PATH='data'
ARCHIVE_GAME_32_FILES='./*.x86 ./lib'
ARCHIVE_GAME_64_PATH='data'
ARCHIVE_GAME_64_FILES='./*.x86_64 ./lib64'
ARCHIVE_GAME_MAIN_PATH='data'
ARCHIVE_GAME_MAIN_FILES='./*'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_32='./DustAET.bin.x86'
APP_MAIN_EXE_64='./DustAET.bin.x86_64'
APP_MAIN_ICON='Dust An Elysian Tail.bmp'
APP_MAIN_ICON_RES='64x64'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_32_ARCH='32'
PKG_32_CONFLICTS_DEB="$GAME_ID"
PKG_32_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6, libogg0, libopenal1, libsdl2-2.0-0, libtheora0, libvorbisfile3, libvorbis0a"
PKG_32_DEPS_ARCH="$PKG_DATA_ID lib32-libogg lib32-openal lib32-sdl2 lib32-libtheora lib32-libvorbis"

PKG_64_ARCH='64'
PKG_64_CONFLICTS_DEB="$GAME_ID"
PKG_64_DEPS_DEB="$PKG_32_DEPS_DEB"
PKG_64_DEPS_ARCH="$PKG_DATA_ID libogg openal sdl2 libtheora libvorbis"

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
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_HUMBLE'
check_deps

# Extract game data

set_workdir 'PKG_DATA' 'PKG_32' 'PKG_64'
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_32'
organize_data_generic 'GAME_32' "$PATH_GAME"
PKG='PKG_64'
organize_data_generic 'GAME_64' "$PATH_GAME"
PKG='PKG_DATA'
organize_data_generic 'GAME_MAIN' "$PATH_GAME"
organize_data_generic 'DOC' "$PATH_DOC"

if [ "$NO_ICON" = '0' ]; then
	PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
	extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON"
	mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
	mv "$PLAYIT_WORKDIR/icons/${APP_MAIN_ICON%.bmp}.png" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"
fi

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_32'
APP_MAIN_EXE="$APP_MAIN_EXE_32"
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

PKG='PKG_64'
APP_MAIN_EXE="$APP_MAIN_EXE_64"
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

write_metadata 'PKG_32' 'PKG_64' 'PKG_DATA'
build_pkg      'PKG_32' 'PKG_64' 'PKG_DATA'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n'
printf '32-bit:'
print_instructions "$PKG_DATA_PKG" "$PKG_32_PKG"
printf '64-bit:'
print_instructions "$PKG_DATA_PKG" "$PKG_64_PKG"

exit 0
