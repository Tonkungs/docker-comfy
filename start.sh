#!/bin/bash

# ติดตั้ง cloudflared
echo "Downloading cloudflared if not already downloaded..."
wget -nc -P ~ https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb

echo "Installing cloudflared..."
dpkg -i ~/cloudflared-linux-amd64.deb

# ฟังก์ชันเช็คการรัน ComfyUI และเปิด cloudflared
echo "Waiting for ComfyUI to start..."
while ! curl --silent --head http://127.0.0.1:18188; do
  sleep 0.5
done

echo -e "\nComfyUI finished loading, trying to launch cloudflared...\n"

# เปิด cloudflared และจับเฉพาะ URL ที่แสดงออกมา
CLOUDFLARE_URL=$(cloudflared tunnel --url http://127.0.0.1:18188 2>&1 | grep -o 'https://.*\.trycloudflare\.com' | head -n 1)

# แสดง URL ก่อนเข้าเงื่อนไข if
echo "Cloudflared generated URL: $CLOUDFLARE_URL"

# ถ้าได้ URL มาแล้ว ส่งไปที่ API
# if [[ -n "$CLOUDFLARE_URL" ]]; then
#   echo "Sending URL to https://asdasd.com/api..."
#   curl -X POST "https://asdasd.com/api" \
#     -H "Content-Type: application/json" \
#     -d "{\"url\":\"$CLOUDFLARE_URL\"}"
  
#   echo "URL sent successfully!"
# else
#   echo "Failed to retrieve Cloudflared URL"
# fi
