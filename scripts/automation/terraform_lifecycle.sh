#!/usr/bin/env bash

export PATH=$PATH:/usr/local/bin

terraform_main(){
  parsed_command_line_arguments "$@"

  execute_command
}

# Describe the usage for this pre-commit hook script
usage() {
  cat - >&2 <<EOF
NAME
    terraform_lifecycle.sh - Execute and wrap all terraform commands

SYNOPSIS
    terraform_fmt.sh [-h|--help]
    terraform_fmt.sh [-t|--cmd[=<arg>]]
    terraform_fmt.sh [-v|--vars[=<arg>]]
    terraform_fmt.sh [-c|--config[=<arg>]]
                      [--]

OPTIONS
  -h, --help
          Prints this and exits

  -c, --command
          Name of the terraform command to Execute.
          Valid parameters are: init, plan, apply, destroy

  -d, --dir
          The terraform (module) directory

  -v, --vars
          Path of the terraform.tfvars file

  -c, --config
          Path of the remote.config file used to Initialize the module
* NOTES
---------------------------------------------------------
Config (default: config/remote.config)
Terraform Tfvars (default: config/terraform.tfvars)
Module path (default: example/)
---------------------------------------------------------
EOF
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

# Clean up .terraform folder
clean_local_terraform_state_folder(){
  echo "Cleaning .terraform folder in path [$(pwd)]"
  echo

  local is_dir_scoped_set=${1}

	if [[ -n ${is_dir_scoped_set} ]]; # Conditionally set the directory
    then
    	echo "Directory scope set (establishing...)"
    	pushd "$DIR" >/dev/null
	 fi

  terraform_folder=".terraform"

  if [ -d "$terraform_folder" ]; then
    echo "A .terraform folder has been found. Cleaning it to avoid TF state conflicts"
    echo

    rm -rf "$terraform_folder"
  fi

  if [[ -n ${is_dir_scoped_set} ]];
    then
    	echo "Directory scope set (unset)"
    	popd >/dev/null
   fi

}

# Checks whether the local directory passed as argument exists and its valid
check_input_variables() {
	pushd "$DIR" >/dev/null

  if [[ -n ${PATH_REMOTE_BACKED_CONFIG} ]];
  	then
  		if [[ ! -f ${PATH_REMOTE_BACKED_CONFIG} ]];
  			then
  				echo "Error. File $PATH_REMOTE_BACKED_CONFIG (remote BACKEND config) not found in path --> $(pwd)"
  				echo
  				exit 1
  		fi
  fi

  if [[ -n ${PATH_TF_VARS} ]];
  	then
  		if [[ ! -f ${PATH_TF_VARS} ]];
  			then
  				echo "Error. File $PATH_TF_VARS (terraform TFVARS) not found in path --> $(pwd)"
  				echo
  				exit 1
  		fi
  fi

  popd >/dev/null
}

# Checks whether the local directory passed as argument exists and its valid
check_if_terraform_module_directory_exists() {
  if [[ -d ${DIR} ]]; then
    echo
    echo "Terraform command will run on this module --> ${DIR} in path --> $(pwd)"
    echo

  else
    echo
    echo "Error: ${DIR} not found in path $(pwd)"
    echo

    exit 3
  fi
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
    echo
  done

  for i in "$@"; do
    case $i in
    -h)
      usage
      exit 0
      ;;
    -t=* | --command=*)
      TF_COMMAND="${i#*=}"

      if [[ -z ${TF_COMMAND} ]];
      	then
      		echo "Error. Terraform cmd flag is missing"
      		exit 1
      fi

      shift
      ;;
    -d=* | --dir=*)
      DIR="${i#*=}"
      shift
      ;;
    -c=* | --config=*)
      PATH_REMOTE_BACKED_CONFIG="${i#*=}"
      shift
      ;;
    -v=* | --vars=*)
      PATH_TF_VARS="${i#*=}"
      shift
      ;;
    *)
      ;;
    *) fatal "Unknown option: '-${i}'" "See '${0} --help' for usage" ;;
    esac
  done

  echo "COMMAND                 = ${TF_COMMAND}"
}

