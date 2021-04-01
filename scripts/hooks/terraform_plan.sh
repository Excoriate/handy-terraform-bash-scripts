#!/usr/bin/env bash

set -eo pipefail

export PATH=$PATH:/usr/local/bin

plan_main() {
  parsed_command_line_arguments "$@"

  run_plan
}

run_pre_hook_validations() {
  check_if_terraform_module_directory_exists # validate directory of the main module

  check_terraform_files_in_directory # check .tf allowed files in the given directory
}

usage() {
  cat - >&2 <<EOF
NAME
    terraform_plan.sh - Handy script to integrate in pre-commit or run in a stand-alone mode to wrap the terraform plan cmd

SYNOPSIS
    terraform_plan.sh [-h|--help]
    terraform_plan.sh [-d|--dir[=<arg>]]
                      [-v|--vars[=<arg>]]
                      [-b|--backend[=<arg>]]
                      [--]

OPTIONS
  -h, --help
          Prints this and exits

  -d, --dir
          The terraform (module) directory

  -b, --backend
          (Optional) specify the relative path or directory with the backend config file

NOTE:
   * If no options are provided, it will fallback into a initialization with no backend
   * Once the hook finished, it cleans up the .terraform folder if exists
EOF
}

# Error handling
fatal() {
  for i; do
    echo -e "${i}" >&2
  done
  exit 1
}

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
    -b=* | --backend=*)
      raw_input_backend="${i#*=}"
      echo "Raw input backend =====> $raw_input_backend"
      CONFIG_TERRAFORM_REMOTE_BACKEND_FILE_PATH="$raw_input_backend"
      shift # past argument=value
      ;;
    -v=* | --vars=*)
      raw_input_vars="${i#*=}"
      echo "Raw input vars =====> $raw_input_vars"
      CONFIG_TERRAFORM_TFVARS_FILE_PATH="$raw_input_vars"
      shift # past argument=value
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
  echo "BACKEND PATH              = ${CONFIG_TERRAFORM_REMOTE_BACKEND_FILE_PATH}"
  echo "TERRAFORM TFVARS PATH     = ${CONFIG_TERRAFORM_TFVARS_FILE_PATH}"
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

# Checks whether the local directory passed as argument exists and its valid
check_if_terraform_module_directory_exists() {

  if [ -d "$DIR" ]; then
    echo
    echo "Terraform plan (hook) will run on this module --> $DIR in path --> $(pwd)"
    echo

  else
    echo
    echo "Error: $DIR not found in path $(pwd)"
    echo

    exit 3
  fi
}

# Validate if a given directory exists
check_config_file_if_exists() {
  local_config_file="$1"

  if [ -f "$local_config_file" ]; then
    echo
    echo "Config file --> $local_config_file validated in path --> $(pwd)"
    echo

  else
    echo
    echo "Error: $local_config_file configuration file not found in path $(pwd)"
    echo

    exit 3
  fi
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

# Run terraform init command. Compatible with either (remote) backend or without it
run_terraform_init_cmd(){
  pushd "$DIR" >/dev/null

  echo "Terraform Init..."
  echo

  if [[ -z ${CONFIG_TERRAFORM_REMOTE_BACKEND_FILE_PATH} ]];
    then
      echo "Terraform Init started without backend configuration"
      echo

      terraform init -backend=false
    else
      echo "Terraform Init with backend file configuration in --> $CONFIG_TERRAFORM_REMOTE_BACKEND_FILE_PATH"
      echo

      check_config_file_if_exists "$CONFIG_TERRAFORM_REMOTE_BACKEND_FILE_PATH"

      terraform init \
      	-backend-config "$CONFIG_TERRAFORM_REMOTE_BACKEND_FILE_PATH"
  fi

  popd >/dev/null
}

run_terraform_plan_cmd(){
  pushd "$DIR" >/dev/null

  echo "Terraform Plan command..."
  echo

  if [[ -z ${CONFIG_TERRAFORM_TFVARS_FILE_PATH} ]];
    then
      echo "Terraform Plan started without an specific terraform.tfvars file"
      echo

      terraform plan
    else
      echo "Terraform Plan with a [terraform.tfvars] file --> $CONFIG_TERRAFORM_TFVARS_FILE_PATH"
      echo

      check_config_file_if_exists "$CONFIG_TERRAFORM_TFVARS_FILE_PATH"

      terraform plan \
      -var-file="$CONFIG_TERRAFORM_TFVARS_FILE_PATH"
  fi

  popd >/dev/null
}

run_plan() {
  # 1. Validate terraform module directory
  check_if_terraform_module_directory_exists

  # 2. Validate allowed files (.tf) in given directory
  check_terraform_files_in_directory

  # 3. Prevent previous executions and clean up .terraform folder directory from modules path
  clean_local_terraform_state_folder

  # 4. Run terraform init. Required to execute later on the [terraform plan] command
  run_terraform_init_cmd

  # 5. Run terraform plan
  run_terraform_plan_cmd

  # 6.Clean up .terraform folder directory from modules path
  clean_local_terraform_state_folder
}

# Globals
declare -a DIR
declare -a CONFIG_TERRAFORM_TFVARS_FILE_PATH
declare -a CONFIG_TERRAFORM_REMOTE_BACKEND_FILE_PATH

[[ ${BASH_SOURCE[0]} != "$0" ]] || plan_main "$@"
