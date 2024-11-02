#!/bin/bash
# * =====================================================
# * Copyright © hk. 2022-2025. All rights reserved.
# * File name  : 1.sh
# * Author     : 苏木
# * Date       : 2024-11-01
# * ======================================================
##

##======================================================
BLACK="\033[1;30m"
RED='\033[1;31m'    # 红
GREEN='\033[1;32m'  # 绿
YELLOW='\033[1;33m' # 黄
BLUE='\033[1;34m'   # 蓝
PINK='\033[1;35m'   # 紫
CYAN='\033[1;36m'   # 青
WHITE='\033[1;37m'  # 白
CLS='\033[0m'       # 清除颜色

INFO="${GREEN}[INFO]${CLS}"
WARN="${YELLOW}[WARN]${CLS}"
ERR="${RED}[ERR ]${CLS}"

SCRIPT_NAME=${0#*/}
SCRIPT_CURRENT_PATH=${0%/*}
SCRIPT_ABSOLUTE_PATH=`cd $(dirname ${0}); pwd`

SYSTEM_ENVIRONMENT_FILE=/etc/profile # 系统环境变量位置
USER_ENVIRONMENT_FILE=~/.bashrc
SOFTWARE_DIR_PATH=~/2software        # 软件安装目录

TIME_START=
TIME_END=

#===============================================
function get_start_time()
{
	TIME_START=$(date +'%Y-%m-%d %H:%M:%S')
}
function get_end_time()
{
	TIME_END=$(date +'%Y-%m-%d %H:%M:%S')
}

function get_execute_time()
{
	start_seconds=$(date --date="$TIME_START" +%s);
	end_seconds=$(date --date="$TIME_END" +%s);
	duration=`echo $(($(date +%s -d "${TIME_END}") - $(date +%s -d "${TIME_START}"))) | awk '{t=split("60 s 60 m 24 h 999 d",a);for(n=1;n<t;n+=2){if($1==0)break;s=$1%a[n]a[n+1]s;$1=int($1/a[n])}print s}'`
	echo "===*** 运行时间：$((end_seconds-start_seconds))s,time diff: ${duration} ***==="
}

function get_ubuntu_info()
{
    # 获取内核版本信息
    local kernel_version=$(uname -r) # -a选项会获得更详细的版本信息
    # 获取Ubuntu版本信息
    local ubuntu_version=$(lsb_release -ds)

    # 获取Ubuntu RAM大小
    local ubuntu_ram_total=$(cat /proc/meminfo |grep 'MemTotal' |awk -F : '{print $2}' |sed 's/^[ \t]*//g')
    # 获取Ubuntu 交换空间swap大小
    local ubuntu_swap_total=$(cat /proc/meminfo |grep 'SwapTotal' |awk -F : '{print $2}' |sed 's/^[ \t]*//g')
    #显示硬盘，以及大小
    #local ubuntu_disk=$(sudo fdisk -l |grep 'Disk' |awk -F , '{print $1}' | sed 's/Disk identifier.*//g' | sed '/^$/d')
    
    #cpu型号
    local ubuntu_cpu=$(grep 'model name' /proc/cpuinfo |uniq |awk -F : '{print $2}' |sed 's/^[ \t]*//g' |sed 's/ \+/ /g')
    #物理cpu个数
    local ubuntu_physical_id=$(grep 'physical id' /proc/cpuinfo |sort |uniq |wc -l)
    #物理cpu内核数
    local ubuntu_cpu_cores=$(grep 'cpu cores' /proc/cpuinfo |uniq |awk -F : '{print $2}' |sed 's/^[ \t]*//g')
    #逻辑cpu个数(线程数)
    local ubuntu_processor=$(grep 'processor' /proc/cpuinfo |sort |uniq |wc -l)
    #查看CPU当前运行模式是64位还是32位
    local ubuntu_cpu_mode=$(getconf LONG_BIT)

    # 打印结果
    echo "ubuntu: $ubuntu_version - $ubuntu_cpu_mode"
    echo "kernel: $kernel_version"
    echo "ram   : $ubuntu_ram_total"
    echo "swap  : $ubuntu_swap_total"
    echo "cpu   : $ubuntu_cpu,physical id is$ubuntu_physical_id,cores is $ubuntu_cpu_cores,processor is $ubuntu_processor"
}
#===============================================
# 开发环境信息
function dev_env_info()
{
    echo "Development environment: "
    echo "ubuntu : 20.04.2-64(1核12线程 16GB RAM,512GB SSD)"
    echo "VMware : VMware® Workstation 17 Pro 17.6.0 build-24238078"
    echo "Windows: "
    echo "          处理器 AMD Ryzen 7 5800H with Radeon Graphics 3.20 GHz 8核16线程"
    echo "          RAM	32.0 GB (31.9 GB 可用)"
    echo "          系统类型	64 位操作系统, 基于 x64 的处理器"
    echo "说明: 初次安装完SDK,在以上环境下编译大约需要3小时,不加任何修改进行编译大约需要10~15分钟左右"
}
#===============================================

LINUX_KERNEL_DIR_PATH=~/7Linux/imx6ull-kernel
ZIMAGE_DIR_PATH=arch/arm/boot
DTB_DIR_PATH=arch/arm/boot/dts
CONFIGS_DIR_PATH=arch/arm/configs
IMAGE_DIR_PATH=image

TARGET_FILE[0]=${ZIMAGE_DIR_PATH}/zImage                # linux内核镜像
TARGET_FILE[1]=${DTB_DIR_PATH}/imx6ull-14x14-evk.dtb    # 设备树文件

ARCH_NAME=arm
CROSS_COMPILE_NAME=arm-linux-gnueabihf-
BOARD_CONFIG_NAME=imx_v6_v7_defconfig


function time_count_down
{
    for i in {3..1}
    do     

        echo -ne "${INFO}after ${i} is end!!"
        echo -ne "\r\r"        # echo -e 处理特殊字符  \r 光标移至行首，但不换行
        sleep 1
    done
    echo "" # 打印一个空行，防止出现混乱
}
function clean_project()
{
    make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} distclean
}

