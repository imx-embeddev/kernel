#!/bin/sh
SCRIPT_NAME=${0#*/}
SCRIPT_PATH=${0%/*}

UBUNTU_LINUX_KERNEL_ROOT_PATH=~/5ALPHA/linux-imx-rel_imx_4.1.15_2.1.0_ga

# 配置文件
mkdir -p ${SCRIPT_PATH}/arch/arm/configs
cp -p ${UBUNTU_LINUX_KERNEL_ROOT_PATH}/arch/arm/configs/imx_alpha_emmc_defconfig ${SCRIPT_PATH}/arch/arm/configs

# 设备树
mkdir -p ${SCRIPT_PATH}/arch/arm/boot/dts
cp -p ${UBUNTU_LINUX_KERNEL_ROOT_PATH}/arch/arm/boot/dts/imx6ull-alpha-emmc.dts ${SCRIPT_PATH}/arch/arm/boot/dts
cp -p ${UBUNTU_LINUX_KERNEL_ROOT_PATH}/arch/arm/boot/dts/Makefile ${SCRIPT_PATH}/arch/arm/boot/dts

# 网络驱动相关
mkdir -p ${SCRIPT_PATH}/drivers/net/ethernet/freescale
cp -p ${UBUNTU_LINUX_KERNEL_ROOT_PATH}/drivers/net/ethernet/freescale/fec_main.c ${SCRIPT_PATH}/drivers/net/ethernet/freescale
mkdir -p ${SCRIPT_PATH}/drivers/net/phy
cp -p ${UBUNTU_LINUX_KERNEL_ROOT_PATH}/drivers/net/phy/smsc.c ${SCRIPT_PATH}/drivers/net/phy
