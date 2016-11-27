# display an error if a function has been called with invalid arguments
# USAGE: liberror $var_name $calling_function
liberror() {
	local var="$1"
	local value="$(eval echo \$$var)"
	local func="$2"
	case ${LANG%_*} in
		('fr')
			printf "$string_error_fr\n"
			echo "valeur incorrecte pour $var appelée par $func : $value"
		;;
		('en'|*)
			printf "$string_error_en\n"
			echo "invalid value for $var called by $func: $value"
		;;
	esac
	return 1
}

