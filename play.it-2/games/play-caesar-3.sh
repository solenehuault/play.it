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
# Caesar III
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170108.1

# Set game-specific variables

GAME_ID='caesar-3'
GAME_NAME='Caesar III'

ARCHIVE_GOG='setup_caesar3_2.0.0.9.exe'
ARCHIVE_GOG_MD5='2ee16fab54493e1c2a69122fd2e56635'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='550000'
ARCHIVE_GOG_VERSION='1.1-gog2.0.0.9'

ARCHIVE_DOC1_PATH='tmp'
ARCHIVE_DOC1_FILES='./gog_eula.txt ./eula.txt'
ARCHIVE_DOC2_PATH='app'
ARCHIVE_DOC2_FILES='./readme.txt ./*.pdf'
ARCHIVE_GAME_PATH='app'
ARCHIVE_GAME_FILES='./555 ./smk ./wavs ./*.555 ./*.emp ./*.eng ./*.inf ./*.map ./*.sg2 ./c3.exe ./c3_model.txt ./caesar3.ini ./mission1.pak ./smackw32.dll'

CONFIG_FILES='./caesar3.ini'
DATA_FILES='./c3_model.txt ./status.txt ./*.sav'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='./c3.exe'
APP_MAIN_ICON='./c3.exe'
APP_MAIN_ICON_RES='16x16 32x32'

PKG_MAIN_ARCH='32on64'
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
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG'
check_deps

# Extract game data

set_workdir 'PKG_MAIN'
extract_data_from "$SOURCE_ARCHIVE"

organize_data

extract_and_sort_icons_from 'APP_MAIN'

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
