# set defaults rights on files (755 for dirs & 644 for regular files)
# USAGE: fix_rights $dir
fix_rights() {
[ -d "$1" ] || return 1
find "$1" -type d -exec chmod -c 755 '{}' +
find "$1" -type f -exec chmod -c 644 '{}' +
}

