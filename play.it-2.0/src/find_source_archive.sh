
# alias
# USAGE: find_source_archive $archive_name[…]
# CALLS: set_source_archive, check_deps, set_common_paths, file_checksum, check_deps
find_source_archive() {
set_source_archive "$@"
check_deps
set_common_paths
if [ -n "$ARCHIVE" ]; then
	file_checksum "$SOURCE_ARCHIVE" "$ARCHIVE"
else
	file_checksum "$SOURCE_ARCHIVE" "$@"
fi
check_deps
}

