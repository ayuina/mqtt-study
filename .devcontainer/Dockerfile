FROM mcr.microsoft.com/devcontainers/javascript-node:1-20-bullseye

WORKDIR /var/tmp
RUN apt-get update
RUN npm install -g azurite
RUN wget https://dl.smallstep.com/gh-release/cli/docs-cli-install/v0.24.4/step-cli_0.24.4_amd64.deb \
    && sudo dpkg -i step-cli_0.24.4_amd64.deb

