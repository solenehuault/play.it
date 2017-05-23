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
# conversion script for the Windward installer sold on GOG.com
# build a .deb package from the MojoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161213.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='windward'
GAME_ID_SHORT='windward'
GAME_NAME='Windward'

GAME_ARCHIVE_GOG='gog_windward_2.35.0.38.sh'
GAME_ARCHIVE_GOG_MD5='f5ce09719bf355e48d2eac59b84592d1'
GAME_ARCHIVE_GOG_FULLSIZE='120000'
GAME_ARCHIVE_GOG_TYPE='mojo'
GAME_ARCHIVE_GOG_VERSION='20160707-gog2.35.0.38'

INSTALLER_DOC_PATH='data/noarch/docs'
INSTALLER_DOC_FILES='./*'
INSTALLER_GAME_PATH='data/noarch/game'
INSTALLER_GAME_FILES='./*'

APP_MAIN_ID="${GAME_ID}"
APP_MAIN_EXE='./Windward.x86'
APP_MAIN_ICON='Windward_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128x128'
APP_MAIN_NAME="${GAME_NAME}"
APP_MAIN_NAME_FR="${GAME_NAME}"
APP_MAIN_CAT='Game'

PKG_MAIN_ID="${GAME_ID}"
PKG_MAIN_ARCH='i386'
PKG_MAIN_CONFLICTS=''
PKG_MAIN_DEPS='libc6, libstdc++6, libglu1-mesa | libglu1'
PKG_MAIN_RECS=''
PKG_MAIN_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

# Load common functions

TARGET_LIB_VERSION='1.14'

if [ -z "${PLAYIT_LIB}" ]; then
	PLAYIT_LIB='./play-anything.sh'
fi

if ! [ -e "${PLAYIT_LIB}" ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'play-anything.sh not found.\n'
	printf 'It must be placed in the same directory than this script.\n\n'
	exit 1
fi

LIB_VERSION="$(grep '^# library version' "${PLAYIT_LIB}" | cut -d' ' -f4 | cut -d'.' -f1,2)"

if [ ${LIB_VERSION%.*} -ne ${TARGET_LIB_VERSION%.*} ] || [ ${LIB_VERSION#*.} -lt ${TARGET_LIB_VERSION#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'Wrong version of play-anything.\n'
	printf 'It must be at least %s ' "${TARGET_LIB_VERSION}"
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

check_deps_hard ${SCRIPT_DEPS_HARD}

printf '\n'
GAME_ARCHIVE1="$GAME_ARCHIVE_GOG"
set_target '1' 'gog.com'
ARCHIVE_TYPE="$GAME_ARCHIVE_GOG_TYPE"
GAME_ARCHIVE_MD5="$GAME_ARCHIVE_GOG_MD5"
GAME_ARCHIVE_FULLSIZE="$GAME_ARCHIVE_GOG_FULLSIZE"
PKG_VERSION="$GAME_ARCHIVE_GOG_VERSION"
printf '\n'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG_MAIN_DIR' "${PKG_MAIN_ID}_${PKG_VERSION}_${PKG_MAIN_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DOC="/usr/local/share/doc/${GAME_ID}"
PATH_DESK='/usr/local/share/applications'
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON="/usr/local/share/icons/hicolor/${APP_MAIN_ICON_RES}/apps"

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE_MD5}"
fi

# Extract game data

printf '%s…\n' "$(l10n 'build_pkg_dirs')"

rm -Rf "${PKG_MAIN_DIR}"
for dir in '/DEBIAN' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_GAME}"; do
	mkdir -p "${PKG_MAIN_DIR}${dir}"
done

print wait

extract_data "$ARCHIVE_TYPE" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'fix_rights,quiet'

cd "$PKG_TMPDIR/$INSTALLER_DOC_PATH"
for file in $INSTALLER_DOC_FILES; do
	mv "$file" "${PKG_MAIN_DIR}${PATH_DOC}"
done
cd - > /dev/null

cd "$PKG_TMPDIR/$INSTALLER_GAME_PATH"
for file in $INSTALLER_GAME_FILES; do
	mv "$file" "${PKG_MAIN_DIR}${PATH_GAME}"
done
cd - > /dev/null

chmod 755 "${PKG_MAIN_DIR}${PATH_GAME}/${APP_MAIN_EXE}"

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_native "${PKG_MAIN_DIR}${PATH_BIN}/${APP_MAIN_ID}" "${APP_MAIN_EXE}" '' '' '' "${APP_MAIN_NAME}"
write_desktop "${APP_MAIN_ID}" "${APP_MAIN_NAME}" "${APP_MAIN_NAME_FR}" "${PKG_MAIN_DIR}${PATH_DESK}/${APP_MAIN_ID}.desktop" "${APP_MAIN_CAT}"
printf '\n'

# Build package

write_pkg_debian "${PKG_MAIN_DIR}" "${PKG_MAIN_ID}" "${PKG_VERSION}" "${PKG_MAIN_ARCH}" "${PKG_MAIN_CONFLICTS}" "${PKG_MAIN_DEPS}" "${PKG_MAIN_RECS}" "${PKG_MAIN_DESC}"

file="${PKG_MAIN_DIR}/DEBIAN/postinst"
cat > "${file}" << EOF
#!/bin/sh -e
mkdir -p "$PATH_ICON"
ln -s "$PATH_GAME/$APP_MAIN_ICON" "$PATH_ICON/$APP_MAIN_ID.png"
exit 0
EOF
chmod 755 "${file}"

file="${PKG_MAIN_DIR}/DEBIAN/prerm"
cat > "${file}" << EOF
#!/bin/sh -e
rm "$PATH_ICON/$APP_MAIN_ID.png"
rmdir -p --ignore-fail-on-non-empty "$PATH_ICON"
exit 0
EOF
chmod 755 "${file}"

build_pkg "${PKG_MAIN_DIR}" "${PKG_MAIN_DESC}" "${PKG_COMPRESSION}"

print_instructions "${PKG_MAIN_DESC}" "${PKG_MAIN_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0
