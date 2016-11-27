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
# prototype script using libplayit2.sh
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161127.1

# Set game-specific variables

GAME_ID='braveland-pirate'
GAME_ID_SHORT='bravelandp'
GAME_NAME='Braveland Pirate'

ARCHIVE_GOG='gog_braveland_pirate_2.1.0.3.sh'
ARCHIVE_GOG_MD5='982331936f2767daf1974c1686ec0bd3'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='610000'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'
ARCHIVE_GAME_32_PATH='data/noarch/game'
ARCHIVE_GAME_32_FILES='./*.x86 ./*_Data/Plugins/x86 ./*_Data/Mono/x86'
ARCHIVE_GAME_64_PATH='data/noarch/game'
ARCHIVE_GAME_64_FILES='./*.x86_64 ./*_Data/Plugins/x86_64 ./*_Data/Mono/x86_64'
ARCHIVE_GAME_MAIN_PATH='data/noarch/game'
ARCHIVE_GAME_MAIN_FILES='./*_Data'

CACHE_DIRS=''
CACHE_FILES=''
CONFIG_DIRS=''
CONFIG_FILES=''
DATA_DIRS=''
DATA_FILES=''

APP_MAIN_TYPE='native'
APP_MAIN_EXE_32='./Braveland Pirate.x86'
APP_MAIN_EXE_64='./Braveland Pirate.x86_64'
APP_MAIN_ICON='*_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128x128'

PKG_MAIN_ID="${GAME_ID}-common"
PKG_MAIN_VERSION='1.1.1.11-gog2.1.0.4'
PKG_MAIN_ARCH_DEB='all'
PKG_MAIN_ARCH_ARCH='any'
PKG_MAIN_DEPS_DEB=''
PKG_MAIN_DEPS_ARCH=''
PKG_MAIN_DESC="${GAME_NAME} - arch-independant data\n
 package built from GOG.com installer\n
 ./play.it script version ${script_version}"

PKG_32_VERSION="${PKG_MAIN_VERSION}"
PKG_32_ARCH_DEB='i386'
PKG_32_ARCH_ARCH='i686'
PKG_32_DEPS_DEB="$PKG_MAIN_ID, libc6, libstdc++6, libglu | libglu1"
PKG_32_DEPS_ARCH="$PKG_MAIN_ID glu"
PKG_32_DESC="${GAME_NAME}\n
 package built from GOG.com installer\n
 ./play.it script version ${script_version}"

PKG_64_VERSION="${PKG_MAIN_VERSION}"
PKG_64_ARCH_DEB='amd64'
PKG_64_ARCH_ARCH='x86_64'
PKG_64_DEPS_DEB="$PKG_MAIN_ID, libc6, libstdc++6, libglu | libglu1"
PKG_64_DEPS_ARCH="$PKG_MAIN_ID glu"
PKG_64_DESC="${GAME_NAME}\n
 package built from GOG.com installer\n
 ./play.it script version ${script_version}"

PKG_32_CONFLICTS_DEB="${PKG_64_ID}:${PKG_64_ARCH_DEB}"
PKG_64_CONFLICTS_DEB="${PKG_32_ID}:${PKG_32_ARCH_DEB}"
 
# Load common functions

target_version='2.0'

if [ -z "${PLAYIT_LIB2}" ]; then
	[ -n "$XDG_DATA_HOME" ] || XDG_DATA_HOME="${HOME}/.local/share"
	if [ -e "${XDG_DATA_HOME}/play.it/libplayit2.sh" ]; then
		PLAYIT_LIB2="${XDG_DATA_HOME}/play.it/libplayit2.sh"
	elif [ -e './libplayit2.sh' ]; then
		PLAYIT_LIB2='./libplayit2.sh'
	else
		echo '\n\033[1;31mError:\033[0m\nlibplayit2.sh not found.\n'
		return 1
	fi
fi
. "$PLAYIT_LIB2"

if [ ${library_version%.*} -ne ${target_version%.*} ] || [ ${library_version#*.} -lt ${target_version#*.} ]; then
	echo "\n\033[1;31mError:\033[0m\nwrong version of libplayit2.sh\ntarget version is: ${target_version}"
	return 1
fi

# Set extra variables

set_common_defaults
fetch_args "$@"

# Set source archive

set_source_archive 'ARCHIVE_GOG'
check_deps
set_common_paths
if [ -n "$ARCHIVE" ]; then
	file_checksum "$SOURCE_ARCHIVE" "$ARCHIVE"
else
	file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG'
fi
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

PATH_ICON="$PKG_MAIN_PATH$PATH_ICON_BASE/$APP_MAIN_ICON_RES/apps"
mkdir --parents "${PATH_ICON}"
cd "$PATH_ICON"
ln --symbolic "$PATH_GAME/$APP_MAIN_ICON" "./$GAME_ID.png"
cd - > /dev/null

rm --recursive "${PLAYIT_WORKDIR}/gamedata"

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

write_metadata 'PKG_MAIN' 'PKG_32' 'PKG_64'
build_pkg 'PKG_MAIN' 'PKG_32' 'PKG_64'

# Clean up

rm --recursive "${PLAYIT_WORKDIR}"

exit 0
