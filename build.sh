#!/bin/bash
# * =====================================================
# * Copyright © hk. 2022-2025. All rights reserved.
# * File name  : 1.sh
# * Author     : 苏木
# * Date       : 2025-04-19
# * ======================================================
##

# 颜色和日志标识
# ========================================================
# |  ---  | 黑色  | 红色 |  绿色 |  黄色 | 蓝色 |  洋红 | 青色 | 白色  |
# | 前景色 |  30  |  31  |  32  |  33  |  34  |  35  |  35  |  37  |
# | 背景色 |  40  |  41  |  42  |  43  |  44  |  45  |  46  |  47  |
BLACK="\033[1;30m"
RED='\033[1;31m'    # 红
GREEN='\033[1;32m'  # 绿
YELLOW='\033[1;33m' # 黄
BLUE='\033[1;34m'   # 蓝
PINK='\033[1;35m'   # 紫
CYAN='\033[1;36m'   # 青
WHITE='\033[1;37m'  # 白
CLS='\033[0m'       # 清除颜色

INFO="${GREEN}INFO: ${CLS}"
WARN="${YELLOW}WARN: ${CLS}"
ERROR="${RED}ERROR: ${CLS}"

# 脚本和工程路径
# ========================================================
SCRIPT_NAME=${0#*/}
SCRIPT_CURRENT_PATH=${0%/*}
SCRIPT_ABSOLUTE_PATH=`cd $(dirname ${0}); pwd`
PROJECT_ROOT=${SCRIPT_ABSOLUTE_PATH} # 工程的源码目录，一定要和编译脚本是同一个目录
SOFTWARE_DIR_PATH=~/2software        # 软件安装目录
TFTP_DIR=~/3tftp
NFS_DIR=~/4nfs
CPUS=$(($(nproc)-1))                 # 使用总核心数-1来多线程编译
# 可用的emoji符号
# ========================================================
function usage_emoji()
{
    echo -e "⚠️ ✅ ❌ 🚩 📁 🕣️"
}

# 时间计算
# ========================================================
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
	echo "===*** 🕣️ 运行时间：$((end_seconds-start_seconds))s,time diff: ${duration} ***==="
}

function time_count_down
{
    for i in {3..0}
    do     

        echo -ne "${INFO}after ${i} is end!!!"
        echo -ne "\r\r"        # echo -e 处理特殊字符  \r 光标移至行首，但不换行
        sleep 1
    done
    echo "" # 打印一个空行，防止出现混乱
}

function get_run_time_demo()
{
    get_start_time
    time_count_down
    get_end_time
    get_execute_time
}

# 目录切换函数定义
# ========================================================
function cdi()
{
    if command -v pushd &>/dev/null; then
        # 压栈并切换
        pushd $1 >/dev/null || return 1
    else
        cd $1
    fi
}

function cdo()
{
    if command -v popd &>/dev/null; then
        # 弹出并恢复
        popd >/dev/null || return 1
    else
        cd -
    fi
}

# 开发环境信息
# ========================================================
function get_ubuntu_info()
{
    local kernel_version=$(uname -r) # 获取内核版本信息，-a选项会获得更详细的版本信息
    local ubuntu_version=$(lsb_release -ds) # 获取Ubuntu版本信息

    
    local ubuntu_ram_total=$(cat /proc/meminfo |grep 'MemTotal' |awk -F : '{print $2}' |sed 's/^[ \t]*//g')   # 获取Ubuntu RAM大小
    local ubuntu_swap_total=$(cat /proc/meminfo |grep 'SwapTotal' |awk -F : '{print $2}' |sed 's/^[ \t]*//g') # 获取Ubuntu 交换空间swap大小
    #local ubuntu_disk=$(sudo fdisk -l |grep 'Disk' |awk -F , '{print $1}' | sed 's/Disk identifier.*//g' | sed '/^$/d') #显示硬盘，以及大小
    local ubuntu_cpu=$(grep 'model name' /proc/cpuinfo |uniq |awk -F : '{print $2}' |sed 's/^[ \t]*//g' |sed 's/ \+/ /g') #cpu型号
    local ubuntu_physical_id=$(grep 'physical id' /proc/cpuinfo |sort |uniq |wc -l) #物理cpu个数
    local ubuntu_cpu_cores=$(grep 'cpu cores' /proc/cpuinfo |uniq |awk -F : '{print $2}' |sed 's/^[ \t]*//g') #物理cpu内核数
    local ubuntu_processor=$(grep 'processor' /proc/cpuinfo |sort |uniq |wc -l) #逻辑cpu个数(线程数)
    local ubuntu_cpu_mode=$(getconf LONG_BIT) #查看CPU当前运行模式是64位还是32位

    # 打印结果
    echo -e "ubuntu: $ubuntu_version - $ubuntu_cpu_mode"
    echo -e "kernel: $kernel_version"
    echo -e "ram   : $ubuntu_ram_total"
    echo -e "swap  : $ubuntu_swap_total"
    echo -e "cpu   : $ubuntu_cpu,physical id is$ubuntu_physical_id,cores is $ubuntu_cpu_cores,processor is $ubuntu_processor"
}

# 本地虚拟机VMware开发环境信息
function get_dev_env_info()
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

# 环境变量
# ========================================================
# Github Actions托管的linux服务器有以下用户级环境变量，系统级环境变量加上sudo好像也权限修改
# .bash_logout  当用户注销时，此文件将被读取，通常用于清理工作，如删除临时文件。
# .bashrc       此文件包含特定于 Bash Shell 的配置，如别名和函数。它在每次启动非登录 Shell 时被读取。
# .profile、.bash_profile 这两个文件位于用户的主目录下，用于设置特定用户的环境变量和启动程序。当用户登录时，
#                        根据 Shell 的类型和配置，这些文件中的一个或多个将被读取。
USER_ENV=(~/.bashrc ~/.profile ~/.bash_profile)
SYSENV=(/etc/profile) # 系统环境变量位置
ENV_FILE=("${USER_ENV[@]}" "${SYSENV[@]}")

function source_env_info()
{
    for temp in ${ENV_FILE[@]};
    do
        if [ -f ${temp} ]; then
            echo -e "${INFO}source ${temp}"
            source ${temp}
        fi
    done
}

# ========================================================
# kernel 编译
# ========================================================
RESULT_OUTPUT=image_output # 这个是把在linux内核源码中生成的zimage和设备树拷贝到这里
KERNEL_ROOT=${PROJECT_ROOT}/../imx6ull-kernel
BOARD_NAME=alpha
BOARD_DEFCONFIG=imx_alpha_emmc_defconfig
BOARD_DEVICE_TREE=imx6ull-alpha-emmc
BOARD_CONFIG_ENA=0                                        # 是否需要重新执行默认配置
RESULT_FILE=(arch/arm/boot/zImage)
RESULT_FILE+=(arch/arm/boot/dts/${BOARD_DEVICE_TREE}.dtb) # 后面还会改，索引固定是1

ARCH_NAME=arm
CROSS_COMPILE_NAME=arm-linux-gnueabihf-

COMPILE_PLATFORM=local # local：非githubaction自动打包，githubaction：githubaction自动打包
COMPILE_MODE=0         # 0,清除工程后编译，1,不清理直接编译
DOWNLOAD_SDCARD=0      # 0,不执行下载到sd卡的流程，1,编译完执行下载到sd卡流程
REDIRECT_LOG_FILE=
COMMAND_EXIT_CODE=0    # 要有一个初始值，不然可能会报错
V=0                    # 主要是保存到日志文件的时候可以改成1，这样可以看到更加详细的日志
# 脚本参数传入处理
# ========================================================
function usage()
{
	echo -e "================================================="
    echo -e "${PINK}./1.sh       : 根据菜单编译工程${CLS}"
    echo -e "${PINK}./1.sh -p 1  : githubaction自动编译工程${CLS}"
    echo -e "${PINK}./1.sh -m 1  : 增量编译，不清理工程${CLS}"
    echo -e "${PINK}./1.sh -u 1  : 强制配置工程(清理后会自动配置)${CLS}"
    echo -e ""
    echo -e "================================================="
}

# 脚本运行参数处理
echo -e "${CYAN}There are $# parameters: $@ (\$1~\$$#)${CLS}"
while getopts "b:p:m:u" arg #选项后面的冒号表示该选项需要参数
    do
        case ${arg} in
            b)
                if [ $OPTARG == "nxp" ];then
                    BOARD_NAME=NXP
                    BOARD_DEFCONFIG=imx_v6_v7_defconfig
                    BOARD_DEVICE_TREE=imx6ull-14x14-evk
                    RESULT_FILE[1]="arch/arm/boot/dts/${BOARD_DEVICE_TREE}.dtb"
                fi
                ;;
            p)
                if [ $OPTARG == "1" ];then
                    COMPILE_PLATFORM=githubaction
                    REDIRECT_LOG_FILE="${RESULT_OUTPUT}/kernel-make-$(date +%Y%m%d_%H%M%S).log"
                    V=0 # 保存详细日志就这里改成1 
                    KERNEL_ROOT=${PROJECT_ROOT}/../kernel_nxp_4.19.71
                    BOARD_CONFIG_ENA=1 # githubaction强制每次重新配置工程
                fi
                ;;
            m)
                if [ $OPTARG == "1" ];then
                    COMPILE_MODE=1
                fi
                ;;
            u)
                if [ $OPTARG == "1" ];then
                    BOARD_CONFIG_ENA=1
                fi
                ;;
            ?)  #当有不认识的选项的时候arg为?
                echo -e "${RED}unkonw argument...${CLS}"
                exit 1
                ;;
        esac
    done

