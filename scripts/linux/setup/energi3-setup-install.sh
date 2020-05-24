#!/bin/bash

######################################################################
# Copyright (c) 2020
# All rights reserved.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
#
# Desc:   Batch script to download and setup Energi3 on Linux. The
#         script will upgrade an existing installation. If v2 is
#         installed on the VPS, the script can be used to auto migrate
#         from v2 to v3.
#         This is a modified version for use in Docker container, therefore
#         it is not interactive.
#
# Version:
#   1.2.9  20200309  ZA Initial Script
#   1.2.12 20200311  ZA added removedb to upgrade
#   1.2.14 20200312  ZA added create keystore if not downloading
#   1.2.15 20200423  ZA bug in _add_nrgstaker
#
: '
# Run the script to get started:
```
bash -ic "$(wget -4qO- -o- raw.githubusercontent.com/energicryptocurrency/energi3-provisioning/master/scripts/linux/energi3-linux-installer.sh)" ; source ~/.bashrc
```
'
######################################################################


# Include global variablese from `energi3-setup-global-vars.sh` and functions
# from `energi3-setup-functions.sh`.
# https://stackoverflow.com/a/34208365
DIR=$(dirname $(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null||echo $0))
source "$DIR/energi3-setup-global-vars.sh"
source "$DIR/energi3-setup-functions.sh"


### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
# Main Program
### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

#
# Clear screen and present Energi3 logo
_welcome_instructions

# Check architecture
_os_arch

# Check Install type and set ENERGI3_HOME
_check_install

# Present menu to choose an option based on Installation Type determined
case ${INSTALLTYPE} in
  new)
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Scenario:
    #   * No energi3.ipc file on the computer
    #   * No energi.conf file on the computer
    #
    # Menu Options
    #   a) New server installation of Energi3
    #   x) Exit without doing anything
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    _menu_option_new

    # New server installation of Energi3

    # ==> Run as root / sudo <==
    _pre_setup

    #
    # ==> Run as user <==
    #
    _install_energi3
    #|_add_systemd
    #|_start_energi3

    ;;

  upgrade)
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Scenario:
    #   * energi3.ipc file exists
    #   * Keystore file exists
    #   * Version on computer is older than version in Github
    #   * $ENERGI3_HOME/etc/migrated_to_v3.log exists
    #
    # Menu Options
    #   a) Upgrade version of Energi3
    #   x) Exit without doing anything
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    _menu_option_upgrade

    # Upgrade version of Energi3
    #|_stop_energi3
    _pre_setup

    #
    # ==> Run as user <==
    #
    #|_stop_energi3

    for USRNAME in "${USR[*]}"
    do
      if [[ "${USRNAME}" -ne "${RUNAS}" ]]
      then
        clear
        echo "You have to run the script as root or ${USRNAME}"
        echo "Login as ${USRNAME} and run the script again"
        echo "Exiting script..."
        exit 0
      fi

      USRHOME=`grep "^${USRNAME}:" /etc/passwd | awk -F: '{print $6}'`
      ENERGI3_HOME=${USRHOME}/energi3
      echo "Upgrading Energi3 as ${USRNAME}"

      _upgrade_energi3

      if [[ -f ${CONF_DIR}/removedb-list.db ]]
      then
        for L in `cat ${CONF_DIR}/removedb-list.db`
        do
          if [[ ${L} = ${INSTALL_VERSION} ]]
          then
            echo "${GREEN}Vesion ${L} requires a reset of chaindata${NC}"
            ${BIN_DIR}/${ENERGI3_EXE} removedb
            break

            if [[ -f "${CONF_DIR}/energi3/chaindata/CURRENT" ]]
            then
              echo "Removing chaindata..."
              rm -rf ${CONF_DIR}/energi3/chaindata/*
              touch ${CONF_DIR}/v3.0.1-genesis.stamp
            fi

          fi
        done
      fi
    done

    #|_start_energi3
    ;;

  migrate)
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Scenario:
    #   * No energi3.ipc file on the computer
    #   * energi3.ipc file exists on the computer
    #   * Keystore file does not exists
    #   * $ENERGI3_HOME/etc/migrated_to_v3.log exists
    #
    # Menu Options
    #   a) Migrate from Energi v2 to v3; automatic wallet migration
    #   b) Migrate Energi v2 to v3; manual wallet migration
    #   x) Exit without doing anything
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    _menu_option_mig

    # New server installation of Energi3
    _pre_setup

    #
    # ==> Run as user <==
    #
    _install_energi3

    echo "You have to manually migrate Energi v2 to v3. Please look at Github "
    echo "document on how to manually migrate using Nexus and EnergiWallet."
    echo
    sleep 3
    ;;
esac

##
# End installer
##
_end_instructions

# present enode information
#|_get_enode

# End of Installer
exit 0
