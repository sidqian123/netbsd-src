#!/bin/bash
set -e  # Exit on error

# Get current user's UID and GID
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# Ensure target directory exists with correct permissions
mkdir -p /Volumes/obj
sudo chown -R $USER_ID:$GROUP_ID /Volumes/obj
sudo chmod -R 777 /Volumes/obj

# Run commands inside the existing Docker container
echo "Creating and adding ramdisk to luna68k kernel..."

docker exec -it csci104 /bin/bash -c "
    set -e  # Exit on error inside Docker

    # Define paths
    RAMDISK_PATH=/tmp/luna68k-ramdisk.fs
    RAMDISK_COPY=/work/tmp/luna68k-ramdisk.fs
    ROOTFS_DIR=/work/rootfs_ramdisk
    KERNEL=/work/obj/sys/arch/luna68k/compile/SIDQIAN/netbsd
    MDSETIMAGE=/work/obj/tools/mdsetimage/mdsetimage

    # Create a big-endian FFSv1 ramdisk image (1MB)
    echo 'Creating FFSv1 big-endian ramdisk image (1MB)...'
    /work/obj/tooldir.Linux-6.12.5-linuxkit-aarch64/bin/nbmakefs -s 512k -t ffs -B be -o bsize=8192,fsize=1024,version=1 \$RAMDISK_PATH \$ROOTFS_DIR

    # Verify created ramdisk
    echo 'Checking created ramdisk file...'
    file \$RAMDISK_PATH || echo 'Failed to verify ramdisk format'

    # Ensure file exists before continuing
    if [ ! -f \"\$RAMDISK_PATH\" ]; then
        echo 'ERROR: Ramdisk file was not created!' >&2
        exit 1
    fi

    # Copy the ramdisk explicitly for consistency
    cp \$RAMDISK_PATH \$RAMDISK_COPY

    # Double-check endianness
    echo 'Verifying copied ramdisk file...'
    file \$RAMDISK_COPY || echo 'Failed to verify copied ramdisk format'

    # Check if the kernel has the necessary symbols
    echo 'Checking kernel symbols for embedded ramdisk support...'
    nm \$KERNEL | grep 'md_root_image' || echo 'Warning: md_root_image symbol not found in kernel'

    # Embed the ramdisk into the kernel using mdsetimage
    echo 'Adding ramdisk to kernel...'
    cp \$KERNEL \$KERNEL.orig  # Backup original kernel
    \$MDSETIMAGE -v -I md_root_image -S md_root_size \$KERNEL \$RAMDISK_COPY

    # Verify kernel size before and after
    KERNEL_SIZE_BEFORE=\$(stat -c %s /work/obj/sys/arch/luna68k/compile/SIDQIAN/netbsd.orig 2>/dev/null || echo 'unknown')
    KERNEL_SIZE_AFTER=\$(stat -c %s \$KERNEL)
    echo \"Kernel size: \$KERNEL_SIZE_AFTER bytes (was \$KERNEL_SIZE_BEFORE bytes)\"

    # Make a copy of the kernel with ramdisk
    cp \$KERNEL /work/netbsd-src/netbsd-with-ramdisk

    # Verify the final embedded kernel's endianness
    echo 'Final check: Verifying kernel-embedded ramdisk endianness...'
    file /work/netbsd-src/netbsd-with-ramdisk || echo 'Failed to verify final kernel format'
"

echo "Process completed! The modified kernel is available as 'netbsd-with-ramdisk' in the /work/netbsd-src directory."
