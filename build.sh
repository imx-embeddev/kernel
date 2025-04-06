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
PROJECT_ROOT=${SCRIPT_ABSOLUTE_PATH} # 工程的源码目录，一定要和编译脚本是同一个目录

# Github Actions托管的linux服务器有以下用户级环境变量，系统级环境变量加上sudo好像也权限修改
# .bash_logout  当用户注销时，此文件将被读取，通常用于清理工作，如删除临时文件。
# .bashrc       此文件包含特定于 Bash Shell 的配置，如别名和函数。它在每次启动非登录 Shell 时被读取。
# .profile、.bash_profile 这两个文件位于用户的主目录下，用于设置特定用户的环境变量和启动程序。当用户登录时，
#                        根据 Shell 的类型和配置，这些文件中的一个或多个将被读取。
USER_ENV_FILE_BASHRC=~/.bashrc
USER_ENV_FILE_PROFILE=~/.profile
USER_ENV_FILE_BASHRC_PROFILE=~/.bash_profile

SYSTEM_ENVIRONMENT_FILE=/etc/profile # 系统环境变量位置

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
LINUX_KERNEL_BACKUP=${PROJECT_ROOT}/../linux-kernel
RESULT_OUTPUT=image_output # 这个是把在linux内核源码中生成的zimage和设备树拷贝到这里

COMPILE_PLATFORM=local # local：非githubaction自动打包，githubaction：githubaction自动打包

# 脚本运行参数处理
echo "There are $# parameters: $@"
while getopts "p:t:" arg #选项后面的冒号表示该选项需要参数
    do
        case ${arg} in
            p)
                # echo "a's arg:$OPTARG"     # 参数存在$OPTARG中
                if [ $OPTARG == "1" ];then # 使用NXP官方的默认配置文件
                    COMPILE_PLATFORM=githubaction
                fi
                ;;
            t)
                # echo "a's arg:$OPTARG"     # 参数存在$OPTARG中
                if [ $OPTARG == "0" ];then # 使用NXP官方的默认配置文件
                    DEF_CONFIG_TYPE=nxp
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
BOARD_DEVICE_TREE=imx6ull-14x14-evk
BOARD_DTB_FILE=imx6ull-14x14-evk.dtb
BOARD_DEFCONFIG=imx_v6_v7_defconfig
else
# ./build.sh 1
BOARD_DEVICE_TREE=imx6ull-alpha-emmc
BOARD_DTB_FILE=imx6ull-alpha-emmc.dtb
BOARD_DEFCONFIG=imx_alpha_emmc_defconfig
fi

RESULT_FILE=(arch/arm/boot/zImage
             arch/arm/boot/dts/${BOARD_DTB_FILE})

function clean_project()
{
    if [ ! -d "${PROJECT_ROOT}/../imx6ull-kernel" ];then
        echo "${PROJECT_ROOT}/../imx6ull-kernel 不存在......"
        exit 0
    fi
    cd ${PROJECT_ROOT}/../imx6ull-kernel

    if [ -d "${RESULT_OUTPUT}" ];then
        rm -rvf  ${RESULT_OUTPUT}
    fi

    #make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
    make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} distclean
}

