# OCR Service

基于 macOS Vision Framework 的 HTTP OCR 服务，使用 Swift Vapor 框架构建。

## 特性

- 🔥 原生 macOS Vision Framework OCR 引擎
- 🚀 高性能 Vapor HTTP 服务器
- 📱 支持多种图片格式 (JPG, PNG, TIFF, BMP)
- 🌍 多语言识别支持 (中文、英文等)
- 📊 返回置信度和边界框信息
- 🍺 Homebrew 集成支持
- ⚙️ 系统服务自动管理

## 系统要求

- macOS 12.0 (Monterey) 或更高版本
- Xcode Command Line Tools
- Swift 6.0

## 快速开始

### 1. 克隆项目
```bash
git clone https://github.com/EnjoyWT/ocrl.git
cd ocrl
```

### 2. 安装服务

**推荐方式：Homebrew 安装**
```bash
brew install --build-from-source Formula/ocrs.rb
brew services start ocrs
```

**或 脚本安装（仅限本地开发/调试）**
```bash
chmod +x scripts/install.sh
./scripts/install.sh
ocr-service-start
```

> 两种安装方式任选其一，无需同时执行。

### 3. 测试服务
```bash
# 健康检查
curl http://localhost:7321/health

# 服务信息
curl http://localhost:7321/api/v1/ocr/info

# OCR 识别 (multipart 上传)
curl -X POST -F "image=@test.jpg" http://localhost:7321/api/v1/ocr

# OCR 识别 (二进制上传)
curl -X POST -H "Content-Type: application/octet-stream" \
     --data-binary "@test.jpg" \
     "http://localhost:7321/api/v1/ocr?language=zh-CN"
```

## API 文档

### 健康检查
```
GET /health
```
返回服务状态信息。

### 服务信息
```
GET /api/v1/ocr/info
```
返回服务配置和支持的功能。

### OCR 识别
```
POST /api/v1/ocr
```

**支持的上传方式：**

1. **Multipart Form Upload**
   ```bash
   curl -X POST -F "image=@image.jpg" -F "language=zh-CN" \
        http://localhost:7321/api/v1/ocr
   ```

2. **Binary Upload**
   ```bash
   curl -X POST -H "Content-Type: application/octet-stream" \
        --data-binary "@image.jpg" \
        "http://localhost:7321/api/v1/ocr?language=zh-CN"
   ```

3. **JSON Upload**
   ```bash
   curl -X POST -H "Content-Type: application/json" \
        -d '{
              "image": "<base64字符串>",
              "language": "zh-CN",
              "recognitionLevel": "accurate",
              "confidence": 0.8
            }' \
        http://localhost:7321/api/v1/ocr
   ```

**参数说明：**
| 参数             | 类型     | 说明                                   | 是否必需 |
|------------------|----------|----------------------------------------|----------|
| image            | 文件/字符串 | 图片文件（multipart/binary）或 base64 字符串（json） | 必需     |
| language         | 字符串   | 识别语言，如 zh-CN, en-US              | 可选     |
| recognitionLevel | 字符串   | 识别精度（仅 JSON），如 accurate/fast   | 可选     |
| confidence       | 浮点数   | 置信度阈值（仅 JSON），如 0.8           | 可选     |

**响应格式：**
```json
{
  "status": "success",
  "data": {
    "text": "识别的文字内容",
    "confidence": 0.95,
    "processingTime": 120,
    "boundingBoxes": [
      {
        "text": "文字片段",
        "confidence": 0.92,
        "x": 0.1,
        "y": 0.2,
        "width": 0.3,
        "height": 0.1
      }
    ]
  }
}
```

**错误响应：**
```json
{
  "status": "error",
  "error": "Invalid image format"
}
```

## 服务管理

### 启动服务
```bash
brew services start ocrs
```

### 停止服务
```bash
brew services stop ocrs
```

### 检查状态
```bash
brew services list | grep ocrs
```

### 查看日志
```bash
# 标准输出日志
cat /usr/local/var/log/ocrs.log

# 错误日志
cat /usr/local/var/log/ocrs.error.log
```

## 开发

