# Dockerized Energi Gen 3 Core

To run Energi Gen 3 Core Node in a Docker container:

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
