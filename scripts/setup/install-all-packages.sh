#!/bin/bash

install_required_libraries(){
  set -eo pipefail

  brew tap liamg/tfsec
  brew install pre-commit gawk terraform-docs tflint tfsec coreutils
}

install_required_libraries
