#!/usr/bin/env bash

set -eo pipefail

export PATH=$PATH:/usr/local/bin

git_authenticate(){

  if [ "$DEPLOYMENT_LOCAL" != "true" ] || [ -z "$DEPLOYMENT_LOCAL" ];
  	 then
       	echo "Attempting to register a git GITLAB_TOKEN in automation"
      	echo

        git config --global credential.helper store
        echo "https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com" > ~/.git-credentials
		else
        echo "Skipping. Local execution detected..."
        echo
  fi
}

git_authenticate