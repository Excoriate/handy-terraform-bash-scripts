#!/usr/bin/env bash

set -eo pipefail

export PATH=$PATH:/usr/local/bin

entry_point(){
  parsed_command_line_arguments "$@"

  lint
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
    terraform_lint.sh - Handy script to integrate in pre-commit or run in a stand-alone mode to wrap the terraform TFLINT utility

SYNOPSIS
    terraform_lint.sh [-h|--help]
    terraform_lint.sh [-d|--dir[=<arg>]]
    terraform_lint.sh [-|--module[=<true/false>]]
    terraform_lint.sh [-c|--config[=<arg>]]
                      [--]

OPTIONS
  -h, --help
          Prints this and exits

  -d, --dir
          The terraform (module) directory
  -c, --config
          In case the .tflint configuration file is in a custom directory or path.
          Omit it whether the file is expected to be in the [dir] directory given.
  -m, --module
          Enable module deep inspection. If this option is set to true, it
          will make a terraform initialization in order to do a terraform get
          and the required child modules called
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
    -c=* | --config=*)
      raw_input_config="${i#*=}"
      echo "Raw input config =====> $raw_input_config"
      CONFIG_TFLINT="$raw_input_config"
      shift # past argument=value
      ;;
    -m=* | --module=*)
      raw_input_module="${i#*=}"
      echo "Raw input module =====> $raw_input_module"
      MODULE="$raw_input_module"
      shift # past argument=value
      ;;
    *)
      ;;
    *) fatal "Unknown option: '-${i}'" "See '${0} --help' for usage" ;;
    esac
  done

  echo "DIRECTORY                 = ${DIR}"
  echo "TFCONFIG FILE             = ${CONFIG_TFLINT}"
  echo "MODULE             				= ${MODULE}"
}

# Run terraform init command. Compatible with either (remote) backend or without it
run_terraform_init_cmd(){
  echo "Terraform Init..."
  echo

	terraform init -backend=false
}

# Clean up .terraform folder
clean_local_terraform_state_folder(){
  echo "directory received: --> $DIR"
  echo "Cleaning .terraform folder in path [$(pwd)]"
  echo

  terraform_folder=".terraform"

  if [ -d "$terraform_folder" ]; then
    echo "A .terraform folder has been found. Cleaning it to avoid TF state conflicts"
    echo

    find . -name "$terraform_folder" -type d -exec rm -rf {} +
  fi
}

# Wrap and run the TFLINT command
run_tf_lint(){
	pushd "$DIR" >/dev/null

	tflint_config_resolved=$(if [[ -z ${CONFIG_TFLINT} ]]; then echo ".tflint.hcl"; else "$CONFIG_TFLINT"; fi)

	echo "Configuration TFLINT file --> [$tflint_config_resolved]"

	if [[ ! -f ${tflint_config_resolved} ]];
		then
			echo "Error: Configuration file for TFLINT does not exist in path --> $(pwd)"
			echo
			exit 3
	fi


	if [[ -z ${MODULE} ]] ||  [[ ${MODULE} != "true" ]];
		then
			echo "Executing TFLINT without the [MODULE] deep inspection."
			echo

			tflint --config="$tflint_config_resolved"
		else
			echo "Executing TFLINT with [MODULE] deep inspection."
			echo

			# An initialization is required
			run_terraform_init_cmd
			tflint --module --config="$tflint_config_resolved"
			clean_local_terraform_state_folder
	fi

  popd > /dev/null
}

lint(){
	# Validate working directory
	check_if_terraform_module_directory_exists

	# Validate if valid files are present in the given (passed) directory
	check_terraform_files_in_directory

	# Run TFLint on the current directory
	run_tf_lint
}


# Globals
declare -a DIR
declare -a CONFIG_TFLINT
declare -a MODULE

[[ ${BASH_SOURCE[0]} != "$0" ]] || entry_point "$@"
