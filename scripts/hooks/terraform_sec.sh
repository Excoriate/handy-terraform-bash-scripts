#!/usr/bin/env bash

set -eo pipefail

export PATH=$PATH:/usr/local/bin

sec_main(){
  parsed_command_line_arguments "$@"

  scan "$DIR"
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
    terraform_sec.sh - Handy script to integrate in pre-commit or run in a stand-alone mode to wrap the tfsec utility

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

run_tf_sec(){
  pushd "$DIR" >/dev/null

  echo "Scanning...."
  echo

  TF_SEC_ERROR=0

  tfsec . || TF_SEC_ERROR=$?

  exit ${TF_SEC_ERROR}

  echo "All files scanned successfully in path [$(pwd)]"
  echo
}

# initialize set of required global bash variables
initialize(){
  DIR=("$@")
  echo "Current path is: [$(pwd)]"
  echo

  echo "Current scoped directory is: [$DIR]"
  echo
}

scan(){
  # 1.  validate directory
  check_if_terraform_module_directory_exists

  # 2.  validate files allowed in directory passed
  check_terraform_files_in_directory

  # 3.  Run scan with tfsec
  run_tf_sec
}

# Globals
declare -a DIR

[[ ${BASH_SOURCE[0]} != "$0" ]] || sec_main "$@"
