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
# Braveland Wizard
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161218.1

# Set game-specific variables

GAME_ID='braveland-wizard'
GAME_NAME='Braveland Wizard'

ARCHIVE_GOG='gog_braveland_wizard_2.1.0.4.sh'
ARCHIVE_GOG_MD5='14346dc8d6e7ad410dd1b179763aa94e'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='450000'
ARCHIVE_GOG_VERSION='1.1.1.11-gog2.1.0.4'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'
ARCHIVE_GAME_32_PATH='data/noarch/game'
ARCHIVE_GAME_32_FILES='./*.x86 ./*_Data/*/x86'
ARCHIVE_GAME_64_PATH='data/noarch/game'
ARCHIVE_GAME_64_FILES='./*.x86_64 ./*_Data/*/x86_64'
ARCHIVE_GAME_MAIN_PATH='data/noarch/game'
ARCHIVE_GAME_MAIN_FILES='./*_Data'

DATA_DIRS='./logs'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_32='./Braveland Wizard.x86'
APP_MAIN_EXE_64='./Braveland Wizard.x86_64'
APP_MAIN_OPTIONS='-logFile ./logs/$(date +%F-%R).log'
APP_MAIN_ICON='*_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128x128'

PKG_MAIN_ID="${GAME_ID}-common"
PKG_MAIN_ARCH_DEB='all'
PKG_MAIN_ARCH_ARCH='any'
PKG_MAIN_DESC_DEB="$GAME_NAME - arch-independant data\n
 ./play.it script version $script_version"
PKG_MAIN_DESC_ARCH="$GAME_NAME - arch-independant data - ./play.it script version $script_version"

PKG_32_ARCH_DEB='i386'
PKG_32_ARCH_ARCH='i686'
PKG_32_DEPS_DEB="$PKG_MAIN_ID, libc6, libstdc++6, libglu | libglu1"
PKG_32_DEPS_ARCH="$PKG_MAIN_ID glu"
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

set_source_archive 'ARCHIVE_GOG'
check_deps
set_common_paths
PATH_ICON="$PKG_MAIN_PATH$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG'
check_deps

# Extract game data

set_workdir 'PKG_MAIN' 'PKG_32' 'PKG_64'
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_32'
organize_data_generic 'GAME_32' "$PATH_GAME"
PKG='PKG_64'
organize_data_generic 'GAME_64' "$PATH_GAME"
PKG='PKG_MAIN'
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

write_metadata 'PKG_MAIN'
rm "$postinst" "$prerm"
write_metadata 'PKG_32' 'PKG_64'
build_pkg 'PKG_MAIN' 'PKG_32' 'PKG_64'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n32-bit:'
print_instructions "$PKG_MAIN_PKG" "$PKG_32_PKG"
printf '\n64-bit:'
print_instructions "$PKG_MAIN_PKG" "$PKG_64_PKG"

exit 0
