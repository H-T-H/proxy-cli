# proxy-cli

一条命令开关 Linux 终端代理，**只对当前终端会话生效**，支持本地代理和远程代理。

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/H-T-H/proxy-cli/main/install.sh | bash
```

没有 curl 时：

```bash
wget -qO- https://raw.githubusercontent.com/H-T-H/proxy-cli/main/install.sh | bash
```

安装完成后，新开的终端自动可用；当前终端执行一次：

```bash
source ~/.local/share/proxy-cli/proxy.sh
```

## 用法

```bash
proxy_on 60000                     # 只写端口 → 本地代理 http://127.0.0.1:60000
proxy_on 192.168.1.10:7890         # 远程代理
proxy_on socks5://10.0.0.2:1080    # 指定协议：http / https / socks4 / socks5 / socks5h
proxy_on user:pass@10.0.0.2:3128   # 带认证（显示时自动隐藏账号密码）
proxy_status                       # 查看当前代理
proxy_test                         # 用 curl 测试连通性（默认访问 google.com）
proxy_off                          # 关闭代理
```

`proxy_on` 会设置 `http_proxy`、`https_proxy`、`ftp_proxy`、`all_proxy` 及其大写形式，并把本机和内网地址写入 `no_proxy`。

### 自定义默认值

在 `~/.bashrc` 中、`proxy-cli` 那段之前设置：

| 变量 | 默认值 |
|---|---|
| `PROXY_DEFAULT_SCHEME` | `http` |
| `PROXY_DEFAULT_HOST` | `127.0.0.1` |
| `PROXY_NO_PROXY` | `localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,.local` |

## 卸载

```bash
curl -fsSL https://raw.githubusercontent.com/H-T-H/proxy-cli/main/install.sh | bash -s -- --uninstall
```

## 原理

安装脚本把 `proxy.sh` 放到 `~/.local/share/proxy-cli/`，并在 `~/.bashrc`（及已存在的 `~/.zshrc`）中加入一段 `source` 语句。
命令以 shell 函数形式加载，因此能直接修改当前会话的环境变量，而不会影响其他终端。

## 许可证

[MIT](LICENSE)
