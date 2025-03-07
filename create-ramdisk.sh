#!/bin/bash
set -e

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
    # Create ramdisk image with small size
    echo 'Creating minimal ramdisk image (1MB)...'
    /work/obj/tooldir.Linux-6.12.5-linuxkit-aarch64/bin/nbmakefs -s 1024k -t ffs /tmp/luna68k-ramdisk.fs /work/rootfs_ramdisk

    # Get kernel file
    KERNEL=/work/obj/sys/arch/luna68k/compile/SIDQIAN/netbsd

    # Get mdsetimage tool - correct path
    MDSETIMAGE=/work/obj/tools/mdsetimage/mdsetimage

    # Embed the ramdisk into the kernel properly
    echo 'Adding ramdisk to kernel...'
    cp \$KERNEL \$KERNEL.orig  # Backup original kernel
    \$MDSETIMAGE -v -s 2048k \$KERNEL /tmp/luna68k-ramdisk.fs

    # Verify kernel size (before and after)
    KERNEL_SIZE_BEFORE=\$(stat -c %s /work/obj/sys/arch/luna68k/compile/SIDQIAN/netbsd.orig 2>/dev/null || echo 'unknown')
    KERNEL_SIZE_AFTER=\$(stat -c %s \$KERNEL)
    echo \"Kernel size: \$KERNEL_SIZE_AFTER bytes (was \$KERNEL_SIZE_BEFORE bytes)\"

    # Make a copy of the kernel with ramdisk
    cp \$KERNEL /work/netbsd-src/netbsd-with-ramdisk
"

echo "Process completed! The modified kernel is available as 'netbsd-with-ramdisk' in the /work/netbsd-src directory."
