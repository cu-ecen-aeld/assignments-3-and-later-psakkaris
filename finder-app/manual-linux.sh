#!/bin/bash
# Script outline to install and build kernel.
# Author: Perry

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.110
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
TOOLCHAIN_HOME="${HOME}/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu"
# cross compile toolchain installed in $HOME dir
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Building Kernel Version ${KERNEL_VERSION}"
    # We downloaded the kernel so don't nee git: git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    # DONE
    yes "" | make ARCH=${ARCH} oldconfig
    make -j6 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir rootfs
cd rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p mkdir usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
# DONE
echo "Building busybox..."
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make -j6 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install CONFIG_PREFIX=${OUTDIR}/rootfs


echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
# DONE
cp ${TOOLCHAIN_HOME}/libc/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib
cp ${TOOLCHAIN_HOME}/libc/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64
cp ${TOOLCHAIN_HOME}/libc/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64
cp ${TOOLCHAIN_HOME}/libc/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64


# TODO: Make device nodes
# Done
cd ${OUTDIR}/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1
ls -l dev

#sudo mount -t proc proc /proc
#sudo mount -t sysfs sysfs /sys
#ls -l proc
#ls -l sys

# TODO: Clean and build the writer utility
cd ${HOME}/code/assignment-1-psakkaris/finder-app/
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} clean
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}


# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp writer ${OUTDIR}/rootfs/home
cp finder-test.sh ${OUTDIR}/rootfs/home
cp finder.sh ${OUTDIR}/rootfs/home
cp autorun-qemu.sh ${OUTDIR}/rootfs/home
cd ${OUTDIR}/rootfs/home
mkdir -p conf
echo "psakkaris" > conf/username.txt
echo "assignment3" > conf/assignment.txt

# TODO: Chown the root directory
# Done
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
# Done
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
gzip -f ../initramfs.cpio