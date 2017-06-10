#!/bin/sh -e

###
# Copyright (c) 2015, Antoine Le Gonidec
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
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
###

###
# conversion script for the To The Moon installer sold on HumbleBundle.com
# build a .deb package from the .sh installer
# tested on Debian, should work on any .deb-based distribution
#
# script version 20150808.1
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

# Setting game-specific variables
GAME_ID='to-the-moon'
GAME_ARCHIVE1='ToTheMoon_linux_1389114090.sh'
GAME_ARCHIVE1_MD5='706a5c9467328438d412370ffb1454de'
GAME_FULL_SIZE='92232'
APP1_ID="${GAME_ID}"
APP1_EXE_ARCH1='./ToTheMoon.bin.x86'
APP1_EXE_ARCH2='./ToTheMoon.bin.x86_64'
APP1_ICON='./ToTheMoon.png'
APP1_ICON_RES='32x32'
APP1_NAME='To The Moon'
APP1_CAT='Game'
PKG_ID="${GAME_ID}"
PKG_VERSION='1.0'
PKG_ORIGIN='humblebundle'
PKG_REVISION='1389114090'
PKG_DEPS='libasound2-plugins, libfreetype6, libgl1-mesa-glx | libgl1, libsdl2-2.0-0'
PKG_DESC='To The Moon'
PKG1_ARCH='i386'
PKG2_ARCH='amd64'
PKG1_CONFLICTS="${PKG_ID}:${PKG2_ARCH}"
PKG2_CONFLICTS="${PKG_ID}:${PKG1_ARCH}"

# Setting extra variables
PKG_PREFIX_DEFAULT='/usr/local'
PKG_COMPRESSION_DEFAULT='none'
GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
if [ $(df --output=avail /tmp | tail -n1) -ge $((${GAME_FULL_SIZE}*2)) ]; then
	PKG1_DIR="/tmp/${PKG_ID}_${PKG_VERSION}-${PKG_ORIGIN}${PKG_REVISION}_${PKG1_ARCH}"
	PKG2_DIR="/tmp/${PKG_ID}_${PKG_VERSION}-${PKG_ORIGIN}${PKG_REVISION}_${PKG2_ARCH}"
	PKG_TMPDIR="/tmp/${GAME_ID}.tmp-$(date +%s)"
else
	PKG1_DIR="${PWD}/${PKG_ID}_${PKG_VERSION}-${PKG_ORIGIN}${PKG_REVISION}_${PKG1_ARCH}"
	PKG2_DIR="${PWD}/${PKG_ID}_${PKG_VERSION}-${PKG_ORIGIN}${PKG_REVISION}_${PKG2_ARCH}"
	PKG_TMPDIR="${PWD}/${GAME_ID}.tmp-$(date +%s)"
	export TMPDIR="${PKG_TMPDIR}"
fi

# Defining script-specific functions
build_package() {
local dir="$1"
local desc="$2"
local compression="$3"
local arch="$4"
printf '%s %s (%s)…\n' "$(l10n 'Construction du paquet pour' 'Building package for')" "${desc}" "${arch}"
fakeroot -- dpkg-deb -Z"${compression}" -b "${dir}" "${PWD}/$(basename "${dir}").deb" 1>/dev/null
}

checksum() {
local file="$1"
local target_md5="$2"
printf '%s %s…\n' "$(l10n 'Contrôle de l’intégrité de' 'Checking integrity of')" "$(basename "${file}")"
print_wait
file_md5="$(md5sum "${file}" | cut -d' ' -f1)"
if ! [ "${file_md5}" = "${target_md5}" ]; then
	print_error
	printf '%s\n' "$(l10n 'Somme de contrôle incohérente.' 'Hashsum mismatch.')"
	printf '%s %s\n' "${file}" "$(l10n 'n’est pas le fichier attendu, ou il est corrompu.' 'is not the expected file, or it is corrupted.')"
	printf '\n'
	exit 1
fi
print_done
}

extract_gamedata() {
local archive="$1"
local target="$2"
printf '%s %s…\n' "$(l10n 'Extraction des données depuis' 'Extracting game data from')" "$(basename "${archive}")"
print_wait
mkdir "${target}"
unzip -qq -d "${target}" "${archive}" 2>/dev/null || true
print_done
}