# 功能实现
# ========================================================
# 不知道为什么当日志和脚本在同一个目录，日志最后就会被删除
function log_redirect_start()
{
    # 启用日志时重定向输出
    if [[ -n "${REDIRECT_LOG_FILE}" ]]; then
        exec 3>&1 4>&2 # 备份原始输出描述符
        echo -e "${BLUE}▶ 编译日志保存到: 📁 ${REDIRECT_LOG_FILE}${CLS}"
        # 初始化日志目录
        if [ ! -d "$RESULT_OUTPUT" ];then
            mkdir -pv "$RESULT_OUTPUT"
        fi
        if [ -s "${REDIRECT_LOG_FILE}" ]; then
            exec >> "${REDIRECT_LOG_FILE}" 2>&1
        else
            exec > "${REDIRECT_LOG_FILE}" 2>&1
        fi
        
        # 日志头存放信息s
        echo -e "=== 开始执行命令 ==="
        echo -e "当前时间: $(date +'%Y-%m-%d %H:%M:%S')"
    fi
}

function log_redirect_recovery()
{
    # 恢复原始输出
    if [[ -n "${REDIRECT_LOG_FILE}" ]]; then
        echo -e "当前时间: $(date +'%Y-%m-%d %H:%M:%S')"
        echo -e "=== 执行命令结束 ==="
        exec 1>&3 2>&4

        # 输出结果
        if [ $1 -eq 0 ]; then
            echo -e "${GREEN}✅ 命令执行成功!${CLS}"
        else
            echo -e "${RED}命令执行成失败 (退出码: $1)${CLS}"
            [[ -n "${REDIRECT_LOG_FILE}" ]] && echo -e "${YELLOW}查看日志: tail -f ${REDIRECT_LOG_FILE}${CLS}"
        fi
        exec 3>&- 4>&- # 关闭备份描述符

        # 验证日志完整性
        if [[ -n "${REDIRECT_LOG_FILE}" ]]; then
            if [[ ! -s "${REDIRECT_LOG_FILE}" ]]; then
                echo -e "${YELLOW}⚠ 警告: 日志文件为空，可能未捕获到输出${CLS}"
            else
                echo -e "${BLUE}📁 日志大小: $(du -h "${REDIRECT_LOG_FILE}" | cut -f1)${CLS}"
            fi
        fi
    fi
}

