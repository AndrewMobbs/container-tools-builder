# Use a minimal Debian Bookworm image as the base
FROM debian:bookworm

# Set environment to noninteractive for apt-get commands
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary build dependencies
# Combine update and install into a single RUN layer for efficiency.
# Clean up apt cache afterwards to reduce the final image size.
RUN apt-get update -qq \
    && apt-get -y install \
    autoconf \
    automake \
    bats \
    btrfs-progs \
    build-essential \
    curl \
    gcc \
    git \
    go-md2man \
    groff \
    libapparmor-dev \
    libbtrfs-dev \
    libcap-dev \
    libglib2.0-dev \
    libgpgme11-dev \
    libprotobuf-c-dev \
    libseccomp-dev \
    libselinux1-dev \
    libsystemd-dev \
    libtool \
    libyajl-dev \
    make \
    man-db \
    pkgconf \
    python3 \
    runc \
    skopeo \
    asciidoctor \
    && rm -rf /var/lib/apt/lists/*

# Define the Go version as an environment variable for easy updates
ENV GO_VERSION 1.24.2

# Set GOROOT and update the system-wide PATH to include Go's bin directory
ENV GOROOT /usr/local/go
ENV PATH ${GOROOT}/bin:${PATH}

# Download and extract the Go SDK into the GOROOT directory
# Combine download and extraction into a single RUN layer.
RUN curl -sL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar xzf - -C /usr/local/

# Create a non-root user for building.
# Building as a non-root user is a recommended security practice.
RUN useradd -ms /bin/bash build

# Switch to the 'build' user for subsequent operations
USER build

# Set the working directory for the 'build' user
# All subsequent commands will be relative to this directory (/home/build)
WORKDIR /home/build

# Create source and binary directories
RUN mkdir -p bin src

# Clone the source repositories
# Each clone is a separate layer. This improves caching if only one repository changes.
# Cloned into the 'src' subdirectory within the build user's home.
RUN git clone https://github.com/cpuguy83/go-md2man src/go-md2man
RUN git clone https://github.com/containers/podman src/podman
RUN git clone https://github.com/containers/buildah src/buildah
RUN git clone https://passt.top/passt src/passt
RUN git clone https://github.com/rootless-containers/rootlesskit src/rootlesskit
RUN git clone https://github.com/containers/crun src/crun

# Build and install go-md2man
# Combine the change directory, build, and copy steps into one RUN instruction.
# Copies the resulting binary to the central 'bin' directory.
RUN cd ~/src/go-md2man && make && cp -a bin/go-md2man ~/bin

# Build and install podman
# Combine steps; copies all binaries from podman's bin dir.
RUN cd ~/src/podman && make && cp -a bin/* ~/bin

# Build and install buildah
# Combine steps; copies all binaries from buildah's bin dir.
RUN cd ~/src/buildah && make && cp -a bin/* ~/bin

# Build and install passt (builds pasta and passt binaries)
# Combine steps; copies both resulting binaries.
RUN cd ~/src/passt && make && cp -a pasta passt ~/bin

# Build and install rootlesskit
# Combine steps; copies all binaries from rootlesskit's bin dir.
RUN cd ~/src/rootlesskit && make && cp -a bin/* ~/bin

# Build and install crun (uses autotools: autogen, configure, make)
# Combine steps; copies the crun binary.
RUN cd ~/src/crun && ./autogen.sh && ./configure && make && cp -a crun ~/bin

# Create a tar archive of all built binaries located in the 'bin' directory.
# The tar file 'bin.tar' will be created in the user's home directory (/home/build).
# This is the final artifact containing all the built tools.
RUN cd ~/bin && tar cvf ../bin.tar *

# The final artifact, 'bin.tar', is now available inside the container at /home/build/bin.tar.
# You can copy it out after building the image, for example:
# podman build -t container-tools-builder .
# podman create --name builder_container container-tools-builder
# podman cp builder_container:/home/build/bin.tar ./
# podman rm builder_container
