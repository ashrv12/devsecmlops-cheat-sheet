# First download the latest version of rathole from the source code releases page
# current version as of this doc is 0.5.0
https://github.com/rathole-org/rathole


# --------------------------------------------------
# PUBLIC SERVER SECTION
# --------------------------------------------------

# create the service for server
sudo vim /etc/systemd/system/rathole.service 

# paste this into the file
[Unit]
Description=Rathole Reverse Proxy
After=network.target

[Service]
Type=simple
ExecStart=/root/rathole/rathole -s /root/rathole/client.toml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target

# run it and make sure it is enabled to run on start
sudo systemctl enable --now rathole



# --------------------------------------------------
# LOCAL CLIENT SECTION
# --------------------------------------------------

# create the service for client
sudo vim /etc/systemd/system/rathole.service 

# paste this into the file on client
[Unit]
Description=Rathole Reverse Proxy
After=network.target

[Service]
Type=simple
ExecStart=/root/rathole/rathole -c /root/rathole/client.toml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target

# run it and make sure it is enabled to run on start
sudo systemctl enable --now rathole