function arm_gcc_check()
{
    echo -e "${INFO}▶ 验证工具链版本..."
    if arm-linux-gnueabihf-gcc --version &> /dev/null; then
        echo -e "${GREEN}✅ 验证成功！工具链版本信息：${CLS}"
        arm-linux-gnueabihf-gcc --version | head -n1
    else
        echo -e "${RED}工具链验证失败，请手动执行以下命令：${CLS}"
        echo "source ~/.bashrc 或重新打开终端"
        exit 1
    fi
}

# 获取内核源码
function get_kernel_source_code()
{
    cdi ${PROJECT_ROOT}
    echo ""
    echo -e "🚩 ===> function ${FUNCNAME[0]}"
    echo -e "${PINK}current path :$(pwd)${CLS}"
    echo -e "${PINK}board_config :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"

    if [ -d "../kernel_nxp_4.19.71" ]; then
        echo -e "${INFO}▶ ../kernel_nxp_4.19.71 已存在..."
        cdo
        return
    fi

    chmod 777 get_kernel_src.sh
    ./get_kernel_src.sh -r https://github.com/nxp-imx/linux-imx \
                        -b v4.19.71 \
                        -c e7d2672c66e4d3675570369bf20856296da312c4 \
                        -d ../kernel_nxp_4.19.71
    cdo
}

