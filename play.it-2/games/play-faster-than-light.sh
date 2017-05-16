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
# Faster Than Light
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170516.1

# Set game-specific variables

GAME_ID='faster-than-light'
GAME_NAME='Faster Than Light'

ARCHIVES_LIST='ARCHIVE_GOG ARCHIVE_HUMBLE'

ARCHIVE_GOG='gog_ftl_advanced_edition_2.0.0.2.sh'
ARCHIVE_GOG_MD5='2c24b70b31316acefedc082e9441a69a'
ARCHIVE_GOG_SIZE='220000'
ARCHIVE_GOG_VERSION='1.5.13-gog2.0.0.2'

ARCHIVE_HUMBLE='FTL.1.5.13.tar.gz'
ARCHIVE_HUMBLE_MD5='791e0bc8de73fcdcd5f461a4548ea2d8'
ARCHIVE_HUMBLE_SIZE='220000'
ARCHIVE_HUMBLE_VERSION='1.5.13-humble140602'

ARCHIVE_DOC1_PATH_GOG='data/noarch/docs'
ARCHIVE_DOC1_PATH_HUMBLE='FTL'
ARCHIVE_DOC1_FILES='./*.html ./*.txt'

ARCHIVE_DOC2_PATH_GOG='data/noarch/game/data'
ARCHIVE_DOC2_PATH_HUMBLE='FTL/data'
ARCHIVE_DOC2_FILES='./licenses'

ARCHIVE_GAME_BIN32_PATH_GOG='data/noarch/game/data'
ARCHIVE_GAME_BIN32_PATH_HUMBLE='FTL/data'
ARCHIVE_GAME_BIN32_FILES='./x86'

ARCHIVE_GAME_BIN64_PATH_GOG='data/noarch/game/data'
ARCHIVE_GAME_BIN64_PATH_HUMBLE='FTL/data'
ARCHIVE_GAME_BIN64_FILES='./amd64'

ARCHIVE_GAME_DATA_PATH_GOG='data/noarch/game/data'
ARCHIVE_GAME_DATA_PATH_HUMBLE='FTL/data'
ARCHIVE_GAME_DATA_FILES='./exe_icon.bmp ./resources'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN32='x86/bin/FTL'
APP_MAIN_EXE_BIN64='amd64/bin/FTL'
APP_MAIN_LIBS_BIN32='x86/lib'
APP_MAIN_LIBS_BIN64='amd64/lib'
APP_MAIN_ICON1='exe_icon.bmp'
APP_MAIN_ICON1_RES='64'
APP_MAIN_ICON2='resources/exe_icon.bmp'
APP_MAIN_ICON2_RES='32'

PACKAGES_LIST='PKG_DATA PKG_BIN32 PKG_BIN64'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6, libgl1-mesa-glx | libgl1, libsdl1.2debian"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-libgl lib32-sdl"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID libgl sdl"

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

PKG='PKG_BIN32'
organize_data 'GAME_BIN32' "$PATH_GAME"

PKG='PKG_BIN64'
organize_data 'GAME_BIN64' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC1'      "$PATH_DOC"
organize_data 'DOC2'      "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON1"
res="$APP_MAIN_ICON1_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"
mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
mv "$PLAYIT_WORKDIR/icons/${APP_MAIN_ICON1%.bmp}.png" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"

extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON2"
res="$APP_MAIN_ICON2_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"
mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
mv "$PLAYIT_WORKDIR/icons/$(basename ${APP_MAIN_ICON2%.bmp}).png" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"

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
print_instructions "$PKG_DATA_PKG" "$PKG_BIN32_PKG"
printf '64-bit:'
print_instructions "$PKG_DATA_PKG" "$PKG_BIN64_PKG"

exit 0