### 本地开发运行
```bash
# 安装依赖
swift package resolve

# 编译
swift build

# 运行
.build/debug/App

# 或者直接运行
swift run App
```

### 测试
```bash
# 运行测试脚本
chmod +x scripts/test.sh
./scripts/test.sh
```

### 项目结构
```
ocr-service/
├── Package.swift              # Swift Package 配置
├── Sources/App/
│   ├── main.swift            # 应用入口
│   ├── configure.swift       # 应用配置
│   ├── Controllers/
│   │   └── OCRController.swift   # OCR API 控制器
│   ├── Models/
│   │   └── OCRModels.swift       # 数据模型
│   └── Services/
│       └── VisionOCRService.swift # Vision OCR 服务
├── scripts/
│   ├── install.sh            # 安装脚本
│   └── test.sh              # 测试脚本
└── Formula/
    └── ocr-service.rb       # Homebrew Formula
```

## 性能优化建议

1. **图片预处理**
   - 建议上传前压缩大图片
   - 支持的最大文件大小：10MB

2. **并发处理**
   - 服务支持异步处理
   - Vision Framework 会自动利用多核心

3. **缓存策略**
   - 可以考虑添加结果缓存
   - 重复图片识别会更快

## Homebrew 集成

### Homebrew Formula 说明

本项目自带 Homebrew Formula（`Formula/ocr-service.rb`），用于一键安装和注册系统服务。

- **服务名称**：`ocrs`（所有 brew 命令均用 ocrs）
- **安装路径**：可执行文件安装为 `/usr/local/bin/ocrs`
- **配置文件**：`/usr/local/etc/ocrs/config.json`，可自定义 host、port、log_level、max_file_size 等参数
- **日志路径**：
  - 标准日志：`/usr/local/var/log/ocrs.log`
  - 错误日志：`/usr/local/var/log/ocrs.error.log`
- **数据目录**：`/usr/local/var/ocrs`
- **服务管理**：通过 `brew services` 管理，支持自动重启
- **测试**：brew 安装后自动运行健康检查（`/health`）

#### 主要 Formula 字段说明
- `desc`/`homepage`/`url`/`sha256`/`license`：描述、主页、源码包、校验和、许可证
- `depends_on`：依赖 macOS Monterey 及 Xcode 13+
- `install`：编译并安装可执行文件，生成默认配置
- `service do ... end`：定义服务启动命令、工作目录、日志、自动重启
- `test do ... end`：安装后自动健康检查

#### 自定义配置
如需修改端口、日志路径等，可编辑 `/usr/local/etc/ocrs/config.json`，修改后重启服务：
```bash
brew services restart ocrs
```

#### 常见 Homebrew 服务排查
- 查看服务状态：
  ```bash
  brew services list | grep ocrs
  ```
- 查看日志：
  ```bash
  cat /usr/local/var/log/ocrs.log
  cat /usr/local/var/log/ocrs.error.log
  ```
- 手动测试服务：
  ```bash
  curl http://localhost:7321/health
  ```
- 重新安装/修复权限：
  ```bash
  brew services stop ocrs
  brew uninstall ocrs
  brew install --build-from-source Formula/ocr-service.rb
  brew services start ocrs
  ```

## 故障排除

### 常见问题

**1. 服务无法启动**
```bash
# 检查端口是否被占用
lsof -i :76ers 321

# 检查权限
ls -la /usr/local/bin/ocr-service

# 查看错误日志
tail -f /usr/local/var/log/ocr-service.error.log
```

**2. OCR 识别失败**
- 确保图片格式受支持
- 检查图片是否包含文字
- 尝试不同的语言参数

**3. 权限问题**
```bash
# 重新安装并修复权限
sudo ./scripts/install.sh
```

### 调试模式

开发时可以设置环境变量启用调试：
```bash
export LOG_LEVEL=debug
swift run App
```

## 贡献

欢迎提交 Issue 和 Pull Request！

### 开发规范
1. 代码遵循 Swift 官方规范
2. 提交前运行测试脚本
3. 更新相关文档

## 许可证

MIT License

## 支持

如有问题请提交 GitHub Issue 或联系维护者。

---

**注意：** 此服务仅在 macOS 上运行，因为依赖于 Apple 的 Vision Framework。
