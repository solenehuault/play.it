# put files from archive in the right package directories (alias)
# USAGE: organize_data
# CALLS: organize_data_generic
organize_data() {
	if [ -n "${ARCHIVE_DOC_PATH}" ]; then
		organize_data_generic 'DOC'  "$PATH_DOC"
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
# NEEDED VARS: $PKG, $PKG_PATH, $PLAYIT_WORKDIR
# CALLED BY: organize_data
organize_data_generic() {
	local archive_path="$(eval echo \$ARCHIVE_${1}_PATH)"
	if [ "$archive_path" ] && [ -e "$PLAYIT_WORKDIR/gamedata/$archive_path" ]; then
		local pkg_path="$(eval echo \$${PKG}_PATH)${2}"
		mkdir --parents "$pkg_path"
		(
			cd "$PLAYIT_WORKDIR/gamedata/$archive_path"
			for file in $(eval echo \$ARCHIVE_${1}_FILES); do
				if [ -e "$file" ]; then
					cp --recursive --link --parents "$file" "$pkg_path"
					rm --recursive "$file"
				fi
			done
		)
	fi
}

