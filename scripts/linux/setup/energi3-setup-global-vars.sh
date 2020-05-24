#!/bin/bash

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# Global Variables
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

# Check if we have enough memory
if [[ $(LC_ALL=C free -m | awk '/^Mem:/{print $2}') -lt 850 ]]; then
  echo "This installation requires at least 1GB of RAM.";
  exit 1
fi

# OS Settings
export DEBIAN_FRONTEND=noninteractive

# Locations of Repositories and Guide
API_URL="https://api.github.com/repos/energicryptocurrency/energi3/releases/latest"

# Production
if [[ -z ${BASE_URL} ]]
then
  BASE_URL="raw.githubusercontent.com/energicryptocurrency/energi3-provisioning/master/scripts"
fi

#==> For testing set environment variable
#BASE_URL="raw.githubusercontent.com/zalam003/EnergiCore3/master/production/scripts"
SCRIPT_URL="${BASE_URL}/linux"
TP_URL="${BASE_URL}/thirdparty"
DOC_URL="https://docs.energi.software"
S3URL="https://s3-us-west-2.amazonaws.com/download.energi.software/releases/energi3"

# Snapshot Block (need to update)
MAINNETSSBLOCK=1108550
TESTNETSSBLOCK=1500000

# Set Executables & Configuration
export ENERGI3_EXE=energi3
export ENERGI3_CONF=energi3.toml
export ENERGI3_IPC=energi3.ipc

# Set colors
BLUE=`tput setaf 4`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 2`
NC=`tput sgr0`
