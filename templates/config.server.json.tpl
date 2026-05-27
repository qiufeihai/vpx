{
  "log": {
    "loglevel": "__XRAY_LOGLEVEL__"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": __SERVER_PORT__,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "__UUID__",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "__REALITY_DEST__",
          "xver": 0,
          "serverNames": [
            "__REALITY_SERVER_NAME__"
          ],
          "privateKey": "__REALITY_PRIVATE_KEY__",
          "shortIds": [
            "__REALITY_SHORT_ID__"
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ],
        "routeOnly": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
