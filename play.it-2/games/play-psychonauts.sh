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
# Psychonauts
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170215.1

# Set game-specific variables

GAME_ID='psychonauts'
GAME_NAME='Psychonauts'

ARCHIVE_GOG='gog_psychonauts_2.0.0.3.sh'
ARCHIVE_GOG_MD5='8bf1bd92e7784adce2fb952fdde7fdb5'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='52000000'
ARCHIVE_GOG_VERSION='1.04-gog2.0.0.3'
ARCHIVE_GOG_TYPE='mojosetup_unzip'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'
ARCHIVE_DOC2_PATH='data/noarch/game/'
ARCHIVE_DOC2_FILES='./Documents/*'
ARCHIVE_GAME_PATH='data/noarch/game'
ARCHIVE_GAME_FILES='./*'

CONFIG_FILES='./DisplaySettings.ini ./psychonauts.ini'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='Psychonauts'
APP_MAIN_ICON='./psychonauts.png'
APP_MAIN_ICON_RES='512x512'

PKG_MAIN_ARCH='32on64'
PKG_MAIN_DEPS_DEB='libc6, libglu1-mesa | libglu1, libstdc++6, libxcursor1, libxrandr2'
PKG_MAIN_DEPS_ARCH='lib32-glu lib32-libxcursor lib32-libxrandr'

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

set_workdir 'PKG_MAIN'
extract_data_from "$SOURCE_ARCHIVE"

organize_data

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_MAIN'
write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

cat > "$postinst" << EOF
mkdir --parents "$PATH_ICON"
ln --symbolic "$PATH_GAME"/$APP_MAIN_ICON "$PATH_ICON/$GAME_ID.png"
EOF

cat > "$prerm" << EOF
rm "$PATH_ICON/$GAME_ID.png"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON"
EOF

write_metadata 'PKG_MAIN'
rm "$postinst" "$prerm"
build_pkg 'PKG_MAIN'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_MAIN_PKG"

exit 0
