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
# The Settlers 2
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161230.1

# Set game-specific variables

GAME_ID='the-settlers-2'
GAME_NAME='The Settlers II'

ARCHIVE_GOG_EN='setup_settlers2_gold_2.0.0.14.exe'
ARCHIVE_GOG_EN_MD5='6f64b47b15f6ba5d43670504dd0bb229'
ARCHIVE_GOG_EN_VERSION='1.51-gog2.0.0.14'
ARCHIVE_GOG_EN_UNCOMPRESSED_SIZE='370000'

ARCHIVE_GOG_FR='setup_settlers2_gold_french_2.1.0.16.exe'
ARCHIVE_GOG_FR_MD5='1eca72ca45d63e4390590d495657d213'
ARCHIVE_GOG_FR_VERSION='1.51-gog2.1.0.16'
ARCHIVE_GOG_FR_UNCOMPRESSED_SIZE='410000'

ARCHIVE_GOG_DE='setup_settlers2_gold_german_2.1.0.17.exe'
ARCHIVE_GOG_DE_MD5='2a0b5292c82b0d4c8f2cafe53a20ba5e'
ARCHIVE_GOG_DE_VERSION='1.51-gog2.1.0.17'
ARCHIVE_GOG_DE_UNCOMPRESSED_SIZE='370000'

ARCHIVE_DOC1_PATH='tmp'
ARCHIVE_DOC1_FILES='./*eula.txt'
ARCHIVE_DOC2_PATH='app'
ARCHIVE_DOC2_FILES='./eula ./*.txt'
ARCHIVE_GAME_BIN_PATH='app'
ARCHIVE_GAME_BIN_FILES='./dos4gw.exe ./s2edit.exe ./s2.exe ./setup.exe ./setup.ini video/smackply.exe'
ARCHIVE_GAME_IMAGE_PATH='app'
ARCHIVE_GAME_IMAGE_FILES='./settlers2.gog ./settlers2.inst'
ARCHIVE_GAME_DATA1_PATH='app'
ARCHIVE_GAME_DATA1_FILES='./data ./drivers ./gfx ./video ./gfw_high.ico ./goggame-1207658786.ico ./install.scr ./settler2.vmc save/mission.dat'
ARCHIVE_GAME_DATA2_PATH='app/__support/save'
ARCHIVE_GAME_DATA2_FILES='save/mission.dat'

CONFIG_FILES='./setup.ini'
DATA_DIRS='./data ./gfx ./save ./worlds'

GAME_IMAGE='settlers2.inst'

APP_MAIN_TYPE='dosbox'
APP_MAIN_EXE='s2.exe'
APP_MAIN_PRERUN='@video\smackply video\intro.smk'
APP_MAIN_EN_ICON='gfw_high.ico'
APP_MAIN_FR_ICON='goggame-1207658786.ico'
APP_MAIN_DE_ICON='goggame-1207658786.ico'
APP_MAIN_ICON_RES='16x16 32x32 48x48 256x256'

APP_EDITOR_TYPE='dosbox'
APP_EDITOR_ID="${GAME_ID}_edit"
APP_EDITOR_EXE='s2edit.exe'
APP_EDITOR_NAME="$GAME_NAME - Editor"

APP_SETUP_TYPE='dosbox'
APP_SETUP_ID="${GAME_ID}_setup"
APP_SETUP_EXE='setup.exe'
APP_SETUP_NAME="$GAME_NAME - Setup"
APP_SETUP_CAT='Settings'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_ARCH_DEB='all'
PKG_DATA_ARCH_ARCH='any'
PKG_DATA_DESCRIPTION='data'

PKG_IMAGE_ID="${GAME_ID}-image"
PKG_IMAGE_ARCH_DEB='all'
PKG_IMAGE_ARCH_ARCH='any'
PKG_IMAGE_DESCRIPTION='disk image'

PKG_BIN_ARCH_DEB='all'
PKG_BIN_ARCH_ARCH='any'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, $PKG_IMAGE_ID, dosbox"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID $PKG_IMAGE_ID dosbox"

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

set_source_archive 'ARCHIVE_GOG_EN' 'ARCHIVE_GOG_FR' 'ARCHIVE_GOG_DE'
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE" 'ARCHIVE_GOG_EN' 'ARCHIVE_GOG_FR' 'ARCHIVE_GOG_DE'
check_deps

case "$ARCHIVE" in
	('ARCHIVE_GOG_EN')
		APP_MAIN_ICON="$APP_MAIN_EN_ICON"
	;;
	('ARCHIVE_GOG_FR')
		APP_MAIN_ICON="$APP_MAIN_FR_ICON"
	;;
	('ARCHIVE_GOG_DE')
		APP_MAIN_ICON="$APP_MAIN_DE_ICON"
	;;
esac

# Extract game data

set_workdir 'PKG_BIN' 'PKG_DATA' 'PKG_IMAGE'
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_BIN'
organize_data_generic 'GAME_BIN' "$PATH_GAME"

PKG='PKG_IMAGE'
organize_data_generic 'GAME_IMAGE' "$PATH_GAME"

PKG='PKG_DATA'
organize_data_generic 'GAME_DATA1' "$PATH_GAME"
organize_data_generic 'GAME_DATA2' "$PATH_GAME"
organize_data_generic 'DOC1'       "$PATH_DOC"
organize_data_generic 'DOC2'       "$PATH_DOC"

sed -i 's/SETTLERS2.gog/settlers2.gog/' "${PKG_IMAGE_PATH}${PATH_GAME}/$GAME_IMAGE"

if [ "$NO_ICON" = '0' ]; then
	extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON"
	extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
	sort_icons 'APP_MAIN'
	rm --recursive "$PLAYIT_WORKDIR/icons"
fi
rm "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_bin     'APP_MAIN' 'APP_EDITOR' 'APP_SETUP'
write_desktop 'APP_MAIN' 'APP_EDITOR' 'APP_SETUP'

# Build package

cat > "$postinst" << EOF
for res in $APP_MAIN_ICON_RES; do
	cd $PATH_ICON_BASE/\$res/apps
	ln --symbolic $GAME_ID.png $APP_EDITOR_ID.png
	ln --symbolic $GAME_ID.png $APP_SETUP_ID.png
done
EOF

cat > "$prerm" << EOF
for res in $APP_MAIN_ICON_RES; do
	cd $PATH_ICON_BASE/\$res/apps
	rm $APP_EDITOR_ID.png
	rm $APP_SETUP_ID.png
done
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_BIN' 'PKG_IMAGE'

build_pkg 'PKG_BIN' 'PKG_DATA' 'PKG_IMAGE'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_DATA_PKG" "$PKG_IMAGE_PKG" "$PKG_BIN_PKG"

exit 0
