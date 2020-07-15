# Energi Gen 3 Core Node provisioning with Docker

> This repository is now considered inactive as there is an official [Energi Gen 3 Docker image](https://hub.docker.com/r/energicryptocurrency/energi3) and this repository is left for reference.
>
> Below is the answer from the Energi support regarding running core node in a Docker container:
>
> ---
>
> As for the Docker container - we do have a release at the Docker hub that can be pulled with the following command:
>
> ``` sh
> docker pull energicryptocurrency/energi3:v3.0.6
> ```
>
> Once you have pulled the image, you can create a new container with
>
> ``` sh
> sudo docker run -d --name CONTAINER_NAME -v /home/USER/nrgdocker:/root energicryptocurrency/energi3:v3.0.6
> ```
>
> This will create a new container named `CONTAINER_NAME` (replace with a name you seem fit) and create a persistent storage space to host your keystore / blockchain files at `/home/USER/nrgdocker` (replace the `USER` portion with the current Linux user you are creating the container with).
>
> After the container is created, you can access the console and issue all the commands to check it is running and synchronizing (like `miner.stakingStatus()` and `nrg.syncing`) with the following command:
>
> ``` sh
> sudo docker exec -it CONTAINER_NAME energi3 attach
> ```
>
> replacing `CONTAINER_NAME` by the name you chose for your container.
>
> To import a new wallet, you can place the keystore files at the `/home/USER/nrgdocker/.energicore3/keystore/` - again, replacing `USER` for the username you are currently creating the container with.
>
> ---
>
> Here is a repository to make launching Energi Gen 3 Core Node in a Docker container easier using Docker Compose and the official Energi Gen 3 Docker image: [`energi3-docker-compose`](https://github.com/eandersons/energi3-docker-compose).

- [Energi Gen 3 Core Node provisioning with Docker](#energi-gen-3-core-node-provisioning-with-docker)
  - [Install Energi Gen 3 Core Node using Docker](#install-energi-gen-3-core-node-using-docker)
  - [Improvements for dockerization](#improvements-for-dockerization)
  - [Energi Gen 3 Core Node provisioning](#energi-gen-3-core-node-provisioning)

This fork was created to install Energi Gen 3 Core Node in a Docker container so Energi3 Core Node could be installed on any server that can run Docker.

> Not sure, but it seems that it could be possible to run Energi Gen3 Core in a Docker container using this repository: <https://github.com/energicryptocurrency/energi3> (using <https://github.com/energicryptocurrency/energi3/blob/master/Dockerfile> or <https://github.com/energicryptocurrency/energi3/blob/master/containers/docker/master-ubuntu/Dockerfile>).

Modifications were made with a single account staking in mind. More adjustments may be needed to stake using multiple accounts or to use Energi Gen 3 Core Node as a Masternode.
Current solution for staking multiple accounts would be to run multiple containers, but it may be not an ideal solution performance-wise.

## Install Energi Gen 3 Core Node using Docker

To run Energi Gen 3 Core Node in a Docker container:

- clone this git repository: `git clone https://github.com/eandersons/energi3-provisioning.git`;
- create the following files:
  - `Docker/configs/energi3_account_address` that contains the Energi Gen 3 account address;
  - `Docker/configs/energi3_account_password` that contains the Energi Gen 3 account password;

  these files are used to get account's address and password to automatically unlock account for staking after the container has been started;
- copy the file `scripts/linux/nodemon.conf` to `Docker/configs` and adjust values in it if the node monitor should send notifications to an email and/or a SMS email gateway;
- run Docker container using `docker-compose`:

  ``` sh
  cd /path/to/energi3-provisioning/Docker
  # `sudo` may be necessary to use `docker-compose`
  docker-compose up --detach
  ```

- open the necessary ports for external inbound access in router and/or firewall:
  - `39795` TCP;
  - `39796` TCP;
  - `39797` TCP and UDP;

  not sure about the first two ports, but `39797` TCP/UDP port is required for staking and Masternode as it is mentioned [here](https://docs.energi.software/en/advanced/core-node-vps#h-17-firewall-rules).

## Improvements for dockerization

Possible improvements for Energi Gen 3 Core Node dockerization:

- [ ] adjust `scripts/linux/energi3-linux-installer.sh` to be suitable for installation in Docker containers as well;

  `DOCKER` could be the environment variable that is used to control whether installation should be interactive or not with a value something like `true`, `1` or `yes`;
- [ ]  make necessary adjustments to stake multiple accounts in a single dockerized Energi Gen 3 Core Node instance;
- [ ]  make necessary adjustments to run dockerized Energi Gen 3 Core Node as a Masternode;
- [ ]  make Energi Core Node Monitor installation optional;
- [ ]  create a separate APT packages list for Energi Gen 3 Core installation in Docker container as not all of them are used in dockerized core version.

Any suggestions and solutions for improvements are welcome.

## Energi Gen 3 Core Node provisioning

> This section contains the original content of `README.md` with minor formatting adjustments.

This repository has provisioning scripts as well as startup scripts for Energi Core Node:

- Linux/VPS
  - `energi3-linux-installer.sh`: provisioning Script for amd64 or x86_64 Linux
  - `energi3-aarch64-installer.sh`: provisioning Script for RPi and i386 (32-bit   inux)
  - `start_staking.sh`: start Staking
  - `start_screen_staking.sh`: start Staking within `screen`
  - `start_mn.sh`: start Masternode
  - `start_screen_mn.sh`: start Masternode  within `screen`
  - `energi3-cli`: wrapper command-line script

- Windows
  - `energi3-windows-installer.bat`: provisioning Script
  - `start_mn.bat`: start Masternode
  - `start_staking.bat`: start Staking
  - `energi3.ico`: energi Icon Logo

- MacOS
  - `energi3-macos-installer.sh`: provisioning Script
  - `start_node.sh`: script to start staking/mastrnode in mainnet or testnet
  - `start_staking.sh`: start Staking
  - `start_mn.sh`: start Masternode
