#!/bin/sh
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
# Sunless Sea + Zubmariner
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170312.1

# Set game-specific variables

GAME_ID='sunless-sea'
GAME_NAME='Sunless Sea'

ARCHIVE_GOG='gog_sunless_sea_2.8.0.11.sh'
ARCHIVE_GOG_MD5='1cf6bb7a440ce796abf8e7afcb6f7a54'
ARCHIVE_GOG_VERSION='2.2.2.3129-gog2.8.0.11'
ARCHIVE_GOG_UNCOMPRESSED_SIZE='700000'

ARCHIVE_HUMBLE='Sunless_Sea_Setup_V2.2.2.3129_LINUX.zip'
ARCHIVE_HUMBLE_MD5='bdb37932e56fd0655a2e4263631e2582'
ARCHIVE_HUMBLE_VERSION='2.2.2.3129-humble170131'
ARCHIVE_HUMBLE_UNCOMPRESSED_SIZE='700000'

ARCHIVE_DLC1_GOG='gog_sunless_sea_zubmariner_2.5.0.6.sh'
ARCHIVE_DLC1_GOG_MD5='692cd0dac832d5254bd38d7e1a05b918'
ARCHIVE_DLC1_GOG_VERSION='2.2.2.3130-gog2.5.0.6'

ARCHIVE_DOC_PATH_GOG='data/noarch/game'
ARCHIVE_DOC_PATH_HUMBLE='data/noarch'
ARCHIVE_DOC_FILES='./README.linux'

ARCHIVE_DOC2_PATH_GOG='data/noarch/docs'
ARCHIVE_DOC2_FILES_GOG='./*'

ARCHIVE_GAME_BIN32_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_BIN32_PATH_HUMBLE1='data/x86'
ARCHIVE_GAME_BIN32_PATH_HUMBLE2='data/noarch'
ARCHIVE_GAME_BIN32_FILES='./*.x86 ./*_Data/*/x86'

ARCHIVE_GAME_BIN64_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_BIN64_PATH_HUMBLE1='data/x86_64'
ARCHIVE_GAME_BIN64_PATH_HUMBLE2='data/noarch'
ARCHIVE_GAME_BIN64_FILES='./*.x86_64 ./*_Data/*/x86_64'

ARCHIVE_GAME_DATA_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_DATA_PATH_HUMBLE='data/noarch'
ARCHIVE_GAME_DATA_FILES='./*'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN32='./Sunless Sea.x86'
APP_MAIN_EXE_BIN64='./Sunless Sea.x86_64'
APP_MAIN_ICON1='Sunless Sea_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON1_RES='128x128'
APP_MAIN_ICON2='./Icon.png'
APP_MAIN_ICON2_RES='256x256'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libglu1-mesa | libglu1, libxcursor1"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-glu lib32-libxcursor"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_DATA_ID glu libxcursor"

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

set_source_archive 'ARCHIVE_GOG' 'ARCHIVE_HUMBLE'
if [ "$ARCHIVE" = 'ARCHIVE_GOG' ]; then
	set_archive 'ARCHIVE_DLC1' "$ARCHIVE_DLC1_GOG"
fi
check_deps
set_common_paths
file_checksum "$SOURCE_ARCHIVE"
if [ "$ARCHIVE_DLC1" ]; then
	ARCHIVE_REAL="$ARCHIVE"
	ARCHIVE='ARCHIVE_DLC1_GOG'
	file_checksum "$ARCHIVE_DLC1"
	PKG_VERSION="$ARCHIVE_DLC1_GOG_VERSION"
	ARCHIVE="$ARCHIVE_REAL"
fi
check_deps

