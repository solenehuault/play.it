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

script_version=20170405.1

# Set game-specific variables

GAME_ID='faster-than-light'
GAME_NAME='Faster Than Light'

ARCHIVE_GOG='gog_ftl_advanced_edition_2.0.0.2.sh'
ARCHIVE_GOG_MD5='2c24b70b31316acefedc082e9441a69a'
ARCHIVE_GOG_SIZE='220000'
ARCHIVE_GOG_VERSION='1.5.13-gog2.0.0.2'

ARCHIVE_HUMBLE='FTL.1.5.13.tar.gz'
ARCHIVE_HUMBLE_MD5='791e0bc8de73fcdcd5f461a4548ea2d8'
ARCHIVE_HUMBLE_SIZE='220000'
ARCHIVE_HUMBLE_VERSION='1.5.13-humble140602'

ARCHIVE_GOG_DOC1_PATH='data/noarch/docs'
ARCHIVE_HUMBLE_DOC1_PATH='FTL'
ARCHIVE_DOC1_FILES='./*.html ./*.txt'

ARCHIVE_GOG_DOC2_PATH='data/noarch/game/data'
ARCHIVE_HUMBLE_DOC2_PATH='FTL/data'
ARCHIVE_DOC2_FILES='./licenses'

ARCHIVE_GOG_GAME_BIN32_PATH='data/noarch/game/data'
ARCHIVE_HUMBLE_GAME_BIN32_PATH='FTL/data'
ARCHIVE_GAME_BIN32_FILES='./x86'

ARCHIVE_GOG_GAME_BIN64_PATH='data/noarch/game/data'
ARCHIVE_HUMBLE_GAME_BIN64_PATH='FTL/data'
ARCHIVE_GAME_BIN64_FILES='./amd64'

ARCHIVE_GOG_GAME_DATA_PATH='data/noarch/game/data'
ARCHIVE_HUMBLE_GAME_DATA_PATH='FTL/data'
ARCHIVE_GAME_DATA_FILES='./exe_icon.bmp ./resources'

APP_MAIN_TYPE='native'
APP_MAIN_32_EXE='x86/bin/FTL'
APP_MAIN_32_LIBS='x86/lib'
APP_MAIN_64_EXE='amd64/bin/FTL'
APP_MAIN_64_LIBS='amd64/lib'

APP_MAIN_ICON1='exe_icon.bmp'
APP_MAIN_ICON1_RES='64x64'
APP_MAIN_ICON2='resources/exe_icon.bmp'
APP_MAIN_ICON2_RES='32x32'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='arch-independant data'

PKG_BIN32_ARCH='32'
PKG_BIN32_CONFLICTS_DEB="$GAME_ID"
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6, libgl1-mesa-glx | libgl1, libsdl1.2debian"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-libgl lib32-sdl"

PKG_BIN64_ARCH='64'
PKG_BIN64_CONFLICTS_DEB="$GAME_ID"
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

set_source_archive 'ARCHIVE_GOG' 'ARCHIVE_HUMBLE'
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG' 'ARCHIVE_HUMBLE'
check_deps

case "$ARCHIVE" in
	('ARCHIVE_GOG')
		ARCHIVE_DOC1_PATH="$ARCHIVE_GOG_DOC1_PATH"
		ARCHIVE_DOC2_FILES="$ARCHIVE_GOG_DOC2_FILES"
		ARCHIVE_GAME_BIN32_PATH="$ARCHIVE_GOG_GAME_BIN32_PATH"
		ARCHIVE_GAME_BIN64_PATH="$ARCHIVE_GOG_GAME_BIN64_PATH"
		ARCHIVE_GAME_DATA_PATH="$ARCHIVE_GOG_GAME_DATA_PATH"
	;;
	('ARCHIVE_HUMBLE')
		ARCHIVE_DOC1_PATH="$ARCHIVE_HUMBLE_DOC1_PATH"
		ARCHIVE_DOC2_FILES="$ARCHIVE_HUMBLE_DOC2_FILES"
		ARCHIVE_GAME_BIN32_PATH="$ARCHIVE_HUMBLE_GAME_BIN32_PATH"
		ARCHIVE_GAME_BIN64_PATH="$ARCHIVE_HUMBLE_GAME_BIN64_PATH"
		ARCHIVE_GAME_DATA_PATH="$ARCHIVE_HUMBLE_GAME_DATA_PATH"
	;;
esac

# Extract game data

set_workdir 'PKG_DATA' 'PKG_BIN32' 'PKG_BIN64'
extract_data_from "$SOURCE_ARCHIVE"
fix_rights "$PLAYIT_WORKDIR/gamedata"

PKG='PKG_BIN32'
organize_data 'GAME_BIN32' "$PATH_GAME"
PKG='PKG_BIN64'
organize_data 'GAME_BIN64' "$PATH_GAME"
PKG='PKG_DATA'
organize_data 'GAME_DATA' "$PATH_GAME"
organize_data 'DOC1' "$PATH_DOC"
organize_data 'DOC2' "$PATH_DOC"

if [ "$NO_ICON" = '0' ]; then

	extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON1"
	PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON1_RES/apps"
	mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
	mv "$PLAYIT_WORKDIR/icons/${APP_MAIN_ICON1%.bmp}.png" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"

	extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON2"
	PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON2_RES/apps"
	mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
	mv "$PLAYIT_WORKDIR/icons/$(basename ${APP_MAIN_ICON2%.bmp}).png" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"

fi

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN32'
APP_MAIN_EXE="$APP_MAIN_32_EXE"
APP_MAIN_LIBS="$APP_MAIN_32_LIBS"
write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

PKG='PKG_BIN64'
APP_MAIN_EXE="$APP_MAIN_64_EXE"
APP_MAIN_LIBS="$APP_MAIN_64_LIBS"
write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

write_metadata 'PKG_DATA' 'PKG_BIN32' 'PKG_BIN64'
build_pkg 'PKG_DATA' 'PKG_BIN32' 'PKG_BIN64'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n32-bit:'
print_instructions "$PKG_DATA_PKG" "$PKG_BIN32_PKG"
printf '\n64-bit:'
print_instructions "$PKG_DATA_PKG" "$PKG_BIN64_PKG"

exit 0
