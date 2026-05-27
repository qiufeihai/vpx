proxies:
  - name: vless-reality
    type: vless
    server: __SERVER_ADDRESS__
    port: __SERVER_PORT__
    uuid: __UUID__
    network: tcp
    tls: true
    udp: true
    flow: xtls-rprx-vision
    servername: __REALITY_SERVER_NAME__
    client-fingerprint: __CLIENT_FINGERPRINT__
    reality-opts:
      public-key: __REALITY_PUBLIC_KEY__
      short-id: __REALITY_SHORT_ID__

proxy-groups:
  - name: PROXY
    type: select
    proxies:
      - vless-reality

rules:
  - MATCH,PROXY