function record_kernel_file_update()
{
    if [ ! -d "${PROJECT_ROOT}/../imx6ull-kernel" ];then
        echo "${PROJECT_ROOT}/../imx6ull-kernel 不存在......"
        exit 0
    fi
    cd ${PROJECT_ROOT}/../imx6ull-kernel
    echo -e "${PINK}current path         :$(pwd)${CLS}"
    echo -e "${PINK}BOARD_DEFCONFIG      :${BOARD_DEFCONFIG}${CLS}"

    # 备份目录
    if [ ! -d "${LINUX_KERNEL_BACKUP}" ];then
        mkdir -p ${LINUX_KERNEL_BACKUP}
    fi

    # 设备树相关文件
    if [ ! -d "${LINUX_KERNEL_BACKUP}/arch/arm/boot/dts" ];then
        mkdir -p ${LINUX_KERNEL_BACKUP}/arch/arm/boot/dts
    fi
    cp -pvf arch/arm/boot/dts/${BOARD_DEVICE_TREE}.dts ${LINUX_KERNEL_BACKUP}/arch/arm/boot/dts
    cp -pvf arch/arm/boot/dts/${BOARD_DEVICE_TREE}.dtsi ${LINUX_KERNEL_BACKUP}/arch/arm/boot/dts

    # 配置文件
    if [ ! -d "${LINUX_KERNEL_BACKUP}/arch/arm/configs" ];then
        mkdir -p ${LINUX_KERNEL_BACKUP}/arch/arm/configs
    fi
    cp -pvf ${RESULT_OUTPUT}/${BOARD_DEFCONFIG} ${LINUX_KERNEL_BACKUP}/arch/arm/configs/
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
    if [ ! -d "${PROJECT_ROOT}/../imx6ull-kernel" ];then
        echo "${PROJECT_ROOT}/../imx6ull-kernel 不存在......"
        exit 0
    fi
    cd ${PROJECT_ROOT}/../imx6ull-kernel
    echo -e "${PINK}current path         :$(pwd)${CLS}"
    echo -e "${PINK}BOARD_DEFCONFIG      :${BOARD_DEFCONFIG}${CLS}"

    get_start_time
    # $0是脚本的名称，若是给函数传参，$1 表示跟在函数名后的第一个参数
    echo "build_linux_project有 $# 个参数:$@"
    local board_defconfig_name=$1

    # 1. 清理工程，但是每次编译时间太长，不会清理后编译
    # 2. 配置linux内核
    # 默认配置文件只需要首次执行，后续执行会覆盖掉后来修改的配置，除非每次都更新默认配置文件
    echo -e "${INFO}正在配置编译选项(board_defconfig_name=${board_defconfig_name})..."
    # make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx_alpha_emmc_defconfig
    make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} ${board_defconfig_name}
    # 3. 编译linux内核
    echo -e "${INFO}正在编译工程(board_defconfig_name=${board_defconfig_name})..."
    # make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all -j16
    make V=0 ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} all -j16

    # 4.检查成果物
    for temp in ${RESULT_FILE[@]}
    do
        if [ ! -f "${RESULT_FILE}" ];then
            echo -e "${ERR}${temp} 编译失败,请检查后重试"
            continue
        else
            echo -e "${INFO}${temp} 编译成功."
        fi
        if [ ! -d "${RESULT_OUTPUT}" ];then
            mkdir -p ${RESULT_OUTPUT}
        fi
        cp -pvf ${temp} ${RESULT_OUTPUT}
    done

    # 5.生成默认配置文件
    echo -e "${INFO}正在编译工程(board_defconfig_name=${board_defconfig_name})..."
    # make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all -j16
    make V=0 ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} savedefconfig
    if [ ! -f "defconfig" ];then
        echo -e "${ERR}defconfig 不存在,请检查后重试"
    else
        cp -pvf defconfig ${RESULT_OUTPUT}/${board_defconfig_name}
    fi
    
    get_end_time
    get_execute_time
}

function get_kernel_source_code()
{
    chmod 777 get_kernel_src.sh
    ./get_kernel_src.sh -r https://github.com/nxp-imx/linux-imx \
                        -b v4.19.71 \
                        -c e7d2672c66e4d3675570369bf20856296da312c4 \
                        -d ../kernel_nxp_4.19.71
}

function source_env_info()
{
    if [ -f ${USER_ENV_FILE_PROFILE} ]; then
        source ${USER_ENV_FILE_BASHRC}
    fi
    # 修改可能出现的其他用户级环境变量，防止不生效
    if [ -f ${USER_ENV_FILE_PROFILE} ]; then
        source ${USER_ENV_FILE_PROFILE}
    fi

    if [ -f ${USER_ENV_FILE_BASHRC_PROFILE} ]; then
        source ${USER_ENV_FILE_BASHRC_PROFILE}
    fi

}

