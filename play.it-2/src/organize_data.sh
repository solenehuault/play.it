# put files from archive in the right package directories (alias)
# USAGE: organize_data
# NEEDED VARS: PKG_PATH, PKG, $PKG_PATH
# CALLS: organize_data_doc, organize_data_game
organize_data() {
	[ -n "$PKG_PATH" ] || PKG_PATH="$(eval echo \$${PKG}_PATH)"
	if [ -n "${ARCHIVE_DOC_PATH}" ]; then
		organize_data_generic 'DOC' "$PATH_DOC"
	fi
	if [ -n "${ARCHIVE_DOC1_PATH}" ]; then
		organize_data_generic 'DOC1' "$PATH_DOC"
	fi
	if [ -n "${ARCHIVE_DOC2_PATH}" ]; then
		organize_data_generic 'DOC2' "$PATH_DOC"
	fi
	if [ -n "${ARCHIVE_GAME_PATH}" ]; then
		organize_data_generic 'GAME' "$PATH_GAME"
	fi
}

# put files from archive in the right package directories (generic function)
# USAGE: organize_data_generic $id $path
# NEEDED VARS: PKG_PATH, PLAYIT_WORKDIR
# CALLED BY: organize_data_doc organize_data_game
organize_data_generic() {
	local archive_path="${PLAYIT_WORKDIR}/gamedata/$(eval echo \$ARCHIVE_${1}_PATH)"
	local archive_files="$(eval echo \"\$ARCHIVE_${1}_FILES\")"
	local pkg_path="${PKG_PATH}${2}"
	mkdir --parents "$pkg_path"
	cd "$archive_path"
	for file in $archive_files; do
		mv "$file" "$pkg_path"
	done
	cd - > /dev/null
}

