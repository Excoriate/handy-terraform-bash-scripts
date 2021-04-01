#!/usr/bin/env bash

set -e
export PATH=$PATH:/usr/local/bin

validate_main() {
	parsed_command_line_arguments "$@"

	run_validate
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

# Clean up .terraform folder
clean_local_terraform_state_folder(){

  pushd "$DIR" >/dev/null

  echo "directory received: --> $DIR"

  echo "Cleaning .terraform folder in path [$(pwd)]"
  terraform_folder=".terraform"

  if [ -d "$terraform_folder" ]; then
    echo "A .terraform folder has been found. Cleaning it to avoid TF state conflicts"
    echo

    #find . -name "$terraform_folder" -type d -exec rm -rf {} +
    rm -rf "$terraform_folder"
  fi

  popd >/dev/null
}

# Checks whether the local directory passed as argument exists and its valid
check_if_terraform_module_directory_exists() {
  if [[ -d ${DIR} ]]; then
    echo
    echo "Terraform validate (hook) will run on this module --> ${DIR} in path --> $(pwd)"
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
    terraform_validate.sh - Handy script to integrate in pre-commit or run in a stand-alone mode to wrap the terraform validate cmd

SYNOPSIS
    terraform_validate.sh [-h|--help]
    terraform_validate.sh [-d|--dir[=<arg>]]
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

# Run terraform validate without backend
run_validate_terraform_cmd(){
  pushd "$DIR" >/dev/null
  echo "Running validation in directory -->  $DIR"
  echo

  VALIDATE_ERROR=0

	terraform init -backend=false || VALIDATE_ERROR=$?
 	terraform validate

 	if [[ ${VALIDATE_ERROR} != 0 ]];
 		then
 			echo "Terraform validate failed in directory --> [$DIR]"
 			echo

 			exit ${VALIDATE_ERROR}
 	fi

  popd >/dev/null
}

# Wrapper function
run_validate(){
	# validate directory
	check_if_terraform_module_directory_exists

	# clean up .terraform folder
	clean_local_terraform_state_folder

	# validate allowed files and module structure
	check_terraform_files_in_directory

	# Run terraform validate command
	run_validate_terraform_cmd

	# clean up .terraform folder
	clean_local_terraform_state_folder
}

# global arrays
declare -a DIR

[[ ${BASH_SOURCE[0]} != "$0" ]] || validate_main "$@"
