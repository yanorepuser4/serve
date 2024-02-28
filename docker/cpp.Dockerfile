# syntax = docker/dockerfile:experimental
#
# This file can build images for CPU with CPP backend support.
#
# Following comments have been shamelessly copied from https://github.com/pytorch/pytorch/blob/master/Dockerfile
#
# NOTE: To build this you will need a docker version > 18.06 with
#       experimental enabled and DOCKER_BUILDKIT=1
#
#       If you do not use buildkit you are not going to have a good time
#
#       For reference:
#           https://docs.docker.com/develop/develop-images/build_enhancements/


ARG BASE_IMAGE=ubuntu:rolling
ARG PYTHON_VERSION=3.9

FROM ${BASE_IMAGE} AS cpp-dev-image
ARG PYTHON_VERSION
ARG BRANCH_NAME
ENV PYTHONUNBUFFERED TRUE

RUN --mount=type=cache,id=apt-dev,target=/var/cache/apt \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install software-properties-common -y && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt remove python-pip  python3-pip && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        sudo \
        vim \
        git \
        curl \
        wget \
        rsync \
        python$PYTHON_VERSION \
        python$PYTHON_VERSION-venv \
    && rm -rf /var/lib/apt/lists/*

# Enable installation of latest cmake release
# Ref: https://apt.kitware.com/
RUN apt-get install -y ca-certificates gpg lsb-release
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null
RUN apt-get update

# Create a virtual environment and "activate" it by adding it first to the path.
RUN python$PYTHON_VERSION -m venv /home/venv
ENV PATH="/home/venv/bin:$PATH"

RUN git clone --recursive https://github.com/pytorch/serve.git \
    && cd serve \
    && git checkout ${BRANCH_NAME}

WORKDIR "serve"

EXPOSE 8080 8081 8082 7070 7071
