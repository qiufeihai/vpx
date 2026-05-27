# 自用高性能 Xray 极简脚本包计划

## Summary

- 目标：在当前空仓库中新增一套“自用、极简、性能优先”的 Xray 部署脚本包。
- 默认协议栈定为：`VLESS + TCP(raw) + REALITY + xtls-rprx-vision`。
- 交付形态定为：极简脚本包，而不是面板、全家桶运维系统或复杂参数化平台。
- 支持范围定为：`Debian 12`、`Ubuntu 24.04`、`Rocky 9` 三系统可安装；性能优化采用分层支持，`Debian/Ubuntu` 为完整性能层，`Rocky 9` 为兼容层并明确限制。
- 使用规模定为：单机单用户。
- 客户端输出定为：标准 `vless://` 分享链接、`Mihomo / Clash.Meta` YAML、可直接给 `Shadowrocket` 导入的链接文件。

## Current State Analysis

- 当前工作目录 `/Users/qiufeihai/workspace/vpx` 为空，没有现有脚本、模板、配置或文档可复用。
- 官方安装仓库 `XTLS/Xray-install` 已提供稳定的 systemd 安装入口，默认安装路径为：
  - `/usr/local/bin/xray`
  - `/usr/local/etc/xray/config.json`
  - `/etc/systemd/system/xray.service`
- 官方示例仓库 `XTLS/Xray-examples` 中已存在与目标最接近的配置目录：`VLESS-TCP-XTLS-Vision-REALITY`。
- 官方示例的服务端关键字段表明，极简配置只需保留：
  - 单个 `vless` 入站
  - `flow: xtls-rprx-vision`
  - `network: tcp`
  - `security: reality`
  - `realitySettings.dest/serverNames/privateKey/shortIds`
  - 单个 `freedom` 出站
- 额外调研显示，`XHTTP` 在 2026 年仍有多条性能、资源占用和 iOS 兼容性反馈；对本项目“自用 + 性能优先 + iOS 客户端 + 低复杂度”的目标不合适，因此不纳入默认方案。
- 由此得出的实现边界：
  - 不做 `WS`、`gRPC`、`XHTTP`
  - 不做面板
  - 不做多用户
  - 不做 CDN 反代链路
  - 不做证书/域名依赖

## Proposed Changes

### 1. `README.md`

用途：
- 作为唯一主文档，覆盖安装、部署、重启、状态检查、客户端导出和系统差异说明。

内容：
- 明确说明这是“单机单用户、自用性能优先”的极简方案。
- 给出支持矩阵：
  - `Debian 12`：推荐
  - `Ubuntu 24.04`：推荐
  - `Rocky 9`：兼容支持，性能调优受内核与系统默认栈限制
- 解释为何默认使用 `VLESS + TCP(raw) + REALITY + xtls-rprx-vision`，并明确排除 `WS/gRPC/XHTTP`。
- 提供最小操作面：
  - `install`
  - `deploy`
  - `restart`
  - `status`
  - `show-client`
- 说明前置条件：
  - 单台 Linux VPS
  - 已开放 `443/tcp`
  - 具备 root 权限
  - 有公网 IPv4
- 说明生成产物与保存位置。

### 2. `scripts/xray-selfhost`

用途：
- 作为唯一主入口脚本，收敛所有日常操作，避免多脚本分散。

命令设计：
- `install`
  - 检测发行版与包管理器
  - 调用官方 `install-release.sh` 安装或升级 Xray
  - 检查 `systemctl`、`curl`、`openssl`、基础网络工具
  - 初始化本项目的本地状态目录
- `deploy`
  - 生成或读取 `UUID`
  - 生成或读取 `x25519` 密钥对
  - 生成或读取 `shortId`
  - 读取用户配置变量
  - 渲染服务端 `config.json`
  - 生成客户端分享链接与 `Mihomo` 配置
  - 执行 `xray run -test -config ...`
  - 通过后重启 `xray`
- `restart`
  - 仅执行 `systemctl restart xray`
- `status`
  - 输出 `systemctl status xray --no-pager`
  - 输出监听端口、当前拥塞控制算法、关键文件位置
- `show-client`
  - 打印标准 `vless://` 链接
  - 展示生成文件路径

实现原则：
- 只保留单入口，不拆成复杂脚本树。
- 所有逻辑优先使用固定路径和直接流程，避免过度参数化。
- 对支持系统只做必要分支：
  - `apt` 路线：`Debian/Ubuntu`
  - `dnf` 路线：`Rocky 9`
- 严格避免引入与转发性能无关的后台进程、面板、容器层和额外代理层。

### 3. `.env.example`

用途：
- 作为唯一用户可编辑输入文件模板，避免脚本内部散落可变参数。

字段设计：
- `SERVER_ADDRESS`
- `SERVER_PORT=443`
- `REALITY_DEST`
- `REALITY_SERVER_NAME`
- `CLIENT_FINGERPRINT=chrome`
- `UUID=`
- `REALITY_PRIVATE_KEY=`
- `REALITY_PUBLIC_KEY=`
- `REALITY_SHORT_ID=`
- `XRAY_LOGLEVEL=warning`

规则：
- 未填写的 `UUID / 密钥 / shortId` 在 `deploy` 时自动生成并写入本地状态文件。
- `REALITY_DEST` 与 `REALITY_SERVER_NAME` 必须成对校验，避免产出不可连接配置。

### 4. `templates/config.server.json.tpl`

用途：
- 生成部署到服务器的唯一 `Xray` 服务端配置。

