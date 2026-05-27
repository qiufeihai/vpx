# 自用高性能 Xray 极简脚本包

这是一套只面向单机单用户的极简部署包，默认协议固定为：

- `VLESS + TCP(raw) + REALITY + xtls-rprx-vision`

不包含：

- `WS`
- `gRPC`
- `XHTTP`
- 面板
- 多用户
- CDN 反代链路
- 域名和证书依赖

## 目标系统

- `Ubuntu 24.04`：推荐
- `Rocky 9`：兼容支持

说明：

- 两个系统都支持安装、部署、重启、查看状态。
- 性能优化优先面向 `Ubuntu 24.04`。
- `Rocky 9` 默认内核和网络栈不一定达到相同性能上限。

## 前置条件

- 一台具备公网 IPv4 的 Linux VPS
- `443/tcp` 已放行
- 具备 root 权限
- 目标客户端支持 `REALITY + Vision`
- 桌面端使用 `Mihomo / Clash.Meta`
- iOS 使用 `Shadowrocket`

## 使用方式

最短上线清单：

```bash
cp .env.example .env.local
```

编辑 `.env.local`，至少确认这三个字段：

- `SERVER_ADDRESS`
- `REALITY_DEST`
- `REALITY_SERVER_NAME`

```bash
sudo ./scripts/vless-reality install
sudo ./scripts/vless-reality deploy
./scripts/vless-reality show-client
```

部署特性：

- 部署前会预检查 `REALITY_DEST` 与 `REALITY_SERVER_NAME` 是否可连通且证书匹配。
- 部署时会先备份现有 `/usr/local/etc/xray/config.json`。
- 部署时会按 `xray.service` 的运行用户设置配置文件权限，避免服务进程读不到 `config.json`。
- 新配置重启失败时会自动回滚到上一个配置。
- 部署成功后会直接输出服务状态、`443` 监听和当前拥塞控制信息。

## 命令

```bash
./scripts/vless-reality install
./scripts/vless-reality deploy
./scripts/vless-reality restart
./scripts/vless-reality status
./scripts/vless-reality show-client
```

## 产物

- `generated/client.vless.txt`
- `generated/client.mihomo.yaml`
- `state/runtime.env`

说明：

- `generated/client.vless.txt` 可直接导入 `Shadowrocket`，也可供其他支持 `REALITY + Vision` 的客户端使用。
- `generated/client.mihomo.yaml` 用于 `Mihomo / Clash.Meta`。
- `state/runtime.env` 保存自动生成的 `UUID`、密钥和 `shortId`。

导入建议：

- iOS：执行 `./scripts/vless-reality show-client`，复制 `vless://` 链接导入 `Shadowrocket`。
- Windows：执行 `./scripts/vless-reality show-client`，把 `mihomo:` 段落保存为本地 `client.mihomo.yaml` 后导入客户端。
- macOS / Linux：可直接使用 `generated/client.mihomo.yaml`，也可先复制到本地后再导入。

## 配置字段

- `SERVER_ADDRESS`：服务器公网 IP 或域名
- `SERVER_PORT`：默认 `443`
- `REALITY_DEST`：伪装目标，格式如 `www.microsoft.com:443`
- `REALITY_SERVER_NAME`：对应 `SNI`
- `CLIENT_FINGERPRINT`：默认 `chrome`
- `UUID`：可留空，部署时自动生成
- `REALITY_PRIVATE_KEY`：可留空，部署时自动生成
- `REALITY_PUBLIC_KEY`：可留空，部署时自动生成
- `REALITY_SHORT_ID`：可留空，部署时自动生成
- `XRAY_LOGLEVEL`：默认 `warning`

## 修改配置

正常修改方式：

1. 编辑 `.env.local`
2. 执行 `sudo ./scripts/vless-reality deploy`
3. 如有需要，再执行 `./scripts/vless-reality show-client` 导出最新客户端配置

说明：

- 日常改配置只需要改 `.env.local`，不要直接长期手改 `/usr/local/etc/xray/config.json`。
- `deploy` 会重新渲染服务端配置和客户端配置，并自动重启 `xray`。
- 如果新配置启动失败，脚本会自动回滚到上一个可用配置。
- `generated/client.vless.txt` 和 `generated/client.mihomo.yaml` 都是生成产物，下次 `deploy` 会被覆盖。
- `state/runtime.env` 会保存自动生成的 `UUID`、密钥和 `shortId`；只改 `SERVER_ADDRESS`、`REALITY_DEST`、`REALITY_SERVER_NAME`、`XRAY_LOGLEVEL` 这类字段时，一般不用动它。
- 如果你想换一整套新的 `UUID` / `REALITY` 密钥，可在 `.env.local` 手动填写新值，或删除 `state/runtime.env` 后重新 `deploy` 让脚本自动生成。

## 验证

如果你要手工复查，可再执行：

```bash
sudo ./scripts/vless-reality status
sudo systemctl status xray --no-pager
sudo ss -lntp | grep ':443'
```

客户端导入验证：

- iOS：导入 `generated/client.vless.txt`
- Windows：将 `show-client` 输出的 `mihomo` 内容保存为本地 `.yaml` 后导入
- macOS / Linux：导入 `generated/client.mihomo.yaml`

## 生产注意事项

- `install` 会按能力探测后尝试启用 `fq + bbr`，内核不支持时会跳过，不再因为调优失败打断安装。
- 在 `Rocky 9` 上如果看到 `skip bbr tuning: bbr not available on this kernel`，这只是警告，不代表 `Xray` 安装失败。
- `deploy` 通过 `xray run -test` 只代表配置语法通过，不代表你的目标网络环境一定可用；首次上线仍建议你在控制台保持会话，不要盲切。
