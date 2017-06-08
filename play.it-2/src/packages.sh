# write package meta-data
# USAGE: write_metadata [$pkg…]
# NEEDED VARS: (ARCHIVE) GAME_NAME (OPTION_PACKAGE) PACKAGES_LIST (PKG_ARCH) PKG_DEPS_ARCH PKG_DEPS_DEB PKG_DESCRIPTION PKG_ID PKG_PATH PKG_PROVIDE PKG_VERSION
# CALLS: liberror pkg_write_arch pkg_write_deb set_architecture testvar
write_metadata() {
	if [ $# = 0 ]; then
		write_metadata $PACKAGES_LIST
		return 0
	fi
	for pkg in $@; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'write_metadata'

		# Set package-specific variables
		local pkg_architecture
		set_architecture "$pkg"
		local pkg_id="$(eval echo \$${pkg}_ID)"
		local pkg_maint="$(whoami)@$(hostname)"
		local pkg_path="$(eval echo \$${pkg}_PATH)"
		local pkg_provide="$(eval echo \$${pkg}_PROVIDE)"

		if [ "$(eval echo \$${pkg}_DESCRIPTION_${ARCHIVE#ARCHIVE_})" ]; then
			pkg_description="$(eval echo \$${pkg}_DESCRIPTION_${ARCHIVE#ARCHIVE_})"
		else
			pkg_description="$(eval echo \$${pkg}_DESCRIPTION)"
		fi

		if [ "$(eval echo \$${pkg}_VERSION)" ]; then
			pkg_version="$(eval echo \$${pkg}_VERSION)"
		else
			pkg_version="$PKG_VERSION"
		fi

		case $OPTION_PACKAGE in
			('arch')
				pkg_write_arch
			;;
			('deb')
				pkg_write_deb
			;;
			(*)
				liberror 'OPTION_PACKAGE' 'write_metadata'
			;;
		esac
	done
}

# build .pkg.tar or .deb package
# USAGE: build_pkg [$pkg…]
# NEEDED VARS: (OPTION_COMPRESSION) (LANG) (OPTION_PACKAGE) PACKAGES_LIST PKG_PATH PLAYIT_WORKDIR
# CALLS: liberror pkg_build_arch pkg_build_deb testvar
build_pkg() {
	if [ $# = 0 ]; then
		build_pkg $PACKAGES_LIST
		return 0
	fi
	for pkg in $@; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'build_pkg'
		local pkg_path="$(eval echo \$${pkg}_PATH)"
		case $OPTION_PACKAGE in
			('arch')
				pkg_build_arch "$pkg_path"
			;;
			('deb')
				pkg_build_deb "$pkg_path"
			;;
			(*)
				liberror 'OPTION_PACKAGE' 'build_pkg'
			;;
		esac
	done
}

# print package building message
# USAGE: pkg_print $file
# NEEDED VARS: (LANG)
# CALLED BY: pkg_build_arch pkg_build_deb
pkg_print() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Construction de %s\n'
		;;
		('en'|*)
			string='Building %s\n'
		;;
	esac
	printf "$string" "$1"
}

