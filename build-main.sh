#!/usr/bin/env bash
# =============================================================================
# Skizo_ゆらぎ-Sukisu 内核编译脚本 (手动 Neutron Clang - 2025 稳定版)
# 使用前请手动安装 Neutron Clang 17
# =============================================================================
# -------------------------------
# 配置
# -------------------------------
declare -A DEVICES=(
    ["vangogh"]="gki_defconfig"
)
# ✅ 保存源码目录
KERNEL_DIR="$(pwd)"
TOOLCHAIN_DIR="$HOME/toolchains/neutron-clang"
OUT_DIR="out"
BUILD_LOG="/root/20250913-SukisuUltra_AK3_nongki_vangogh/kernel_xiaomi_sm7250_a16bpf/build_log/build.log"
# -------------------------------
# 函数
# -------------------------------
print_help() {
    cat << EOF
用法: $0 <设备> [选项]
支持的设备: ${!DEVICES[@]}
选项:
  -j <任务数>     并行任务数 (默认: 自动)
  -h            显示此帮助信息
EOF
    exit 1
}
error_exit() {
    echo "❌ 错误: $1" >&2
    exit 1
}
log() {
    echo "🔹 $1"
}
success() {
    echo "✅ $1"
}
# -------------------------------
# 参数解析
# -------------------------------
[[ $# -eq 0 ]] && print_help
DEVICE="" JOBS=""
while [[ $# -gt 0 ]]; do
    case $1 in
        monet|vangogh)
            DEVICE="$1"; shift
            ;;
        -j)
            JOBS="$2"; shift 2
            ;;
        -h|--help)
            print_help
            ;;
        *)
            error_exit "未知参数: $1"
            ;;
    esac
done
[[ -z "$DEVICE" ]] && error_exit "未指定设备！"
[[ -z "${DEVICES[$DEVICE]}" ]] && error_exit "不支持的设备: $DEVICE"
DEFCONFIG="${DEVICES[$DEVICE]}"
# -------------------------------
# 并行任务数
# -------------------------------
export KEBABS="${JOBS:-$(( $(nproc) + 2 ))}"
log "使用 ${KEBABS} 个并行任务"
# -------------------------------
# 工具链设置: 手动模式 (无 antman)
# -------------------------------
log "🔧 检查 Neutron Clang 安装..."
if [[ ! -f "$TOOLCHAIN_DIR/bin/clang" ]]; then
    error_exit "未找到 Clang！请手动安装 Neutron Clang 17：
    mkdir -p ~/toolchains/neutron-clang && cd ~/toolchains/neutron-clang
    curl -LO https://github.com/Neutron-Toolchains/clang-build/releases/download/17/clang-17.tar.zst
    zstd -d clang-17.tar.zst && tar -xf clang-17.tar
    wget -qO- https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman | bash -s -- --patch=glibc
    然后重试。
    "
fi
# ✅ 验证 clang 是否可执行
if ! "$TOOLCHAIN_DIR/bin/clang" --version &> /dev/null; then
    error_exit "Clang 存在但无法执行！请检查权限或重新安装。"
fi
success "Neutron Clang 已找到并准备就绪"
# -------------------------------
# 环境变量
# -------------------------------
export ARCH=arm64
export O="$OUT_DIR"
export SUBARCH=arm64
export CC=clang
export LLVM=1
export LLVM_IAS=1
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE="$TOOLCHAIN_DIR/bin/aarch64-linux-gnu-"
export CROSS_COMPILE_COMPAT="$TOOLCHAIN_DIR/bin/arm-linux-gnueabi-"
export PATH="$TOOLCHAIN_DIR/bin:$PATH"
# 编译器版本
export KBUILD_COMPILER_STRING="$("$TOOLCHAIN_DIR/bin/clang" --version | head -n1 | sed 's/(https[^)]*)//g;s/  */ /g;s/[[:space:]]*$//')"
export KBUILD_LINKER_STRING="$("$TOOLCHAIN_DIR/bin/ld.lld" --version | head -n1)"
# -------------------------------
# 编译配置
# -------------------------------
DATE=$(date '+%Y%m%d-%H%M')
VERSION="Skizo_ゆらぎ-Sukisu--${DEVICE}-${DATE}"
ZIP_NAME="${VERSION}.zip"
export ZIPNAME="$ZIP_NAME"
# 清理旧编译文件
[[ -d "$OUT_DIR" ]] && rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
log "🎯 正在为设备编译: $DEVICE"
log "⚙️  配置文件: $DEFCONFIG"
log "📦 输出文件: $ZIP_NAME"
# ✅ 验证 PATH 是否生效
log "🔧 验证 clang 是否在 PATH 中..."
if ! command -v clang &> /dev/null; then
    error_exit "clang 不在 PATH 中！请运行: export PATH=\"$TOOLCHAIN_DIR/bin:\$PATH\""
fi
log "clang 已找到: $(command -v clang)"
# -------------------------------
# 编译
# -------------------------------
START_TIME=$(date +%s)
log "🔧 生成配置文件..."
make -C "$KERNEL_DIR" O="$OUT_DIR" "$DEFCONFIG" || error_exit "配置文件生成失败"
log "🔧 运行 olddefconfig..."
make -C "$KERNEL_DIR" O="$OUT_DIR" olddefconfig || error_exit "olddefconfig 失败"
log "🚀 开始内核编译..."
make -C "$KERNEL_DIR" O="$OUT_DIR" -j"$KEBABS" \
    CC="ccache clang" \
    HOSTCC="ccache gcc" \
    HOSTCXX="ccache g++" \
    2>&1 | tee "$BUILD_LOG"
[[ ${PIPESTATUS[0]} -ne 0 ]] && error_exit "编译失败！请检查 $BUILD_LOG"
success "编译成功"
# -------------------------------
# 打包 DTB
# -------------------------------
DTB_DIR="arch/arm64/boot/dts/vendor/qcom"
DTB_FILE="$OUT_DIR/arch/arm64/boot/dtb"
log "📦 打包 DTB..."
find "$OUT_DIR/$DTB_DIR" -name '*.dtb' -exec cat {} + > "$DTB_FILE" || error_exit "DTB 打包失败"
# -------------------------------
# AnyKernel3 打包
# -------------------------------
[[ ! -f "$OUT_DIR/arch/arm64/boot/Image" || ! -f "$DTB_FILE" ]] && \
    error_exit "缺少内核镜像或 DTB！终止 ZIP 生成。"
log "📦 创建可刷入的 ZIP 包..."
rm -rf AnyKernel3
git clone -q "https://github.com/alecchangod/AnyKernel3.git" -b "$DEVICE" AnyKernel3 || \
    git clone -q "https://github.com/alecchangod/AnyKernel3.git" AnyKernel3
cp "$OUT_DIR/arch/arm64/boot/Image" AnyKernel3/
cp "$DTB_FILE" AnyKernel3/
cd AnyKernel3 || error_exit "无法进入 AnyKernel3 目录"
zip -r9 "../$ZIP_NAME" . -x '*.git*' 'README.md' '*placeholder' > /dev/null
cd .. || exit
rm -rf AnyKernel3
success "ZIP 包已创建: $ZIP_NAME"
# -------------------------------
# 最终结果
# -------------------------------
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
success "编译完成Ciallo～(∠・ω≤)⌒★，耗时 $((DURATION / 60)) 分 $((DURATION % 60)) 秒"
echo "📁 $ZIP_NAME 已生成，路径: $(pwd)/$ZIP_NAME"