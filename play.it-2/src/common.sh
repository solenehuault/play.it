# set package distribution-specific architecture
# USAGE: set_arch
# NEEDED VARS: $PACKAGE_TYPE
# CALLED BY: set_workdir_pkg write_metadata
set_arch() {
	case $PACKAGE_TYPE in

		('arch')
			case "$(eval echo \$${pkg}_ARCH)" in
				('32'|'64')
					pkg_arch='x86_64'
				;;
				(*)
					pkg_arch='any'
				;;
			esac
		;;

		('deb')
			case "$(eval echo \$${pkg}_ARCH)" in
				('32')
					pkg_arch='i386'
				;;
				('64')
					pkg_arch='amd64'
				;;
				(*)
					pkg_arch='all'
				;;
			esac
		;;

	esac
}

