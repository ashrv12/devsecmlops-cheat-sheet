# Find the storage
lsblk

| Device           | Mount Point                  | Type      | Size       | Likely Use           |
| ---------------- | ---------------------------- | --------- | ---------- | -------------------- |
| `nvme0n1` (SSD)  | `/` (root), `/home`, `/boot` | fast SSD  | ~890 GB    | OS + apps            |
| `sda` (HDD, LVM) | `/mnt/DATA`                  | large HDD | **5.8 TB** | general data storage |

# Create the data directory
sudo mkdir -p /mnt/DATA/ollama-data
sudo chmod 777 /mnt/DATA/ollama-data

# create ollama-system namespace
microk8s kubectl create ns ollama-system