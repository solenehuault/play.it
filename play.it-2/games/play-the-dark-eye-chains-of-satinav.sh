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
# The Dark Eye: Chains of Satinav
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170327.1

# Set game-specific variables

GAME_ID='the-dark-eye-chains-of-satinav'
GAME_NAME='The Dark Eye: Chains of Satinav'

ARCHIVE_GOG='setup_the_dark_eye_chains_of_satinav_2.0.0.4.exe'
ARCHIVE_GOG_MD5='d1c375ba007b7ed6574a16cca823258a'
ARCHIVE_GOG_PART_2='setup_the_dark_eye_chains_of_satinav_2.0.0.4-1.bin'
ARCHIVE_GOG_PART_2_MD5='0c9ea69bdb3e2c66d13f2d27812279b6'
ARCHIVE_GOG_PART_3='setup_the_dark_eye_chains_of_satinav_2.0.0.4-2.bin'
ARCHIVE_GOG_PART_3_MD5='d87f0693751554c1d382f770202e8c45'
ARCHIVE_GOG_PART_4='setup_the_dark_eye_chains_of_satinav_2.0.0.4-3.bin'
ARCHIVE_GOG_PART_4_MD5='ef662b59635829ed4505f6d7272e4bb7'
ARCHIVE_GOG_PART_5='setup_the_dark_eye_chains_of_satinav_2.0.0.4-4.bin'
ARCHIVE_GOG_PART_5_MD5='555d8af3bb598ed4c481e3e3d63b0221'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='5500000'
ARCHIVE_GOG_VERSION='1.0-gog2.0.0.4'
ARCHIVE_GOG_PART_2_TYPE='innosetup'
ARCHIVE_GOG_PART_3_TYPE='innosetup'
ARCHIVE_GOG_PART_4_TYPE='innosetup'
ARCHIVE_GOG_PART_5_TYPE='innosetup'

ARCHIVE_DOC1_PATH='app'
ARCHIVE_DOC1_FILES='./documents/licenses'
ARCHIVE_DOC2_PATH='tmp'
ARCHIVE_DOC2_FILES='./tmp/*.txt'
ARCHIVE_GAME_PATH='app'
ARCHIVE_GAME_FILES='./audiere.dll ./avcodec-53.dll ./avformat-53.dll ./avutil-51.dll ./banner.jpg ./characters ./config.ini ./data.vis ./documents ./folder.jpg ./language.xml ./lua ./satinav.exe ./scenes ./sdl.dll ./swscale-2.dll ./videos ./visionaireconfigurationtool.exe ./zlib1.dll'

CONFIG_FILES='./*.ini ./*.xml'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='./satinav.exe'
APP_MAIN_ICON='./satinav.exe'
APP_MAIN_ICON_RES='16x16 24x24 32x32 48x48 256x256'

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
unset SOURCE_ARCHIVE
set_source_archive 'ARCHIVE_GOG_PART_3'
ARCHIVE_PART_3="$SOURCE_ARCHIVE"
unset SOURCE_ARCHIVE
set_source_archive 'ARCHIVE_GOG_PART_4'
ARCHIVE_PART_4="$SOURCE_ARCHIVE"
unset SOURCE_ARCHIVE
set_source_archive 'ARCHIVE_GOG_PART_5'
ARCHIVE_PART_5="$SOURCE_ARCHIVE"
SOURCE_ARCHIVE="$MAIN_ARCHIVE"

ARCHIVE_UNCOMPRESSED_SIZE="$ARCHIVE_GOG_UNCOMPRESSED_SIZE"
PKG_VERSION="$ARCHIVE_GOG_VERSION"

check_deps
set_common_paths
ARCHIVE='ARCHIVE_GOG'
file_checksum "$SOURCE_ARCHIVE"
ARCHIVE='ARCHIVE_GOG_PART_2'
file_checksum "$ARCHIVE_PART_2"
ARCHIVE='ARCHIVE_GOG_PART_3'
file_checksum "$ARCHIVE_PART_3"
ARCHIVE='ARCHIVE_GOG_PART_4'
file_checksum "$ARCHIVE_PART_4"
ARCHIVE='ARCHIVE_GOG_PART_5'
file_checksum "$ARCHIVE_PART_5"
ARCHIVE='ARCHIVE_GOG'
check_deps

# Extract game data

set_workdir 'PKG_MAIN'

extract_data_from "$SOURCE_ARCHIVE"
tolower "$PLAYIT_WORKDIR/gamedata"

PKG='PKG_MAIN'
organize_data_generic 'GAME' "$PATH_GAME"

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