配置策略：
- 单 `inbound`
- 单 `outbound`
- `port = 443`
- `protocol = vless`
- `decryption = none`
- 客户端 `flow = xtls-rprx-vision`
- `streamSettings.network = tcp`
- `streamSettings.security = reality`
- `sniffing.enabled = true`
- `sniffing.routeOnly = true`
- `destOverride = ["http", "tls", "quic"]`
- `loglevel = warning`

明确不加入：
- `routing`
- `dns`
- `api`
- `stats`
- `fallbacks`
- `ws/grpc/xhttp`
- 任何分流、广告过滤、国内外路由逻辑

原因：
- 这些内容不提升你的主目标性能，反而增加复杂度、维护面和故障概率。

### 5. `templates/client.vless.uri.tpl`

用途：
- 生成通用标准 `vless://` 分享链接。

面向对象：
- `Shadowrocket`
- 支持 `REALITY + Vision` 的通用导入客户端

包含字段：
- `UUID`
- `SERVER_ADDRESS`
- `SERVER_PORT`
- `security=reality`
- `flow=xtls-rprx-vision`
- `sni`
- `fp=chrome`
- `pbk`
- `sid`
- `type=tcp`

### 6. `templates/client.mihomo.yaml.tpl`

用途：
- 生成适配 `Mihomo / Clash.Meta` 的最小可用客户端配置片段。

内容：
- 单个 `proxy`
- 必要的 `server / port / uuid / network / tls / reality-opts / client-fingerprint / flow`
- 一个最小 `proxy-groups`
- 一个最小 `rules`

策略：
- 仅生成足够导入验证的最小配置，不扩展成完整桌面代理体系。
- 不引入 TUN、DNS、脚本规则集、订阅系统等额外复杂项。

### 7. `.gitignore`

用途：
- 避免把生成的密钥、部署状态和客户端配置误提交。

至少忽略：
- `.env.local`
- `generated/`
- `state/`
- `*.qr.png`

### 8. `generated/` 与 `state/` 目录约定

用途：
- 明确“生成物”和“本地状态”的边界，减少误操作。

内容：
- `generated/`
  - `client.vless.txt`
  - `client.mihomo.yaml`
  - 可选 `client.qr.txt`
- `state/`
  - 持久化的实际密钥与派生变量
  - 上次部署用到的参数快照

规则：
- `state/` 不纳入版本控制。
- `generated/` 默认也不纳入版本控制。

## Assumptions & Decisions

### 已确认决策

- 协议默认选择：`VLESS + TCP(raw) + REALITY + xtls-rprx-vision`
- 不采用 `WS`、`gRPC`、`XHTTP`
- 交付形态：极简脚本包
- 规模：单机单用户
- 客户端输出：`Mihomo / Clash.Meta` + `Shadowrocket` 可导入链接
- 系统支持：`Debian 12`、`Ubuntu 24.04`、`Rocky 9` 三系统都可安装
- 系统策略：分层支持而非完全等价支持

### 实施层决策

- 安装层复用官方 `XTLS/Xray-install`，不重复造安装轮子。
- 配置层使用本仓库模板渲染，不直接让用户手改庞大 JSON。
- 操作层只暴露 5 个命令，避免面板化和多入口分裂。
- 性能调优采取“最小但有效”的系统优化：
  - 检查并启用可用的 `bbr`
  - 设置 `fq`
  - 不在首版引入更重的内核升级、第三方内核仓库或长期驻留调参服务
- `Rocky 9` 仅做兼容支持：
  - 保证安装、部署、重启、状态查看可用
  - 文档明确说明其默认内核/网络栈不一定达到 `Debian 12 / Ubuntu 24.04` 的同等性能上限

### 前提假设

- 服务器为独立公网 VPS，而不是容器嵌套环境。
- 使用者可接受 root 权限执行安装与 systemd 管理。
- 主要开放端口为 `443/tcp`。
- 目标是个人长期使用，不考虑多租户或流量审计需求。
- 客户端具备 `REALITY + Vision` 支持；`Clash` 语义在本项目中等同于 `Mihomo / Clash.Meta`。

## Verification Steps

### 开发期验证

- 对脚本执行 `shellcheck` 风格自检，修复明显可移植性问题。
- 对模板渲染结果做占位符完整性检查，确保不存在未替换变量。
- 对生成的服务端配置执行：
  - `xray run -test -config <rendered-config>`

### 部署后验证

- 验证服务状态：
  - `systemctl is-active xray`
  - `systemctl status xray --no-pager`
- 验证监听：
  - `ss -lntp | grep ':443'`
- 验证系统调优：
  - `sysctl net.core.default_qdisc`
  - `sysctl net.ipv4.tcp_congestion_control`
- 验证客户端产物：
  - `generated/client.vless.txt` 内容完整
  - `generated/client.mihomo.yaml` 字段完整
- 验证连接链路：
  - 使用生成的 `vless://` 在 `Shadowrocket` 导入
  - 使用生成的 `Mihomo` YAML 在桌面端导入
  - 实测访问 HTTPS 站点、视频站点和大文件下载

### 验收标准

- 新机器上能用一条主脚本完成安装与部署。
- 用户只需维护极少变量即可重新部署。
- 服务端最终配置收敛为单协议、单监听、单出站的极简结构。
- 可以稳定输出：
  - 一个 `vless://` 链接
  - 一个 `Mihomo` YAML
- 文档明确区分推荐系统与兼容系统，不误导 `Rocky 9` 的性能预期。

## Implementation Order

1. 新增 `README.md`、`.gitignore`、`.env.example`
2. 实现 `scripts/xray-selfhost` 主脚本骨架与命令分发
3. 新增服务端与客户端模板
4. 实现变量加载、随机值生成、模板渲染
5. 接入官方安装脚本与 systemd 操作
6. 接入配置测试与状态输出
7. 完成文档中的三系统差异说明与使用示例
