# write launcher script
# USAGE: write_bin $app
# NEEDED VARS: $app_ID, $app_TYPE, PKG, PATH_BIN, $app_EXE
# CALLS: liberror, write_bin_header, write_bin_set_vars, write_bin_set_exe, write_bin_set_prefix, write_bin_build_userdirs, write_bin_build_prefix, write_bin_run
write_bin() {
	PKG_PATH="$(eval echo \$${PKG}_PATH)"
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'write_bin'
		local app_id="$(eval echo \$${app}_ID)"
		if [ -z "$app_id" ]; then
			app_id="$GAME_ID"
		fi
		local app_type="$(eval echo \$${app}_TYPE)"
		local file="${PKG_PATH}${PATH_BIN}/${app_id}"
		mkdir --parents "${file%/*}"
		write_bin_header
		write_bin_set_vars
		if [ "$app_type" != 'scummvm' ]; then
			local app_exe="$(eval echo \$${app}_EXE)"
			chmod +x "${PKG_PATH}${PATH_GAME}/$app_exe"
			write_bin_set_exe
			write_bin_set_prefix
			write_bin_build_userdirs
			write_bin_build_prefix
		fi
		write_bin_run
		sed -i 's/  /\t/g' "$file"
		chmod 755 "$file"
	done
}

# write launcher script header
# USAGE: write_bin_header
# CALLED BY: write_bin
write_bin_header() {
	cat > "$file" <<- EOF
	#!/bin/sh
	set -o errexit
	
	EOF
}

