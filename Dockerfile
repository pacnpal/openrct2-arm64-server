# Build OpenRCT2
FROM ubuntu:24.04 AS build-env
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install --no-install-recommends -y git cmake pkg-config ninja-build clang nlohmann-json3-dev libcurl4-openssl-dev libcrypto++-dev libfontconfig1-dev libfreetype6-dev libpng-dev libzip-dev libssl-dev libicu-dev libflac-dev libvorbis-dev \
 && rm -rf /var/lib/apt/lists/*

ARG OPENRCT2_REF=master
WORKDIR /openrct2
RUN git -c http.sslVerify=false clone --depth 1 -b $OPENRCT2_REF https://github.com/OpenRCT2/OpenRCT2 . \
 && mkdir build \
 && cd build \
 && cmake .. -G Ninja -DCMAKE_BUILD_TYPE=release -DCMAKE_INSTALL_PREFIX=/openrct2-install/usr -DDISABLE_GUI=ON -DENABLE_HEADERS_CHECK=OFF \
 && ninja -k0 install \
 && rm /openrct2-install/usr/lib/libopenrct2.a \
 # HACK due to issue in cmakelists, move content from cli
 && mv /openrct2-install/usr/share/openrct2-cli/* /openrct2-install/usr/share/openrct2 \
 && rm -rf /openrct2-install/usr/share/openrct2-cli

# Build runtime image
FROM ubuntu:24.04

ENV USER=container \
    HOME=/home/container \
    DEBIAN_FRONTEND=noninteractive

# Install OpenRCT2 and dependencies
COPY --from=build-env /openrct2-install /openrct2-install
RUN apt-get update \
 && apt-get install --no-install-recommends -y rsync ca-certificates libpng16-16 libzip4 libcurl4 libfreetype6 libfontconfig1 libicu74 jq curl \
 && rm -rf /var/lib/apt/lists/* \
 && rsync -a /openrct2-install/* / \
 && rm -rf /openrct2-install \
 && openrct2-cli --version \
 # Create container user and setup directories with proper permissions
 && useradd -d /home/container -m container \
 && mkdir -p /home/container \
            /serverdata/serverfiles/user-data \
            /serverdata/serverfiles/saves \
            /serverdata/serverfiles/user-data/logs \
 && chown -R container:container /home/container \
                                /serverdata/serverfiles \
 && chmod 775 /serverdata/serverfiles \
 && touch /serverdata/serverfiles/user-data/logs/server.log \
 && chown container:container /serverdata/serverfiles/user-data/logs/server.log \
 # Test run and scan
 && openrct2-cli scan-objects \
 && chown -R container:container /serverdata

# Copy and setup entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
 && chown container:container /entrypoint.sh

# Set working directory
WORKDIR /home/container

# Expose default port
EXPOSE 11753

# Switch to container user
USER container

# Use entrypoint script
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
