[Interface]
PrivateKey = <Router_Private_Key>
Address = 10.0.0.1/24
ListenPort = 51820
# Crucial: Enable packet forwarding in Linux
# sysctl -w net.ipv4.ip_forward=1

[Peer] # Node 1
PublicKey = <Node_1_Pub>
AllowedIPs = 10.0.0.11/32

[Peer] # Node 2
PublicKey = <Node_2_Pub>
AllowedIPs = 10.0.0.12/32

# ... repeat for all nodes