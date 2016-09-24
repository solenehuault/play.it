write_app() {
for app in "$@"; do
	write_bin "$app"
	write_desktop "$app"
done
}