help() {
	printf '%s %s\n\n' "$0" '[<archive>] [--checksum=md5|none] [--compression=none|gzip|xz] [--prefix=dir]'
	printf '\t%s\n\t%s\n\t(%s: %s)\n\n' '--checksum=md5|none' "$(l10n 'Choix de la méthode de vérification de l’intégrité des fichiers cibles.' 'Set the checksum method for the target files.')" "$(l10n 'défaut ' 'default')" "${GAME_ARCHIVE_CHECKSUM_DEFAULT}"
	printf '\t%s\n\t%s\n\t(%s: %s)\n\n' '--compression=none|gzip|xz' "$(l10n 'Choix de la méthode de compression du paquet final.' 'Set the compression method for the final package.')" "$(l10n 'défaut ' 'default')" "${PKG_COMPRESSION_DEFAULT}"
	printf '\t%s\n\t%s\n\t(%s: %s)\n\n' '--prefix=DIR' "$(l10n 'Choix du préfixe d’installation. "DIR" doit être un chemin absolu.' 'Set the installation prefix. "DIR" must be an absolute path.')" "$(l10n 'défaut ' 'default')" "${PKG_PREFIX_DEFAULT}"
}

l10n() {
local fr="$1"
local en="$2"
if [ -n "$(printf "${LANG}" | grep ^'fr')" ]; then
	printf '%s' "${fr}"
else
	printf '%s' "${en}"
fi
}

print_done() {
printf '\033[0;32m%s.\033[0m\n\n' "$(l10n 'Fait' 'Done')"
}

print_error() {
printf '\n\033[1;31m%s:\033[0m\n' "$(l10n 'Erreur ' 'Error')"
}

print_wait() {
printf '%s\n' "$(l10n 'Cette étape peut durer plusieurs minutes.' 'This might take several minutes.')"
}

write_bin() {
local target="$1"
local exe="$2"
printf '%s %s…\n' "$(l10n 'Écriture du script de lancement pour' 'Writing launcher script for')" "$(basename "${exe}")"
cat > "${target}" << EOF
#!/bin/sh -e

# Setting game-specific variables
GAME_EXE="${exe}"
GAME_PATH="${PATH_GAME}"

# Launching the game
cd "\${GAME_PATH}"
"\${GAME_EXE}" \$@

exit 0
EOF
chmod 755 "${target}"
}

write_desktop () {
local id="$1"
local name="$2"
local cat="$3"
local arch="$4"
local target="$5"
printf '%s %s (%s)…\n' "$(l10n 'Écriture de l’entrée de menu pour' 'Writing menu entry for')" "${name}" "${arch}"
cat > "${target}" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${name}
Icon=${id}
Exec=${id}
Categories=${cat}
EOF
if [ -z "$(printf '%s' "${PATH}" | grep -e "${PATH_BIN}")" ]; then
	sed -i "s#Exec=${id}#Exec=${PATH_BIN}/${id}#" "${target}"
fi
}

write_pkg_debian () {
local dir="$1"
local id="$2"
local version="$3"
local arch="$4"
local deps="$5"
local conflicts="$6"
local desc="$7"
local size="$(LC_ALL=C du -cks $(realpath ${dir}/* | grep -v DEBIAN$) | grep total | cut -f1)"
local maint="$(whoami)@$(hostname)"
local target="${dir}/DEBIAN/control"
printf '%s %s (%s)…\n' "$(l10n 'Écriture des méta-données du paquet pour' 'Writing package meta-data for')" "${desc}" "${arch}"
cat > "${target}" << EOF
Package: ${id}
Version: ${version}
Architecture: ${arch}
Maintainer: ${maint}
Installed-Size: ${size}
Depends: ${deps}
Conflicts: ${conflicts}
Section: non-free/games
Description: ${desc}
EOF
}

# Fetch arguments
GAME_ARCHIVE=''
GAME_ARCHIVE_CHECKSUM=''
PKG_COMPRESSION=''
PKG_PREFIX=''
for arg in $@; do
	case "${arg}" in
		"--help")
			help
			exit 0
			;;
		"--checksum="*)
			GAME_ARCHIVE_CHECKSUM="$(printf '%s' "${arg}" | cut -d'=' -f2)"
			;;
		"--compression="*)
			PKG_COMPRESSION="$(printf '%s' "${arg}" | cut -d'=' -f2)"
			;;
		"--prefix="*)
			PKG_PREFIX="$(printf '%s' "${arg}" | cut -d'=' -f2)"
			;;
		*)
			GAME_ARCHIVE="${arg}"
			;;
	esac
done

