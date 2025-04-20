#!/bin/bash
# * =====================================================
# * Copyright © hk. 2022-2025. All rights reserved.
# * File name  : pushd_popd_demo.sh
# * Author     : 苏木
# * Date       : 2025-04-19
# * ======================================================
##

function cdi()
{
    # 压栈并切换
    pushd $1 >/dev/null || return 1
}

function cdo()
{
    # 弹出并恢复
    popd >/dev/null || return 1
}

# 创建测试目录
mkdir -p {dir1/dir1_1,dir2/dir2_2} || exit 1

# 初始状态
echo -e "\n\033[34m=== 初始状态 ===\033[0m"
echo "当前目录: $(pwd)"
echo "目录栈内容:"
dirs -v

# 第一次 pushd
echo -e "\n\033[34m=== 执行: pushd dir1 ===\033[0m"
pushd dir1 >/dev/null
echo "当前目录: $(pwd)"
echo "目录栈内容:"
dirs -v

# 第二次 pushd
echo -e "\n\033[34m=== 执行: pushd ../dir2/dir2_2 ===\033[0m"
pushd ../dir2/dir2_2 >/dev/null
echo "当前目录: $(pwd)"
echo "目录栈内容:"
dirs -v

# 第三次 pushd
echo -e "\n\033[34m=== 执行: pushd ../../dir1/dir1_1 ===\033[0m"
pushd ../../dir1/dir1_1 >/dev/null
echo "当前目录: $(pwd)"
echo "目录栈内容:"
dirs -v

# 第一次 popd
echo -e "\n\033[34m=== 执行: popd ===\033[0m"
popd >/dev/null
echo "当前目录: $(pwd)"
echo "目录栈内容:"
dirs -v

# 第二次 popd
echo -e "\n\033[34m=== 执行: popd ===\033[0m"
popd >/dev/null
echo "当前目录: $(pwd)"
echo "目录栈内容:"
dirs -v

# 第三次 popd
echo -e "\n\033[34m=== 执行: popd ===\033[0m"
popd >/dev/null
echo "当前目录: $(pwd)"
echo "目录栈内容:"
dirs -v

# 清理测试目录
echo -e "\n\033[34m=== 清理测试目录 ===\033[0m"
rm -rf dir1 dir2 dir3
