#!/usr/bin/env bash

set -eo pipefail

export PATH=$PATH:/usr/local/bin


env_source_main(){
	parsed_command_line_arguments "$@"

	initialize_or_fallback

	run_pre_validations

	source_env_in_current_shell_session
}

initialize_or_fallback(){
	if [[ -z ${ENV} ]];
		then
			echo "Fallback option. Setting to .env"
			echo
			ENV=".env"
	fi
}

run_pre_validations(){
	if [[ ! -f ${ENV} ]];
		then
			echo "Error. Dot env file $ENV could not be found in path --> $(pwd)"
			echo
			exit 4
	fi

	if [[ ! -s ${ENV} ]];
		then
			echo "Error. Dot env file $ENV is empty --> $(pwd)"
			echo
			exit 4
		else
			cat ${ENV}
	fi
}

source_env_in_current_shell_session(){
	. ${ENV}
	printenv
}

parsed_command_line_arguments() {

  for arg in "$@"; do
    echo "argument received --> [$arg]"
  done

  for i in "$@"; do
    case $i in
    -h)
      usage
      exit 0
      ;;
    -f=* | --file=*)
      raw_input_file="${i#*=}"
      echo "Raw input file =====> $raw_input_file"
      FILE="$raw_input_file"
      shift # past argument=value
      ;;
    *)
      ;;
    *) fatal "Unknown option: '-${i}'" "See '${0} --help' for usage" ;;
    esac
  done

  echo "FILE                	 = ${FILE}"
}

usage() {
  cat - >&2 <<EOF
NAME
    sourcer_env.sh - Source .env files throughout bash ;)

SYNOPSIS
    sourcer_env.sh [-h|--help]
    sourcer_env.sh [-f|--file[=<arg>]]
                      [--]

OPTIONS
  -h, --help
          Prints this and exits
  -f, --file
          How the .env file is named. Defaults to .env
EOF
}

# Globals
declare FILE

[[ ${BASH_SOURCE[0]} != "$0" ]] || env_source_main "$@"