# Checking dependencies
printf '\n%s…\n' "$(l10n 'Contrôle des dépendances' 'Checking dependencies')"
deps_required='unzip fakeroot'
for dep in ${deps_required}; do
	if [ -z $(which ${dep}) ]; then
		print_error
		printf '%s %s\n' "${dep}" "$(l10n 'est introuvable.' 'not found.')"
		printf '%s\n' "$(l10n 'Installez-le avant de lancer ce script.' 'Install it before running this script.')"
		printf '\n'
		exit 1
	fi
done

# Setting checksum method
if [ -z "${GAME_ARCHIVE_CHECKSUM}" ]; then
	GAME_ARCHIVE_CHECKSUM="${GAME_ARCHIVE_CHECKSUM_DEFAULT}"
fi
printf '\n%s: %s\n' "$(l10n 'Méthode de vérification du fichier cible définie à ' 'Checksum method set to')" "${GAME_ARCHIVE_CHECKSUM}"
if [ -z "$(printf ' md5sum none ' | grep " ${GAME_ARCHIVE_CHECKSUM} ")" ]; then
	print_error
	printf '%s %s --checksum.\n' "${GAME_ARCHIVE_CHECKSUM}" "$(l10n 'n’est pas une valeur valide pour' 'is not a valid value for')"
	printf '%s: none, md5sum\n' "$(l10n 'Les valeurs acceptées sont ' 'Accepted values are')"
	printf '%s: %s\n\n' "$(l10n 'La valeur par défaut est ' 'Default value is')" "${GAME_ARCHIVE_CHECKSUM_DEFAULT}"
	exit 1
fi

# Setting compression method
if [ -z "${PKG_COMPRESSION}" ]; then
	PKG_COMPRESSION="${PKG_COMPRESSION_DEFAULT}"
fi
printf '%s: %s\n' "$(l10n 'Méthode de compression définie à ' 'Compression method set to')" "${PKG_COMPRESSION}"
if [ -z "$(printf ' gzip xz none ' | grep " ${PKG_COMPRESSION} ")" ]; then
	print_error
	printf '%s %s --compression.\n' "${PKG_COMPRESSION}" "$(l10n 'n’est pas une valeur valide pour' 'is not a valid value for')"
	printf '%s: none, gzip, xz\n' "$(l10n 'Les valeurs acceptées sont ' 'Accepted values are')"
	printf '%s: %s\n\n' "$(l10n 'La valeur par défaut est ' 'Default value is')" "${PKG_COMPRESSION_DEFAULT}"
	exit 1
fi

# Setting installation prefix
if [ -z "${PKG_PREFIX}" ]; then
	PKG_PREFIX="${PKG_PREFIX_DEFAULT}"
fi
printf '%s: %s\n' "$(l10n 'Préfixe d’installation défini à ' 'Installation prefix set to')" "${PKG_PREFIX}"
if [ "$(printf '%s' "${PKG_PREFIX}" | cut -c1)" != '/' ]; then
	print_error
	printf '%s --prefix %s\n' "$(l10n 'La valeur assignée à' 'The value assigned to')" "$(l10n 'doit être un chemin absolu.' 'must be an absolute path.')"
	printf '%s: %s\n\n' "$(l10n 'La valeur par défaut est ' 'Default value is')" "${PKG_PREFIX_DEFAULT}"
	exit 1
fi
PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON="/usr/local/share/icons/hicolor/${APP1_ICON_RES}/apps"

# Setting target file
printf '\n%s…\n' "$(l10n 'Recherche du fichier cible' 'Looking for target file')"
if [ -z "$GAME_ARCHIVE" ]; then
	if [ -f "${PWD}/${GAME_ARCHIVE1}" ]; then
		GAME_ARCHIVE="${PWD}/${GAME_ARCHIVE1}"
	elif [ -f "${HOME}/${GAME_ARCHIVE1}" ]; then
		GAME_ARCHIVE="${HOME}/${GAME_ARCHIVE1}"
	else
		print_error
		printf '%s. (%s)\n\n' "$(l10n 'Ce script prend en argument le chemin vers l’archive téléchargée depuis humblebundle.com' 'This script needs to be given the path to the humblebundle.com archive as an argument')" "${GAME_ARCHIVE1}"
		exit 1
	fi
fi
printf '%s %s\n' "$(l10n 'Utilisation de' 'Using')" "$(realpath "${GAME_ARCHIVE}")"
if ! [ -f "${GAME_ARCHIVE}" ]; then
	print_error
	printf '%s: %s.\n\n' "${GAME_ARCHIVE}" "$(l10n 'fichier introuvable' 'file not found')"
	exit 1
fi

