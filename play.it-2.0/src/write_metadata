write_metadata() {
local pkg="$1"
testvar "$pkg" 'PKG'
local pkg_arch=$(eval echo \$${pkg}_ARCH)
local pkg_conflicts="$(eval echo \$${pkg}_CONFLICTS)"
local pkg_deps="$(eval echo \$${pkg}_DEPS)"
local pkg_desc="$(eval echo \$${pkg}_DESC)"
local pkg_id=$(eval echo \$${pkg}_ID)
local pkg_maint="$(whoami)@$(hostname)"
local pkg_path="$(eval echo \$${pkg}_PATH)"
local pkg_version=$(eval echo \$${pkg}_VERSION)
local pkg_size=$(du --total --block-size=1K --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
case $PACKAGE_TYPE in
	deb) write_metadata_deb ;;
	tar) return 0 ;;
esac
}

write_metadata_deb() {
local target="${pkg_path}/DEBIAN/control"
mkdir --parents "${target%/*}"
cat > "${target}" << EOF
Package: $pkg_id
Version: $pkg_version
Architecture: $pkg_arch
Maintainer: $pkg_maint
Installed-Size: $pkg_size
Conflicts: $pkg_conflicts
Depends: $pkg_deps
Section: non-free/games
Description: $pkg_desc
EOF
if [ "$pkg_arch" = 'all' ]; then
	sed -i 's/Architecture: all/&\nMulti-Arch: foreign/' "${target}"
fi
}

