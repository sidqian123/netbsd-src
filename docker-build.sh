#!/bin/bash
set -e

# Get current user's UID and GID
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# Ensure target directory exists with correct permissions
mkdir -p /Volumes/obj
sudo chown -R $USER_ID:$GROUP_ID /Volumes/obj
sudo chmod -R 777 /Volumes/obj

# Step 1: Build tools for luna68k using GCC (not Clang)
echo "Step 1: Building tools for luna68k architecture..."
docker exec -it csci104 /bin/bash -c "
    cd /work/netbsd-src &&
    ./build.sh -O /work/obj -m luna68k -N1 -j 50 -U tools
"

# Step 2: Build the kernel
echo "Building kernel=SIDQIAN with gcc..."
docker exec -it csci104 /bin/bash -c "
    cd /work/netbsd-src &&
    ./build.sh -O /work/obj -m luna68k -N1 -j 50 -U -u kernel=SIDQIAN
"

echo "Build completed!"
