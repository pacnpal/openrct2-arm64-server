Docker: https://hub.docker.com/repository/docker/pacnpal/openrct2-arm64

### OpenRCT2 Arm64 Server

This repository contains the files necessary to build the Docker Arm64 image for OpenRCT2, so it can be run as a headless server.

## Building

According to the [Official Documentation](https://github.com/OpenRCT2/OpenRCT2/wiki/Building-OpenRCT2-on-Linux), these are the requirements to build on Debian/Ubuntu:

Required packages:
```bash
# Core build dependencies
apt-get install -y git cmake pkg-config gcc g++ libsdl2-dev libicu-dev libjansson-dev libspeex-dev libspeexdsp-dev libcurl4-openssl-dev libcrypto++-dev libfontconfig1-dev libfreetype6-dev libpng-dev libssl-dev libzip-dev ninja-build 

# Optional, but recommended dependencies
apt-get install -y libduktape207 liblzma-dev libdbus-1-dev libunwind-dev
```

Note: Package names and versions may vary slightly depending on your distribution and version.

## Compilation Steps

1. Clone the repository and enter its directory:
```bash
git clone https://github.com/OpenRCT2/OpenRCT2.git
cd OpenRCT2
```

2. Create a build directory and enter it:
```bash
mkdir build
cd build
```

3. Configure the build (headless mode for server):
```bash
cmake .. -G Ninja -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=MinSizeRel -DDOWNLOAD_TITLE_SEQUENCES=OFF -DDOWNLOAD_OBJECTS=OFF -DDISABLE_GUI=ON -DDISABLE_TTF=ON -DUSE_MMAP=OFF
```

4. Build OpenRCT2:
```bash
ninja
```

# Build Actions Documentation

## update-and-build.sh
Script to automatically update and rebuild OpenRCT2 from source.

### Purpose
- Maintains fresh builds of OpenRCT2 by automatically handling the update and build process
- Ensures clean builds by removing previous local copies
- Streamlines the build process for the Linux container image
- Automatically installs and configures required dependencies

### Process Flow
1. Checks for and installs required packages (git, docker) if missing
2. Removes existing local repository if present
3. Clones latest version from OpenRCT2 GitHub repository
4. Initiates Linux container image build

### Dependencies
The script will automatically install:
- Git (for repository management)
- Docker (for container builds)

### Supported Package Managers
- apt-get (Debian/Ubuntu based systems)
- yum (Red Hat/CentOS based systems)

### Usage
```bash
./update-and-build.sh
```

### Permissions
- Script requires sudo access for package installation and docker operations
- Execute permissions are required for the script (`chmod +x update-and-build.sh`)

### Error Handling
- Validates package manager availability
- Checks for successful package installations
- Verifies Docker service status
- Handles repository clone failures
- Monitors Docker build process

The compiled binary will be located in the `build` directory as `openrct2`.
