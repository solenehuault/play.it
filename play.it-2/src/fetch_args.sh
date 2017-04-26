# parse arguments given to the script
# USAGE: fetch_args $argument[…]
# CALLS: fetch_args_set_var
fetch_args() {
	unset CHECKSUM_METHOD
	unset COMPRESSION_METHOD
	unset INSTALL_PREFIX
	unset PACKAGE_TYPE
	unset SOURCE_ARCHIVE
	for arg in "$@"; do
		case "$arg" in
			('--checksum='*)
				export CHECKSUM_METHOD="${arg#*=}"
			;;
			('--compression='*)
				export COMPRESSION_METHOD="${arg#*=}"
			;;
			('--prefix='*)
				export INSTALL_PREFIX="${arg#*=}"
			;;
			('--package='*)
				export PACKAGE_TYPE="${arg#*=}"
			;;
			('--'*)
				return 1
			;;
			(*)
				export SOURCE_ARCHIVE="$arg"
			;;
		esac
	done
	fetch_args_set_var 'CHECKSUM_METHOD'
	fetch_args_set_var 'COMPRESSION_METHOD'
	fetch_args_set_var 'INSTALL_PREFIX'
	fetch_args_set_var 'PACKAGE_TYPE'
}

# set global vars not already set by script arguments
# USAGE: fetch_args_set_var $var_name
# CALLED BY: fetch_args
fetch_args_set_var() {
	local value="$(eval echo \$$1)"
	if [ -z "$value" ]; then
		local value_default="$(eval echo \$DEFAULT_$1)"
		if [ -n "$value_default" ]; then
			export $1="$value_default"
		fi
	fi
}

