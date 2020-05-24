#!/bin/bash
# A script to be used as an Docker container entrypoint to run
# Energi Gen 3 Core and unlock account for staking when a container is started.

# Turn on `bash`'s job control
# https://docs.docker.com/config/containers/multi-service_container/
set -m

cd /root/energi3/bin

# Launch Energi Gen 3 Core in background without input from shell so process
# keeps running
./energi3\
 --datadir /root/.energicore3\
 --masternode\
 --mine\
 --nat extip:`curl -s https://ifconfig.me/`\
 --preload /root/energi3/js/utils.js\
 --rpc\
 --rpcport 39796\
 --rpcaddr "127.0.0.1" \
 --rpcapi admin,eth,web3,rpc,personal,energi\
 --ws\
 --wsaddr "127.0.0.1"\
 --wsport 39795\
 --wsapi admin,eth,net,web3,personal,energi\
 --verbosity 3 < /dev/null &
# https://stackoverflow.com/questions/17621798/linux-process-in-background-stopped-in-jobs#comment25653828_17621863
# https://stackoverflow.com/a/17626350

# Wait till Energi Gen 3 Core has been successfully started to unlock account
# for staking
sleep 2.5

while [[ $(./energi3 attach --exec "personal.unlockAccount(
    '`cat /run/secrets/account_address`',
    '`cat /run/secrets/account_password`',
    0,
    true
)") != "true" ]]
do
    sleep 2.5
done

# Put Energi Core process in foreground
fg %1