function kernel_project_clean()
{
    cdi ${KERNEL_ROOT}
    echo ""
    echo -e "🚩 ===> function ${FUNCNAME[0]}"
    echo -e "${PINK}current path :$(pwd)${CLS}"
    echo -e "${PINK}board_config :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"

    # 增量编译直接返回
    if [ ${COMPILE_MODE} == "1" ] && [ -z $1 ]; then
        cdo
        return
    fi

    # 1. 删除成果物目录 image_output
    if [ -d "${RESULT_OUTPUT}" ];then
        rm -rvf  ${RESULT_OUTPUT}
    fi

    # 2. 清理整个工程
    echo -e "${INFO}▶ make V=${V} ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} distclean"
    log_redirect_start
    make V=${V} ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} distclean || COMMAND_EXIT_CODE=$?
    BOARD_CONFIG_ENA=1 # 清理之后需要重新配置一次默认配置文件
    log_redirect_recovery ${COMMAND_EXIT_CODE}
    # make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} clean
    cdo
}

# 说明：Kconfig中默认为y的参数不会被保存到defconfig中，即便默认配置文件没有对应的选项，在执行了默认配置文件后
# 也依然会被选中
function kernel_savedefconfig()
{
    cdi ${KERNEL_ROOT}
    echo ""
    echo -e "🚩 ===> function ${FUNCNAME[0]}"
    echo -e "${PINK}current path :$(pwd)${CLS}"
    echo -e "${PINK}board_config :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"

    # 保存默认配置文件
    echo -e "${INFO}▶ make V=${V} ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} savedefconfig"
    log_redirect_start
    make V=${V} ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} savedefconfig || COMMAND_EXIT_CODE=$?
    log_redirect_recovery ${COMMAND_EXIT_CODE}

    if [ ! -d "${RESULT_OUTPUT}" ];then
        mkdir -pv ${RESULT_OUTPUT}
    fi
    
    echo -e "${INFO}▶ 拷贝配置文件到 ${RESULT_OUTPUT} 目录"
    if [ -f "defconfig" ]; then
        cp -avf defconfig ${RESULT_OUTPUT}/${BOARD_DEFCONFIG}
    fi
    cp -avf .config ${RESULT_OUTPUT}
    cdo
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

