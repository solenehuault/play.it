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
# Bastion
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170425.1

# Set game-specific variables

GAME_ID='bastion'
GAME_NAME='Bastion'

ARCHIVE_GOG='gog_bastion_2.0.0.1.sh'
ARCHIVE_GOG_MD5='e5e6eefb4885b67abcfa201b1b3a9c48'
ARCHIVE_GOG_SIZE='1300000'
ARCHIVE_GOG_VERSION='1.2.20161020-gog2.0.0.1'

ARCHIVE_HUMBLE='bastion-10162016-bin'
ARCHIVE_HUMBLE_MD5='19fea173ff2da0f990f60bd5e7c3b237'
ARCHIVE_HUMBLE_SIZE='1300000'
ARCHIVE_HUMBLE_VERSION='1.2.20161020-humble161019'
ARCHIVE_HUMBLE_TYPE='mojosetup'

ARCHIVE_DOC_PATH_GOG='data/noarch/docs'
ARCHIVE_DOC_PATH_HUMBLE='data'
ARCHIVE_DOC_FILES_GOG='./*'
ARCHIVE_DOC_FILES_HUMBLE='./Linux.README'

ARCHIVE_GAME_BIN32_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_BIN32_PATH_HUMBLE='data'
ARCHIVE_GAME_BIN32_FILES='./Bastion.bin.x86 ./lib'

ARCHIVE_GAME_BIN64_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_BIN64_PATH_HUMBLE='data'
ARCHIVE_GAME_BIN64_FILES='./Bastion.bin.x86_64 ./lib64'

ARCHIVE_GAME_DATA_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_DATA_PATH_HUMBLE='data'
ARCHIVE_GAME_DATA_FILES='./*.config ./*.dll ./*.txt ./Bastion.exe ./Bastion.bmp ./Content ./mono'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN32='Bastion.bin.x86'
APP_MAIN_EXE_BIN64='Bastion.bin.x86_64'
APP_MAIN_ICON='Bastion.bmp'
APP_MAIN_ICON_RES='512x512'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6, libgcc1, libsdl1.2debian"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-glu lib32-gcc-libs"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_DATA_ID glu gcc-libs"

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

set_source_archive 'ARCHIVE_GOG' 'ARCHIVE_HUMBLE'
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE"

# Extract game data

set_workdir 'PKG_DATA' 'PKG_BIN32' 'PKG_BIN64'
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_BIN32'
organize_data 'GAME_BIN32' "$PATH_GAME"

PKG='PKG_BIN64'
organize_data 'GAME_BIN64' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON"
mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
mv "$PLAYIT_WORKDIR/icons/${APP_MAIN_ICON%.bmp}.png" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN32'
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

PKG='PKG_BIN64'
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

write_metadata 'PKG_BIN32' 'PKG_BIN64' 'PKG_DATA'
build_pkg      'PKG_BIN32' 'PKG_BIN64' 'PKG_DATA'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n'
printf '32-bit:'
print_instructions "$PKG_DATA_PKG" "$PKG_BIN32_PKG"
printf '64-bit:'
print_instructions "$PKG_DATA_PKG" "$PKG_BIN64_PKG"

exit 0
