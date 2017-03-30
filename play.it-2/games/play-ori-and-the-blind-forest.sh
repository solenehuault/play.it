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
# Ori and the Blind Forest
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170326.1

# Set game-specific variables

GAME_ID='ori-and-the-blind-forest'
GAME_NAME='Ori and the Blind Forest'

ARCHIVE_GOG='setup_ori_and_the_blind_forest_de_2.0.0.2-1.bin'
ARCHIVE_GOG_MD5='d5ec4ea264c372a4fdd52b5ecbd9efe6'
ARCHIVE_GOG_PART_2='setup_ori_and_the_blind_forest_de_2.0.0.2-2.bin'
ARCHIVE_GOG_PART_2_MD5='94c3d33701eadca15df9520de55f6f03'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='11000000'
ARCHIVE_GOG_VERSION='1.0-gog2.0.0.2'
ARCHIVE_GOG_TYPE='rar'
ARCHIVE_GOG_PART_2_TYPE='rar'

DATA_FILES='./oride_data/output_log.txt'

ARCHIVE_GAME_PATH='game'
ARCHIVE_GAME_FILES='./oride_data ./oride.exe'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='./oride.exe'
APP_MAIN_ICON='./oride.exe'
APP_MAIN_ICON_RES='16x16 24x24 32x32 48x48 64x64 96x96 128x128 192x192 256x256'

PKG_MAIN_ARCH='32'
PKG_MAIN_DEPS_DEB='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG_MAIN_DEPS_ARCH='wine'

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
MAIN_ARCHIVE="$SOURCE_ARCHIVE"
unset SOURCE_ARCHIVE
set_source_archive 'ARCHIVE_GOG_PART_2'
ARCHIVE_PART_2="$SOURCE_ARCHIVE"
SOURCE_ARCHIVE="$MAIN_ARCHIVE"

check_deps
set_common_paths
ARCHIVE='ARCHIVE_GOG'
file_checksum "$SOURCE_ARCHIVE"
ARCHIVE='ARCHIVE_GOG_PART_2'
file_checksum "$ARCHIVE_PART_2"
ARCHIVE='ARCHIVE_GOG'
check_deps

# Extract game data

set_workdir 'PKG_MAIN'
ln --symbolic "$(readlink -f $SOURCE_ARCHIVE)" "$PLAYIT_WORKDIR/$GAME_ID.r00"
ln --symbolic "$(readlink -f $ARCHIVE_PART_2)" "$PLAYIT_WORKDIR/$GAME_ID.r01"

extract_data_from "$PLAYIT_WORKDIR/$GAME_ID.r00"
tolower "$PLAYIT_WORKDIR/gamedata"

PKG='PKG_MAIN'
organize_data 'GAME' "$PATH_GAME"

if [ "$NO_ICON" = '0' ]; then
	(
		cd "${PKG_MAIN_PATH}${PATH_GAME}"
		extract_icon_from "$APP_MAIN_ICON"
		extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
		sort_icons 'APP_MAIN'
		rm --recursive "$PLAYIT_WORKDIR/icons"
	)
fi

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
