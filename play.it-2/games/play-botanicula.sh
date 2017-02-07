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
# Botanicula
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170206.1

# Set game-specific variables

GAME_ID='botanicula'
GAME_NAME='Botanicula'

ARCHIVE_GOG='gog_botanicula_2.0.0.2.sh'
ARCHIVE_GOG_MD5='7b92a379f8d2749e2f97c43ecc540c3c'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='760000'
ARCHIVE_GOG_VERSION='1.0-gog2.0.0.2'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'
ARCHIVE_GAME_PATH='data/noarch/game'
ARCHIVE_GAME_FILES='./bin ./runtimes'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='bin/adl'
APP_MAIN_OPTIONS='bin/BotaniculaLinux-app.xml'
APP_MAIN_ICON='data/noarch/support/icon.png'
APP_MAIN_ICON_RES='256x256'

PKG_MAIN_ARCH='32on64'
PKG_MAIN_DEPS_DEB='libc6, libstdc++6, libnss3, libgtk2.0-0'
PKG_MAIN_DEPS_ARCH='lib32-nss lib32-gtk2'

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

mkdir --parents "$PKG_MAIN_PATH/$PATH_ICON"
mv "$PLAYIT_WORKDIR/gamedata/$APP_MAIN_ICON" "$PKG_MAIN_PATH/$PATH_ICON/$GAME_ID.png"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

write_metadata 'PKG_MAIN'
build_pkg 'PKG_MAIN'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_MAIN_PKG"

exit 0
