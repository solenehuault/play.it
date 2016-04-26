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

script_version=20160425.1

# Set game-specific variables

GAME_ID='lure-of-the-temptress'
GAME_ID_SHORT='lure'
GAME_NAME='Lure of the Temptress'

ARCHIVE1='gog_lure_of_the_temptress_2.0.0.6.sh'
ARCHIVE1_MD5='86d110cf60accee567af61e22657a14f'
ARCHIVE1_TYPE='mojosetup'
ARCHIVE1_UNCOMPRESSED_SIZE='60000'

ARCHIVE2='gog_lure_of_the_temptress_french_2.0.0.6.sh'
ARCHIVE2_MD5='d3f454f2d328b5ac91874e79c0b4b0ca'
ARCHIVE2_TYPE='mojosetup'
ARCHIVE2_UNCOMPRESSED_SIZE='60000'

ARCHIVE_DOC_PATH='data/noarch'
ARCHIVE_DOC_FILES='docs/* data/*.txt'
ARCHIVE_GAME_PATH='data/noarch/data'
ARCHIVE_GAME_FILES='./*'

APP1_ID="${GAME_ID}"
APP1_TYPE='scummvm'
APP1_SCUMMID='lure'
APP1_ICON='data/noarch/support/icon.png'
APP1_ICON_RES='256x256'
APP1_NAME="${GAME_NAME}"
APP1_CAT='Game'

PKG1_ID="${GAME_ID}"
PKG1_ARCH='all'
PKG1_VERSION='1.1-gog2.0.0.6'
PKG1_CONFLICTS=''
PKG1_DEPS='scummvm'
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

PATH_ICON="${PATH_ICON_BASE}/${APP1_ICON_RES}/apps"
mkdir --parents "${PKG_PATH}${PATH_ICON}"
mv "${PLAYIT_WORKDIR}/gamedata/${APP1_ICON}" "${PKG_PATH}${PATH_ICON}/${APP1_ID}.png"

rm --recursive "${PLAYIT_WORKDIR}/gamedata"

# Write launchers

write_app 'APP1'

# Build package

write_metadata 'PKG1'
build_pkg 'PKG1'

# Clean up

rm --recursive "${PLAYIT_WORKDIR}"

exit 0
