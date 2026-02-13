# Hardened image for Mist Server
Mist Server is a truly amazing project developed by DDVTech. With this docker image you can enjoy the Mist Server with High security

## How to use it ? 
It's easy, you can find packages built with docker in [here](https://github.com/coral-land/atoll-mistserver-docker/pkgs/container/atoll-mistserver-docker). Pick the right version then pull and run image and there is a prepared docker compose witch you can use to run it with greate security [here](./docker/docker-compose.yaml).

## Mist server config update
You can find a minimal configuration file in [config](./config) folder witch you can modify and update as your needs.

## Make command
If you have make installed on your system you can access to a helpfull set of commands by running `make` command in root of the project:

```bash
$ make

Usage:
  make <target>

Targets:
  up                    Run Docker compose with latest image
  down                  Same Docker compose down
  prune                 Remove docker latest odcker image
  logs                  Logs for Mist Server Container
  updev                 Run docker comopse dev
  downdev               Stop docker compose for dev
  help                  Show this help
```
