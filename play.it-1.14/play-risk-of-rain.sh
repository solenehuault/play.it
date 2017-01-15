#!/bin/sh -e

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
# conversion script for Risk Of Rain archives sold on HumbleBundle.com and GOG.com
# build a .deb package from the original archives
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170115.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='risk-of-rain'
GAME_ID_SHORT='ror'
GAME_NAME='Risk of Rain'

GAME_ARCHIVE1='Risk_of_Rain_v1.3.0_DRM-Free_Linux_.zip'
GAME_ARCHIVE1_MD5='21eb80a7b517d302478c4f86dd5ea9a2'
GAME_ARCHIVE1_TYPE='zip'
GAME_ARCHIVE1_FULLSIZE='100000'
GAME_ARCHIVE1_VERSION='1.3.0-humble160519'
GAME_ARCHIVE1_DESC="$GAME_NAME
 package built from HumbleBundle.com archive
 ./play.it script version $script_version"

GAME_ARCHIVE2='gog_risk_of_rain_2.1.0.5.sh'
GAME_ARCHIVE2_MD5='34f8e1e2dddc6726a18c50b27c717468'
GAME_ARCHIVE2_TYPE='mojo'
GAME_ARCHIVE2_FULLSIZE='180000'
GAME_ARCHIVE2_VERSION='1.2.8-gog2.1.0.5'
GAME_ARCHIVE2_DESC="$GAME_NAME
 package built from GOG.com installer
 ./play.it script version $script_version"

GAME_ARCHIVE1_INSTALLER_PATH='.'
GAME_ARCHIVE2_INSTALLER_PATH='data/noarch'
GAME_ARCHIVE2_INSTALLER_DOC='docs/*'
GAME_ARCHIVE1_INSTALLER_GAME='./Risk_of_Rain ./assets'
GAME_ARCHIVE2_INSTALLER_GAME='game/*'

APP1_ID="$GAME_ID"
APP1_EXE='./Risk_of_Rain'
APP1_ICON='assets/icon.png'
APP1_ICON_RES='256x256'
APP1_NAME="$GAME_NAME"
APP1_NAME_FR="$GAME_NAME"
APP1_CAT='Game'

PKG1_ID="$GAME_ID"
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='libc6, libstdc++6, libcurl3, libgl1-mesa-glx | libgl1, libopenal1, libssl1.0.0, libxrandr2'
PKG1_RECS=''

# Load common functions

TARGET_LIB_VERSION='1.14'

if [ -z "$PLAYIT_LIB" ]; then
	PLAYIT_LIB='./play-anything.sh'
fi

