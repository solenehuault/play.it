write_bin_run() {
cat >> "$file" << EOF
# Run the game

EOF
case $app_type in
	dosbox) write_bin_run_dosbox ;;
	native) write_bin_run_native ;;
	scummvm) write_bin_run_scummvm ;;
	wine) write_bin_run_wine ;;
esac
if ! [ $app_type = 'scummvm' ]; then
	cat >> "$file" <<- EOF
	
	sleep 5
	clean_userdir "\$PATH_CACHE" \$CACHE_FILES
	clean_userdir "\$PATH_CONFIG" \$CONFIG_FILES
	clean_userdir "\$PATH_DATA" \$DATA_FILES
	EOF
fi
cat >> "$file" <<- EOF

exit 0
EOF
}

write_bin_run_dosbox() {
cat >> "$file" << EOF
cd "\${PATH_PREFIX}/\${APP_EXE%/*}"
dosbox -c "mount c .
c:
imgmount d \$GAME_IMAGE -t iso -fs iso
\${APP_EXE##*/} \$@
exit"
EOF
}

write_bin_run_native() {
cat >> "$file" << EOF
cd "\${PATH_PREFIX}/\${APP_EXE%/*}"
./\${APP_EXE##*/} \$@
EOF
}

write_bin_run_scummvm() {
cat >> "$file" << EOF
scummvm -p "\${PATH_GAME}" \$@ \$SCUMMVM_ID
EOF
}

write_bin_run_wine() {
cat >> "$file" << EOF
cd "\${PATH_PREFIX}/\${APP_EXE%/*}"
wine "\${APP_EXE##*/}" \$@
EOF
}

