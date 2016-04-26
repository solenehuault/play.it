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

script_version=20160426.1

# Set game-specific variables

GAME_ID='torchlight'
GAME_ID_SHORT='torch'
GAME_NAME='Torchlight'

ARCHIVE1='setup_torchlight_2.0.0.12.exe'
ARCHIVE1_MD5='4b721e1b3da90f170d66f42e60a3fece'
ARCHIVE1_TYPE='innosetup'
ARCHIVE1_UNCOMPRESSED_SIZE='460000'

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

APP1_ID="${GAME_ID}"
APP1_TYPE='wine'
APP1_EXE='./torchlight.exe'
APP1_ICON='torchlight.ico'
APP1_ICON_RES='16x16 24x24 32x32 48x48 256x256'
APP1_NAME="${GAME_NAME}"
APP1_CAT='Game'

PKG1_ID="${GAME_ID}"
PKG1_VERSION='1.15-gog2.0.0.12'
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS="wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386"
PKG1_DESC="${GAME_NAME}\n
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

find_source_archive 'ARCHIVE1' 'ARCHIVE2'

# Extract game data

set_workdir 'PKG1'
extract_data_from "$SOURCE_ARCHIVE"

organize_data

if [ "${NO_ICON}" = '0' ]; then
	extract_icon_from "${PKG1_PATH}${PATH_GAME}/${APP1_ICON}"
	sort_icons 'APP1'
	rm --recursive "${PLAYIT_WORKDIR}/icons"
fi

rm --recursive "${PLAYIT_WORKDIR}/gamedata"

# Write launchers

write_app 'APP1'

# Build package

write_metadata 'PKG1'
build_pkg 'PKG1'

# Clean up

rm --recursive "${PLAYIT_WORKDIR}"

exit 0
