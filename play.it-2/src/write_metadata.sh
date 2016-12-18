# write package meta-data
# USAGE: write_metadata $pkg
# NEEDED VARS: $pkg_ARCH_ARCH, $pkg_ARCH_DEB, $pkg_CONFLICTS_ARCH, $pkg_CONFLICTS_DEB, $pkg_DEPS_ARCH, $pkg_DEPS_DEB, $pkg_DESC_ARCH, $pkg_DESC_DEB, $pkg_ID, $pkg_PATH, $pkg_PROVIDES_ARCH, $pkg_PROVIDES_DEB, $pkg_VERSION, $PACKAGE_TYPE
# CALLS: testvar, liberror, write_metadata_arch, write_metadata_deb
write_metadata() {
	for pkg in $@; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'write_metadata'
		local pkg_id="$(eval echo \$${pkg}_ID)"
		if [ -z "$pkg_id" ]; then
			pkg_id="$GAME_ID"
		fi
		local pkg_maint="$(whoami)@$(hostname)"
		local pkg_path="$(eval echo \$${pkg}_PATH)"
		local pkg_version="$(eval echo \$${pkg}_VERSION)"
		if [ -z "$pkg_version" ]; then
			pkg_version="$PKG_VERSION"
		fi
		if [ -z "$pkg_version" ]; then
			pkg_version='1.0-1'
		fi
		case $PACKAGE_TYPE in
			('arch')
				local pkg_arch="$(eval echo \$${pkg}_ARCH_ARCH)"
				local pkg_conflicts="$(eval echo \$${pkg}_CONFLICTS_ARCH)"
				local pkg_desc="$(eval echo \$${pkg}_DESC_ARCH)"
				local pkg_deps="$(eval echo \$${pkg}_DEPS_ARCH)"
				local pkg_provides="$(eval echo \$${pkg}_PROVIDES_ARCH)"
				local pkg_size=$(du --total --block-size=1 --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
				write_metadata_arch
			;;
			('deb')
				local pkg_arch="$(eval echo \$${pkg}_ARCH_DEB)"
				local pkg_conflicts="$(eval echo \$${pkg}_CONFLICTS_DEB)"
				local pkg_deps="$(eval echo \$${pkg}_DEPS_DEB)"
				local pkg_desc="$(eval echo \$${pkg}_DESC_DEB)"
				local pkg_provides="$(eval echo \$${pkg}_PROVIDES_DEB)"
				local pkg_size=$(du --total --block-size=1K --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
				write_metadata_deb
			;;
			('tar')
				return 0
			;;
		esac
	done
}

# write .pkg.tar.xz package meta-data
# USAGE: write_metadata_arch
# CALLED BY: write_metadata
write_metadata_arch() {
	local target="${pkg_path}/.PKGINFO"
	mkdir --parents "${target%/*}"
	cat > "${target}" <<- EOF
	pkgname = $pkg_id
	pkgver = $pkg_version
	pkgdesc = $pkg_desc
	packager = $pkg_maint
	builddate = $(date +"%m%d%Y")
	size = $pkg_size
	arch = $pkg_arch
	EOF
	for dep in $pkg_deps; do
		cat >> "${target}" <<- EOF
		depend = $dep
		EOF
	done
	for conflict in $pkg_conflicts; do
		cat >> "${target}" <<- EOF
		conflict = $conflict
		EOF
	done
	for provide in $pkg_provides; do
		cat >> "${target}" <<- EOF
		provide = $provide
		EOF
	done
	local target="${pkg_path}/.INSTALL"
	if [ -e "$postinst" ]; then
		cat >> "$target" <<- EOF
		post_install() {
		EOF
		cat "$postinst" >> "$target"
		cat >> "$target" <<- EOF
		}
		post_upgrade() {
		post_install
		}
		EOF
	fi
	if [ -e "$prerm" ]; then
		cat >> "$target" <<- EOF
		pre_remove() {
		EOF
		cat "$prerm" >> "$target"
		cat >> "$target" <<- EOF
		}
		pre_upgrade() {
		pre_remove
		}
		EOF
	fi
}

# write .deb package meta-data
# USAGE: write_metadata_deb
# CALLED BY: write_metadata
write_metadata_deb() {
	local target="$pkg_path/DEBIAN/control"
	mkdir --parents "${target%/*}"
	cat > "$target" <<- EOF
	Package: $pkg_id
	Version: $pkg_version
	Architecture: $pkg_arch
	Maintainer: $pkg_maint
	Installed-Size: $pkg_size
	EOF
	if [ -n "$pkg_conflicts" ]; then
		cat >> "$target" <<- EOF
		Conflicts: $pkg_conflicts
		EOF
	fi
	if [ -n "$pkg_provides" ]; then
		cat >> "$target" <<- EOF
		Provides: $pkg_provides
		EOF
	fi
	if [ -n "$pkg_deps" ]; then
		cat >> "$target" <<- EOF
		Depends: $pkg_deps
		EOF
	fi
	cat >> "$target" <<- EOF
	Section: non-free/games
	Description: $pkg_desc
	EOF
	if [ "$pkg_arch" = 'all' ]; then
		sed -i 's/Architecture: all/&\nMulti-Arch: foreign/' "$target"
	fi
	if [ -e "$postinst" ]; then
		local target="$pkg_path/DEBIAN/postinst"
		cat > "$target" <<- EOF
		#!/bin/sh -e
		EOF
		cat "$postinst" >> "$target"
		cat >> "$target" <<- EOF
		exit 0
		EOF
		chmod 755 "$target"
	fi
	if [ -e "$prerm" ]; then
		local target="$pkg_path/DEBIAN/prerm"
		cat > "$target" <<- EOF
		#!/bin/sh -e
		EOF
		cat "$prerm" >> "$target"
		cat >> "$target" <<- EOF
		exit 0
		EOF
		chmod 755 "$target"
	fi
}

