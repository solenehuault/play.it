write_desktop() {
local app="$1"
testvar "$app" 'APP' || liberror 'app' 'write_desktop'
local app_id=$(eval echo \$${app}_ID)
local app_name="$(eval echo \$${app}_NAME)"
local app_cat="$(eval echo \$${app}_CAT)"
local target="${PKG_PATH}${PATH_DESK}/${app_id}.desktop"
mkdir --parents "${target%/*}"
cat > "${target}" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$app_name
Icon=$app_id
Exec=$app_id
Categories=$app_cat
EOF
}

