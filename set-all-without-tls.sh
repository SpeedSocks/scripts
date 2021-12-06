#!/bin/bash
bash <(curl -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh)
read -p 'Enter Node ID:'Node_ID
read -p 'Enter ApiKey:'ApiKey
read -p 'Enter ApiHost:'ApiHost
cat << EOF > /etc/XrayR/config.yml
Log:
      Level: none # Log level: none, error, warning, info, debug 
      AccessPath: # ./access.Log
      ErrorPath: # ./error.log
      DnsConfigPath: # ./dns.json Path to dns config
      ConnetionConfig:
      Handshake: 4 # Handshake time limit, Second
      ConnIdle: 30 # Connection idle time limit, Second
      UplinkOnly: 2 # Time limit when the connection downstream is closed, Second
      DownlinkOnly: 4 # Time limit when the connection is closed after the uplink is closed, Second
      BufferSize: 64 # The internal cache size of each connection, kB 
Nodes:
  -
    PanelType: "SSpanel" # Panel type: SSpanel, V2board, PMpanel, , Proxypanel
    ApiConfig:
      ApiHost: "${ApiHost}"
      ApiKey: "${ApiKey}"
      NodeID: ${Node_ID}
      NodeType: V2ray # Node type: V2ray, Shadowsocks, Trojan, Shadowsocks-Plugin
      Timeout: 30 # Timeout for the api request
      EnableVless: false # Enable Vless for V2ray Type
      EnableXTLS: false # Enable XTLS for V2ray and Trojan
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings, 0 means disable
      DeviceLimit: 0 # Local settings will replace remote settings, 0 means disable
      RuleListPath: # ./rulelist Path to local rulelist file
    ControllerConfig:
      ListenIP: 0.0.0.0 # IP address you want to listen
      SendIP: 0.0.0.0 # IP address you want to send pacakage
      UpdatePeriodic: 60 # Time to update the nodeinfo, how many sec.
      EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
      DNSType: AsIs # AsIs, UseIP, UseIPv4, UseIPv6, DNS strategy
      EnableProxyProtocol: false # Only works for WebSocket and TCP
      EnableFallback: false # Only support for Trojan and Vless
      FallBackConfigs:  # Support multiple fallbacks
        -
          SNI: # TLS SNI(Server Name Indication), Empty for any
          Path: # HTTP PATH, Empty for any
          Dest: 80 # Required, Destination of fallback, check https://xtls.github.io/config/fallback/ for details.
          ProxyProtocolVer: 0 # Send PROXY protocol version, 0 for dsable
          CertConfig:
          CertMode: dns # Option about how to get certificate: none, file, http, dns. Choose "none" will forcedly disable the tls config.
          CertDomain: "node1.test.com" # Domain to cert
          CertFile: ./cert/node1.test.com.cert # Provided if the CertMode is file
          KeyFile: ./cert/node1.test.com.key
          Provider: alidns # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
          Email: test@me.com
          DNSEnv: # DNS ENV option used by DNS provider
          ALICLOUD_ACCESS_KEY: aaa
          ALICLOUD_SECRET_KEY: bbb
  # -
  #   PanelType: "V2board" # Panel type: SSpanel, V2board
  #   ApiConfig:
  #   ApiHost: "http://127.0.0.1:668"
  #   ApiKey: "123"
  #   NodeID: 4
  #   NodeType: Shadowsocks # Node type: V2ray, Shadowsocks, Trojan
  #   Timeout: 30 # Timeout for the api request
  #   EnableVless: false # Enable Vless for V2ray Type
  #   EnableXTLS: false # Enable XTLS for V2ray and Trojan
  #   SpeedLimit: 0 # Mbps, Local settings will replace remote settings
  #   DeviceLimit: 0 # Local settings will replace remote settings
  #   ControllerConfig:
  #   ListenIP: 0.0.0.0 # IP address you want to listen
  #   UpdatePeriodic: 10 # Time to update the nodeinfo, how many sec.
  #   EnableDNS: false # Use custom DNS config, Please ensure that you set the dns.json well
  #   CertConfig:
  #   CertMode: dns # Option about how to get certificate: none, file, http, dns
  #   CertDomain: "node1.test.com" # Domain to cert
  #   CertFile: ./cert/node1.test.com.cert # Provided if the CertMode is file
  #   KeyFile: ./cert/node1.test.com.pem
  #   Provider: alidns # DNS cert provider, Get the full support list here: https://go-acme.github.io/lego/dns/
  #   Email: test@me.com
  #   DNSEnv: # DNS ENV option used by DNS provider
  #   ALICLOUD_ACCESS_KEY: aaa
  #   ALICLOUD_SECRET_KEY: bbb
EOF
XrayR restart
XrayR enable
XrayR status
apt update&&apt install nginx -y
systemctl stop nginx
read -p 'Enter XrayR backend port:' XrayR_port
read -p 'Enter XrayR backend path:' XrayR_path
read -p 'Enter the site  you want to proxy:(eg.https://huawei.com)' remote_path ##eg.https://huawei.com/

cat << EOF > /etc/nginx/nginx.conf
worker_processes  4;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  300;
    server 
    {
	listen 80 default_server;
	
        location ${XrayR_path}
        {
        
            proxy_pass http://127.0.0.1:${XrayR_port}${XrayR_path};
            proxy_buffering off;
            proxy_buffer_size 4k;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-Host \$server_name;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Forwarded-Ssl on;
        }
        location /
        {
        
            proxy_pass ${remote_path};
            proxy_buffering off;
            proxy_buffer_size 4k;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-Host \$server_name;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Forwarded-Ssl on;
        }
    }
}
EOF
systemctl enable --now nginx