#!/bin/bash

# ติดตั้ง cloudflared
echo "Downloading cloudflared if not already downloaded..."
wget -nc -P ~ https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb

echo "Installing cloudflared..."
dpkg -i ~/cloudflared-linux-amd64.deb

# ฟังก์ชันเช็คการรัน ComfyUI และเปิด cloudflared
echo "Waiting for ComfyUI to start..."
while ! curl --silent --head http://127.0.0.1:18188; do
  echo "Waiting for ComfyUI to start... "
  sleep 0.5
done

echo -e "\nComfyUI finished loading, trying to launch cloudflared...\n"

# รัน cloudflared แบบ background (&)
cloudflared tunnel --url http://127.0.0.1:18188 > cloudflared.log 2>&1 &

# แจ้งให้ผู้ใช้รู้ว่ากำลังรอ URL
echo "Waiting for Cloudflared to generate URL..."

# รอให้ cloudflared สร้าง URL
while true; do
  CLOUDFLARE_URL=$(grep -o 'https://.*\.trycloudflare\.com' cloudflared.log | head -n 1)
  if [[ -n "$CLOUDFLARE_URL" ]]; then
    break
  fi
  sleep 0.5
done

# แสดง URL ทันที
echo "✅ Cloudflared generated URL: $CLOUDFLARE_URL"

# ดึง public IP
PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me)
if [ -z "$PUBLIC_IP" ]; then
  PUBLIC_IP=$(curl -s --max-time 5 https://ipinfo.io/ip)
fi

if [ -z "$PUBLIC_IP" ]; then
  echo "❌ ไม่สามารถดึง Public IP ได้"
else
  export PUBLIC_IP
  echo "✅ Public IP: $PUBLIC_IP"
fi

# ส่งไปยัง API พร้อม retry
echo "Sending URL to https://gary-indonesia-kurt-coming.trycloudflare.com/server"
MAX_RETRIES=5
ATTEMPT=1
SUCCESS=false

while [ $ATTEMPT -le $MAX_RETRIES ]; do
  echo "Attempt $ATTEMPT of $MAX_RETRIES..."
  
  curl -X POST "https://gary-indonesia-kurt-coming.trycloudflare.com/server" \
    -H "Content-Type: application/json" \
    -d "{\"server_url\":\"$CLOUDFLARE_URL\",\"server_ip\":\"$PUBLIC_IP\"}"

  if [ $? -eq 0 ]; then
    echo "✅ URL sent successfully!"
    SUCCESS=true
    break
  else
    echo "❌ Failed to send URL. Retrying in 2 seconds..."
    sleep 2
  fi

  ATTEMPT=$((ATTEMPT + 1))
done

if [ "$SUCCESS" = false ]; then
  echo "❌ ERROR: Could not send URL after $MAX_RETRIES attempts."
fi