function kernel_build()
{
    # 判断源码目录是否存在
    if [ ! -d "${KERNEL_ROOT}" ];then
        echo "${RED}${KERNEL_ROOT} 不存在...${CLS}"
        exit 0
    fi

    cdi ${KERNEL_ROOT}
    local board_defconfig_name=$1 # 获取配置文件名称 $0是脚本的名称，若是给函数传参，$1 表示跟在函数名后的第一个参数
    echo ""
    echo -e "🚩 ===> function ${FUNCNAME[0]}"
    echo -e "${PINK}current path :$(pwd)${CLS}"
    echo -e "${PINK}board_config :${BOARD_NAME} ${board_defconfig_name}${CLS}"

    # 1. 清理工程，根据-m参数决定是否清理
    # 判断成果物目录是否存在，并且是否是增量编译,成果物目录存在且为全编译的时候需要清除之前的文件
    if [ -d "${RESULT_OUTPUT}" ] && [ "$COMPILE_MODE" != "1" ];then # 使用NXP官方的默认配置文件
         echo -e "${INFO}▶ 正在清理工程文件..."
        # 1.1 清理工程，但是每次编译时间太长，不会清理后编译
        kernel_project_clean
    fi

    # 2. 配置linux内核
    if [ "$BOARD_CONFIG_ENA" == "1" ]; then
        # 默认配置文件只需要首次执行，后续执行会覆盖掉后来修改的配置，除非每次都更新默认配置文件
        echo -e "${INFO}▶ make V=${V} ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} ${board_defconfig_name}..."
        # make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx_alpha_emmc_defconfig
        log_redirect_start
        make V=${V} ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} ${board_defconfig_name} || ${COMMAND_EXIT_CODE}=$?
        log_redirect_recovery ${COMMAND_EXIT_CODE}
    fi
    get_start_time
    
    # 3. 编译linux内核
    echo -e "${INFO}▶ 正在编译工程(board_defconfig_name=${board_defconfig_name} githubaction need about 7min)..."
    # make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all -j16
    log_redirect_start
    make V=${V} ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} all -j${CPUS} || ${COMMAND_EXIT_CODE}=$?
    log_redirect_recovery ${COMMAND_EXIT_CODE}

    # 4.检查成果物
    for temp in ${RESULT_FILE[@]}
    do
        if [ ! -f "${RESULT_FILE}" ];then
            echo -e "❌ ${temp} 编译失败,请检查后重试!"
            continue
        else
            echo -e "✅ ${temp} 编译成功!"
        fi
    done

    get_end_time
    get_execute_time
    cdo
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
    if [ ! -d "${PROJECT_ROOT}" ];then
        mkdir -p ${PROJECT_ROOT}
    fi

    # 设备树相关文件
    if [ ! -d "${PROJECT_ROOT}/arch/arm/boot/dts" ];then
        mkdir -p ${PROJECT_ROOT}/arch/arm/boot/dts
    fi
    cp -pvf arch/arm/boot/dts/${BOARD_DEVICE_TREE}.dts ${PROJECT_ROOT}/arch/arm/boot/dts
    cp -pvf arch/arm/boot/dts/${BOARD_DEVICE_TREE}.dtsi ${PROJECT_ROOT}/arch/arm/boot/dts

    # 配置文件,通过make savedefconfig 由.config文件生成的xxx_defconfig文件，两个文件都备份一遍
    if [ ! -d "${PROJECT_ROOT}/arch/arm/configs" ];then
        mkdir -p ${PROJECT_ROOT}/arch/arm/configs
    fi
    cp -pvf ${RESULT_OUTPUT}/${BOARD_DEFCONFIG} ${PROJECT_ROOT}/arch/arm/configs/
    cp -pvf .config ${PROJECT_ROOT}
    # 源文件相关备份
}