case "$ARCHIVE" in
	('ARCHIVE_GOG')
		ARCHIVE_DOC_PATH="$ARCHIVE_DOC_PATH_GOG"
		ARCHIVE_DOC2_PATH="$ARCHIVE_DOC2_PATH_GOG"
		ARCHIVE_DOC2_FILES="$ARCHIVE_DOC2_FILES_GOG"
		ARCHIVE_GAME_BIN32_PATH="$ARCHIVE_GAME_BIN32_PATH_GOG"
		ARCHIVE_GAME_BIN64_PATH="$ARCHIVE_GAME_BIN64_PATH_GOG"
		ARCHIVE_GAME_DATA_PATH="$ARCHIVE_GAME_DATA_PATH_GOG"
	;;
	('ARCHIVE_HUMBLE')
		ARCHIVE_DOC_PATH="$ARCHIVE_DOC_PATH_HUMBLE"
		unset ARCHIVE_DOC2_PATH
		unset ARCHIVE_DOC2_FILES
		ARCHIVE_GAME_BIN32_PATH="$ARCHIVE_GAME_BIN32_PATH_HUMBLE1"
		ARCHIVE_GAME_BIN64_PATH="$ARCHIVE_GAME_BIN64_PATH_HUMBLE1"
		ARCHIVE_GAME_DATA_PATH="$ARCHIVE_GAME_DATA_PATH_HUMBLE"
	;;
esac

# Extract game data

set_workdir 'PKG_BIN32' 'PKG_BIN64' 'PKG_DATA'
extract_data_from "$SOURCE_ARCHIVE"
if [ "$ARCHIVE" = 'ARCHIVE_HUMBLE' ]; then
	ARCHIVE_HUMBLE_TYPE='mojosetup'
	archive="$PLAYIT_WORKDIR/gamedata/Sunless Sea.sh"
	extract_data_from "$archive"
	rm "$archive"
fi
if [ "$ARCHIVE_DLC1" ]; then
	extract_data_from "$ARCHIVE_DLC1"
fi

PKG='PKG_BIN32'
organize_data_generic 'GAME_BIN32' "$PATH_GAME"
if [ "$ARCHIVE" = 'ARCHIVE_HUMBLE' ]; then
	ARCHIVE_GAME_BIN32_PATH="$ARCHIVE_GAME_BIN32_PATH_HUMBLE2"
	organize_data_generic 'GAME_BIN32' "$PATH_GAME"
fi

PKG='PKG_BIN64'
organize_data_generic 'GAME_BIN64' "$PATH_GAME"
if [ "$ARCHIVE" = 'ARCHIVE_HUMBLE' ]; then
	ARCHIVE_GAME_BIN64_PATH="$ARCHIVE_GAME_BIN64_PATH_HUMBLE2"
	organize_data_generic 'GAME_BIN64' "$PATH_GAME"
fi

PKG='PKG_DATA'
organize_data_generic 'GAME_DATA' "$PATH_GAME"
organize_data_generic 'DOC'       "$PATH_DOC"
organize_data_generic 'DOC2'      "$PATH_DOC"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN32'
APP_MAIN_EXE="$APP_MAIN_EXE_BIN32"
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

PKG='PKG_BIN64'
APP_MAIN_EXE="$APP_MAIN_EXE_BIN64"
write_bin     'APP_MAIN'
write_desktop 'APP_MAIN'

# Build package

cat > "$postinst" << EOF
mkdir --parents "$PATH_ICON_BASE/$APP_MAIN_ICON1_RES/apps"
mkdir --parents "$PATH_ICON_BASE/$APP_MAIN_ICON2_RES/apps"
ln --symbolic "$PATH_GAME/$APP_MAIN_ICON1" "$PATH_ICON_BASE/$APP_MAIN_ICON1_RES/apps/$GAME_ID.png"
ln --symbolic "$PATH_GAME/$APP_MAIN_ICON2" "$PATH_ICON_BASE/$APP_MAIN_ICON2_RES/apps/$GAME_ID.png"
EOF

cat > "$prerm" << EOF
rm "$PATH_ICON_BASE/$APP_MAIN_ICON1_RES/apps/$GAME_ID.png"
rm "$PATH_ICON_BASE/$APP_MAIN_ICON2_RES/apps/$GAME_ID.png"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON_BASE/$APP_MAIN_ICON1_RES/apps"
rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON_BASE/$APP_MAIN_ICON2_RES/apps"
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_BIN32' 'PKG_BIN64'
build_pkg      'PKG_BIN32' 'PKG_BIN64' 'PKG_DATA'

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n'
printf '32-bit:'
print_instructions "$PKG_DATA_PKG" "$PKG_BIN32_PKG"
printf '64-bit:'
print_instructions "$PKG_DATA_PKG" "$PKG_BIN64_PKG"

exit 0
