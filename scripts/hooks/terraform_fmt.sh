#!/usr/bin/env bash

set -eo pipefail

export PATH=$PATH:/usr/local/bin

# Entry point for this pre-commit bash script
fmt_main(){
	parsed_command_line_arguments "$@"

	check_if_terraform_module_directory_exists

	check_terraform_files_in_directory

	run_terraform_fmt
}

# Checks whether the local directory passed as argument exists and its valid
check_if_terraform_module_directory_exists() {
  if [[ -d ${DIR} ]]; then
    echo
    echo "Terraform fmt (hook) will run on this module --> ${DIR} in path --> $(pwd)"
    echo

  else
    echo
    echo "Error: ${DIR} not found in path $(pwd)"
    echo

    exit 3
  fi
}

# Check whether exists allowed files to be scanned in current directory
check_terraform_files_in_directory() {
  pushd "$DIR" >/dev/null

  local terraform_files_in_path
  terraform_files_in_path=$(find ./ -maxdepth 1 -name "*.tf")

  if [ ${#terraform_files_in_path[@]} -gt 0 ]; then
    echo "Directory contains valid terraform files (.tf)"
    echo
  else
    echo "Error. Cannot identify valid terraform files in directory --> $DIR in path --> $(pwd)"
    echo
    exit 3
  fi

  popd >/dev/null
}

# Describe the usage for this pre-commit hook script
usage() {
  cat - >&2 <<EOF
NAME
    terraform_fmt.sh - Handy script to integrate in pre-commit or run in a stand-alone mode to wrap the terraform fmt cmd

SYNOPSIS
    terraform_fmt.sh [-h|--help]
    terraform_fmt.sh [-d|--dir[=<arg>]]
                      [--]

OPTIONS
  -h, --help
          Prints this and exits

  -d, --dir
          The terraform (module) directory
EOF
}

# Error handling
fatal() {
  for i; do
    echo -e "${i}" >&2
  done
  exit 1
}

# Parse command line arguments
parsed_command_line_arguments() {
  delimiter_flag="="

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

  echo "DIRECTORY                 = ${DIR}"
}

run_terraform_fmt_check(){
 	#pushd "$DIR" >/dev/null
  FMT_ERROR=0

  echo "(FMT) directory to format: --> $DIR in path: $(pwd)"

  for file in ${DIR}/*.tf; do
    echo "Checking format of file --> $file"
    terraform fmt -diff -check "$file" || FMT_ERROR=$?
  done

  if [[ -n ${FMT_ERROR} ]] && [[  ${FMT_ERROR} != 0 ]];
  	then
  		echo "Error. Terraform fmt (fix) exited with an error code --> $FMT_ERROR"
  		echo

  		exit ${FMT_ERROR}
  fi

#  popd >/dev/null
}

run_terraform_fmt_fix(){
#  pushd "$DIR" >/dev/null
  FMT_ERROR=0

  echo "(FMT) directory to format: --> $DIR in path: $(pwd)"

  for file in ${DIR}/*.tf; do
    echo "Formatting and fixing file --> $file"
    terraform fmt -list=true -write=true "$file" || FMT_ERROR=$?
  done

  if [[ -n ${FMT_ERROR} ]] && [[  ${FMT_ERROR} != 0 ]];
  	then
  		echo "Error. Terraform fmt (fix) exited with an error code --> $FMT_ERROR"
  		echo

  		exit ${FMT_ERROR}
  fi

#  popd >/dev/null
}

run_terraform_fmt(){
	# Fix whether exists errors
	run_terraform_fmt_fix

	# Check whether it is addressed the canonical format and convention forced by TF.
	run_terraform_fmt_check
}

# Globals
declare -a DIR

[[ ${BASH_SOURCE[0]} != "$0" ]] || fmt_main "$@"
