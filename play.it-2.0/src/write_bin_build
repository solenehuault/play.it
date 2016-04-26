write_bin_build_userdirs() {
cat >> "$file" << EOF
# Build user-writable directories

if [ ! -e "\$PATH_CACHE" ]; then
	mkdir -p "\$PATH_CACHE"
	init_userdir_dirs "\$PATH_CACHE" \$GAME_CACHE_DIRS
	init_userdir_files "\$PATH_CACHE" \$GAME_CACHE_FILES
fi
if [ ! -e "\$PATH_CONFIG" ]; then
	mkdir -p "\$PATH_CONFIG"
	init_userdir_dirs "\$PATH_CONFIG" \$GAME_CONFIG_DIRS
	init_userdir_files "\$PATH_CONFIG" \$GAME_CONFIG_FILES
fi
if [ ! -e "\$PATH_DATA" ]; then
	mkdir -p "\$PATH_DATA"
	init_userdir_dirs "\$PATH_DATA" \$GAME_DATA_DIRS
	init_userdir_files "\$PATH_DATA" \$GAME_DATA_FILES
fi

EOF
}

write_bin_build_userdirs_wine() {
cat >> "$file" << EOF
export WINEPREFIX WINEARCH WINEDEBUG WINEDLLOVERRIDES
if ! [ -e "\$WINEPREFIX" ]; then
	mkdir -p "\${WINEPREFIX%/*}"
	wineboot -i 2>/dev/null
	rm "\${WINEPREFIX}/dosdevices/z:"
fi
EOF
}

write_bin_build_prefix() {
cat >> "$file" << EOF
# Build prefix

EOF
[ "$app_type" = 'wine' ] && write_bin_build_userdirs_wine
cat >> "$file" << EOF
if [ ! -e "\$PATH_PREFIX" ]; then
	mkdir -p "\$PATH_PREFIX"
	cp -surf "\${PATH_GAME}"/* "\${PATH_PREFIX}"
fi
init_prefix_files "\$PATH_CACHE"
init_prefix_files "\$PATH_CONFIG"
init_prefix_files "\$PATH_DATA"
init_prefix_dirs "\$PATH_CACHE" \$GAME_CACHE_DIRS
init_prefix_dirs "\$PATH_CONFIG" \$GAME_CONFIG_DIRS
init_prefix_dirs "\$PATH_DATA" \$GAME_DATA_DIRS

EOF
}

