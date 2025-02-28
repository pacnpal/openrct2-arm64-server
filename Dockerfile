# Build OpenRCT2
FROM ubuntu:24.04 AS build-env
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    clang \
    cmake \
    git \
    libcrypto++-dev \
    libcurl4-openssl-dev \
    libflac-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libicu-dev \
    libpng-dev \
    libssl-dev \
    libvorbis-dev \
    libzip-dev \
    ninja-build \
    nlohmann-json3-dev \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

# Clone and build OpenRCT2
ARG OPENRCT2_REF=master
ARG OPENRCT2_COMMIT_SHA
WORKDIR /openrct2
RUN git -c http.sslVerify=false clone --depth 1 -b "$OPENRCT2_REF" https://github.com/OpenRCT2/OpenRCT2 . \
 && if [ ! -z "$OPENRCT2_COMMIT_SHA" ]; then \
      echo "Verifying commit SHA: $OPENRCT2_COMMIT_SHA" && \
      [ "$(git rev-parse HEAD)" = "$OPENRCT2_COMMIT_SHA" ]; \
    fi \
 && mkdir build \
 && cd build \
 && cmake .. \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=release \
    -DCMAKE_INSTALL_PREFIX=/openrct2-install/usr \
    -DDISABLE_GUI=ON \
    -DENABLE_HEADERS_CHECK=OFF \
 && ninja -k0 install \
 && rm /openrct2-install/usr/lib/libopenrct2.a \
 # HACK due to issue in cmakelists, move content from cli
 && mv /openrct2-install/usr/share/openrct2-cli/* /openrct2-install/usr/share/openrct2 \
 && rm -rf /openrct2-install/usr/share/openrct2-cli

# Build runtime image
FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    USER=container \
    HOME=/home/container

# Install OpenRCT2 and dependencies
COPY --from=build-env /openrct2-install /openrct2-install
RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    jq \
    libcurl4 \
    libfontconfig1 \
    libfreetype6 \
    libicu72 \
    libpng16-16 \
    libzip4 \
    rsync \
 && rm -rf /var/lib/apt/lists/* \
 && rsync -a /openrct2-install/* / \
 && rm -rf /openrct2-install \
 # Create container user and setup directories with proper permissions
 && useradd -d "$HOME" -m container \
 && mkdir -p "$HOME/serverdata/serverfiles/"{user-data/logs,saves} \
 && touch "$HOME/serverdata/serverfiles/user-data/logs/server.log" \
 && chown -R container:container "$HOME" \
 && chmod 775 "$HOME/serverdata/serverfiles" \
 # Verify installation
 && openrct2-cli --version \
 && openrct2-cli scan-objects

# Copy and setup entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
 && chown container:container /entrypoint.sh

# Set working directory
WORKDIR /home/container/serverdata

# Expose default port
EXPOSE 11753

# Switch to container user
USER container

# Use entrypoint script
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
