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
# Emperor: Rise of the Middle Kingdom
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170210.1

# Set game-specific variables

GAME_ID='emperor-rise-of-the-middle-kingdom'
GAME_NAME='Emperor: Rise of the Middle Kingdom'

ARCHIVE_GOG='setup_emperor_rise_of_the_middle_kingdom_2.0.0.2.exe'
ARCHIVE_GOG_MD5='5e50e84c028a85eafe5dd5f2aa277fea'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='820000'
ARCHIVE_GOG_VERSION='1.0.1.0-gog2.0.0.2'

ARCHIVE_DOC_PATH='app'
ARCHIVE_DOC_FILES='./*.txt ./*.pdf'
ARCHIVE_GAME_BIN_PATH='app'
ARCHIVE_GAME_BIN_FILES='./*.exe ./binkw32.dll ./ijl10.dll ./mss32.dll ./sierrapt.dll'
ARCHIVE_GAME_DATA_PATH='app'
ARCHIVE_GAME_DATA_FILES='./*.cfg ./*.eng ./*.inf ./audio ./binks ./campaigns ./cities ./data ./dragon.ico ./emperor.ini ./model ./mp3dec.asi ./mssds3dh.m3d ./mssrsx.m3d ./res ./save'

CONFIG_FILES='./*.cfg ./*.ini'
DATA_DIRS='./save'

APP_MAIN_TYPE='wine'
APP_MAIN_EXE='emperor.exe'
APP_MAIN_ICON1='emperor.exe'
APP_MAIN_ICON2='dragon.ico'
APP_MAIN_ICON_RES='16x16 32x32'

APP_EDIT_ID="${GAME_ID}_editor"
APP_EDIT_NAME="$GAME_NAME - Editor"
APP_EDIT_TYPE='wine'
APP_EDIT_EXE='emperoredit.exe'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='32on64'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID wine"

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

set_workdir 'PKG_BIN' 'PKG_DATA'
extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_BIN'
organize_data_generic 'GAME_BIN' "$PATH_GAME"

PKG='PKG_DATA'
organize_data_generic 'GAME_DATA' "$PATH_GAME"
organize_data_generic 'DOC'       "$PATH_DOC"

if [ "$NO_ICON" = '0' ]; then
	extract_icon_from "${PKG_BIN_PATH}${PATH_GAME}/$APP_MAIN_ICON1"
	extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON2"
	extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
	rm "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON2"
	rm "$PLAYIT_WORKDIR/icons/$APP_MAIN_ICON1"*32x32*.png
	sort_icons 'APP_MAIN'
	rm --recursive "$PLAYIT_WORKDIR/icons"
fi

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

write_bin     'APP_MAIN' 'APP_EDIT'
write_desktop 'APP_MAIN' 'APP_EDIT'

# Build package

cat > "$postinst" << EOF
for res in $APP_MAIN_ICON_RES; do
	ln --symbolic "$GAME_ID.png" "$PATH_ICON_BASE/\$res/apps/$APP_EDIT_ID.png"
done
EOF

cat > "$prerm" << EOF
for res in $APP_MAIN_ICON_RES; do
	rm "$PATH_ICON_BASE/\$res/apps/$APP_EDIT_ID.png"
done
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_BIN'
build_pkg      'PKG_BIN' 'PKG_DATA'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions "$PKG_DATA_PKG" "$PKG_BIN_PKG"

exit 0
