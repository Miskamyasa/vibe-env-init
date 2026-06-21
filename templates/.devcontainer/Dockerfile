FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    make \
    gnupg \
    git \
    curl \
    ca-certificates \
    locales \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

ENV HOME=/home/ubuntu

ENV XDG_CONFIG_HOME=$HOME/.config
ENV XDG_CACHE_HOME=$HOME/.cache
ENV XDG_DATA_HOME=$HOME/.local/share
ENV XDG_STATE_HOME=$HOME/.local/state

ENV PATH=$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

USER ubuntu
WORKDIR /home/ubuntu

RUN mkdir -p \
    ~/.local/state \
    ~/.local/share \
    ~/.config \
    ~/.cache

RUN curl https://mise.run | sh -s -- --version latest --install-dir /home/ubuntu/.local/bin
