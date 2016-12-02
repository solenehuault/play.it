# display an error if a function has been called with invalid arguments
# USAGE: liberror $var_name $calling_function
liberror() {
	local var="$1"
	local value="$(eval echo \$$var)"
	local func="$2"
	print_error
	case ${LANG%_*} in
		('fr')
			printf 'valeur incorrecte pour %s appelée par %s : %s\n' "$var" "$func" "$value"
		;;
		('en'|*)
			printf 'invalid value for %s called by %s: %s\n' "$var" "$func" "$value"
		;;
	esac
	return 1
}