function update_result_file()
{
    # 判断源码目录是否存在
    if [ ! -d "${KERNEL_ROOT}" ];then
        echo "${RED}${KERNEL_ROOT} 不存在...${CLS}"
        exit 0
    fi

    cdi ${KERNEL_ROOT}
    echo ""
    echo -e "🚩 ===> function ${FUNCNAME[0]}"
    echo -e "${PINK}current path :$(pwd)${CLS}"
    echo -e "${PINK}board_config :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"

    # 成果物文件拷贝
    echo -e "${INFO}▶ 检查并拷贝 ${RESULT_FILE[*]} 到 ${RESULT_OUTPUT}"
    if [ ! -d "${RESULT_OUTPUT}" ];then
        mkdir -pv ${RESULT_OUTPUT}
    fi
    for temp in "${RESULT_FILE[@]}";
    do
        if [ -f "${temp}" ];then
            cp -avf ${temp} ${RESULT_OUTPUT}
        else
            echo -e "${RED}${temp} 不存在 ${CLS}"
        fi
    done

    # 开始判断并打包文件
    # 1.获取父目录绝对路径，判断是否是 Git 仓库并获取版本号
    parent_dir=$(dirname "$(realpath "${RESULT_OUTPUT}")")
    if git -C "$parent_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        version=$(git -C "$parent_dir" rev-parse --short HEAD)
    else
        version="unknown"
    fi

    # 2. 生成时间戳（格式：年月日时分秒）
    timestamp=$(date +%Y%m%d%H%M%S)
    subdir="kernel-${timestamp}-${version}"
    output_file="${RESULT_OUTPUT}/${subdir}.tar.bz2" # 设置输出文件名

    # 3. 打包压缩文件
    echo -e "${INFO}▶ 正在打包文件到 ${output_file} ..."
    #tar -cjf "${output_file}" -C "${RESULT_OUTPUT}" . # 这个文件解压后直接就是文件
    # 这个命令解压后会存在一级目录
    tar -cjf "${output_file}" \
        --exclude='*.tar.bz2' \
        --transform "s|^|${subdir}/|" \
        -C "${RESULT_OUTPUT}" .
    
    # 4. 验证压缩结果
    if [ -f "$output_file" ]; then
        echo -e "${INFO}▶ 打包成功！文件结构验证："
        tar -tjf "$output_file" # | head -n 5
        echo ""
        echo -e "${INFO}▶ 生成文件："
        ls -lh "$output_file"
    else
        cho -e "${RED}错误：文件打包失败${CLS}"
        exit 1
    fi
    cdo
}

function echo_menu()
{
    echo "================================================="
	echo -e "${GREEN}               build project ${CLS}"
	echo -e "${GREEN}                by @苏木    ${CLS}"
	echo "================================================="
    echo -e "${PINK}current path         :$(pwd)${CLS}"
    echo -e "${PINK}PROJECT_ROOT         :${PROJECT_ROOT}${CLS}"
    echo -e "${PINK}KERNEL_ROOT          :${KERNEL_ROOT}${CLS}"
    echo -e "${PINK}ARCH_NAME            :${ARCH_NAME}${CLS}"
    echo -e "${PINK}CROSS_COMPILE_NAME   :${CROSS_COMPILE_NAME}${CLS}"
    echo -e "${PINK}BOARD_DEFCONFIG      :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"
    echo -e "${PINK}BOARD_DEVICE_TREE    :${BOARD_DEVICE_TREE}${CLS}"
    echo ""
    echo -e "* [0] 编译linux kernel"
    echo -e "* [1] 清理linux kernel工程"
    echo -e "* [2] 同步linux内核文件的修改"
    echo -e "* [3] 保存kernel默认配置文件到输出目录"
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
		"0") 
            kernel_build ${BOARD_DEFCONFIG}
            kernel_savedefconfig
            update_result_file
            ;;
		"1") kernel_project_clean ${BOARD_DEFCONFIG};;
		"2") record_kernel_file_update;;
        "3") kernel_savedefconfig;;
		"4") 
            source_env_info
            arm_gcc_check
            get_kernel_source_code
            kernel_build ${BOARD_DEFCONFIG}
            kernel_savedefconfig
            update_result_file
            ;;
		*) 
            kernel_build ${BOARD_DEFCONFIG}
            kernel_savedefconfig
            update_result_file
            ;;
	esac
}

echo_menu
func_process
