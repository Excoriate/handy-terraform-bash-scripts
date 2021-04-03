#!/usr/bin/env bash

set -eo pipefail

export PATH=$PATH:/usr/local/bin

docs_main(){
  parsed_command_line_arguments "$@"

  initialize_arguments_or_fallback

  set_constants

  run_pre_validations

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

#Run set of validations based on the arguments passed
run_pre_validations(){
	check_whether_folder_exists "${DIR}"

  check_whether_folder_exists "${TERRAFORM_MODULE}"

  check_terraform_files_in_directory

  check_markdown_files_in_directory
}


usage() {
  cat - >&2 <<EOF
NAME
    terraform_docs.sh - Automate terraform documentation and markdown documentation.

SYNOPSIS
    terraform_docs.sh [-h|--help]
    terraform_docs.sh [-d|--dir[=<arg>]]
    terraform_docs.sh [-m|--module[=<arg>]]
    terraform_docs.sh [-x|--tfdocs[=<arg>]]
    terraform_docs.sh [-a|--auto[=<arg>]]
                      [--]

OPTIONS
  -h, --help
          Prints this and exits

  -d, --dir
          The directory in which find the .md files to use for build the readme.md. Default root folder

  -m, --module
          Main directory which contains valid terraform module files

  -a, --auto
          If set (true/false), it will scan all the .md files found in the passed [dir]. Default true

  -x, --tfdocs
          If set (true/false), it will generate automatically terraform documentation. Default false
EOF
}

set_constants(){
	README=("readme.md")
  README_NEW=("readme_new.md")
  README_TEMP=("readme_temp.md")

  TEMPLATE_HOW_TO_USE_IT=("4_how_to_use_it.md")
	TEMPLATE_HOW_TO_GENERATE_DOCS=("5_how_to_generate_documentation.md")

	TEMPLATE_PROJECT_DEPENDENCIES=("3_project_dependencies.md")
	TEMPLATE_PROJECT_DESCRIPTION=("1_project_description.md")
	TEMPLATE_PROJECT_REQUIREMENTS=("2_project_requirements.md")
	TFDOC_DOC_TEMP_FILENAME="0_tfdoc_automatic_generated.md"
}

# check whether a directory exists
check_whether_folder_exists(){
	local passed_folder="$1"

	if [[ -d ${passed_folder} ]];
		then
			echo "Folder $passed_folder validated in path --> $(pwd)"
			echo
		else
			echo "Folder $passed_folder does not exists in path --> $(pwd)"
	    exit 3
	fi
}

# initialize set of required global bash variables
initialize_arguments_or_fallback(){

  if [[ -z ${AUTO} ]];
  	then
  		AUTO="false"
  	else
  		if  [[ ${AUTO} != "true" ]];
  			then
  				echo "Unknown option received for variables: $AUTO"
  				exit 3
  		fi
  fi

  if [[ -z ${TFDOCS_ENABLED} ]];
  	then
  		TFDOCS_ENABLED="false"
  	else
  		if  [[ ${TFDOCS_ENABLED} != "true" ]];
  			then
  				echo "Unknown option received for [TFDOCS_ENABLED] option: $TFDOCS_ENABLED"
  				echo $TFDOCS_ENABLED
  				exit 3
  		fi
  fi

  if [[ -z ${DIR} ]];
  	then
  		DIR=("docs")
  		echo "Unknown [dir] option. Fallback to .docs/"
  fi

  if [[ -z ${TERRAFORM_MODULE} ]];
  	then
  		TERRAFORM_MODULE=("module")
  		echo "Unknown [TERRAFORM_MODULE] option. Fallback to module/"
  fi
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
    -a=* | --auto=*)
      raw_input_auto="${i#*=}"
      echo "Raw input auto =====> $raw_input_auto"
      AUTO="$raw_input_auto"
      shift # past argument=value
      ;;
    -x=* | --tfdocs=*)
      raw_input_tfdocs="${i#*=}"
      echo "Raw input raw_input_tfdocs =====> $raw_input_tfdocs"
      TFDOCS_ENABLED="$raw_input_tfdocs"
      shift # past argument=value
      ;;
    -m=* | --module=*)
      raw_input_module="${i#*=}"
      echo "Raw input module =====> $raw_input_module"
      TERRAFORM_MODULE="$raw_input_module"
      shift # past argument=value
      ;;
    *)
      ;;
    *) fatal "Unknown option: '-${i}'" "See '${0} --help' for usage" ;;
    esac
  done

  echo "DOCS DIRECTORY                	 	= ${DIR}"
  echo "AUTO SCAN OPTION             			= ${AUTO}"
  echo "TERRAFORM MODULE DIR             	= ${TERRAFORM_MODULE}"
  echo "TERRAFORM DOCS GENERATOR          = ${TFDOCS_ENABLED}"
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
create_new_blank_readme_file(){
	pushd "$DIR" >/dev/null

	if [[ ! -f ${README_NEW} ]];
		then
			touch "$README_NEW"
			echo "Created new readme.md file in path $(pwd)"
		else
			echo "Creation of readme_new.md temporal file was ignored."
			echo
	fi

	popd >/dev/null
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
append_markdown_document(){
	pushd "$DIR" >/dev/null

	local document="$1"

  if [ -f "${document}" ];
    then
        echo "Generating document appending $document  ................."
        echo

        echo -e "$(cat $document)\n\n" >> "$README_NEW"

        echo "Appended document $document"
        echo
    else
        echo "Error, cannot append file  --> $document. Is not present in folder $DIR examined in path $(pwd)"
        exit 3
  fi

  popd >/dev/null
}

# Run terraform-docs command to append a markdown table to the readme.md
append_terraform_tfdoc_output(){
  pushd "$TERRAFORM_MODULE" >/dev/null

	# this document is generated in the module folder. See argument $TERRAFORM_MODULE
  echo -e "$(terraform-docs markdown table .)\n\n"  >>  ${TFDOC_DOC_TEMP_FILENAME}

  popd >/dev/null

	# Move the file to the /docs folder. See argument $DIR
  mv "$TERRAFORM_MODULE/$TFDOC_DOC_TEMP_FILENAME" "$DIR/$TFDOC_DOC_TEMP_FILENAME"
}

replace_readme_with_new_version(){
  local new_readme_full_path="$DIR/$README_NEW"
  local new_readme_on_root_directory="$README"

  mv "$new_readme_full_path" "$new_readme_on_root_directory"

	if [[ -f ${README_TEMP} ]];
		then
			rm "$README_TEMP"
	fi
}

# Check whether exists allowed files to be scanned in current directory
check_markdown_files_in_directory() {
  pushd "$DIR" >/dev/null

  local markdown_compatible_docs
  markdown_compatible_docs=$(find ./ -maxdepth 1 -name "*.md")

  if [ ${#markdown_compatible_docs[@]} -gt 0 ]; then
    echo "Directory contains valid markdown files (.md)"
    echo
  else
    echo "Error. Cannot identify valid markdown files in directory --> $DIR in path --> $(pwd)"
    echo
    exit 3
  fi

  popd >/dev/null
}

# Check whether exists allowed files to be scanned in current directory
check_terraform_files_in_directory() {
  pushd "$TERRAFORM_MODULE" >/dev/null

  local terraform_files_in_path
  terraform_files_in_path=$(find ./ -maxdepth 1 -name "*.tf")

  if [ ${#terraform_files_in_path[@]} -gt 0 ]; then
    echo "Directory contains valid terraform files (.tf)"
    echo
  else
    echo "Error. Cannot identify valid terraform files in directory --> $TERRAFORM_MODULE in path --> $(pwd)"
    echo
    exit 3
  fi

  popd >/dev/null
}

build_markdown_document(){

	if [[ ${TFDOCS_ENABLED} == "true" ]];
		then
			echo "Option $TFDOCS_ENABLED is enabled. Generating terraform docs..."
			echo

			append_terraform_tfdoc_output
	fi

	if [[ ${AUTO} == "true" ]];
		then
			# if auto is enabled, dynamically will scan the DIR folder looking for *.md files
			#TODO: Pending to implement static argument-based .md files structure generation
			echo "Option AUTO is enabled. Dynamically appending .md files..."
			echo
		else
			# Create the readme following the default preset structure documents
			echo "Option AUTO is disabled."
			echo

			append_markdown_document "$TEMPLATE_PROJECT_DESCRIPTION"
			append_markdown_document "$TEMPLATE_PROJECT_REQUIREMENTS"
			append_markdown_document "$TEMPLATE_PROJECT_DEPENDENCIES"
			append_markdown_document "$TEMPLATE_HOW_TO_USE_IT"
			append_markdown_document "$TEMPLATE_HOW_TO_GENERATE_DOCS"

			if [[ ${TFDOCS_ENABLED} == "true" ]];
				then
					append_markdown_document "$TFDOC_DOC_TEMP_FILENAME"

					pushd "$DIR" >/dev/null
					rm $TFDOC_DOC_TEMP_FILENAME #after append, this file is no longer needed.
					popd >/dev/null
			fi
	fi
}

generate_docs(){
  # 1.  make the backup
  if_exists_do_backup

  # 2. create the new readme.md file to be updated
  create_new_blank_readme_file

  # 3. append the parts or components of the final readme.md file to generate
  build_markdown_document

  # 4. Place file readme.md file into root directory
  replace_readme_with_new_version
}

# Globals / arguments
declare AUTO
declare TFDOCS_ENABLED
declare -a TERRAFORM_MODULE
declare -a DIR

# constants
declare -a README
declare -a README_NEW
declare -a README_TEMP
declare TFDOC_DOC_TEMP_FILENAME

# constants
declare -a TEMPLATE_HOW_TO_USE_IT
declare -a TEMPLATE_HOW_TO_GENERATE_DOCS
declare -a TEMPLATE_PROJECT_DEPENDENCIES
declare -a TEMPLATE_PROJECT_DESCRIPTION
declare -a TEMPLATE_PROJECT_REQUIREMENTS

[[ ${BASH_SOURCE[0]} != "$0" ]] || docs_main "$@"
