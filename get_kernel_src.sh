#!/bin/bash

# 使用方法说明
function usage() 
{
    echo "Git提交记录获取脚本"
    echo "用法: $0 [-r 仓库地址] [-b 分支名] [-c 提交哈希] [-d 目标目录]"
    echo "示例: $0 -r https://github.com/user/repo.git -b main -c a1b2c3d -d ./myrepo"
    exit 1
}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 恢复默认颜色

# 初始化变量
REPO_URL=""
BRANCH=""
COMMIT_HASH=""
TARGET_DIR=""

SCRIPT_NAME=${0#*/}
SCRIPT_CURRENT_PATH=${0%/*}
SCRIPT_ABSOLUTE_PATH=`cd $(dirname ${0}); pwd`

# 解析命令行参数
while getopts "r:b:c:d:" opt; do
    case $opt in
        r) REPO_URL="$OPTARG" ;;
        b) BRANCH="$OPTARG" ;;
        c) COMMIT_HASH="$OPTARG" ;;
        d) TARGET_DIR="$OPTARG" ;;
        *) usage ;;
    esac
done

# 参数验证
check_arguments() {
    [[ -z "$REPO_URL" ]] && { echo -e "${RED}错误：必须指定仓库地址${NC}"; usage; }
    [[ -z "$BRANCH" ]] && { echo -e "${RED}错误：必须指定分支名称${NC}"; usage; }
    [[ -z "$COMMIT_HASH" ]] && { echo -e "${RED}错误：必须指定提交哈希${NC}"; usage; }
    [[ -z "$TARGET_DIR" ]] && { echo -e "${RED}错误：必须指定目标目录${NC}"; usage; }
}

# 检查Git是否安装
check_git_installation() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}错误：Git未安装，请先安装Git${NC}"
        exit 1
    fi
}

# 克隆或更新仓库
function prepare_repository() 
{
    if [ -d "$TARGET_DIR/.git" ]; then
        echo -e "${YELLOW}检测到已有仓库，尝试更新...${NC}"
        cd "$TARGET_DIR" || exit 1
        git fetch origin || {
            echo -e "${RED}更新仓库失败${NC}";
            exit 1;
        }
    else
        echo -e "${GREEN}正在克隆仓库到 $TARGET_DIR ...${NC}"
        git clone -b ${BRANCH} --depth=1 "$REPO_URL" "$TARGET_DIR" || {
            echo -e "${RED}克隆仓库失败${NC}";
            exit 1;
        }
        cd "$TARGET_DIR" || exit 1
    fi
}

# 检出指定提交
function checkout_commit() 
{
    echo -e "${YELLOW}正在检出分支 $BRANCH ...${NC}"
    git checkout "$BRANCH" 2>/dev/null || {
        echo -e "${RED}分支 $BRANCH 不存在，正在尝试创建追踪分支${NC}"
        git checkout -b "$BRANCH" "origin/$BRANCH" || {
            echo -e "${RED}无法创建分支 $BRANCH${NC}";
            exit 1;
        }
    }

    echo -e "${YELLOW}正在拉取最新更改...${NC}"
    git pull origin "$BRANCH" || {
        echo -e "${RED}拉取更新失败${NC}";
        exit 1;
    }

    echo -e "${GREEN}正在检出提交 $COMMIT_HASH ...${NC}"
    git checkout "$COMMIT_HASH" || {
        echo -e "${RED}提交哈希 $COMMIT_HASH 不存在${NC}";
        exit 1;
    }
}

function get_alpha_file()
{
    # find 命令
    cd ${SCRIPT_ABSOLUTE_PATH}
    chmod 777 build.sh
    cp -af arch ${TARGET_DIR}
    cp -af drivers ${TARGET_DIR}
    cp -af build.sh ${TARGET_DIR}
}

# 主执行流程
function func_process() 
{
    check_arguments
    check_git_installation
    prepare_repository

    echo -e "${GREEN}git clone 操作成功完成！当前状态：${NC}"
    cd ${TARGET_DIR}
    git switch -c master
    git show --oneline -s
    
    # checkout_commit
    get_alpha_file
    echo -e "${GREEN}get_alpha_file 操作成功完成！当前状态：${NC}"
    cd ${TARGET_DIR}
    git status
    echo -e "${GREEN}当前目录：${NC}$(pwd)"
}

# 执行主函数
# ./get_kernel_src.sh -r https://github.com/nxp-imx/linux-imx -b v4.19.71 -c e7d2672c66e4d3675570369bf20856296da312c4 -d kernel_nxp_4.19.71

func_process
