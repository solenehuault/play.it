# alias
# USAGE: write_app $app[…]
# CALLS: write_bin, write_desktop
write_app() {
for app in "$@"; do
	write_bin "$app"
	write_desktop "$app"
done
}

