# Quick guide on how to harden and secure your public facing brand new server

1. Always update all of your system packages, since stale packages are the number 1 vector of attack.

```bash
sudo apt update && sudo apt upgrade -y
```

2. The most common attack you will see is a "brute force" attack on Port 22. You need to make this impossible to succeed.

```bash
adduser myuser             # Follow prompts for password
usermod -aG sudo myuser    # Grant admin rights
su - myuser                # Switch to new user to test
```

3. Set up SSH Keys On your local machine (not the server), generate a key if you haven't already and copy it to the server.

```bash
# On your LOCAL computer
ssh-copy-id myuser@<your-server-ip>
```

4. Harden SSH Configuration Edit the SSH config file on the server:

```bash
sudo vim /etc/ssh/sshd_config
```

```bash
# Find and change these lines to strictly disable password logins and root login:

PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
```

5. Save and exit. Restart SSH:

> [!WARNING]
> Warning: Do not close your current terminal session until you verify you can log in with a new terminal window using your SSH key.

```bash
sudo systemctl restart ssh
```

6. Configure the Firewall (UFW)

> [!INFO]
> You want a "Default Deny" policy. This means everything is blocked unless you explicitly allow it.

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (Port 22)
sudo ufw allow 22/tcp

# Allow HTTPS (Port 443)
sudo ufw allow 443/tcp

# Allow HTTP (Port 80)
# Note: Even if you only use HTTPS, you usually need port 80 open
# so your Ingress Controller can redirect HTTP -> HTTPS or solve ACME (Let's Encrypt) challenges.
sudo ufw allow 80/tcp
```

7. Allow Kubernetes pod to pod networking:

```bash
# Allow traffic from the server to itself (localhost/internal IPs)
sudo ufw allow from 127.0.0.1 to any

# localhost
sudo ufw allow in on lo
sudo ufw allow out on lo

# allow pod veth interfaces
sudo ufw allow in on cali+
sudo ufw allow out on cali+


# this
kubectl cluster-info dump | grep -m1 -E "cluster-cidr|service-cluster-ip-range"
# or that
kubectl get cm -n kube-system calico-config -o yaml
# sample
CALICO_IPV4POOL_CIDR=10.1.0.0/16

# also for services
kubectl get svc kubernetes -o wide
# sample
Service CIDR: 10.152.183.0/24

# node to node vxlan (cluster situation)
4789/udp
```

> [!WARNING]
> Mandatory UFW rules for MicroK8s

```bash
# Pod network
sudo ufw allow from 10.1.0.0/16
sudo ufw allow to   10.1.0.0/16

# Service IPs
sudo ufw allow from 10.152.183.0/24
sudo ufw allow to   10.152.183.0/24

# Node-to-node VXLAN
sudo ufw allow 4789/udp

# Kubernetes control plane
sudo ufw allow 16443/tcp
sudo ufw allow 10250/tcp

# DNS inside cluster
sudo ufw allow 53
sudo ufw allow 9153/tcp
```

> [!INFO]
> Multinode cluster within a LAN.
> Must allow the following.

```bash
sudo ufw allow from 192.168.0.0/16
sudo ufw allow to   192.168.0.0/16
```
