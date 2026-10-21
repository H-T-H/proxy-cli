# proxy.sh —— 一键设置终端代理（仅对当前 shell 会话生效）
#
# 一键安装：
#     curl -fsSL https://raw.githubusercontent.com/H-T-H/proxy-cli/main/install.sh | bash
#
# 用法：
#     proxy_on 60000                    # 本地代理 http://127.0.0.1:60000
#     proxy_on 192.168.1.10:7890        # 远程代理 http://192.168.1.10:7890
#     proxy_on socks5://10.0.0.2:1080   # 指定协议（http / https / socks5 / socks5h）
#     proxy_on user:pass@10.0.0.2:3128  # 带认证
#     proxy_off                         # 关闭代理
#     proxy_status                      # 查看当前代理
#     proxy_test [url]                  # 测试代理连通性（需要 curl）
#
# 注意：必须用 source 加载为函数，直接执行脚本无法修改当前 shell 的环境变量。

PROXY_DEFAULT_SCHEME="${PROXY_DEFAULT_SCHEME:-http}"
PROXY_DEFAULT_HOST="${PROXY_DEFAULT_HOST:-127.0.0.1}"
PROXY_NO_PROXY="${PROXY_NO_PROXY:-localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.local}"

_proxy_is_port() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
    esac
    [ "$1" -ge 1 ] && [ "$1" -le 65535 ]
}

proxy_on() {
    if [ $# -ne 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "用法: proxy_on [协议://][用户:密码@][主机:]端口"
        echo "示例: proxy_on 60000 | proxy_on 192.168.1.10:7890 | proxy_on socks5://10.0.0.2:1080"
        return 1
    fi

    local input="$1" scheme="$PROXY_DEFAULT_SCHEME" auth="" hostport host port

    # 协议
    case "$input" in
        *://*) scheme="${input%%://*}"; input="${input#*://}" ;;
    esac
    case "$scheme" in
        http|https|socks4|socks4a|socks5|socks5h) ;;
        *) echo "proxy_on: 不支持的协议 '$scheme'" >&2; return 1 ;;
    esac

    # 认证信息
    case "$input" in
        *@*) auth="${input%@*}@"; input="${input##*@}" ;;
    esac

    hostport="${input%/}"
    if _proxy_is_port "$hostport"; then
        # 只写端口 → 本地代理
        host="$PROXY_DEFAULT_HOST"
        port="$hostport"
    else
        host="${hostport%:*}"
        port="${hostport##*:}"
        if [ "$host" = "$hostport" ] || [ -z "$host" ] || ! _proxy_is_port "$port"; then
            echo "proxy_on: 无法解析 '$1'，应为 端口 或 主机:端口" >&2
            return 1
        fi
    fi

    local url="${scheme}://${auth}${host}:${port}"

    export http_proxy="$url"  HTTP_PROXY="$url"
    export https_proxy="$url" HTTPS_PROXY="$url"
    export ftp_proxy="$url"   FTP_PROXY="$url"
    export all_proxy="$url"   ALL_PROXY="$url"
    export no_proxy="$PROXY_NO_PROXY" NO_PROXY="$PROXY_NO_PROXY"

    # 显示时隐藏密码
    echo "代理已开启: ${scheme}://${auth:+***@}${host}:${port}（仅当前会话）"
}

proxy_off() {
    unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY \
          ftp_proxy FTP_PROXY all_proxy ALL_PROXY no_proxy NO_PROXY
    echo "代理已关闭"
}

proxy_status() {
    if [ -z "${http_proxy:-}${https_proxy:-}${all_proxy:-}" ]; then
        echo "代理: 未开启"
        return 0
    fi
    local masked
    masked="$(printf '%s' "${all_proxy:-$http_proxy}" | sed -E 's#://[^@/]*@#://***@#')"
    echo "代理: $masked"
    echo "no_proxy: ${no_proxy:-}"
}

proxy_test() {
    local url="${1:-https://www.google.com}"
    if ! command -v curl >/dev/null 2>&1; then
        echo "proxy_test: 需要 curl" >&2
        return 1
    fi
    local code
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "$url")"
    if [ "$code" != "000" ]; then
        echo "连通 ✔  $url → HTTP $code"
    else
        echo "连接失败 ✘  $url" >&2
        return 1
    fi
}
