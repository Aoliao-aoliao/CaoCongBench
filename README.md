# 草丛测评 CaoCong Bench

在沙箱环境中运行服务器测评脚本，并排版测试结果。

作者：草丛

## 使用

```bash
bash <(curl -sL https://run.caocong.example.com)
```

| 参数 | 说明 |
|---|---|
| `-4` / `-6` | 只测 IPv4 / 只测 IPv6 |
| `-E` | 英文输出 |
| `-d 目录` | 指定临时文件存放目录（至少 1 GB 可用空间） |

需要 root 权限。

## 特性

- **硬件质量**：CPU、内存、硬盘全面体检，含 Sysbench、Geekbench、Crystal / ATTO 磁盘测试
- **IP 质量**：IP 类型、欺诈风险评分，Netflix、YouTube、ChatGPT 等解锁检测
- **网络质量**：三网测速、延迟、回程路由追踪
- **无痕测试**：所有测试在临时准系统 BenchOS 中执行，测完自动卸载、删除，原系统零残留
- **一键分享**：测试结果自动上传，生成网页报告链接，可复制为文本或 Markdown

## 沙箱隔离，无痕测试

测试往往需要安装很多工具、产生很多临时文件。为了不弄脏原系统，所有测试都在 **BenchOS** 中进行：

- BenchOS 是一个预装好常用测试工具的精简 Debian 根文件系统
- 使用 chroot 临时切换进 BenchOS，无需重装系统，也无需 Docker / 虚拟机
- 使用时挂载，使用后卸载并删除，中途按 Ctrl+C 退出也会自动清理
- 除了用 curl 下载文件，不需要在服务器上额外安装任何程序


## 仓库结构

| 路径 | 说明 |
|---|---|
| [CaoCong.sh](CaoCong.sh) | 主脚本 |
| [part/header.sh](part/header.sh) | 报告头 |
| [promo/terminal.txt](promo/terminal.txt) | 终端推广位，留空不显示 |
| [providers/data.json](providers/data.json) | 商家列表，欢迎 PR |

## 致谢

- 测试核心来自 [xykt](https://github.com/xykt) 的 [HardwareQuality](https://github.com/xykt/HardwareQuality)、[IPQuality](https://github.com/xykt/IPQuality)、[NetQuality](https://github.com/xykt/NetQuality)
- 沙箱方案改自 [NodeQuality](https://github.com/LloydAsp/NodeQuality)
- 回程路由使用 [NextTrace](https://github.com/nxtrace/NTrace-core)

## 许可

本项目基于 AGPL-3.0 许可的 NodeQuality 修改，同样以 [AGPL-3.0](LICENSE) 开源。
