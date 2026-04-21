# 1. Generate Keys
# On each node, generate a unique key pair:
wg genkey | tee privatekey | wg pubkey > publickey
wg genpsk > preshared.key

# Note: For maximum security, use the same preshared.key across all nodes to simplify,
# or generate unique ones for each pair.

# Node 1 Setup
[Interface]
PrivateKey = <Node_1_Private_Key>
Address = 10.0.0.1/24
ListenPort = 51820

# Connection to Node 2
[Peer]
PublicKey = <Node_2_Public_Key>
PresharedKey = <PSK>
Endpoint = 2.2.2.2:51820
AllowedIPs = 10.0.0.2/32
PersistentKeepalive = 25

# Connection to Node 3
[Peer]
PublicKey = <Node_3_Public_Key>
PresharedKey = <PSK>
Endpoint = 3.3.3.3:51820
AllowedIPs = 10.0.0.3/32
PersistentKeepalive = 25

# Node 2 Setup
[Interface]
PrivateKey = <Node_2_Private_Key>
Address = 10.0.0.2/24
ListenPort = 51820

# Connection to Node 1
[Peer]
PublicKey = <Node_1_Public_Key>
PresharedKey = <PSK>
Endpoint = 1.1.1.1:51820
AllowedIPs = 10.0.0.1/32
PersistentKeepalive = 25

# Connection to Node 3
[Peer]
PublicKey = <Node_3_Public_Key>
PresharedKey = <PSK>
Endpoint = 3.3.3.3:51820
AllowedIPs = 10.0.0.3/32
PersistentKeepalive = 25

# Node 3 Setup
[Interface]
PrivateKey = <Node_3_Private_Key>
Address = 10.0.0.3/24
ListenPort = 51820

# Connection to Node 1
[Peer]
PublicKey = <Node_1_Public_Key>
PresharedKey = <PSK>
Endpoint = 1.1.1.1:51820
AllowedIPs = 10.0.0.1/32
PersistentKeepalive = 25

# Connection to Node 2
[Peer]
PublicKey = <Node_2_Public_Key>
PresharedKey = <PSK>
Endpoint = 2.2.2.2:51820
AllowedIPs = 10.0.0.2/32
PersistentKeepalive = 25

# Firewall hardening
ufw allow from 2.2.2.2 to any port 51820 proto udp
ufw allow from 3.3.3.3 to any port 51820 proto udp

# 4. K3s Cluster Initialization
# Initialize Node 1 (Server/Master):
curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip=10.0.0.1 \
  --advertise-address=10.0.0.1 \
  --flannel-iface=wg0

# Join Node 2 & 3 (Agents/Workers):
# Run this on both worker nodes (using their respective 10.0.0.x IP):
curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.1:6443 \
  K3S_TOKEN=<TOKEN_FROM_MASTER> \
  sh -s - agent \
  --node-ip=<NODE_INTERNAL_IP> \
  --flannel-iface=wg0

# BONUS ADDING A FOURTH PRIVATE NODE

# 1. Configure the Private Node (Node 4)
# Node 4 needs to know where the public nodes are, but it doesn't need to listen on a public port
# because no one can reach it anyway.

# [/etc/wireguard/wg0.conf] on Node 4:
[Interface]
PrivateKey = <Node_4_Private_Key>
Address = 10.0.0.4/24
# No ListenPort needed, but we define the outgoing interface

# Connect to Public Node 1
[Peer]
PublicKey = <Node_1_Public_Key>
Endpoint = 1.1.1.1:51820
AllowedIPs = 10.0.0.1/32
PersistentKeepalive = 25

# Connect to Public Node 2
[Peer]
PublicKey = <Node_2_Public_Key>
Endpoint = 2.2.2.2:51820
AllowedIPs = 10.0.0.2/32
PersistentKeepalive = 25

# Connect to Public Node 3
[Peer]
PublicKey = <Node_3_Public_Key>
Endpoint = 3.3.3.3:51820
AllowedIPs = 10.0.0.3/32
PersistentKeepalive = 25

# Crucial: The PersistentKeepalive = 25 is mandatory here.
# It keeps the NAT/Firewall at the private location
# "open" so the public nodes can send data back to Node 4.

# 2. Update the Public Nodes (1, 2, and 3)
# The public nodes need to know Node 4 exists, but since Node 4 has no public IP,
# they will not have an Endpoint line for it. They will simply wait for Node 4 to check in.

# Add this to [/etc/wireguard/wg0.conf] on Node 1, 2, and 3:
# Add this at the bottom of the existing config
[Peer]
PublicKey = <Node_4_Public_Key>
AllowedIPs = 10.0.0.4/32
# Note: No Endpoint line here!

# After adding this, restart wireguard on the public nodes: systemctl restart wg-quick@wg0.

# 3. How the Connection Functions
# Node 4 sends a packet to Node 1 (1.1.1.1:51820).

# Node 1 sees the packet, verifies the key, and notes the "Source IP and Port"
# that Node 4's router used to send the packet.

# Node 1 can now send K3s traffic back to Node 4 using that recorded temporary port.

# Because Node 4 also connects to Node 2 and Node 3 directly, it maintains a direct path
# to every node in the cluster despite being behind a NAT.

# 4. Join the K3s Cluster
# On Node 4, install the K3s agent pointing to the Master node's VPN IP:
curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.1:6443 \
  K3S_TOKEN=<TOKEN> sh -s - agent \
  --node-ip=10.0.0.4 \
  --flannel-iface=wg0
