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
# 140
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170329.1

# Set game-specific variables

GAME_ID='140-game'
GAME_NAME='140'

ARCHIVE_GOG='gog_140_2.0.0.1.sh'
ARCHIVE_GOG_MD5='49ec4cff5fa682517e640a2d0eb282c8'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='110000'
ARCHIVE_GOG_VERSION='2.0-gog2.0.0.1'

ARCHIVE_HUMBLE='140_Linux_1389820765.zip'
ARCHIVE_HUMBLE_MD5='e78c09a2a9f47d89a4bb1e4e97911e79'
ARCHIVE_HUMBLE_UNCOMPRESSED_SIZE='92000'
ARCHIVE_HUMBLE_VERSION='1.0-humble1389820765'

ARCHIVE_GAME_BIN32_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_BIN32_PATH_HUMBLE='.'
ARCHIVE_GAME_BIN32_FILES='./140.x86 140_Data/*/x86'

ARCHIVE_GAME_BIN64_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_BIN64_PATH_HUMBLE='.'
ARCHIVE_GAME_BIN64_FILES='./140.x86_64 140_Data/*/x86_64'

ARCHIVE_GAME_DATA_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_DATA_PATH_HUMBLE='.'
ARCHIVE_GAME_DATA_FILES='./140_Data'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_32='140.x86'
APP_MAIN_EXE_64='140.x86_64'
APP_MAIN_ICON='140_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128x128'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRITPION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6, libglu1-mesa | libglu1, libxcursor1"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-glu lib32-alsa-lib lib32-libxcursor"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_DATA_ID glu alsa-lib libxcursor"

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
case "$ARCHIVE" in
	
	('ARCHIVE_GOG')
		ARCHIVE_GAME_BIN32_PATH="$ARCHIVE_GAME_BIN32_PATH_GOG"
		ARCHIVE_GAME_BIN64_PATH="$ARCHIVE_GAME_BIN64_PATH_GOG"
		ARCHIVE_GAME_DATA_PATH="$ARCHIVE_GAME_DATA_PATH_GOG"
	;;
	
	('ARCHIVE_HUMBLE')
		ARCHIVE_GAME_BIN32_PATH="$ARCHIVE_GAME_BIN32_PATH_HUMBLE"
		ARCHIVE_GAME_BIN64_PATH="$ARCHIVE_GAME_BIN64_PATH_HUMBLE"
		ARCHIVE_GAME_DATA_PATH="$ARCHIVE_GAME_DATA_PATH_HUMBLE"
	;;
	
esac
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG' 'ARCHIVE_HUMBLE'
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
organize_data 'DOC'       "$PATH_DOC"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN32'
APP_MAIN_EXE="$APP_MAIN_EXE_32"
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

PKG='PKG_BIN64'
APP_MAIN_EXE="$APP_MAIN_EXE_64"
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"

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
write_metadata 'PKG_BIN32' 'PKG_BIN64'
build_pkg      'PKG_BIN32' 'PKG_BIN64' 'PKG_DATA'

# Clean up

rm --recursive "${PLAYIT_WORKDIR}"

# Print instructions

printf '\n'
printf '32-bit:'
print_instructions "$PKG_DATA_PKG" "$PKG_BIN32_PKG"
printf '64-bit:'
print_instructions "$PKG_DATA_PKG" "$PKG_BIN64_PKG"

exit 0
