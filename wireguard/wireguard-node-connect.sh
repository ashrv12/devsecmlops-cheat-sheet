# Install WireGuard on both:
apt update && apt install wireguard -y

# Generate Keys on both:
wg genkey | tee privatekey | wg pubkey > publickey


# Configure Server A (/etc/wireguard/wg0.conf):
[Interface]
PrivateKey = <Server_A_Private_Key>
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <Server_B_Public_Key>
Endpoint = 2.2.2.2:51820
AllowedIPs = 10.0.0.2/32

# Configure Server B (/etc/wireguard/wg0.conf):
[Interface]
PrivateKey = <Server_B_Private_Key>
Address = 10.0.0.2/24
ListenPort = 51820

[Peer]
PublicKey = <Server_A_Public_Key>
Endpoint = 1.1.1.1:51820
AllowedIPs = 10.0.0.1/32

# Start the tunnel
systemctl enable --now wg-quick@wg0

# connect the cluster
curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip=10.0.0.1 \
  --advertise-address=10.0.0.1 \
  --flannel-iface=wg0

curl -sfL https://get.k3s.io | K3S_URL=https://10.0.0.1:6443 \
  K3S_TOKEN=<TOKEN> sh -s - agent \
  --node-ip=10.0.0.2 \
  --flannel-iface=wg0

# Defence against quantum brute force attempts
# this is the preshared key we generate on the secure laptop or device
wg genpsk > preshared.key

# we add this peer preshared key to both servers
[Peer]
PresharedKey = <Contents_of_preshared.key>

# add a heartbeat so that wireguard will never sleep
[Peer]
PersistentKeepalive = 25