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
INSTALL_DIR="/usr/local/ocrs"
sudo mkdir -p "$INSTALL_DIR"
sudo mkdir -p "/usr/local/var/log"

# 编译项目
echo "📦 Building OCR service..."
swift build -c release

# 安装二进制文件
echo "📋 Installing binary..."
sudo cp .build/release/App "$INSTALL_DIR/ocrs"
sudo chmod +x "$INSTALL_DIR/ocrs"

# 创建符号链接
sudo ln -sf "$INSTALL_DIR/ocrs" /usr/local/bin/ocrs

# 创建配置文件
CONFIG_DIR="/usr/local/etc/ocrs"
sudo mkdir -p "$CONFIG_DIR"

if [[ ! -f "$CONFIG_DIR/config.json" ]]; then
    echo "⚙️  Creating default configuration..."
    sudo tee "$CONFIG_DIR/config.json" > /dev/null <<EOF
{
  "host": "0.0.0.0",
  "port": 7321,
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
        <string>$INSTALL_DIR/ocrs</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$INSTALL_DIR</string>
    <key>RunAtLoad</key>
    <false/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/usr/local/var/log/ocrs.log</string>
    <key>StandardErrorPath</key>
    <string>/usr/local/var/log/ocrs.error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PORT</key>
        <string>7321</string>
    </dict>
</dict>
</plist>
EOF

# 创建控制脚本
echo "📝 Creating control scripts..."
sudo tee /usr/local/bin/ocrs-start > /dev/null <<'EOF'
#!/bin/bash
sudo launchctl load /Library/LaunchDaemons/com.ocrservice.plist
echo "✅ OCR Service started"
echo "🌐 Service available at: http://localhost:7321"
echo "🏥 Health check: http://localhost:7321/health"
EOF

sudo tee /usr/local/bin/ocrs-stop > /dev/null <<'EOF'
#!/bin/bash
sudo launchctl unload /Library/LaunchDaemons/com.ocrservice.plist
echo "🛑 OCR Service stopped"
EOF

sudo tee /usr/local/bin/ocrs-status > /dev/null <<'EOF'
#!/bin/bash
if sudo launchctl list | grep -q com.ocrservice; then
    echo "✅ OCR Service is running"
    echo "🌐 Available at: http://localhost:7321"
    curl -s http://localhost:7321/health | python3 -m json.tool 2>/dev/null || echo "Service may be starting up..."
else
    echo "🛑 OCR Service is not running"
fi
EOF

sudo chmod +x /usr/local/bin/ocrs-*

echo ""
echo "🎉 Installation completed!"
echo ""
echo "Usage:"
echo "  ocrs-start   # Start the service"
echo "  ocrs-stop    # Stop the service"
echo "  ocrs-status  # Check service status"
echo ""
echo "API Endpoints:"
echo "  POST http://localhost:7321/api/v1/ocr    # Upload image for OCR"
echo "  GET  http://localhost:7321/api/v1/ocr/info # Service info"
echo "  GET  http://localhost:7321/health        # Health check"
echo ""
echo "Start the service with: ocrs-start"
