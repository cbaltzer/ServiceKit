# Mostly from the example VSCode container, originally for Node so some of 
# this is probably not needed

FROM swift:latest

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Leaving this from the OG sample
# See https://aka.ms/vscode-remote/containers/non-root-user.
ARG USER_UID=1000
ARG USER_GID=$USER_UID


# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \ 
    
    # Verify git and needed tools are installed
    && apt-get install -y git procps \

    # Curl and etc 
    && apt-get -y install --fix-missing libssl-dev libcurl4-openssl-dev \
    && apt-get install -y curl apt-transport-https lsb-release


# SourceKite isn't great, but until there's a Swift 5.1 container with LSP..
RUN git clone https://github.com/vknabel/sourcekite \
    && cd sourcekite \
    && make install PREFIX=/usr/local


# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=