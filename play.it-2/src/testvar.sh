# test the validity of the argument given to parent function
# USAGE: testvar $var_name $pattern
testvar() {
	if [ -z "$(echo "$1" | grep ^${2})" ]; then
		return 1
	fi
}