function github_actions_build()
{
    if [ ! -d "${PROJECT_ROOT}/../kernel_nxp_4.19.71" ];then
        echo "${PROJECT_ROOT}/../kernel_nxp_4.19.71 不存在......"
        exit 0
    fi
    cd ${PROJECT_ROOT}/../kernel_nxp_4.19.71
    echo -e "${PINK}current path         :$(pwd)${CLS}"
    echo -e "${PINK}BOARD_DEFCONFIG      :${BOARD_DEFCONFIG}${CLS}"

    get_start_time
    # 设置环境变量
    source_env_info
    
    # $0是脚本的名称，若是给函数传参，$1 表示跟在函数名后的第一个参数
    echo "build_linux_project有 $# 个参数:$@"
    local board_defconfig_name=$1

    # 1. 清理工程，但是每次编译时间太长，不会清理后编译
    make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} distclean > make.log

    # 2. 配置linux内核
    # 默认配置文件只需要首次执行，后续执行会覆盖掉后来修改的配置，除非每次都更新默认配置文件
    echo -e "${INFO}正在配置编译选项(board_defconfig_name=${board_defconfig_name})..."
    # make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx_alpha_emmc_defconfig
    make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} ${board_defconfig_name} >> make.log
    # 3. 编译linux内核
    echo -e "${INFO}正在编译工程(board_defconfig_name=${board_defconfig_name})..."
    # make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all -j16
    make V=0 ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} all -j16 >> make.log

    # 4.检查成果物
    for temp in ${RESULT_FILE[@]}
    do
        if [ ! -f "${RESULT_FILE}" ];then
            echo -e "${ERR}${temp} 编译失败,请检查后重试"
            continue
        else
            echo -e "${INFO}${temp} 编译成功."
        fi
        if [ ! -d "${RESULT_OUTPUT}" ];then
            mkdir -p ${RESULT_OUTPUT}
        fi
        cp -pvf ${temp} ${RESULT_OUTPUT}
    done

    # 5.生成默认配置文件
    echo -e "${INFO}正在编译工程(board_defconfig_name=${board_defconfig_name})..."
    # make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all -j16
    make V=0 ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} savedefconfig
    if [ ! -f "defconfig" ];then
        echo -e "${ERR}defconfig 不存在,请检查后重试"
    else
        cp -pvf defconfig ${RESULT_OUTPUT}/${board_defconfig_name}
    fi
    echo "📁 日志文件: $(realpath make.log)"

    # 开始判断并打包文件
    # 获取父目录绝对路径
    parent_dir=$(dirname "$(realpath "${RESULT_OUTPUT}")")
    # 判断是否是 Git 仓库并获取版本号
    if git -C "$parent_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        version=$(git -C "$parent_dir" rev-parse --short HEAD)
    else
        version="unknown"
    fi
    # 生成时间戳（格式：年月日时分秒）
    timestamp=$(date +%Y%m%d%H%M%S)
    # 设置输出文件名
    subdir="kernel-${timestamp}-${version}"
    output_file="${RESULT_OUTPUT}/${subdir}.tar.bz2"

    # 打包压缩文件
    echo "正在打包文件到 ${output_file} ..."
    # 这个文件解压后直接就是文件
    #tar -cjf "${output_file}" -C "${RESULT_OUTPUT}" . 
    # 这个命令解压后会存在一级目录
    tar -cjf "${output_file}" \
        --transform "s|^|${subdir}/|" \
        -C "${RESULT_OUTPUT}" .
    # 验证压缩结果
    if [ -f "$output_file" ]; then
        echo "打包成功！文件结构验证："
        tar -tjf "$output_file" | head -n 5
        echo -e "\n生成文件："
        ls -lh "$output_file"
    else
        echo "错误：文件打包失败"
        exit 1
    fi

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
    echo -e "${PINK}BOARD_DTB_FILE       :${BOARD_DTB_FILE}${CLS}"
    echo -e "${PINK}BOARD_DEFCONFIG      :${BOARD_DEFCONFIG}${CLS}"
    echo ""
    echo -e "* [0] 编译linux kernel"
    echo -e "* [1] 清理linux kernel工程"
    echo -e "* [2] 同步linux内核文件的修改"
    echo -e "* [4] github actions编译工程并发布"
    echo "================================================="
}

function func_process()
{
    if [ ${COMPILE_PLATFORM} == 'githubaction' ];then
    choose=4
    else
    read -p "请选择功能,默认选择0:" choose
    fi

	case "${choose}" in
		"0") build_linux_project ${BOARD_DEFCONFIG};;
		"1") clean_project ${BOARD_DEFCONFIG};;
		"2") record_kernel_file_update;;
		"4") 
            get_kernel_source_code
            github_actions_build ${BOARD_DEFCONFIG}
            ;;
		*) build_linux_project ${BOARD_DEFCONFIG};;
	esac
}

echo_menu
func_process
