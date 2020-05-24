#!/bin/bash

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# Functions used in Energi setup scripts
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

_add_logrotate () {
  # Setup log rotate

  # Logs in $HOME/.energicore3 will rotate automatically when it reaches 100M
  if [ ! -f /etc/logrotate.d/energi3 ]
  then
    echo "Setting up log maintenance for energi3"
    sleep 0.3
    cat << ENERGI3_LOGROTATE | ${SUDO} tee /etc/logrotate.d/energi3 >/dev/null
${CONF_DIR}/*.log {
  su ${USRNAME} ${USRNAME}
  rotate 3
  minsize 100M
  copytruncate
  compress
  missingok
}
ENERGI3_LOGROTATE

  logrotate -f /etc/logrotate.d/energi3

  fi
}

_add_nrgstaker () {
  # Check if user nrgstaker exists if not add the user

  export USRHOME=`grep "^${USRNAME}:" /etc/passwd | awk -F: '{print $6}'`
  export ENERGI3_HOME=${USRHOME}/energi3

  touch ${USRHOME}/.sudo_as_admin_successful
  chmod 644 ${USRHOME}/.sudo_as_admin_successful

  if [[ ${EUID} = 0 ]]
  then
      chown ${USRNAME}:${USRNAME} ${USRHOME}/.sudo_as_admin_successful
  fi

  # Add PATH variable for Energi3
  CHKBASHRC=`grep "Energi3 PATH" "${USRHOME}/.bashrc"`

  if [ -z "${CHKBASHRC}" ]
  then
    echo "" >> "${USRHOME}/.bashrc"
    echo "# Energi3 PATH" >> "${USRHOME}/.bashrc"
    echo "export PATH=\${PATH}:\${HOME}/energi3/bin" >> "${USRHOME}/.bashrc"
    echo
    echo "  .bashrc updated with PATH variable"
    if [[ $EUID != 0 ]]
    then
      source ${USRHOME}/.bashrc
    fi
  else
    echo "  .bashrc up to date. Nothing to add"
  fi

  echo
  echo "${GREEN}*** User ${USRNAME} will be used to install the software and configurations ***${NC}"
  sleep 0.3
}

_check_clock() {
  if [ ! -x "$( command -v ntpdate )" ]
  then
    echo "Installing ntpdate"
    ${SUDO} apt-get install -yq ntpdate 2>/dev/null
  fi
  echo "Checking system clock..."
  ${SUDO} ntpdate -q pool.ntp.org | tail -n 1 | grep -o 'offset.*' | awk '{print $1 ": " $2 " " $3 }' 2>/dev/null
}

_check_runas () {
  # Who is running the script
  # If root no sudo required
  # If user has sudo privilidges, run sudo when necessary

  RUNAS=`whoami`

  if [[ $EUID = 0 ]]
  then
    SUDO=""
  else
    ISSUDOER=`getent group sudo | grep ${RUNAS}`
    if [ ! -z "${ISSUDOER}" ]
    then
      SUDO='sudo'
    else
      echo "User ${RUNAS} does not have sudo permissions."
      echo "Run ${BLUE}sudo ls -l${NC} to set permissions if you know the user ${RUNAS} has sudo previlidges"
      echo "and then rerun the script"
      echo "Exiting script..."
      sleep 3
      exit 0
    fi
  fi
}

_check_install () {
  # Check if run as root or user has sudo privilidges

  _check_runas

  CHKV3USRTMP=/tmp/chk_v3_usr.tmp
  >${CHKV3USRTMP}
  ${SUDO} find /home -name nodekey | awk -F\/ '{print $3}' > ${CHKV3USRTMP}
  ${SUDO} find /root -name nodekey | awk -F\/ '{print $3}' >> ${CHKV3USRTMP}
  V3USRCOUNT=`wc -l ${CHKV3USRTMP} | awk '{ print $1 }'`

  case ${V3USRCOUNT} in
    0)
      # New Installation:
      #   * No energi3.ipc file on the computer
      #   * No energi.conf or energid on the computer
      #
      echo "${YELLOW}Not installed${NC}"
      echo

      # Set username
      USRNAME=root
      INSTALLTYPE=new

      _add_nrgstaker
      ;;

    1)
      # Upgrade existing version of Energi 3:
      #   * One instance of Energi3 is already installed
      #   * nodekey file exists
      #   * Version on computer is older than version in Github

      export USRNAME=`cat ${CHKV3USRTMP}`
      INSTALLTYPE=upgrade
      echo "The script will upgrade to the latest version of energi3 from Github"
      echo "if available as user: ${GREEN}${USRNAME}${NC}"
      sleep 0.3

      export USRHOME=`grep "^${USRNAME}:" /etc/passwd | awk -F: '{print $6}'`
      export ENERGI3_HOME=${USRHOME}/energi3

      ;;

    *)
      # Upgrade existing version of Energi3:
      #   * More than one instance of Energi3 is already installed
      #   * energi3.ipc file exists
      #   * Version on computer is older than version in Github
      #   * All instances will be upgraded

      I=1
      for U in `cat ${CHKV3USRTMP}`
      do
        USR[${I}]=${U}
        echo "${I}: ${USR[${I}]}"
        ((I=I+1))

        if [ ${I} = ${V3USRCOUNT} ]
        then
          break
        fi
      done

      export USR="${USR[*]}"
      INSTALLTYPE=upgrade
      ;;
  esac

  # Clean-up temporary file
  rm ${CHKV3USRTMP}
}

_check_ismainnet () {
  # Confirm Mainnet or Testnet
  # Default: Mainnet

  if [[ "${INSTALLTYPE}" == "new" ]]
  then
    isMainnet=y

    if [[ "${isMainnet}" == 'y' ]] || [[ -z "${isMainnet}" ]]
    then
      export CONF_DIR=${USRHOME}/.energicore3
      export FWPORT=39797
      export APPARG=''
      export isMainnet=y
      echo "The application will be setup for Mainnet"
    else
      export CONF_DIR=${USRHOME}/.energicore3/testnet
      export APPARG='--testnet'
      export FWPORT=49797
      export isMainnet=n
      echo "The application will be setup for Testnet"
    fi

  elif [[ "${INSTALLTYPE}" == "upgrade" ]]
  then
    if [ ! -d "${USRNAME}/.energicore3/testnet" ]
    then
      export CONF_DIR=${USRHOME}/.energicore3
      export FWPORT=39797
      export isMainnet=y
      echo "The application will be setup for Mainnet"
    else
      export CONF_DIR=${USRHOME}/.energicore3/testnet
      export FWPORT=49797
      export isMainnet=n
      echo "The application will be setup for Testnet"
    fi

  else
    # INSTALLTYPE = migrate
    if [ ! -d "${USRNAME}/.energicore/testnet" ]
    then
      export CONF_DIR=${USRHOME}/.energicore3
      export FWPORT=39797
      export isMainnet=y
      echo "The application will be setup for Mainnet"
    else
      export CONF_DIR=${USRHOME}/.energicore3/testnet
      export FWPORT=49797
      export isMainnet=n
      echo "The application will be setup for Testnet"
    fi
  fi
  echo
  sleep 0.3
}

_get_enode () {
  # Print enode of core node
  I=1
  while [ ! -S ${CONF_DIR}/${ENERGI3_IPC} ] || [ ${I} = 60 ]
  do
    sleep 1
    ((I++))
  done

  sleep 1

  if [[ ${EUID} = 0 ]] && [[ -S ${CONF_DIR}/${ENERGI3_IPC} ]]
  then
    echo "${GREEN}To Announce Masternode go to:${NC} https://gen3.energi.network/masternodes/announce"
    echo -n "Owner Address: "
    su - ${USRNAME} -c "${BIN_DIR}/energi3 ${APPARG} attach -exec 'personal.listAccounts' " 2>/dev/null | jq -r '.[]' | head -1
    echo "Masternode enode URL: "
    su - ${USRNAME} -c "${BIN_DIR}/energi3 ${APPARG} attach -exec 'admin.nodeInfo.enode' " 2>/dev/null | jq -r
  else
    echo "${GREEN}To Announce Masternode go to:${NC} https://gen3.energi.network/masternodes/announce"
    echo -n "Owner Address: "
    energi3 ${APPARG} attach -exec "personal.listAccounts" 2>/dev/null | jq -r | head -1
    echo "Masternode enode URL: "
    energi3 ${APPARG} attach -exec "admin.nodeInfo.enode" 2>/dev/null | jq -r
  fi

  echo
}

_install_apt () {
  # Check if any apt packages need installing or upgrade
  # Setup server to auto updating security related packages automatically

  if [ ! -x "$( command -v aria2c )" ] || [ ! -x "$( command -v unattended-upgrade )" ] || [ ! -x "$( command -v ntpdate )" ] || [ ! -x "$( command -v google-authenticator )" ] || [ ! -x "$( command -v php )" ] || [ ! -x "$( command -v jq )" ]  || [ ! -x "$( command -v qrencode )" ]
  then
    echo
    echo "Updating linux first."
    echo "    Running apt-get update."
    sleep 1
    ${SUDO} apt-get update -yq 2> /dev/null
    echo "    Running apt-get upgrade."
    sleep 1
    ${SUDO} apt-get upgrade -yq 2> /dev/null
    echo "    Running apt-get dist-upgrade."
    sleep 1
    ${SUDO} apt-get -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade 2> /dev/null

    if [ ! -x "$( command -v unattended-upgrade )" ]
    then
      echo "    Running apt-get install unattended-upgrades php ufw."
      sleep 1
      ${SUDO} apt-get install -yq unattended-upgrades php ufw 2> /dev/null

      if [ ! -f /etc/apt/apt.conf.d/20auto-upgrades ]
      then
        # Enable auto updating of Ubuntu security packages.
        echo "Setting up server to update security related packages anytime they are available"
        sleep 0.3
        cat << UBUNTU_SECURITY_PACKAGES | ${SUDO} tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null
APT::Periodic::Enable "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
UBUNTU_SECURITY_PACKAGES
      fi
    fi
  fi

  # Install missing programs if needed.
  if [ ! -x "$( command -v aria2c )" ]
  then
    echo "    Installing missing programs..."
    ${SUDO} apt-get install -yq \
      curl \
      lsof \
      util-linux \
      gzip \
      unzip \
      unrar \
      xz-utils \
      procps \
      htop \
      git \
      gpw \
      bc \
      pv \
      sysstat \
      glances \
      psmisc \
      at \
      python3-pip \
      python-pip \
      subnetcalc \
      net-tools \
      sipcalc \
      python-yaml \
      html-xml-utils \
      apparmor \
      ack-grep \
      pcregrep \
      snapd \
      aria2 \
      dbus-user-session \
      logrotate \
      wget 2> /dev/null
  fi

  if [ ! -x "$( command -v jq )" ]
  then
    echo "    Installing jq"
    ${SUDO} apt-get install -yq jq 2> /dev/null
  fi
  echo "    Installing screen and nodejs"
  ${SUDO} apt-get install -yq screen 2> /dev/null
  ${SUDO} apt-get install -yq nodejs 2> /dev/null

  echo "    Removing apt files not required"
  ${SUDO} apt autoremove -y 2> /dev/null
}

_setup_appdir () {
  # Setup application directories if they do not exist

  echo "Energi3 will be installed in ${ENERGI3_HOME}"
  sleep 0.5

  # Set application directories
  export BIN_DIR=${ENERGI3_HOME}/bin
  export ETC_DIR=${ENERGI3_HOME}/etc
  export JS_DIR=${ENERGI3_HOME}/js
  export PW_DIR=${ENERGI3_HOME}/.secure
  export TMP_DIR=${ENERGI3_HOME}/tmp

  # Create directories if they do not exist
  if [ ! -d ${BIN_DIR} ]
  then
    echo "    Creating directory: ${BIN_DIR}"
    mkdir -p ${BIN_DIR}
  fi

  if [ ! -d ${ETC_DIR} ]
  then
    echo "    Creating directory: ${ETC_DIR}"
    mkdir -p ${ETC_DIR}
  fi

  if [ ! -d ${JS_DIR} ]
  then
    echo "    Creating directory: ${JS_DIR}"
    mkdir -p ${JS_DIR}
  fi

  if [ ! -d ${TMP_DIR} ]
  then
    echo "    Creating directory: ${TMP_DIR}"
    mkdir -p ${TMP_DIR}
  fi

  echo
  echo "Changing ownership of ${ENERGI3_HOME} to ${USRNAME}"

  if [[ ${EUID} = 0 ]]
  then
    chown -R ${USRNAME}:${USRNAME} ${ENERGI3_HOME}
  fi
}

_install_energi3 () {
  # Download and install node software and supporting scripts

  # Name of scripts
  NODE_SCRIPT=start_staking.sh
  NODE_SCREEN_SCRIPT=start_screen_staking.sh
  MN_SCRIPT=start_mn.sh
  MN_SCREEN_SCRIPT=start_screen_mn.sh
  MONITOR_SCRIPT=nodemon.sh
  JS_SCRIPT=utils.js

  # Check Github for URL of latest version
  if [ -z "${GIT_LATEST}" ]
  then
    GITHUB_LATEST=$( curl -s ${API_URL} )
    GIT_VERSION=$( echo "${GITHUB_LATEST}" | jq -r '.tag_name' )

    # Extract latest version number without the 'v'
    GIT_LATEST=$( echo ${GIT_VERSION} | sed 's/v//g' )
  fi

  cd ${USRHOME}

  # Download from repositogy
  echo "    Downloading Energi Core Node and scripts"
  ENERGI3_DIR=energi3-${GIT_LATEST}-linux-amd64
  ENERGI3_TGZ=${ENERGI3_DIR}.tgz

  # Pull Energi3 Core Node archive from Amazon S3
  echo "    Downloading Energi Gen 3 Core Node archive from \`${S3URL}/${GIT_LATEST}/${ENERGI3_TGZ}\`"
  wget -4qo- "${S3URL}/${GIT_LATEST}/${ENERGI3_TGZ}" --show-progress --progress=bar:force:noscroll 2>&1
  sleep 0.3

  # Check if Energi3 Core Node archive was downloaded
  if [ ! -f ${ENERGI3_TGZ} ]
  then
    echo "${RED}ERROR: \`{$ENERGI3_TGZ}\` was not downloaded!${NC}"
    sleep 5

    exit 1
  fi

  tar xvfz ${ENERGI3_TGZ}
  sleep 0.3

  # Create missing app directories
  _setup_appdir

  # Copy the latest `energi3` binary and clean up
  if [[ -x "${ENERGI3_EXE}" ]]
  then
    mv ${ENERGI3_DIR}/bin/energi3 ${BIN_DIR}/.
    rm -rf ${ENERGI3_DIR}
  else
    mv ${ENERGI3_DIR} ${ENERGI3_EXE}
  fi

  rm ${ENERGI3_TGZ}

  # Check if BIN directory exists
  if [ ! -d ${BIN_DIR} ]
  then
    echo "${RED}ERROR: \`${BIN_DIR}\` does not exist!${NC}"
    sleep 5

    exit 1
  fi

  cd ${BIN_DIR}
  chmod 755 ${ENERGI3_EXE}

  if [[ ${EUID} = 0 ]]
  then
    chown ${USRNAME}:${USRNAME} ${ENERGI3_EXE}
  fi

  echo "    Getting \`${NODE_SCRIPT}\`"
  wget -4qo- "${SCRIPT_URL}/${NODE_SCRIPT}?dl=1" -O "${NODE_SCRIPT}" --show-progress --progress=bar:force:noscroll 2>&1
  sleep 0.3
  chmod 755 ${NODE_SCRIPT}

  if [[ ${EUID} = 0 ]]
  then
    chown ${USRNAME}:${USRNAME} ${NODE_SCRIPT}
  fi

  echo "    Getting \`${NODE_SCREEN_SCRIPT}\`"
  wget -4qo- "${SCRIPT_URL}/${NODE_SCREEN_SCRIPT}?dl=1" -O "${NODE_SCREEN_SCRIPT}" --show-progress --progress=bar:force:noscroll 2>&1
  sleep 0.3
  chmod 755 ${NODE_SCREEN_SCRIPT}

  if [[ ${EUID} = 0 ]]
  then
    chown ${USRNAME}:${USRNAME} ${NODE_SCREEN_SCRIPT}
  fi

  echo "    Getting \`${MN_SCRIPT}\`"
  wget -4qo- "${SCRIPT_URL}/${MN_SCRIPT}?dl=1" -O "${MN_SCRIPT}" --show-progress --progress=bar:force:noscroll 2>&1
  sleep 0.3
  chmod 755 ${MN_SCRIPT}

  if [[ ${EUID} = 0 ]]
  then
    chown ${USRNAME}:${USRNAME} ${MN_SCRIPT}
  fi

  echo "    Getting \`${MN_SCREEN_SCRIPT}\`"
  wget -4qo- "${SCRIPT_URL}/${MN_SCREEN_SCRIPT}?dl=1" -O "${MN_SCREEN_SCRIPT}" --show-progress --progress=bar:force:noscroll 2>&1
  sleep 0.3
  chmod 755 ${MN_SCREEN_SCRIPT}

  if [[ ${EUID} = 0 ]]
  then
    chown ${USRNAME}:${USRNAME} ${MN_SCREEN_SCRIPT}
  fi

  # Get Energi3 core node monitor script
  echo "    Getting \`${MONITOR_SCRIPT}\`"
  wget -4qo- "${SCRIPT_URL}/${MONITOR_SCRIPT}?dl=1" -O "${MONITOR_SCRIPT}" --show-progress --progress=bar:force:noscroll 2>&1
  sleep 0.3
  chmod 755 ${MONITOR_SCRIPT}

  if [[ ${EUID} = 0 ]]
  then
    chown ${USRNAME}:${USRNAME} ${MONITOR_SCRIPT}
  fi

  if [ ! -d ${JS_DIR} ]
  then
    echo "    Creating directory: ${JS_DIR}"
    mkdir -p ${JS_DIR}
  fi

  cd ${JS_DIR}

  echo "    Getting \`${JS_SCRIPT}\`"
  wget -4qo- "${BASE_URL}/utils/${JS_SCRIPT}?dl=1" -O "${JS_SCRIPT}" --show-progress --progress=bar:force:noscroll 2>&1
  sleep 0.3
  chmod 644 ${JS_SCRIPT}

  if [[ ${EUID} = 0 ]]
  then
    chown ${USRNAME}:${USRNAME} ${JS_SCRIPT}
  fi

  # Clean-up
  rm -rf ${ENERGI3_HOME}.old

  # Change to install directory
  cd
}

_os_arch () {
  # Check Architecture
  OSNAME=`grep ^NAME /etc/os-release | awk -F\" '{ print $2 }'`
  OSVERSIONLONG=`grep ^VERSION_ID /etc/os-release | awk -F\" '{ print $2 }'`
  OSVERSION=`echo ${OSVERSIONLONG} | awk -F\. '{ print $1 }'`
  echo -n "${OSNAME} ${OSVERSIONLONG} is  "
  if [ "${OSNAME}" = "Ubuntu" ] && [ ${OSVERSION} -ge 18 ]
  then
    echo "${GREEN}supported${NC}"
  else
    echo "${RED}not supported${NC}"
    exit 0
  fi

  echo -n "OS architecture "
  OSARCH=`uname -m`
  if [ "${OSARCH}" != "x86_64" ]
  then
    echo "${RED}${OSARCH} is not supported${NC}"
    echo "Please goto our website to check which platforms are supported."
    exit 0
  else
    echo "${GREEN}${OSARCH} is supported${NC}"
    sleep 0.3
  fi
}

_pre_setup () {
  _install_apt
  #|_restrict_logins
  _check_ismainnet
  #|_secure_host
  _check_clock
  #|_add_swap  # Docker is using host's memory and swap
  _add_logrotate
}

_version_gt() {
  # Check if FIRST version is greater than SECOND version

  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

_upgrade_energi3 () {
  # Set PATH to energi3
  export BIN_DIR=${ENERGI3_HOME}/bin

  # Check the latest version in Github

  GITHUB_LATEST=$( curl -s ${API_URL} )
  GIT_VERSION=$( echo "${GITHUB_LATEST}" | jq -r '.tag_name' )

  # Extract latest version number without the 'v'
  GIT_LATEST=$( echo ${GIT_VERSION} | sed 's/v//g' )

  # Installed Version
  INSTALL_VERSION=$( ${BIN_DIR}/${ENERGI3_EXE} version 2>/dev/null | grep "^Version" | awk '{ print $2 }' | awk -F\- '{ print $1 }' )

  if _version_gt ${GIT_LATEST} ${INSTALL_VERSION}; then
    echo "Installing newer version ${GIT_VERSION} from Github"
    if [[ -f "${CONF_DIR}/removedb-list.db" ]]
    then
      rm -f ${CONF_DIR}/removedb-list.db
      wget -4qo- "${BASE_URL}/utils/removedb-list.db?dl=1" -O "${CONF_DIR}/removedb-list.db" --show-progress --progress=bar:force:noscroll 2>&1
    else
      wget -4qo- "${BASE_URL}/utils/removedb-list.db?dl=1" -O "${CONF_DIR}/removedb-list.db" --show-progress --progress=bar:force:noscroll 2>&1
    fi

    if [[ $EUID = 0 ]]
    then
      chown ${USRNAME}:${USRNAME} ${CONF_DIR}/removedb-list.db
    fi

    _install_energi3

  else
    echo "Latest version of Energi3 is installed: ${INSTALL_VERSION}"
    echo "Nothing to install"
    sleep 0.3
  fi
}

_energi3_partial_logo () {
  echo "${GREEN}"
  clear 2> /dev/null
  cat << "ENERGI3"
      ___       ______ _   _ ______ _____   _____ _____ ____
     /\  \     |  ____| \ | |  ____|  __ \ / ____|_   _|___ \
    /::\  \    | |__  |  \| | |__  | |__) | |  __  | |   __) |
   /:/\:\__\   |  __| | . ` |  __| |  _  /| | |_ | | |  |__ <
  /:/ /:/ _/_  | |____| |\  | |____| | \ \| |__| |_| |_ ___) |
 /:/_/:/ /\__\ |______|_| \_|______|_|  \_\\_____|_____|____/
 \:\ \/_/:/  /
ENERGI3
}

_end_instructions () {
  _energi3_partial_logo
  echo "${GREEN}  \:\  /:/  /  ${NC}Please start Docker container:"
  echo "${GREEN}   \:\/:/  /   ${NC}- docker run ..."
  echo "${GREEN}    \::/  /    ${NC}- docker-compose up --detach"
  echo "${GREEN}     \/__/     ${NC}Do not forget to add volume with keystore file to the container!"
  echo ${NC}"For instructions visit: ${DOC_URL}"
  echo
}

_menu_option_new () {
  _energi3_partial_logo
  echo "${GREEN}  \:\  /:/  /  ${NC}"
  echo "${GREEN}   \:\/:/  /   ${NC}"
  echo "${GREEN}    \::/  /    ${NC}"
  echo "${GREEN}     \/__/     ${NC}New server installation of Energi3"
  echo ${NC}
}

_menu_option_mig () {
  _energi3_partial_logo
  echo "${GREEN}  \:\  /:/  /  ${NC}"
  echo "${GREEN}   \:\/:/  /   ${NC}"
  echo "${GREEN}    \::/  /    ${NC}"
  echo "${GREEN}     \/__/     ${NC}Upgrade Energi v2 to v3; automatic wallet migration"
  echo ${NC}
}

_menu_option_upgrade () {
  _energi3_partial_logo
  echo "${GREEN}  \:\  /:/  /  ${NC}"
  echo "${GREEN}   \:\/:/  /   ${NC}"
  echo "${GREEN}    \::/  /    ${NC}"
  echo "${GREEN}     \/__/     ${NC}Upgrade version of Energi3"
  echo ${NC}
}

_welcome_instructions () {
  _energi3_partial_logo
  echo "${GREEN}  \:\  /:/  /  ${NC}Welcome to the Energi3 Installer."
  echo "${GREEN}   \:\/:/  /   ${NC}- New Install : No previous installs"
  echo "${GREEN}    \::/  /    ${NC}- Upgrade     : Upgrade previous version"
  echo "${GREEN}     \/__/     ${NC}- Migrate     : Migrate from Energi v2 (disabled)"
  echo ${NC}
  #|read -t 10 -p "Wait 10 sec or Press [ENTER] key to continue..."
}
