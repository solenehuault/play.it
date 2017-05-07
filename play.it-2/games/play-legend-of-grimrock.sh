#!/bin/sh
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
# Legend of Grimrock
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170405.1

# Set game-specific variables

GAME_ID='legend-of-grimrock'
GAME_NAME='Legend of Grimrock'

ARCHIVE_GOG='gog_legend_of_grimrock_2.1.0.5.sh'
ARCHIVE_GOG_MD5='b63089766247484f5d2b214d924425f6'
ARCHIVE_GOG_VERSION='1.3.7-gog2.1.0.5'
ARCHIVE_GOG_SIZE='690000'

ARCHIVE_DOC1_PATH='data/noarch/game'
ARCHIVE_DOC1_FILES='./README.linux'

ARCHIVE_DOC2_PATH='data/noarch/docs'
ARCHIVE_DOC2_FILES='./*'

ARCHIVE_GAME_BIN32_PATH='data/noarch/game'
ARCHIVE_GAME_BIN32_FILES='./*.x86 ./lib'

ARCHIVE_GAME_BIN64_PATH='data/noarch/game'
ARCHIVE_GAME_BIN64_FILES='./*.x86_64 ./lib64'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./grimrock.dat ./grimrock.png'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN32='Grimrock.bin.x86'
APP_MAIN_EXE_BIN64='Grimrock.bin.x86_64'
APP_MAIN_ICON='grimrock.png'
APP_MAIN_ICON_RES='256x256'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libgl1-mesa-glx | libgl1, libopenal1, libsdl2-2.0-0, libfreeimage3, libminizip1"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-libgl lib32-openal lib32-sdl2 freeimage minizip"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID libgl openal sdl2 freeimage minizip"

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
file_checksum "$SOURCE_ARCHIVE"
check_deps

# Extract game data

set_workdir 'PKG_BIN32' 'PKG_BIN64' 'PKG_DATA'
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_BIN32'
organize_data 'GAME_BIN32' "$PATH_GAME"

PKG='PKG_BIN64'
organize_data 'GAME_BIN64' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'GAME_DATA' "$PATH_GAME"
organize_data 'DOC1'      "$PATH_DOC"
organize_data 'DOC2'      "$PATH_DOC"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN32'
APP_MAIN_EXE="$APP_MAIN_EXE_BIN32"
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

PKG='PKG_BIN64'
APP_MAIN_EXE="$APP_MAIN_EXE_BIN64"
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"

cat > "$postinst" << EOF
mkdir --parents "$PATH_ICON"
ln --symbolic "$PATH_GAME/$APP_MAIN_ICON" "$PATH_ICON/$GAME_ID.png"
EOF

cat > "$prerm" << EOF
rm "$PATH_GAME/$APP_MAIN_ICON" "$PATH_ICON/$GAME_ID.png"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON"
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_BIN32' 'PKG_BIN64'
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
