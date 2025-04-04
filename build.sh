#!/bin/bash
# * =====================================================
# * Copyright © hk. 2022-2025. All rights reserved.
# * File name  : build.sh
# * Author     : 苏木
# * Date       : 2025-04-04
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

#===============================================
TIME_START=
TIME_END=
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

# 本地虚拟机VMware开发环境信息
function dev_env_info()
{
    echo "Development environment: "
    echo "ubuntu : 20.04.2-64(1核12线程 16GB RAM,512GB SSD) arm"
    echo "VMware : VMware® Workstation 17 Pro 17.6.0 build-24238078"
    echo "Windows: "
    echo "          处理器 AMD Ryzen 7 5800H with Radeon Graphics 3.20 GHz 8核16线程"
    echo "          RAM	32.0 GB (31.9 GB 可用)"
    echo "          系统类型	64 位操作系统, 基于 x64 的处理器"
    echo "linux开发板原始系统组件版本:"
    echo "          uboot : v2019.04 https://github.com/nxp-imx/uboot-imx/releases/tag/rel_imx_4.19.35_1.1.0"
    echo "          kernel: v4.19.71 https://github.com/nxp-imx/linux-imx/releases/tag/v4.19.71"
    echo "          rootfs: buildroot-2023.05.1 https://buildroot.org/downloads/buildroot-2023.05.1.tar.gz"
    echo ""
    echo "x86_64-linux-gnu   : gcc version 9.4.0 (Ubuntu 9.4.0-1ubuntu1~20.04.2)"
    echo "arm-linux-gnueabihf:"
    echo "          arm-linux-gnueabihf-gcc 8.3.0"
    echo "          https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz"
}
#===============================================
# 编译工具
ARCH_NAME=arm
CROSS_COMPILE_NAME=arm-linux-gnueabihf-
DEF_CONFIG_TYPE=alpha # nxp 表示编译nxp官方原版配置文件，alpha表示编译我们自定义的配置文件

# linux kernel相关
linux_project_path=.
linux_file_backup_path=${linux_project_path}/../linux-kernel
imx6ull_release_img=()

linux_boot_path=${linux_project_path}/arch/arm/boot
linux_dtb_path=${linux_project_path}/arch/arm/boot/dts
linux_board_cfg_path=${linux_project_path}/arch/arm/configs
linux_image_path=${linux_project_path}/image_output # 这个是把在linux内核源码中生成的zimage和设备树拷贝到这里
linux_img_name=zImage
linux_curconfig_name=.config

manu_func_ena=1 # 手动选择功能
# 脚本运行参数处理
echo "There are $# parameters: $@"
while getopts "a:t:" arg #选项后面的冒号表示该选项需要参数
    do
        case ${arg} in
            t)
                # echo "a's arg:$OPTARG"     # 参数存在$OPTARG中
                if [ $OPTARG == "0" ];then # 使用NXP官方的默认配置文件
                    DEF_CONFIG_TYPE=nxp
                fi
                ;;
            a)
                # echo "a's arg:$OPTARG"     # 参数存在$OPTARG中
                if [ $OPTARG == "1" ];then # 使用NXP官方的默认配置文件
                    manu_func_ena=0
                fi
                ;;
            ?)  #当有不认识的选项的时候arg为?
                echo "${ERR}unkonw argument..."
                exit 1
                ;;
        esac
    done

# 可变参数定义，主要是区分开发板
# ./build.sh 0
if [ ${DEF_CONFIG_TYPE} == "nxp" ];then
linux_dtb_name=imx6ull-14x14-evk.dtb
linux_board_cfg=imx_v6_v7_defconfig
else
# ./build.sh 1
linux_dtb_name=imx6ull-alpha-emmc.dtb
linux_board_cfg=imx_alpha_emmc_defconfig
fi
linux_target=(${linux_boot_path}/${linux_img_name}
              ${linux_dtb_path}/${linux_dtb_name})

imx6ull_release_img[0]=${linux_project_path}/${linux_target[0]}
imx6ull_release_img[1]=${linux_project_path}/${linux_target[1]}