if ! [ -e "$PLAYIT_LIB" ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'play-anything.sh not found.\n'
	printf 'It must be placed in the same directory than this script.\n\n'
	exit 1
fi

LIB_VERSION="$(grep '^# library version' "$PLAYIT_LIB" | cut -d' ' -f4 | cut -d'.' -f1,2)"

if [ ${LIB_VERSION%.*} -ne ${TARGET_LIB_VERSION%.*} ] || [ ${LIB_VERSION#*.} -lt ${TARGET_LIB_VERSION#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'Wrong version of play-anything.\n'
	printf 'It must be at least %s ' "$TARGET_LIB_VERSION"
	printf 'but lower than %s.\n\n' "$((${TARGET_LIB_VERSION%.*}+1)).0"
	exit 1
fi

. "${PLAYIT_LIB}"

# Set extra variables

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard $SCRIPT_DEPS_HARD

printf '\n'
set_target '2' 'humblebundle.com / gog.com'
case "${GAME_ARCHIVE##*/}" in
	("$GAME_ARCHIVE1")
		GAME_ARCHIVE_MD5="$GAME_ARCHIVE1_MD5"
		GAME_ARCHIVE_FULLSIZE="$GAME_ARCHIVE1_FULLSIZE"
		ARCHIVE_TYPE="$GAME_ARCHIVE1_TYPE"
		PKG1_VERSION="$GAME_ARCHIVE1_VERSION"
		PKG1_DESC="$GAME_ARCHIVE1_DESC"
		INSTALLER_PATH="$GAME_ARCHIVE1_INSTALLER_PATH"
		unset INSTALLER_DOC
		INSTALLER_GAME="$GAME_ARCHIVE1_INSTALLER_GAME"
	;;
	("$GAME_ARCHIVE2")
		GAME_ARCHIVE_MD5="$GAME_ARCHIVE2_MD5"
		GAME_ARCHIVE_FULLSIZE="$GAME_ARCHIVE2_FULLSIZE"
		ARCHIVE_TYPE="$GAME_ARCHIVE2_TYPE"
		PKG1_VERSION="$GAME_ARCHIVE2_VERSION"
		PKG1_DESC="$GAME_ARCHIVE2_DESC"
		INSTALLER_PATH="$GAME_ARCHIVE2_INSTALLER_PATH"
		INSTALLER_DOC="$GAME_ARCHIVE2_INSTALLER_DOC"
		INSTALLER_GAME="$GAME_ARCHIVE2_INSTALLER_GAME"
	;;
esac
printf '\n'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="$PKG_PREFIX/games"
PATH_DESK='/usr/local/share/applications'
PATH_GAME="$PKG_PREFIX}share/games/$GAME_ID"
PATH_ICON_BASE="/usr/local/share/icons/hicolor"

# Check target files integrity

if [ "$GAME_ARCHIVE_CHECKSUM" = 'md5sum' ]; then
	checksum "$GAME_ARCHIVE" 'defaults' "$GAME_ARCHIVE_MD5"
fi

# Extract game data

PATH_ICON="$PATH_ICON_BASE/$APP1_ICON_RES/apps"
build_pkg_dirs '1' "$PATH_BIN" "$PATH_DESK" "$PATH_GAME" "$PATH_ICON"
print wait

extract_data "$ARCHIVE_TYPE" "$GAME_ARCHIVE" "$PKG_TMPDIR" 'fix_rights,quiet'

(
	cd "$PKG_TMPDIR/$INSTALLER_PATH"

	if [ "${GAME_ARCHIVE##*/}" = "$GAME_ARCHIVE2" ]; then
		mkdir -p "${PKG1_DIR}${PATH_DOC}"
		for file in $INSTALLER_DOC; do
			mv "$file" "${PKG1_DIR}${PATH_DOC}"
		done
	fi

	for file in $INSTALLER_GAME; do
		mv "$file" "${PKG1_DIR}${PATH_GAME}"
	done
)

chmod 755 "${PKG1_DIR}${PATH_GAME}/$APP1_EXE"

rm -rf "$PKG_TMPDIR"
print done

# Write launchers

write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "$APP1_EXE" '' '' '' "$APP1_NAME"
write_desktop "$APP1_ID" "$APP1_NAME" "$APP1_NAME_FR" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "$APP1_CAT"
printf '\n'

# Build package

write_pkg_debian "$PKG1_DIR" "$PKG1_ID" "$PKG1_VERSION" "$PKG1_ARCH" "$PKG1_CONFLICTS" "$PKG1_DEPS" "$PKG1_RECS" "$PKG1_DESC"

file="$PKG1_DIR/DEBIAN/postinst"
cat > "$file" << EOF
#!/bin/sh -e
ln -s "${PATH_GAME}/${APP1_ICON}" "${PATH_ICON}/${GAME_ID}.png"
exit 0
EOF
chmod 755 "$file"

file="$PKG1_DIR/DEBIAN/prerm"
cat > "$file" << EOF
#!/bin/sh -e
rm "${PATH_ICON}/${GAME_ID}.png"
exit 0
EOF
chmod 755 "$file"

build_pkg "$PKG1_DIR" "$PKG1_DESC" "$PKG_COMPRESSION"

print_instructions "$PKG1_DESC" "$PKG1_DIR"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