function build_project()
{
    get_start_time
    cd ${LINUX_KERNEL_DIR_PATH}
    echo -e ${PINK}"current path:$(pwd)"${CLS}

    # 每次编译时间太长，不会清理后编译
    echo -e "${INFO}正在配置编译选项(BOARD_CONFIG_NAME=${BOARD_CONFIG_NAME})..."
    make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} ${BOARD_CONFIG_NAME}
    echo -e "${INFO}正在编译工程(BOARD_CONFIG_NAME=${BOARD_CONFIG_NAME})..."
    make V=0 ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} -j16

    echo -e "${INFO}检查是否编译成功..."
    for temp in ${TARGET_FILE[@]}
    do
        if [ ! -f "${TARGET_FILE}" ];then
            echo -e "${RED}++++++++++++++++++++++++++++++++++++++++++++++++++++${CLS}"
            echo -e "${ERR}${temp} 编译失败,请检查后重试"
            echo -e "${RED}++++++++++++++++++++++++++++++++++++++++++++++++++++${CLS}"
            continue
        else
            echo -e "${GREEN}++++++++++++++++++++++++++++++++++++++++++++++++++++${CLS}"
            echo -e "${INFO}${temp} 编译成功"
            echo -e "${GREEN}++++++++++++++++++++++++++++++++++++++++++++++++++++${CLS}"
        fi
        if [ ! -d "${IMAGE_DIR_PATH}" ];then
            mkdir -p ${IMAGE_DIR_PATH}
        fi
        cp -pvf ${temp} ${IMAGE_DIR_PATH}
    done
    get_end_time
    get_execute_time
}

function build_NXP_linux()
{
    #make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
    #make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx_v6_v7_defconfig # sd卡启动用这个
    #make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j16
    BOARD_CONFIG_NAME=imx_v6_v7_defconfig
    build_project
}

function build_ALPHA_linux()
{
    #make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
    #make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- mx6ull_alpha_emmc_defconfig # sd卡启动用这个
    #make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j16
    BOARD_CONFIG_NAME=mx6ull_alpha_emmc_defconfig
    build_project
}

function echo_menu()
{
    echo "================================================="
	echo -e "${GREEN}               build project ${CLS}"
	echo -e "${GREEN}                by @苏木    ${CLS}"
	echo "================================================="
    echo -e "${PINK}current path         :$(pwd)${CLS}"
    echo -e "${PINK}SCRIPT_CURRENT_PATH  :${SCRIPT_CURRENT_PATH}${CLS}"
    echo -e "${PINK}ARCH_NAME            :${ARCH_NAME}${CLS}"
    echo -e "${PINK}CROSS_COMPILE_NAME   :${CROSS_COMPILE_NAME}${CLS}"
    echo -e "${PINK}BOARD_CONFIG_NAME    :${BOARD_CONFIG_NAME}${CLS}"
    echo ""
    echo -e "* [0] 编译linux内核"
    echo -e "* [1] 清理linux内核工程"
    echo -e "* [2] 编译NXP官方原版linux内核"
    echo "================================================="
}

function func_process()
{
	read -p "请选择功能,默认选择0:" choose
	case "${choose}" in
		"0") build_ALPHA_linux;;
		"1") clean_project;;
		"2") build_NXP_linux;;
		*) build_ALPHA_linux;;
	esac
}

echo_menu
func_process
