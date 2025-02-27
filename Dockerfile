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
# Install OpenRCT2
COPY --from=build-env /openrct2-install /openrct2-install
RUN apt-get update \
 && apt-get install --no-install-recommends -y rsync ca-certificates libpng16-16 libzip4 libcurl4 libfreetype6 libfontconfig1 libicu74 jq curl \
 && rm -rf /var/lib/apt/lists/* \
 && rsync -a /openrct2-install/* / \
 && rm -rf /openrct2-install \
 && openrct2-cli --version

# Set up user and directories
RUN useradd -m -d /home/openrct2 openrct2 && \
    mkdir -p /serverdata/serverfiles/user-data \
    /serverdata/serverfiles/saves \
    /serverdata/serverfiles/user-data/logs && \
    chown -R openrct2:openrct2 /serverdata/serverfiles && \
    chmod 775 /serverdata/serverfiles

WORKDIR /serverdata/serverfiles

# Copy and setup entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 11753

# Test run and scan
RUN openrct2-cli --version \
 && openrct2-cli scan-objects \
 && touch /serverdata/serverfiles/user-data/logs/server.log \
 && chown openrct2:openrct2 /serverdata/serverfiles/user-data/logs/server.log

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
