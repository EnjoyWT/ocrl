#!/bin/bash
set -e

echo "🚀 Installing OCR Service..."

# 检查系统要求
if [[ $(uname) != "Darwin" ]]; then
    echo "❌ This service only works on macOS"
    exit 1
fi

# 检查 macOS 版本
macos_version=$(sw_vers -productVersion)
if [[ "${macos_version}" < "12.0" ]]; then
    echo "❌ macOS 12.0 (Monterey) or later is required"
    exit 1
fi

# 检查 Xcode Command Line Tools
if ! command -v swift &> /dev/null; then
    echo "❌ Swift is not installed. Please install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

# 创建工作目录
INSTALL_DIR="/usr/local/ocr-service"
sudo mkdir -p "$INSTALL_DIR"
sudo mkdir -p "/usr/local/var/log"

# 编译项目
echo "📦 Building OCR service..."
swift build -c release

# 安装二进制文件
echo "📋 Installing binary..."
sudo cp .build/release/App "$INSTALL_DIR/ocr-service"
sudo chmod +x "$INSTALL_DIR/ocr-service"

# 创建符号链接
sudo ln -sf "$INSTALL_DIR/ocr-service" /usr/local/bin/ocr-service

# 创建配置文件
CONFIG_DIR="/usr/local/etc/ocr-service"
sudo mkdir -p "$CONFIG_DIR"

if [[ ! -f "$CONFIG_DIR/config.json" ]]; then
    echo "⚙️  Creating default configuration..."
    sudo tee "$CONFIG_DIR/config.json" > /dev/null <<EOF
{
  "host": "0.0.0.0",
  "port": 8080,
  "log_level": "info",
  "max_file_size": "10MB"
}
EOF
fi

# 创建 LaunchDaemon
PLIST_PATH="/Library/LaunchDaemons/com.ocrservice.plist"
echo "🔧 Creating system service..."
sudo tee "$PLIST_PATH" > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ocrservice</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/ocr-service</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    <key>RunAtLoad</key>
    <false/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/usr/local/var/log/ocr-service.log</string>
    <key>StandardErrorPath</key>
    <string>/usr/local/var/log/ocr-service.error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PORT</key>
        <string>8080</string>
    </dict>
</dict>
</plist>
EOF

# 创建控制脚本
echo "📝 Creating control scripts..."
sudo tee /usr/local/bin/ocr-service-start > /dev/null <<'EOF'
#!/bin/bash
sudo launchctl load /Library/LaunchDaemons/com.ocrservice.plist
echo "✅ OCR Service started"
echo "🌐 Service available at: http://localhost:8080"
echo "🏥 Health check: http://localhost:8080/health"
EOF

sudo tee /usr/local/bin/ocr-service-stop > /dev/null <<'EOF'
#!/bin/bash
sudo launchctl unload /Library/LaunchDaemons/com.ocrservice.plist
echo "🛑 OCR Service stopped"
EOF

sudo tee /usr/local/bin/ocr-service-status > /dev/null <<'EOF'
#!/bin/bash
if sudo launchctl list | grep -q com.ocrservice; then
    echo "✅ OCR Service is running"
    echo "🌐 Available at: http://localhost:8080"
    curl -s http://localhost:8080/health | python3 -m json.tool 2>/dev/null || echo "Service may be starting up..."
else
    echo "🛑 OCR Service is not running"
fi
EOF

sudo chmod +x /usr/local/bin/ocr-service-*

echo ""
echo "🎉 Installation completed!"
echo ""
echo "Usage:"
echo "  ocr-service-start   # Start the service"
echo "  ocr-service-stop    # Stop the service"
echo "  ocr-service-status  # Check service status"
echo ""
echo "API Endpoints:"
echo "  POST http://localhost:8080/api/v1/ocr    # Upload image for OCR"
echo "  GET  http://localhost:8080/api/v1/ocr/info # Service info"
echo "  GET  http://localhost:8080/health        # Health check"
echo ""
echo "Start the service with: ocr-service-start"