function clean_project()
{
    #make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
    make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} distclean
}

function record_kernel_file_update()
{
    # 备份目录
    if [ ! -d "${linux_file_backup_path}" ];then
        mkdir -p ${linux_file_backup_path}
    fi

    # 设备树相关文件
    if [ ! -d "${linux_file_backup_path}/arch/arm/boot/dts" ];then
        mkdir -p ${linux_file_backup_path}/arch/arm/boot/dts
    fi
    cp -pvf ${linux_project_path}/arch/arm/boot/dts/imx6ull-alpha-emmc.dts ${linux_file_backup_path}/arch/arm/boot/dts
    cp -pvf ${linux_project_path}/arch/arm/boot/dts/imx6ull-alpha-emmc.dtsi ${linux_file_backup_path}/arch/arm/boot/dts

    # 配置文件
    if [ ! -d "${linux_file_backup_path}/arch/arm/configs" ];then
        mkdir -p ${linux_file_backup_path}/arch/arm/configs
    fi
    cp -pvf ${linux_image_path}/${linux_board_cfg} ${linux_file_backup_path}/arch/arm/configs/

    # 源文件相关备份
}

# 编译NXP官方原版镜像
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- clean
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx_v6_v7_defconfig
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all -j16 # 全编译
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage -j16 # 只编译内核镜像
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j16   # 只编译所有的设备树
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx6ull-14x14-evk.dtb -j16 # 只编译指定的设备树

# 编译自己移植的开发板镜像
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- clean
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx_alpha_emmc_defconfig
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all -j16 # 全编译
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage -j16 # 只编译内核镜像
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- dtbs -j16   # 只编译所有的设备树
# make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx6ull-alpha-emmc.dtb -j16 # 只编译指定的设备树

function build_linux_project()
{
    get_start_time
    # $0是脚本的名称，若是给函数传参，$1 表示跟在函数名后的第一个参数
    echo "build_linux_project有 $# 个参数:$@"
    cd ${linux_project_path}

    echo -e ${PINK}"current path:$(pwd)"${CLS}
    local board_defconfig_name=$1
    
    # 每次编译时间太长，不会清理后编译
    # 默认配置文件只需要首次执行，后续执行会覆盖掉后来修改的配置，除非每次都更新默认配置文件
    echo -e "${INFO}正在配置编译选项(board_defconfig_name=${board_defconfig_name})..."
    # make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx_alpha_emmc_defconfig
    make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} ${board_defconfig_name}

    echo -e "${INFO}正在编译工程(board_defconfig_name=${board_defconfig_name})..."
    # make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all -j16
    make V=0 ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} all -j16

    for temp in ${linux_target[@]}
    do
        if [ ! -f "${linux_target}" ];then
            echo -e "${ERR}${temp} 编译失败,请检查后重试"
            continue
        else
            echo -e "${INFO}${temp} 编译成功."
        fi
        if [ ! -d "${linux_image_path}" ];then
            mkdir -p ${linux_image_path}
        fi
        cp -pvf ${temp} ${linux_image_path}
    done
    cp -pvf ${linux_curconfig_name} ${linux_image_path}/${board_defconfig_name}
    get_end_time
    get_execute_time
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
    echo -e "${PINK}linux_dtb_name       :${linux_dtb_name}${CLS}"
    echo -e "${PINK}linux_board_cfg      :${linux_board_cfg}${CLS}"
    echo ""
    echo -e "* [0] 编译linux kernel"
    echo -e "* [1] 同步linux内核文件的修改"
    echo "================================================="
}

function func_process()
{
    if [ ${manu_func_ena} == '1' ];then
	read -p "请选择功能,默认选择0:" choose
    else
    choose=0
    fi
	case "${choose}" in
		"0") build_linux_project ${linux_board_cfg};;
		"1") record_kernel_file_update;;
		*) build_linux_project ${linux_board_cfg};;
	esac
}

echo_menu
func_process
