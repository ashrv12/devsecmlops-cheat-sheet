1. DDOS Protection

```bash
cat <<EOF | sudo tee /etc/sysctl.d/99-edge.conf
# TCP Hardening
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=65535  # Increased from 8192 for edge
net.ipv4.tcp_synack_retries=2       # Lowered to drop half-open connections faster
net.ipv4.tcp_fin_timeout=10         # Faster recycling of sockets
net.ipv4.tcp_rfc1337=1
net.ipv4.icmp_echo_ignore_broadcasts=1

# IP Spoofing protection
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# Routing restrictions
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.all.send_redirects=0

# TCP BBR (Congestion Control) - Great for HTTP/2 performance
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

sudo sysctl --system
```

2. UFW on the edge.

```bash
ufw default deny incoming
ufw default allow outgoing

# Allow SSH only from your specific Management IP or VPN IP.
ufw allow from <YOUR_ADMIN_IP> to any port 22

# If you have dynamic IP, use ufw limit. This blocks IPs that attempt 6 or more connections within 30 seconds.
ufw limit 22/tcp

ufw allow 80/tcp
ufw allow 443/tcp

ufw enable
```

3. Install and deploy HAProxy.

```conf
global
  maxconn 50000                 # Bumped for Edge
  log /dev/log local0
  # Modern SSL Cipher Suite (Mozilla Intermediate)
  ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
  ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
  mode http
  timeout connect 5s
  timeout client 10s            # Tighter client timeout to prevent Slowloris
  timeout server 30s
  option httplog

frontend https-in
  bind *:443 ssl crt /etc/ssl/certs/site.pem alpn h2,http/1.1

  # --- RATE LIMITING ---
  # Define the storage table: 100k entries, expire after 30s
  stick-table type ip size 100k expire 30s store http_req_rate(10s),conn_rate(10s)

  # Track the IP
  http-request track-sc0 src

  # Deny logic with 429 code
  http-request deny deny_status 429 if { sc_http_req_rate(0) gt 100 }
  http-request deny deny_status 429 if { sc_conn_rate(0) gt 30 }

  # --- WAF ---
  filter spoe engine modsecurity config /etc/haproxy/modsec.conf

  default_backend k8s-ingress

backend k8s-ingress
  balance roundrobin
  option httpchk GET /healthz   # Always verify backend health
  server istio1 10.0.0.10:80 check inter 2s fall 3 rise 2
  server istio2 10.0.0.11:80 check inter 2s fall 3 rise 2
```

4. Install ModSecurity WAF

```bash
sudo apt install libapache2-mod-security2
sudo apt install modsecurity-crs

# But instead of Apache, run ModSecurity with HAProxy using spoa:
sudo apt install modsecurity-spoa
```

5. Edit /etc/modsecurity-spoa/modsecurity-spoa.conf:

> [!INFO]
> CRS Setup: Ensure you rename the setup file before including the rules.

```bash
cp /usr/share/modsecurity-crs/crs-setup.conf.example /usr/share/modsecurity-crs/crs-setup.conf
```

> [!INFO]
> Detection Mode First: In /etc/modsecurity-spoa/modsecurity-spoa.conf (or wherever your main ModSec config is), start with:

```text
SecRuleEngine DetectionOnly
Include /usr/share/modsecurity-crs/*.conf
```

Monitor the logs for a week. Once you have whitelisted the false positives, change it to SecRuleEngine On.

```text
SecRuleEngine DetectionOnly
```

```bash
systemctl enable modsecurity-spoa
systemctl start modsecurity-spoa
```

6. Add to HAProxy:

```text
frontend https-in
  filter spoe engine modsecurity config /etc/haproxy/modsec.conf
```

7. Add CrowdSec (distributed IP reputation)

```bash
curl -s https://install.crowdsec.net | sudo sh
sudo apt install crowdsec crowdsec-firewall-bouncer-iptables

sudo cscli collections install crowdsecurity/haproxy

# Configure CrowdSec to read HAProxy logs: Edit /etc/crowdsec/acquis.yaml:
filenames:
  - /var/log/haproxy.log # Ensure HAProxy is outputting here via rsyslog
labels:
  type: haproxy

sudo systemctl restart crowdsec
```

