#!/bin/sh
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

script_version=20160925.1

# Set game-specific variables

GAME_ID='torchlight'
GAME_ID_SHORT='torch'
GAME_NAME='Torchlight'

ARCHIVE_GOG='setup_torchlight_2.0.0.12.exe'
ARCHIVE_GOG_MD5='4b721e1b3da90f170d66f42e60a3fece'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='460000'

ARCHIVE_DOC_PATH='.'
ARCHIVE_DOC_FILES='app/*.pdf tmp/*eula.txt'
ARCHIVE_GAME_PATH='app'
ARCHIVE_GAME_FILES='./*'

CACHE_DIRS=''
CACHE_FILES=''
CONFIG_DIRS=''
CONFIG_FILES=''
DATA_DIRS=''
DATA_FILES=''

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='./torchlight.exe'
APP_MAIN_ICON='torchlight.ico'
APP_MAIN_ICON_RES='16x16 24x24 32x32 48x48 256x256'

PKG_MAIN_VERSION='1.15-gog2.0.0.12'
PKG_MAIN_ARCH='i386'
PKG_MAIN_DEPS="wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386"
PKG_MAIN_DESC="${GAME_NAME}\n
 package built from GOG.com installer\n
 ./play.it script version ${script_version}"

# Load ./play.it library

target_version='2.0'

if [ -z "$PLAYIT_LIB2" ]; then
	[ -n "$XDG_DATA_HOME" ] || XGD_DATA_HOME="${HOME}/.local/share"
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

set_workdir 'PKG_MAIN'
extract_data_from "$SOURCE_ARCHIVE"

organize_data

if [ "${NO_ICON}" = '0' ]; then
	extract_icon_from "${PKG_MAIN_PATH}${PATH_GAME}/${APP_MAIN_ICON}"
	sort_icons 'APP_MAIN'
	rm --recursive "${PLAYIT_WORKDIR}/icons"
fi

rm --recursive "${PLAYIT_WORKDIR}/gamedata"

# Write launchers

write_bin 'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

write_metadata 'PKG_MAIN'
build_pkg 'PKG_MAIN'

# Clean up

rm --recursive "${PLAYIT_WORKDIR}"

exit 0
