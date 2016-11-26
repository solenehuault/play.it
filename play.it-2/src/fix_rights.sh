# set defaults rights on files (755 for dirs & 644 for regular files)
# USAGE: fix_rights $dir[…]
fix_rights() {
	for dir in "$@"; do
		if [ ! -d "$dir" ]; then
			return 1
		fi
		find "$dir" -type d -exec chmod 755 '{}' +
		find "$dir" -type f -exec chmod 644 '{}' +
	done
}

