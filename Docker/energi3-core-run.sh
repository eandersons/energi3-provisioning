#!/bin/bash
# A script to be used as an Docker container entrypoint to run
# Energi Gen 3 Core node and unlock account for staking.

/root/energi3/bin/energi3\
 --datadir /root/.energicore3\
 --masternode\
 --mine\
 --nat extip:`curl -s https://ifconfig.me/`\
 --password /run/secrets/account_password
 --preload /root/energi3/js/utils.js\
 --rpc\
 --rpcport 39796\
 --rpcaddr "0.0.0.0" \
 --rpcapi admin,eth,web3,rpc,personal,energi\
 --unlock `cat /run/secrets/account_address`\
 --unlock.staking\
 --verbosity 3\
 --ws\
 --wsaddr "127.0.0.1"\
 --wsport 39795\
 --wsapi admin,eth,net,web3,personal,energi
