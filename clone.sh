#!/bin/bash
set -euo pipefail

# ===================== 用户配置区 =====================
SOURCE_REPO="https://github.com/kenzok8/small-package.git"
TARGET_USER="RayleanB"
TARGET_REPO_NAME="packages"

# ===================== 增强稀疏克隆 =====================
WORKSPACE="$PWD/sync_workspace"
SRC_DIR="$WORKSPACE/source_content"
TARGET_DIR="$WORKSPACE/target_repo"

CLONE_PATHS=(
    "luci-app-openclash"
    "iptvhelper"
    "luci-app-iptvhelper"
    "luci-app-timecontrol"
    "cdnspeedtest"
    "luci-app-cloudflarespeedtest"
    "luci-app-dnsfilter"
    "luci-app-fileassistant"
    "luci-app-wolplus"
    "luci-app-wechatpush"
    "luci-app-poweroff"
    "istoreenhance"
    "luci-app-istoredup"
    "luci-app-istoreenhance"
    "luci-app-istorego"
    "luci-app-istorepanel"
    "luci-app-istorex"
    "luci-app-quickstart"
    "luci-app-store"
    "luci-lib-taskd"
    "luci-lib-xterm"
    "quickstart"
    "taskd"
    "vmease"
    "wrtbwmon"
)

# ===================== 智能克隆函数 =====================
git_smart_clone() {
    # 禁用干扰提示
    git config --global advice.updateSparsePath false
    
    # 稀疏克隆核心逻辑
    git clone --depth 1 --filter=blob:none --sparse "$SOURCE_REPO" "$SRC_DIR"
    (
        cd "$SRC_DIR"
        git sparse-checkout init --cone
        git sparse-checkout set "${CLONE_PATHS[@]}" 2>/dev/null
        
        # 二次校验路径
        for path in "${CLONE_PATHS[@]}"; do
            [ -e "$path" ] || echo "::warning::路径不存在: $path"
        done
        rm -rf LICENSE
        rm -rf README.md
    )
}

function git_sparse_clone() {
  branch="$1" rurl="$2" localdir="$3" && shift 3
  git clone -b $branch --depth 1 --filter=blob:none --sparse $rurl $localdir
  cd $localdir
  git sparse-checkout init --cone
  git sparse-checkout set $@
  mv -n $@ ../
  cd ..
  rm -rf $localdir
  }
function git_sparse_clone1() {
  branch="$1" rurl="$2" localdir="$3" && shift 3
  git clone -b $branch --depth 1 --filter=blob:none --sparse $rurl $localdir
  cd $localdir
  git sparse-checkout init
  git sparse-checkout set $@
  mv -n $@ ../
  cd ..
  rm -rf $localdir
}


# ===================== 主流程 =====================
main() {
    rm -rf "$WORKSPACE" && mkdir -p "$WORKSPACE"
    
    # 克隆源仓库
    echo "🔍 开始智能克隆..."
    if ! git_smart_clone; then
        echo "::error::克隆失败"
        exit 10
    fi
    echo "🔍 开始稀疏克隆..."
    cd "$SRC_DIR"
    git_sparse_clone main "https://github.com/djylb/nps-openwrt" "openwrt-nps" luci-app-npc luci-app-nps npc nps
    git_sparse_clone main "https://github.com/gdy666/luci-app-lucky" "lucky-wrt" luci-app-lucky lucky
    git_sparse_clone lua "https://github.com/sbwml/luci-app-alist" "lua-alist" luci-app-alist alist
    git_sparse_clone v5-lua "https://github.com/sbwml/luci-app-mosdns" "openwrt-mosdns" luci-app-mosdns mosdns v2dat
    git_sparse_clone lua "https://github.com/brvphoenix/luci-app-wrtbwmon" "wrt-bwmon" luci-app-wrtbwmon
    git clone --depth 1 "https://github.com/ximiTech/msd_lite" msd_lite
    git clone --depth 1 https://github.com/ximiTech/luci-app-msd_lite luci-app-msd_lite
    git clone --depth 1 "https://github.com/sbwml/v2ray-geodata" v2ray-geodata
    
    # 同步到目标仓库
    git clone --depth 1 "https://${TARGET_USER}:${TARGET_PAT}@github.com/${TARGET_USER}/${TARGET_REPO_NAME}.git" "$TARGET_DIR"
    rsync -av --delete --exclude='.git' "$SRC_DIR/" "$TARGET_DIR"
    
    # 提交变更
    (
        cd "$TARGET_DIR"
        git config user.name "Auto Sync"
        git config user.email "auto@github.com"
        git add .
        git commit -m "Sync: $(date +'%F %T')" || exit 0
        git push
    )
}

# ===================== 执行入口 =====================
trap "echo '❌ 进程中断'; exit 130" INT TERM
main
trap - EXIT
echo "✅ 同步成功"
