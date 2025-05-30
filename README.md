# PMMP DORID

[![GitHub Release](https://img.shields.io/github/v/release/Veha0001/pmmp-droid?sort=date&display_name=release&style=for-the-badge&logo=git&logoColor=%239399b2&label=Download&labelColor=%231e1e2e&color=%23f38ba8)](https://github.com/Veha0001/pmmp-droid/releases)
[![Workflows Folder](https://img.shields.io/badge/Workflows-Folder-cyan?style=for-the-badge&logo=github-actions&logoColor=%23FFFAFF&labelColor=%23303036&color=%2330BCED)](.github/workflows)
[![Ko-fi](https://img.shields.io/badge/support_me_on_ko--fi-F16061?style=for-the-badge&logo=kofi&logoColor=f5f5f5)](https://ko-fi.com/Veha0001)

GitHub Actions workflows to build PHP Binaries for PocketMine-MP on Termux (Android).

## ✨ News
You can now download prebuilt PHP binaries for Android directly from the [pmmp GitHub repository](https://github.com/pmmp/PHP-Binaries).

## 📖 About

This repository provides automated workflows to create PHP binaries compatible with [PocketMine-MP](https://pmmp.io/), enabling Minecraft server hosting on Android devices using Termux.

## 🚀 Quick Start

Run the following command to download and execute the script in one step:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Veha0001/pmmp-droid/main/pchan.sh)"
```
This command ensures that the script is fetched and executed securely.

**Running as Root**:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Veha0001/pmmp-droid/main/pchan.sh)" -- -r
```

### 🛠️ Options

`-a`: Use an alternate URL.

`-r`: Skip root check.

`-u`: Trigger update.

`-c`: Force compile.

`-d <dir>`: Set install directory.

`-i`: Ignore SSL certificates.

`-v <channel: stable, beta, pm3..>`: Set update channel.

`-t <url>`: Set custom build URL.
