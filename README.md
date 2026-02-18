# cx20632-extmod (DKMS)

将补丁版 `snd-hda-codec-conexant` 做成 DKMS 项目，内核升级后可自动重编译并安装。

## 特性

- DKMS 自动跟随内核版本重建模块
- 提供统一脚本：安装、卸载、重装、状态查询
- 保留旧脚本名，兼容原有使用方式

## 依赖

- Linux
- `dkms`
- 内核头文件（与目标内核版本匹配）
- 构建工具链（`make`, `gcc`）

Debian/Ubuntu 示例：

```bash
sudo apt update
sudo apt install -y dkms build-essential linux-headers-$(uname -r)
```

## 快速开始

```bash
chmod +x dkms-manager.sh
./dkms-manager.sh install --reload
```

如果你不想立即重载音频模块，可去掉 `--reload`，然后重启。

## 管理脚本

```bash
./dkms-manager.sh install [--reload]
./dkms-manager.sh remove [--reload]
./dkms-manager.sh reinstall [--reload]
./dkms-manager.sh status
```

说明：

- `install`: 注册到 DKMS、编译并安装当前版本
- `remove`: 从 DKMS 卸载当前版本（`--all`）
- `reinstall`: 先删后装
- `status`: 查看 DKMS 状态

## 兼容入口

保留了原来的脚本名：

- `install-patched-conexant.sh` -> 等价于 `./dkms-manager.sh install`
- `uninstall-patched-conexant.sh` -> 等价于 `./dkms-manager.sh remove`

## DKMS 配置

- 包名：`cx20632-extmod`
- 版本：`0.1.0`
- 模块：`snd-hda-codec-conexant`
- 安装位置：`/updates/dkms`

如需发布新版本，更新 `dkms.conf` 中 `PACKAGE_VERSION` 后再执行 `reinstall`。

## Secure Boot 提示

若系统启用了 Secure Boot，模块可能因未签名而无法加载。需要关闭 Secure Boot，或自行配置 MOK 并为模块签名。

## 开源发布建议

建议附带：

- `LICENSE`（例如 GPL-2.0-only）
- 变更说明（`CHANGELOG.md`）
- 受影响机型/Codec 列表

