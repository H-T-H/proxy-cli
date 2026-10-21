#!/usr/bin/env bash
# install.sh —— 安装 / 卸载 proxy_on 等命令
#
# 一键安装：curl -fsSL https://raw.githubusercontent.com/H-T-H/proxy-cli/main/install.sh | bash
# 一键卸载：curl -fsSL https://raw.githubusercontent.com/H-T-H/proxy-cli/main/install.sh | bash -s -- --uninstall
# 本地安装：bash install.sh          本地卸载：bash install.sh --uninstall
#
# 安装会把 proxy.sh 复制到 ~/.local/share/proxy-cli/，
# 并在 ~/.bashrc（以及存在的 ~/.zshrc）中加入 source 语句，
# 之后每个新终端都可以直接使用 proxy_on / proxy_off / proxy_status / proxy_test。

set -euo pipefail

INSTALL_DIR="$HOME/.local/share/proxy-cli"
TARGET="$INSTALL_DIR/proxy.sh"
MARK_BEGIN="# >>> proxy-cli >>>"
MARK_END="# <<< proxy-cli <<<"
REMOTE_URL="https://raw.githubusercontent.com/H-T-H/proxy-cli/main/proxy.sh"

# 本地运行时使用同目录的 proxy.sh；通过 curl | bash 运行时为空，改为从 GitHub 下载
SRC=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/proxy.sh" ]; then
    SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/proxy.sh"
fi

rc_files() {
    echo "$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && echo "$HOME/.zshrc"
    return 0
}

remove_block() {
    local rc="$1"
    [ -f "$rc" ] || return 0
    if grep -qF "$MARK_BEGIN" "$rc"; then
        local tmp
        tmp="$(mktemp)"
        sed "/^$MARK_BEGIN\$/,/^$MARK_END\$/d" "$rc" > "$tmp"
        cat "$tmp" > "$rc"
        rm -f "$tmp"
        echo "  已从 $rc 移除"
    fi
}

install() {
    mkdir -p "$INSTALL_DIR"
    if [ -n "$SRC" ]; then
        cp "$SRC" "$TARGET"
        echo "已复制到 $TARGET"
    else
        local tmp
        tmp="$(mktemp)"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "$REMOTE_URL" -o "$tmp"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$tmp" "$REMOTE_URL"
        else
            echo "错误: 需要 curl 或 wget 来下载 proxy.sh" >&2
            rm -f "$tmp"
            exit 1
        fi
        mv "$tmp" "$TARGET"
        echo "已下载到 $TARGET"
    fi

    local rc
    for rc in $(rc_files); do
        touch "$rc"
        remove_block "$rc" >/dev/null   # 重复安装时先去掉旧的
        {
            echo "$MARK_BEGIN"
            echo "[ -f \"$TARGET\" ] && . \"$TARGET\""
            echo "$MARK_END"
        } >> "$rc"
        echo "已写入 $rc"
    done

    echo
    echo "安装完成！执行下面的命令让当前终端立即生效（新终端会自动生效）："
    echo "    source $TARGET"
    echo
    echo "用法: proxy_on 60000 | proxy_on 192.168.1.10:7890 | proxy_off | proxy_status"
}

uninstall() {
    local rc
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        remove_block "$rc"
    done
    rm -rf "$INSTALL_DIR"
    echo "已删除 $INSTALL_DIR"
    echo "卸载完成。当前终端中已加载的函数在关闭终端后消失，或执行 proxy_off 清除代理变量。"
}

case "${1:-}" in
    ""|--install|install)       install ;;
    -u|--uninstall|uninstall)   uninstall ;;
    -h|--help)
        echo "用法: bash install.sh [--uninstall]" ;;
    *)
        echo "未知参数: $1（用法: bash install.sh [--uninstall]）" >&2
        exit 1 ;;
esac