wrapper_init(){
    set -e
    echo "##### Terraform Init #####"
    echo

    local is_dir_scoped_set=${1}

    if [[ -n ${is_dir_scoped_set} ]]; # Conditionally set the directory
    	then
    		echo "Directory scope set (establishing...)"
    		pushd "$DIR" >/dev/null
    fi

    echo "directory received: --> $DIR in path $(pwd)"

    clean_local_terraform_state_folder

    if [[ -z ${PATH_REMOTE_BACKED_CONFIG} ]];
    	then
    		echo "Terraform initialization will be performed without remote backend"
    		echo

    		terraform init -backend=false
    	else
				if [[ -z ${AWS_ACCESS_KEY_ID} ]];
					then
						echo "AWS_ACCESS_KEY_ID has been detected export (environment variable)"
						echo

						terraform init \
							-backend-config "${PATH_REMOTE_BACKED_CONFIG}" \
							-backend-config="access_key=${AWS_ACCESS_KEY_ID}" \
							-backend-config="secret_key=${AWS_SECRET_ACCESS_KEY}"
					else
						terraform init \
      				-backend-config "${PATH_REMOTE_BACKED_CONFIG}"
				fi
    fi

    if [[ -n ${is_dir_scoped_set} ]];
    	then
    		echo "Directory scope set (unset)"
    		popd >/dev/null
    fi
}

wrapper_plan(){
    set -e
    echo "##### Terraform plan #####"
    echo

    pushd "$DIR" >/dev/null
    echo "directory received: --> $DIR in path $(pwd)"

    wrapper_init

    if [[ -z ${PATH_TF_VARS} ]];
    	then
    		echo "Terraform PLAN without terraform.tfvars set"
    		echo

    		terraform plan
    	else
				echo "Terraform plan using this terraform.tfvars file --> ${PATH_TF_VARS}"
				echo

				echo

				terraform plan \
      			-var-file=${PATH_TF_VARS}
				echo

    fi

    popd >/dev/null
}

wrapper_apply(){
    set -e
    echo "##### Terraform Apply #####"
    echo

    pushd "$DIR" >/dev/null
    echo "directory received: --> $DIR in path $(pwd)"

		wrapper_init

    if [[ -z ${PATH_TF_VARS} ]];
    	then
    		echo "Terraform apply without terraform.tfvars set"
    		echo

    		terraform apply -auto-approve
    	else
				echo "Terraform apply using this terraform.tfvars file --> ${PATH_TF_VARS}"
				echo

				echo

    		terraform apply -auto-approve \
       		-var-file=${PATH_TF_VARS}
    fi

    popd >/dev/null
}

wrapper_destroy(){
    set -e
    echo "##### Terraform Destroy  #####"
    echo

    pushd "$DIR" >/dev/null
    echo "directory received: --> $DIR in path $(pwd)"

		wrapper_init

    if [[ -z ${PATH_TF_VARS} ]];
    	then
    		echo "Terraform destroy without terraform.tfvars set"
    		echo

    		terraform destroy -auto-approve
    	else
				echo "Terraform destroy using this terraform.tfvars file --> ${PATH_TF_VARS}"
				echo

				echo

    		terraform destroy -auto-approve \
       		-var-file=${PATH_TF_VARS}
    fi

    popd >/dev/null
}

execute_command(){
	# Validate first whether the passed module exists
	check_if_terraform_module_directory_exists

	# Validate required files within the module directory
	check_terraform_files_in_directory

	# Validate input variables
	check_input_variables

	while true ; do
			case "$TF_COMMAND" in
					init)
							wrapper_init "true"
							exit "$?"

							shift
					;;

					plan)
							wrapper_plan
							exit "$?"

							shift
					;;

					apply)
							wrapper_apply
							exit "$?"

							shift
					;;

					destroy)
							wrapper_destroy
							exit "$?"

							shift
					;;

					clean)
							clean_local_terraform_state_folder "true"
							exit "$?"

							shift
					;;

					*)
							break
					;;
			esac
	done;
}

# Globals
declare -a PATH_REMOTE_BACKED_CONFIG
declare -a PATH_TF_VARS
declare -a DIR
declare -a TF_COMMAND

[[ ${BASH_SOURCE[0]} != "$0" ]] || terraform_main "$@"