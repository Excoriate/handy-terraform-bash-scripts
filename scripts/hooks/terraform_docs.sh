#!/usr/bin/env bash

set -eo pipefail

export PATH=$PATH:/usr/local/bin

docs_main(){
  initialize

  parsed_command_line_arguments "$@"

  generate_docs
}

# Error handling
fatal() {
  for i; do
    echo -e "${i}" >&2
  done
  exit 1
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


usage() {
  cat - >&2 <<EOF
NAME
    terraform_docs.sh - Automate terraform documentation

SYNOPSIS
    terraform_plan.sh [-h|--help]
    terraform_plan.sh [-d|--dir[=<arg>]]
                      [--]

OPTIONS
  -h, --help
          Prints this and exits

  -d, --dir
          The terraform (module) directory
EOF
}

# initialize set of required global bash variables
initialize(){
  README=("readme.md")
  README_NEW=("readme_new.md")
  README_TEMP=("readme_temp.md")
  TEMPLATE_HOW_TO_USE_IT=("docs/how_to_use_it.md")
  TEMPLATE_REQUIREMENTS=("docs/requirements.md")
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

# Do a backup of the readme.md file if exists
if_exists_do_backup(){
  if [[ -f ${README} ]];
    then
      cp "${README}" "${README_TEMP}"
      echo "Backup created in path --> $(pwd)"
      echo
  fi
}

# Create a new empty readme.md file
create_new_updated_readme_file(){
  touch "$README_NEW"
  echo "Created new readme.md file in path $(pwd)"
  echo
}

# Remove temporal readme backup file created
remove_temp_readme_file(){

  if [ -f "$README_TEMP" ];
    then
      rm "$README_TEMP"

      echo "Backup $README_TEMP removed in path --> $(pwd)"
      echo
  fi
}

# Remove the old outdated 'readme.md' file
remove_old_readme_file(){

  if [ -f "$README" ];
    then

      rm "$README"

      echo "Old readme.md file --> $README removed in path --> $(pwd)"
      echo
  fi
}

replace_final_readme_and_clean_up(){
  echo "Updating readme.md on its final version..."
  echo

  mv "${README_NEW}" ${README}

  if [ -f "$README_NEW" ]; then
      rm "$README_NEW"
  fi

  echo "Successfully generated readme.md file in path --> $(pwd)"
  echo

  cat "$README"
}


# Append to the readme.md file the 'how to use it' part to it.
append_how_to_use_it_doc(){

  if [ -f "${TEMPLATE_HOW_TO_USE_IT}" ];
    then
        echo "Generating HOW_TO_USE_IT template ................."
        echo

        echo -e "$(cat $TEMPLATE_HOW_TO_USE_IT)\n\n" >>  "$README_NEW"

        echo "Appended HOW_TO_USE_IT template."
        echo
    else
        echo "Error, TEMPLATE_HOW_TO_USE_IT file  --> $TEMPLATE_HOW_TO_USE_IT is not present in folder docs/ examined in path $(pwd)"
        exit 3
  fi
}

# Append to the readme.md file the 'basic requirements of this module' part to it.
append_requirements_doc(){
  if [ -f "${TEMPLATE_REQUIREMENTS}" ];
    then
        echo "Generating TEMPLATE_REQUIREMENTS template ................."
        echo

        echo -e "$(cat $TEMPLATE_REQUIREMENTS)\n\n" >> "$README_NEW"

        echo "Appended TEMPLATE_REQUIREMENTS template."
        echo
    else
        echo "Error, TEMPLATE_REQUIREMENTS file  --> $TEMPLATE_REQUIREMENTS is not present in folder docs/ examined in path $(pwd)"
        exit 3
  fi
}

# Run terraform-docs command to append a markdown table to the readme.md
append_terraform_output_doc(){
  echo -e "$(terraform-docs markdown table .)\n\n"  >>  "$README_NEW"
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

build_readme_structured(){
	pushd "$DIR" >/dev/null

	append_requirements_doc
  append_how_to_use_it_doc
  append_terraform_output_doc

  # replace the readme.md file with the updated one
  replace_final_readme_and_clean_up
  remove_temp_readme_file

	popd >/dev/null
}

generate_docs(){
  # 1.  validate directory
  check_terraform_files_in_directory

  # 2.  make the backup
  if_exists_do_backup

  # 3. create the new readme.md file to be updated
  create_new_updated_readme_file

  # 4. remove the old outdated file
  remove_old_readme_file

  # 5. append the parts or components of the final readme.md file to generate
  build_readme_structured
}

# Globals
declare -a DIR
declare -a README
declare -a README_NEW
declare -a README_TEMP
declare -a TEMPLATE_HOW_TO_USE_IT
declare -a TEMPLATE_REQUIREMENTS

[[ ${BASH_SOURCE[0]} != "$0" ]] || docs_main "$@"
