# write launcher script
# USAGE: write_bin $app
# NEEDED VARS: $app_ID, $app_TYPE, PKG_PATH, PATH_BIN, $app_EXE
# CALLS: liberror, write_bin_header, write_bin_set_vars, write_bin_set_exe, write_bin_set_prefix, write_bin_build_userdirs, write_bin_build_prefix, write_bin_run
write_bin() {
for app in $@; do
	testvar "$app" 'APP' || liberror 'app' 'write_bin'
	local app_id="$(eval echo \$${app}_ID)"
	[ -n "$app_id" ] || app_id="$GAME_ID"
	local app_type="$(eval echo \$${app}_TYPE)"
	local file="${PKG_PATH}${PATH_BIN}/${app_id}"
	mkdir --parents "${file%/*}"
	write_bin_header
	write_bin_set_vars
	if [ "$app_type" != 'scummvm' ]; then
		local app_exe="$(eval echo \$${app}_EXE)"
		write_bin_set_exe
		write_bin_set_prefix
		write_bin_build_userdirs
		write_bin_build_prefix
	fi
	write_bin_run
	chmod 755 "$file"
done
}

# write launcher script header
# USAGE: write_bin_header
# CALLED BY: write_bin
write_bin_header() {
cat > "$file" << EOF
#!/bin/sh
set -o errexit

EOF
}