# Checking target file integrity
printf '\n'
if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" "${GAME_ARCHIVE1_MD5}"
fi

# Building package directories
printf '%s…\n' "$(l10n 'Construction de l’arborescence du paquet' 'Building package directories')"
rm -rf "${PKG1_DIR}" "${PKG2_DIR}"
for dir in "${PATH_GAME}" "${PATH_DOC}" "${PATH_BIN}" "${PATH_ICON}" "${PATH_DESK}" '/DEBIAN'; do
	mkdir -p "${PKG1_DIR}${dir}"
	mkdir -p "${PKG2_DIR}${dir}"
done

# Extracting game data
printf '\n'
extract_gamedata "${GAME_ARCHIVE}" "${PKG_TMPDIR}"
find "${PKG_TMPDIR}" -type d -exec chmod 755 '{}' +
find "${PKG_TMPDIR}" -type f -exec chmod 644 '{}' +
for file in './data/noarch/*.txt'; do
	cp -l "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_DOC}"
	cp -l "${PKG_TMPDIR}"/${file} "${PKG2_DIR}${PATH_DOC}"
	rm "${PKG_TMPDIR}"/${file}
done
cp -rl "${PKG_TMPDIR}"/data/noarch/* "${PKG1_DIR}${PATH_GAME}"
cp -rl "${PKG_TMPDIR}"/data/noarch/* "${PKG2_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}"/data/x86/* "${PKG1_DIR}${PATH_GAME}"
mv "${PKG_TMPDIR}"/data/x86_64/* "${PKG2_DIR}${PATH_GAME}"
chmod 755 "${PKG1_DIR}${PATH_GAME}/${APP1_EXE_ARCH1}"
chmod 755 "${PKG2_DIR}${PATH_GAME}/${APP1_EXE_ARCH2}"
mv "${PKG1_DIR}${PATH_GAME}/${APP1_ICON}" "${PKG1_DIR}${PATH_ICON}/${APP1_ID}.png"
mv "${PKG2_DIR}${PATH_GAME}/${APP1_ICON}" "${PKG2_DIR}${PATH_ICON}/${APP1_ID}.png"

# Writing scripts (game launcher)
write_bin "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_ARCH1}"
write_bin "${PKG2_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_ARCH2}"

# Writing menu entries
printf '\n'
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_CAT}" "${PKG1_ARCH}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_CAT}" "${PKG2_ARCH}" "${PKG2_DIR}${PATH_DESK}/${APP1_ID}.desktop"

# Writing package meta-data
printf '\n'
write_pkg_debian "${PKG1_DIR}" "${PKG_ID}" "${PKG_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG1_ARCH}" "${PKG_DEPS}" "${PKG1_CONFLICTS}" "${PKG_DESC}"
write_pkg_debian "${PKG2_DIR}" "${PKG_ID}" "${PKG_VERSION}-${PKG_ORIGIN}${PKG_REVISION}" "${PKG2_ARCH}" "${PKG_DEPS}" "${PKG2_CONFLICTS}" "${PKG_DESC}"

# Building package
printf '\n%s…\n' "$(l10n 'Construction des paquets' 'Building packages')"
print_wait
rm -rf "${PKG_TMPDIR}"
mkdir "${PKG_TMPDIR}"
build_package "${PKG1_DIR}" "${PKG_DESC}" "${PKG_COMPRESSION}" "${PKG1_ARCH}"
rm -rf "${PKG1_DIR}"
build_package "${PKG2_DIR}" "${PKG_DESC}" "${PKG_COMPRESSION}" "${PKG2_ARCH}"
rm -rf "${PKG2_DIR}" "${PKG_TMPDIR}"
print_done
printf '%s %s (%s) %s:\n' "$(l10n 'Installez' 'Install')" "${PKG_DESC}" "${PKG1_ARCH}" "$(l10n 'en lançant la série de commandes suivante en root ' 'by running the following commands as root')"
printf 'dpkg -i %s\napt-get install -f\n' "${PWD}/$(basename ${PKG1_DIR}).deb"
printf '\n%s %s (%s) %s:\n' "$(l10n 'Installez' 'Install')" "${PKG_DESC}" "${PKG2_ARCH}" "$(l10n 'en lançant la série de commandes suivante en root ' 'by running the following commands as root')"
printf 'dpkg -i %s\napt-get install -f\n' "${PWD}/$(basename ${PKG2_DIR}).deb"
printf '\n%s ;)\n\n' "$(l10n 'Bon jeu' 'Have fun')"

exit 0
