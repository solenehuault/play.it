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
# The Elder Scrolls: Arena
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170206.1

# Set game-specific variables

GAME_ID='arena'
GAME_NAME='The Elder Scrolls: Arena'
GAME_IMAGE='.'

ARCHIVE_GOG='setup_tes_arena_2.0.0.5.exe'
ARCHIVE_GOG_MD5='ca5a894aa852f9dbb3ede787e51ec828'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='130000'
ARCHIVE_GOG_VERSION='1.0-gog2.0.0.5'

ARCHIVE_DOC1_PATH='app'
ARCHIVE_DOC1_FILES='./*.pdf'
ARCHIVE_DOC2_PATH='tmp'
ARCHIVE_DOC2_FILES='./gog_eula.txt'
ARCHIVE_GAME_PATH='app'
ARCHIVE_GAME_FILES='./2651.gld ./*.mif ./*.exe ./*.adv ./*.flc ./arena.bat ./*.dat ./*.ico ./arrows.cif ./*.cpy ./*.col ./*.img ./*.65 ./cityintr ./citytxt ./*.inf ./disks.bak ./*.txt ./extra ./*.voc ./*.lgt ./global.bsa ./*.bnk ./*.cfg ./ivb.ntz ./*.rci ./*.cel ./*.mnu ./names.clr ./read.me ./sample.ad ./sample.opl ./speech ./spells.lst ./__support/save ./ultramid.ini ./wingame.xfm'

DATA_DIRS='./save ./arena_cd'

APP_MAIN_TYPE='dosbox'
APP_MAIN_EXE='acd.exe'
APP_MAIN_OPTIONS='-Ssbpdig.adv -IOS220 -IRQS7 -DMAS1 -Mgenmidi.adv -IOM330 -IRQM2 -DMAM1'
APP_MAIN_ICON='goggame-1435828982.ico'
APP_MAIN_ICON_RES='16x16 32x32 48x48 256x256'

PKG_MAIN_DEPS_DEB='dosbox'
PKG_MAIN_DEPS_ARCH='dosbox'

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

sed -i "s/imgmount d $GAME_IMAGE -t iso -fs iso/mount d $GAME_IMAGE -t cdrom\nd:/" "${PKG_MAIN_PATH}${PATH_BIN}/$GAME_ID"

write_desktop 'APP_MAIN'

# Build package

write_metadata 'PKG_MAIN'
build_pkg 'PKG_MAIN'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_MAIN_PKG"

exit 0
