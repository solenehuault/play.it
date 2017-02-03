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
# Never Alone
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170203.1

# Set game-specific variables

GAME_ID='never-alone'
GAME_NAME='Never Alone'

ARCHIVE_HUMBLE='NeverAlone_ArcticCollection.v1.0.tar.gz'
ARCHIVE_HUMBLE_MD5='fe1ca15db6cfe6c1db877e33ace378fa'
ARCHIVE_HUMBLE_UNCOMPRESSED_SIZE='5000000'
ARCHIVE_HUMBLE_VERSION='1.0-humble1'

ARCHIVE_GAME_PATH='NeverAlone_ArcticCollection'
ARCHIVE_GAME_FILES='./*'

DATA_DIRS='./logs'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='Never_Alone.x64'
APP_MAIN_ICON='Never_Alone_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128x128'

PKG_MAIN_ARCH='64'
PKG_MAIN_DEPS_DEB="libc6, libstdc++6, libglu1-mesa | libglu1, libxcursor1"
PKG_MAIN_DEPS_ARCH="glu libxcursor"

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

set_source_archive 'ARCHIVE_HUMBLE'
check_deps
set_common_paths
PATH_ICON="$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_HUMBLE'
check_deps

# Extract game data

set_workdir 'PKG_MAIN'
extract_data_from "$SOURCE_ARCHIVE"

fix_rights "$PLAYIT_WORKDIR/gamedata"
organize_data

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

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
build_pkg 'PKG_MAIN'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_MAIN_PKG"

exit 0
