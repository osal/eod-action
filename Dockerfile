# Container image that runs your code
FROM debian:10.4

# install tools (wget, unzip, git, GitHub CLI)
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates git wget unzip && \
    wget https://github.com/cli/cli/releases/download/v0.10.1/gh_0.10.1_linux_amd64.deb && \
    apt-get install -y ./gh_*_linux_amd64.deb && \
    rm ./gh_*_linux_amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install AWS CLI
RUN wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm ./awscliv2.zip && \
    rm -r ./aws

# configure git
RUN git config --global user.name  "github action bot" && \
    git config --global user.email "github.action.bot@tradingview.com"

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
