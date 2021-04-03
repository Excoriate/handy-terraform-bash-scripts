#!/usr/bin/env bash

set -eo pipefail

export PATH=$PATH:/usr/local/bin

env_sourcer_main(){
	parsed_command_line_arguments "$@"

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
    -d=* | --dir=*)
      raw_input_dir="${i#*=}"
      echo "Raw input dir =====> $raw_input_dir"
      DIR="$raw_input_dir"
      shift # past argument=value
      ;;
    *)
      ;;
    *) fatal "Unknown option: '-${i}'" "See '${0} --help' for usage" ;;
    esac
  done

  echo "DIRECTORY                	 = ${DIR}"
  echo "README             				 = ${README}"
}

usage() {
  cat - >&2 <<EOF
NAME
    sourcer_env.sh - Source .env files throughout bash ;)

SYNOPSIS
    sourcer_env.sh [-h|--help]
    sourcer_env.sh [-d|--dir[=<arg>]]
    sourcer_env.sh [-f|--file[=<arg>]]
                      [--]

OPTIONS
  -h, --help
          Prints this and exits

  -d, --dir
          Where the .env files is located. Defaults to the root of the project
  -f, --file
          How the .env file is named. Defaults to .env
EOF
}

# Globals
declare -a ENV_FILE
declare -a ENV_DIR

[[ ${BASH_SOURCE[0]} != "$0" ]] || env_sourcer_main "$@"

