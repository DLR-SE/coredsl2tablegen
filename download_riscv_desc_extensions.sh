#!/bin/bash

commandline="$0 $*"
echo "Commandline + :" $commandline

if [ "$#" -lt 1 ]; then
  echo "Usage: download_riscv-desc_extensions.sh REPO_PRIVATE_TOKEN" >&2
  exit 1
fi

set -e

REPO_PRIVATE_TOKEN=$1
shift



 rv_cdsl_ext_prj_id=$(curl --header "PRIVATE-TOKEN: $REPO_PRIVATE_TOKEN " --silent "https://gitlab.dlr.de/api/v4/projects?search=riscv-coredsl-extensions" | jq '.[0].id');

 rv_cdsl_ext_pl_id=$(curl --header "PRIVATE-TOKEN: $REPO_PRIVATE_TOKEN " --silent "https://gitlab.dlr.de/api/v4/projects/$rv_cdsl_ext_prj_id/pipelines" | jq '.[0].id') 

 rv_cdsl_ext_job_id=$(curl --header "PRIVATE-TOKEN: $REPO_PRIVATE_TOKEN " --silent "https://gitlab.dlr.de/api/v4/projects/$rv_cdsl_ext_prj_id/jobs" | jq '.[0].id') 

#download the artifact with the previous information
curl --location --header "PRIVATE-TOKEN: $REPO_PRIVATE_TOKEN " --output artifacts.zip "https://gitlab.dlr.de/api/v4/projects/$rv_cdsl_ext_prj_id/jobs/$rv_cdsl_ext_job_id/artifacts"
