# write package meta-data
# USAGE: write_metadata $pkg
# NEEDED VARS: $PKG_ARCH $PKG_DEPS $PKG_DESCRIPTION $PKG_ID $PKG_PATH
#  $PKG_PROVIDE $PKG_VERSION $PACKAGE_TYPE
# CALLS: testvar liberror pkg_write_arch pkg_write_deb
write_metadata() {
	for pkg in $@; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'write_metadata'

		# Set package-specific variables
		local pkg_arch
		set_arch
		local pkg_id="$(eval echo \$${pkg}_ID)"
		local pkg_description="$(eval echo \$${pkg}_DESCRIPTION)"
		local pkg_maint="$(whoami)@$(hostname)"
		local pkg_path="$(eval echo \$${pkg}_PATH)"
		local pkg_provide="$(eval echo \$${pkg}_PROVIDE)"
		local pkg_version="$(eval echo \$${pkg}_VERSION)"
		[ "$pkg_version" ] || pkg_version="$PKG_VERSION"

		case $PACKAGE_TYPE in
			('arch')
				pkg_write_arch
			;;
			('deb')
				pkg_write_deb
			;;
		esac

	done
}

# build .pkg.tar or .deb package
# USAGE: build_pkg $pkg[…]
# NEEDED VARS: $PKG_PATH $PACKAGE_TYPE
# CALLS: testvar liberror pkg_build_arch pkg_build_deb
build_pkg() {
	for pkg in $@; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'build_pkg'
		local pkg_path="$(eval echo \$${pkg}_PATH)"
		case $PACKAGE_TYPE in
			('arch')
				pkg_build_arch
			;;
			('deb')
				pkg_build_deb
			;;
			(*)
				liberror 'PACKAGE_TYPE' 'build_pkg'
			;;
		esac
	done
}

# print package building message
# USAGE: pkg_print
# CALLED BY: pkg_build_arch pkg_build_deb
pkg_print() {
	local string
	case ${LANG%_*} in
		('fr')
			string='Construction de %s\n'
		;;
		('en'|*)
			string='Building %s\n'
		;;
	esac
	printf "$string" "${pkg_filename##*/}"
}