8. Fix HAProxy logs so that it will work with Crowdsec

```bash
# Create a dedicated configuration file for HAProxy in rsyslog.d:
# Create the rsyslog config file
cat <<EOF | sudo tee /etc/rsyslog.d/49-haproxy.conf
# Collect logs from HAProxy on localhost (UDP)
$ModLoad imudp
$UDPServerAddress 127.0.0.1
$UDPServerRun 514

# Define a template for the log format (optional but cleaner)
# This keeps the log file clean without the system hostname repeating
$template HAProxyFmt,"%msg%\n"

# Filter HAProxy logs to a specific file
# 'local0' corresponds to the 'log /dev/log local0' line in your HAProxy config
local0.* /var/log/haproxy.log;HAProxyFmt

# Stop processing these logs (prevent them from going to syslog/messages)
& stop
EOF
```

9. Configure Log Rotation (Crucial)

```bash
# Since this is an edge server, logs will grow very fast. You must rotate them to prevent disk exhaustion.
cat <<EOF | sudo tee /etc/logrotate.d/haproxy
/var/log/haproxy.log {
    daily
    rotate 7
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
```

10. Restart rsyslog and haproxy:

```bash
sudo systemctl restart rsyslog
sudo systemctl restart haproxy
```

11. Verify it works

```bash
curl -I https://localhost  # or your public IP
```

```bash
tail -f /var/log/haproxy.log
```

```bash
# Now that the file exists and is populating, check if CrowdSec is happy:
sudo cscli metrics

# Look for the Acquisition Metrics section. You should see /var/log/haproxy.log listed with a count of Lines read increasing as you make requests.
```

12. How to deal with bad actors or bots creating 403 forbidden requests

Since ModSecurity is working via HAProxy (SPOA), a block by ModSecurity will result in a 403 Forbidden response in the HAProxy logs. By tracking these 403s, you can ban the IP at the firewall level after $N$ attempts, preventing them from even reaching HAProxy for a few hours.

1. The Logic Flow

-   The following diagram illustrates how your stack now works with the log-reading capability you just enabled:

-   Request hits HAProxy.

-   ModSecurity scans and finds a SQL injection attempt; it tells HAProxy to return 403.

-   HAProxy logs the 403 to /var/log/haproxy.log.

-   CrowdSec reads that log line, increments a counter for that IP, and if it hits your limit, it tells the Firewall Bouncer to drop all future packets from that IP.

```bash
# Create a new file for your custom "aggressive 403" detection:
sudo nano /etc/crowdsec/scenarios/haproxy-403-bf.yaml
```

Paste the following configuration:

```yaml
type: leaky
name: yourname/haproxy-403-flood
description: "Detect IPs triggering too many 403 Forbidden errors (WAF blocks)"
# Filter for HAProxy logs where status is 403
filter: "evt.Meta.service == 'http' && evt.Meta.http_status == '403'"
# How many 403s before we trigger? (e.g., 5 within 1 minute)
leakspeed: "1m"
capacity: 5
# Which field identifies the attacker?
groupby: "evt.Meta.source_ip"
blackhole: 1h
labels:
    service: http
    type: security
    remediation: true
```

Apply and test

```bash
sudo systemctl restart crowdsec
```

Verify the scenario is loaded

```bash
sudo cscli scenarios list | grep 403
```

> [!INFO]
> Test it: From an external machine (or your phone on LTE), try to access a page that triggers a ModSecurity rule (or just manually trigger a 403 if you have a rule for it) 6 times quickly.

```bash
# Check Decisions:
sudo cscli decisions list

# You should see your IP address listed with a ban remediation.
```

> [!WARNING]
> Before you go live, ensure you don't ban yourself while testing. Edit /etc/crowdsec/parsers/s02-enrich/whitelists.yaml (create it if it doesn't exist):

```yaml
name: crowdsecurity/whitelists
description: "Whitelist my home/office IP"
whitelist:
    reason: "Admin IP"
    ip:
        - "1.2.3.4" # Your real public IP
```

Restart crowdsec to enable whitelist configuration

```bash
sudo systemctl restart crowdsec
```
