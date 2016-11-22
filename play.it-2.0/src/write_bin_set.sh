# write launcher script - set common vars
# USAGE: write_bin_set_vars
write_bin_set_vars() {
cat >> "$file" << EOF
# Set game-specific variables

GAME_ID="$GAME_ID"
PATH_GAME="$PATH_GAME"

EOF
if [ "$app_type" != 'scummvm' ]; then
	cat >> "$file" <<- EOF
	CACHE_DIRS='$CACHE_DIRS'
	CACHE_FILES='$CACHE_FILES'
	
	CONFIG_DIRS='$CONFIG_DIRS'
	CONFIG_FILES='$CONFIG_FILES'
	
	DATA_DIRS='$DATA_DIRS'
	DATA_FILES='$DATA_FILES'
	
	EOF
else
	cat >> "$file" <<- EOF
	SCUMMVM_ID='$(eval echo \$${app}_SCUMMID)'
	
	EOF
fi
}

# write launcher script - set target binary/script to run the game
# USAGE: write_bin_set_exe
write_bin_set_exe() {
cat >> "$file" << EOF
# Set executable file

unset APP_EXE
case "\${0##*/}" in
	$app_id) APP_EXE="$app_exe" ;;
	*) [ -n "\$1" ] && APP_EXE="\$1" && shift 1 ;;
esac

EOF
[ "$app_type" = 'wine' ] && echo "[ -z \"\$APP_EXE\" ] && APP_EXE='winecfg'\n" >> "$file"
}

# write launcher script - set prefix path
# USAGE: write_bin_set_prefix
# CALLS: write_bin_set_prefix_vars, write_bin_set_prefix_funcs
write_bin_set_prefix() {
cat >> "$file" << EOF
# Set prefix name

[ -n "\$PREFIX_ID" ] || PREFIX_ID="$GAME_ID"

EOF
write_bin_set_prefix_vars
write_bin_set_prefix_funcs
}

# write launcher script - set prefix-specific vars
# USAGE: write_bin_set_prefix_vars
# CALLED BY: write_bin_set_prefix
# CALLS: write_bin_set_prefix_wine
write_bin_set_prefix_vars() {
cat >> "$file" << EOF
# Set prefix-specific variables

[ -w "\$XDG_CACHE_HOME" ] || XDG_CACHE_HOME="\${HOME}/.cache"
[ -w "\$XDG_CONFIG_HOME" ] || XDG_CONFIG_HOME="\${HOME}/.config"
[ -w "\$XDG_DATA_HOME" ] || XDG_DATA_HOME="\${HOME}/.local/share"

PATH_CACHE="\${XDG_CACHE_HOME}/\${PREFIX_ID}"
PATH_CONFIG="\${XDG_CONFIG_HOME}/\${PREFIX_ID}"
PATH_DATA="\${XDG_DATA_HOME}/games/\${PREFIX_ID}"
EOF
if [ "$app_type" = 'wine' ] ; then
	write_bin_set_prefix_vars_wine
else
	cat >> "$file" <<- EOF
	PATH_PREFIX="\${XDG_DATA_HOME}/play.it/prefixes/\${PREFIX_ID}"
	EOF
fi
}

# write launcher script - set WINE-specific prefix-specific vars
# USAGE: write_bin_set_prefix_vars_wine
# CALLED BY: write_bin_set_prefix_vars
write_bin_set_prefix_vars_wine() {
cat >> "$file" << EOF
WINEPREFIX="\${XDG_DATA_HOME}/play.it/prefixes/\${PREFIX_ID}"
PATH_PREFIX="\${WINEPREFIX}/drive_c/\${GAME_ID}"
WINEARCH='win32'
WINEDEBUG='-all'
WINEDLLOVERRIDES='winemenubuilder.exe,mscoree,mshtml=d'

EOF
}

# write launcher script - set prefix-specific functions
# USAGE: write_bin_set_prefix_funcs
# CALLED BY: write_bin_set_prefix
write_bin_set_prefix_funcs() {
cat >> "$file" << EOF
clean_userdir() {
local target="\$1"
shift 1
for file in "\$@"; do
if [ -f "\${file}" ] && [ ! -f "\${target}/\${file}" ]; then
	mkdir -p "\${target}/\${file%/*}"
	mv "\${file}" "\${target}/\${file}"
	ln -s "\${target}/\${file}" "\${file}"
fi
done
}

init_prefix_dirs() {
cd "\$1"
shift 1
for dir in "\$@"; do
	rm -rf "\${PATH_PREFIX}/\${dir}"
	mkdir -p "\${PATH_PREFIX}/\${dir%/*}"
	ln -s "\$(readlink -e "\${dir}")" "\${PATH_PREFIX}/\${dir}"
done
cd - 1>/dev/null
}

init_prefix_files() {
cd "\$1"
find . -type f | while read file; do
	rm -f "\${PATH_PREFIX}/\${file}"
	mkdir -p "\${PATH_PREFIX}/\${file%/*}"
	ln -s "\$(readlink -e "\${file}")" "\${PATH_PREFIX}/\${file}"
done
cd - 1>/dev/null
}

init_userdir_dirs() {
cd "\$1"
shift 1
for dir in "\$@"; do
if ! [ -e "\$dir" ]; then
	if [ -e "\${PATH_GAME}/\${dir}" ]; then
		mkdir -p "\${dir%/*}"
		cp -r "\${PATH_GAME}/\${dir}" "\$dir"
	else
		mkdir -p "\$dir"
	fi
fi
done
cd - 1>/dev/null
}

init_userdir_files() {
cd "\$1"
shift 1
for file in "\$@"; do
if ! [ -e "\$file" ] && [ -e "\${PATH_GAME}/\${file}" ]; then
	mkdir -p "\${file%/*}"
	cp "\${PATH_GAME}/\${file}" "\$file"
fi
done
cd - 1>/dev/null
}

EOF
}

