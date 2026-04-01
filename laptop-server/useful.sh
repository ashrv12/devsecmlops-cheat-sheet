sudo apt install lm-sensors
sudo sensors-detect  # Follow the prompts
watch sensors        # Monitor temperatures in real-time

sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

sudo nano /etc/systemd/logind.conf

# Change these three options and uncomment them from the /etc/systemd/logind.conf
# HandleLidSwitch=ignore
# HandleLidSwitchExternalPower=ignore
# LidSwitchIgnoreInhibited=no

# then restart
sudo systemctl restart systemd-logind

