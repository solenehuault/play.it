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
# Lovers in a Dangerous Spacetime
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161218.2

# Set game-specific variables

GAME_ID='lovers-in-a-dangerous-spacetime'
GAME_NAME='Lovers in a Dangerous Spacetime'

ARCHIVE_HUMBLE='LoversInADangerousSpacetime-1.4.4_Linux.zip'
ARCHIVE_HUMBLE_MD5='38927a73e1fe84620ebc876f8f039adb'
ARCHIVE_HUMBLE_UNCOMPRESSED_SIZE='880000'
ARCHIVE_HUMBLE_VERSION='1.4.4-humble160908'

ARCHIVE_GAME_32_PATH='.'
ARCHIVE_GAME_32_FILES='./*.x86 ./*_Data/*/x86'
ARCHIVE_GAME_64_PATH='.'
ARCHIVE_GAME_64_FILES='./*.x86_64 ./*_Data/*/x86_64'
ARCHIVE_GAME_MAIN_PATH='.'
ARCHIVE_GAME_MAIN_FILES='./*_Data'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_32='./LoversInADangerousSpacetime.x86'
APP_MAIN_EXE_64='./LoversInADangerousSpacetime.x86_64'
APP_MAIN_ICON='*_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128x128'

PKG_COMMON_ID="${GAME_ID}-common"
PKG_COMMON_ARCH_DEB='all'
PKG_COMMON_ARCH_ARCH='any'
PKG_COMMON_DESC_DEB="$GAME_NAME - arch-independant data\n
 ./play.it script version $script_version"
PKG_COMMON_DESC_ARCH="$GAME_NAME - arch-independant data - ./play.it script version $script_version"

PKG_32_ARCH_DEB='i386'
PKG_32_ARCH_ARCH='i686'
PKG_32_DEPS_DEB="$PKG_COMMON_ID, libc6, libstdc++6, libgl1-mesa-glx | libgl1, libxcursor1"
PKG_32_DEPS_ARCH="$PKG_COMMON_ID libgl libxcursor"
PKG_32_DESC_DEB="$GAME_NAME\n
 ./play.it script version $script_version"
PKG_32_DESC_ARCH="$GAME_NAME - ./play.it script version $script_version"

PKG_64_ARCH_DEB='amd64'
PKG_64_ARCH_ARCH='x86_64'
PKG_64_DEPS_DEB="$PKG_32_DEPS_DEB"
PKG_64_DEPS_ARCH="$PKG_32_DEPS_ARCH"
PKG_64_DESC_DEB="$PKG_32_DESC_DEB"
PKG_64_DESC_ARCH="$PKG_32_DESC_ARCH"

PKG_32_CONFLICTS_DEB="${GAME_ID}:${PKG_64_ARCH_DEB}"
PKG_64_CONFLICTS_DEB="${GAME_ID}:${PKG_32_ARCH_DEB}"
 
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

set_workdir 'PKG_COMMON' 'PKG_32' 'PKG_64'
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_32'
organize_data_generic 'GAME_32' "$PATH_GAME"
PKG='PKG_64'
organize_data_generic 'GAME_64' "$PATH_GAME"
PKG='PKG_COMMON'
organize_data_generic 'GAME_MAIN' "$PATH_GAME"
organize_data_generic 'DOC' "$PATH_DOC"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_32'
APP_MAIN_EXE="$APP_MAIN_EXE_32"
write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

PKG='PKG_64'
APP_MAIN_EXE="$APP_MAIN_EXE_64"
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

write_metadata 'PKG_COMMON'
rm "$postinst" "$prerm"
write_metadata 'PKG_32' 'PKG_64'
build_pkg 'PKG_COMMON' 'PKG_32' 'PKG_64'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n32-bit:'
print_instructions "$PKG_COMMON_PKG" "$PKG_32_PKG"
printf '\n64-bit:'
print_instructions "$PKG_COMMON_PKG" "$PKG_64_PKG"

exit 0
