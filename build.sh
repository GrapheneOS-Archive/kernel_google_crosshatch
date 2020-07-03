#!/bin/bash

set -o errexit

[[ $# -eq 1 ]] || exit 1

DEVICE=$1

if [[ $DEVICE != blueline && $DEVICE != crosshatch && $DEVICE != bonito ]]; then
    echo invalid device codename
    exit 1
fi

ROOT_DIR=$(realpath ../../..)

export KBUILD_BUILD_USER=grapheneos
export KBUILD_BUILD_HOST=grapheneos
export KBUILD_BUILD_TIMESTAMP="$(date -d "@$(git --no-pager show -s --format=%ct)")"

PATH="$ROOT_DIR/prebuilts/build-tools/linux-x86/bin:$PATH"
PATH="$ROOT_DIR/prebuilts/build-tools/path/linux-x86:$PATH"
PATH="$ROOT_DIR/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin:$PATH"
PATH="$ROOT_DIR/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin:$PATH"
PATH="$ROOT_DIR/prebuilts/clang/host/linux-x86/clang-r353983c/bin:$PATH"
PATH="$ROOT_DIR/prebuilts/misc/linux-x86/lz4:$PATH"
PATH="$ROOT_DIR/prebuilts/misc/linux-x86/dtc:$PATH"
PATH="$ROOT_DIR/prebuilts/misc/linux-x86/libufdt:$PATH"
export LD_LIBRARY_PATH="$ROOT_DIR/prebuilts/clang/host/linux-x86/clang-r353983c/lib64:$LD_LIBRARY_PATH"

chrt -bp 0 $$

make \
    O=out \
    ARCH=arm64 \
    CC=clang \
    HOSTCC=clang \
    HOSTCXX=clang++ \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-android- \
    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
    ${DEVICE}_defconfig

make -j$(nproc) \
    O=out \
    ARCH=arm64 \
    CC=clang \
    HOSTCC=clang \
    HOSTCXX=clang++ \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    CROSS_COMPILE=aarch64-linux-android- \
    CROSS_COMPILE_ARM32=arm-linux-androideabi-

mkdir -p "$ROOT_DIR/device/google/$DEVICE-kernel"
cp out/arch/arm64/boot/{dtbo.img,Image.lz4} "$ROOT_DIR/device/google/$DEVICE-kernel"

if [[ $DEVICE != bonito ]]; then
    cp out/arch/arm64/boot/dts/qcom/sdm845-v2.1.dtb "$ROOT_DIR/device/google/$DEVICE-kernel"
    cp out/arch/arm64/boot/dts/qcom/sdm845-v2.dtb "$ROOT_DIR/device/google/$DEVICE-kernel"
else
    cp out/arch/arm64/boot/dts/qcom/sdm670.dtb "$ROOT_DIR/device/google/$DEVICE-kernel"
fi
