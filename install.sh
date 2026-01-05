#!/usr/bin/env bash
set -e

INSTALL_DIR="/usr/local/bin"
DATA_DIR="/var/lib/memos"
SERVICE_NAME="memos"
PORT=$1

if [ -z "$PORT" ]; then
  echo "❌ 请提供运行端口，例如: $0 7000"
  exit 1
fi

echo "📦 开始 UseMemos 二进制安装脚本"

echo "🔍 获取最新 UseMemos release 版本..."
LATEST_URL=$(curl -s https://api.github.com/repos/usememos/memos/releases/latest \
  | grep "browser_download_url.*memos_.*_linux_amd64.tar.gz" \
  | cut -d '"' -f 4)

if [ -z "$LATEST_URL" ]; then
  echo "❌ 无法获取最新二进制下载地址，请检查网络或仓库状态。"
  exit 1
fi
echo "➡️ 最新下载地址: $LATEST_URL"

TMPDIR=$(mktemp -d)
ARCHIVE="$TMPDIR/memos.tar.gz"

echo "⬇️ 正在下载二进制包..."
curl -L "$LATEST_URL" -o "$ARCHIVE"

echo "📂 解压二进制..."
tar -xzf "$ARCHIVE" -C "$TMPDIR"

if [ -f "$INSTALL_DIR/memos" ]; then
  echo "🗑️  删除旧版本 $INSTALL_DIR/memos"
  sudo rm -f "$INSTALL_DIR/memos"
fi

echo "📂 安装新版本..."
sudo mv "$TMPDIR/memos" "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/memos"

if "$INSTALL_DIR/memos" --help | grep -q -- "--base-path"; then
  echo "✅ 二进制支持 --base-path"
else
  echo "⚠️ 二进制不支持 --base-path，请确认是否为官方最新 release"
fi

echo "📁 创建数据目录: $DATA_DIR"
sudo mkdir -p "$DATA_DIR"
sudo chown "$(whoami)" "$DATA_DIR"

echo
echo "✅ UseMemos 安装完成!"
echo "   - 二进制路径: $INSTALL_DIR/memos"
echo "   - 数据目录:   $DATA_DIR"
echo
echo "💡 运行 Memos:"
echo "   memos --mode prod --addr 127.0.0.1 --port $PORT --data $DATA_DIR"
echo

read -p "是否为 UseMemos 生成 systemd 服务并启用？(y/N) " yn
if [[ "$yn" =~ ^([yY][eE][sS]|[yY])$ ]]; then

  read -p "是否通过子路径访问（例如 /memos）？(y/N) " baseyn
  BASE_PATH=""
  if [[ "$baseyn" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    read -p "请输入访问路径（以 / 开头，例如 /memos）: " input_path
    BASE_PATH="--base-path $input_path"
  fi

  echo "⚙️  正在创建 systemd 服务..."
  sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=UseMemos
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/memos --mode prod --addr 127.0.0.1 --port $PORT --data $DATA_DIR $BASE_PATH
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now $SERVICE_NAME
  echo "🟢 systemd 服务已启用并启动: $SERVICE_NAME"
  echo "   查看状态: sudo systemctl status $SERVICE_NAME"
fi

echo "🎉 安装脚本执行结束!"
