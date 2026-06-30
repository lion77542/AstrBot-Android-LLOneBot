# AstrBot Android LLOneBot 版
我们正在修改代码 所以程序不太可用 当我们完成代码并测试可用之后 您将会不再看见这条通知！
> 🤖 将你的 QQ 号变成 AI 机器人 — 基于 LLBot (幸运莉莉娅) 的 AstrBot 安卓 App

本项目是基于 [AstrBot-Android-App](https://github.com/zz6zz666/AstrBot-Android-App) 的深度改造版，核心变更：

**🔁 NapCatQQ → LLBot (幸运莉莉娅)**

| 项目 | 原版 | 本版 |
|------|------|------|
| QQ 协议适配 | NapCatQQ（易掉线、不稳定） | **LLBot（幸运莉莉娅）**：更稳定、WebUI 更完善 |
| WebUI 端口 | 6099 | **3080** |
| 安装方式 | napcat-linux-installer 在线脚本 | **预编译二进制**，下载即用，安装更快 |
| 登录方式 | 本地文件读取二维码 | **WebUI 内扫码**，交互更友好 |
| 后台稳定性 | 容易掉线 | LLBot 连接更可靠 |

### ✨ 本版优点

- ✅ **NapCat 已移除** — 所有 NapCat 相关代码、配置、文档全部替换为 LLBot
- ✅ **安装更快** — LLBot 是预编译二进制，无需编译、无需安装依赖
- ✅ **多镜像源下载** — LLBot 下载支持 5 个镜像源自动轮询 + ZIP 校验 + 3次重试
- ✅ **自动检测版本** — LLBot 自动获取最新 release，不再硬编码版本号
- ✅ **更好的 WebUI** — 端口 3080，功能更完善
- ✅ **自动登录支持** — 设置 QQ 号后自动登录
- ✅ **防卡死机制** — 5 分钟超时自动跳转，不再卡在"配置中"
- ✅ **更流畅** — WebView 滚动卡顿已修复
- ✅ **兼容性更好** — 修复仪表盘白屏、git 克隆失败等问题
- ✅ **品牌开屏页** — 首次启动显示改版品牌界面和隐私协议

### 🛠 已修复的上游 Bug

| Issue | 描述 | 修复 |
|-------|------|------|
| #19 | git tag 解析多出 `{}` 导致克隆失败 | 过滤控制字符 |
| #20 #7 #15 | 启动卡在"配置中"白屏 | 5分钟 fallback 定时器 |
| #11 | WebView 滑动卡顿 | 缩小 Obx 重建范围 |
| #17 | git 克隆失败无容错 | 3次重试 + SSL 降级 + ZIP 回退 |
| #10 | 仪表盘白屏 | loadRequest 放在平台配置后 |
| #9 #8 | 后台掉线 | LLBot 替换 NapCat |
| #5 | 快速登录失效 | LLBot WebUI 扫码 |

### 📦 下载

前往 [Releases](https://github.com/lion77542/AstrBot-Android-LLOneBot/releases) 或 [Actions](https://github.com/lion77542/AstrBot-Android-LLOneBot/actions) 下载最新 APK。

### 🔧 构建

```bash
flutter build apk --release --split-per-abi
```

### 📄 许可证

BSD 3-Clause（继承上游）
