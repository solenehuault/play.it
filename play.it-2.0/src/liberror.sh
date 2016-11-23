# display an error if a function has been called with invalid arguments
# USAGE: liberror $var_name $calling_function
liberror() {
	local var="$1"
	local value="$(eval echo \$$var)"
	local func="$2"
	case ${LANG%_*} in
		fr)
			echo "$string_error_fr"
			echo "valeur incorrecte pour $var appelée par $func : $value"
		;;
		en|*)
			echo "$string_error_en"
			echo "invalid value for $var called by $func: $value"
		;;
	esac
	return 1
}

