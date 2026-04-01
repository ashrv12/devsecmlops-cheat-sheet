# CS2 server setup

Before we begin with the setup we need a steam game server manager token. Which you can obtain from [here](https://steamcommunity.com/dev/managegameservers).

## Installation

1. When running it from the terminal we begin by creating our server folder.

```bash
mkdir cs2-server && cd cs2-server
```

2. We need to create a docker-compose.yml file for the cs2 server + mysql.

```bash
vim docker-compose.yml
```

```yaml
services:                                               # Add local console for docker attach, docker attach --sig-proxy=false cs2-dedicated
  cs2-server:
    image: joedwards32/cs2
    container_name: cs2-server
    environment:
      # Server configuration
      - SRCDS_TOKEN=[YOUR TOKEN HERE]                   # Retrieve your token here with the game id '730': https://steamcommunity.com/dev/managegameservers 
      - STEAMAPPVALIDATE=0                              # (0 - no validation, 1 - enable validation)
      - CS2_SERVERNAME="myserver"
      - CS2_PW=1234                                     # add your server password
      - CS2_CHEATS=0                                    # (0 - disable cheats, 1 - enable cheats)
      - CS2_PORT=27015                                  # (CS2 server listen port tcp_udp)
      - CS2_RCON_PORT=28015                             # (Optional, use a simple TCP proxy to have RCON listen on an alternative port.)
      - CS2_SERVER_HIBERNATE=0                          # (Put server in a low CPU state when there are no players. 0 - hibernation disabled, 1 - hibernation enabled)
      - CS2_LAN=0                                       # (0 - LAN mode disabled, 1 - LAN Mode enabled)
      - CS2_RCONPW=changeme                             # (RCON password)
      - CS2_MAXPLAYERS=32                               # (Max players)
      - CS2_ADDITIONAL_ARGS=""                          # (Optional additional arguments to pass into cs2)
      - CS2_CFG_URL                                     # HTTP/HTTPS URL to fetch a Tar Gzip bundle, Tar or Zip archive of configuration files/mods
      # Game modes
      - CS2_GAMEALIAS                                   # (Game type, e.g. casual, competitive, deathmatch. See https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers)
      - CS2_GAMETYPE=0                                  # (Used if CS2_GAMEALIAS not defined. See https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers)
      - CS2_GAMEMODE=1                                  # (Used if CS2_GAMEALIAS not defined. See https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers)
      - CS2_MAPGROUP=mg_active                          # (Map pool. Ignored if Workshop maps are defined.)
      - CS2_STARTMAP=de_inferno                         # (Start map. Ignored if Workshop maps are defined.)
      # Workshop Maps
      - CS2_HOST_WORKSHOP_COLLECTION=3422169295         # The workshop collection to use
      - CS2_HOST_WORKSHOP_MAP=3248665045                # The workshop map to use. If collection is also defined, this is the starting map.
      # TV
      - TV_AUTORECORD=0                                 # Automatically records all games as CSTV demos: 0=off, 1=on.
      - TV_ENABLE=0                                     # Activates CSTV on server: 0=off, 1=on.
      - TV_PORT=27020                                   # Host SourceTV port
      - TV_PW=changeme                                  # CSTV password for clients
      - TV_RELAY_PW=changeme                            # CSTV password for relay proxies
      - TV_MAXRATE=0                                    # World snapshots to broadcast per second. Affects camera tickrate.
      - TV_DELAY=0                                      # CSTV broadcast delay in seconds
      # Logs
      - CS2_LOG=on                                      # 'on'/'off'
      - CS2_LOG_MONEY=0                                 # Turns money logging on/off: (0=off, 1=on)
      - CS2_LOG_DETAIL=0                                # Combat damage logging: (0=disabled, 1=enemy, 2=friendly, 3=all)
      - CS2_LOG_ITEMS=0                                 # Turns item logging on/off: (0=off, 1=on)
    depends_on:
      cs2-db:
        condition: service_healthy
        restart: true
    volumes:
      - ./cs2-data:/home/steam/cs2-dedicated            # Persistent data volume mount point inside container
    ports:
      - "27015:27015/tcp"
      - "27015:27015/udp"
      - "28015:28015"
    networks:
      - cs2-network
    stdin_open: true                                    # Add local console for docker attach, docker attach --sig-proxy=false cs2-dedicated
    tty: true                                           # Add local console for docker attach, docker attach --sig-proxy=false cs2-dedicated
  cs2-db:
    image: mysql:latest
    environment:
      MYSQL_DATABASE: 'db'
      # So you don't have to use root, but you can if you like
      MYSQL_USER: 'server'
      MYSQL_PASSWORD: 'changeme'
      MYSQL_ROOT_PASSWORD: 'changeme'
    healthcheck:
      test: ["CMD", "mysqladmin" ,"ping", "-h", "localhost"]
      timeout: 5s
      retries: 10
    ports:
      - '3306:3306'
    expose:
      - '3306'
    volumes:
      - cs2-db:/var/lib/mysql
    networks:
      - cs2-network
volumes:
  cs2-db:
networks:
  cs2-network:
    driver: bridge
    name: cs2-network
```

3. From within the cs2-server folder create a cs2-data volume folder for keeping the cs2 files on the local path.

```bash
mkdir cs2-data
```

4. IMPORTANT! You need to change the permissions to the folder volumed in the docker image.

```bash
sudo chown 1000:1000 cs2-data
```

5. Time to run the containers and download our cs2 game files.

```bash
docker compose up -d
```

We added the [-d] flag so that we don't have to watch the server run from the terminal. We can check on it here and there.

6. Check on our server to see if it is running correctly.

```bash
docker ps
```

7. Check the game server logs to see the download progress.

```bash
docker logs --tail 10 <container_id>
```

8. Find your server ip which if it's local it should be an address with [192.168.x.x], us the command below.

```bash
ip a | grep 192.168

# something like this 
# inet 192.168.1.23/24 metric 100 brd 192.168.1.255 scope global dynamic enp0s31f6
```

```sh
# FROM WITHIN CS2 AND YOU ARE RUNNING THE SERVER ON A LINUX SERVER
connect <ip_of_your_server>:27015
```

# After checking to see if the server is running and it is, we can now install mods.

1. We need to first download metamod cs2 and copy addons. Initially there is no addons folder so we just copy it.

```bash
curl -O https://mms.alliedmods.net/mmsdrop/2.0/mmsource-2.0.0-git1390-linux.tar.gz && tar -xzf mmsource-2.0.0-git1390-linux.tar.gz
```

```bash
cp addons /root/cs2-server/cs2-data/game/csgo/addons
```

2. Now after we copy metamod to the folder. There are 2 pre start scripts that we need to replace.

pre.sh

```bash
#!/bin/bash

# PRE HOOK
#  Make your customisation here
echo "pre-hook: noop"
echo "PATCHING gameinfo.ini FOR METAMOD FIX..."
bash /home/steam/cs2-dedicated/acmrs.sh
echo "METAMOD PATCH COMPLETE"
```

acmrs.sh

```bash
#!/bin/bash

TARGET_DIR="/home/steam/cs2-dedicated/game/csgo"
GAMEINFO_FILE="${TARGET_DIR}/gameinfo.gi"

if [ ! -f "${GAMEINFO_FILE}" ]; then
    echo "Error: ${GAMEINFO_FILE} does not exist in the specified directory."
    exit 1
fi

NEW_ENTRY="            Game    csgo/addons/metamod"

if grep -Fxq "$NEW_ENTRY" "$GAMEINFO_FILE"; then
    echo "The entry '$NEW_ENTRY' already exists in ${GAMEINFO_FILE}. No changes were made."
else
    awk -v new_entry="$NEW_ENTRY" '
        BEGIN { found=0; }
        // {
            if (found) {
                print new_entry;
                found=0;
            }
            print;
        }
        /Game_LowViolence/ { found=1; }
    ' "$GAMEINFO_FILE" > "$GAMEINFO_FILE.tmp" && mv "$GAMEINFO_FILE.tmp" "$GAMEINFO_FILE"

    echo "The file ${GAMEINFO_FILE} has been modified successfully. '$NEW_ENTRY' has been added."
fi
```

After creating the two files ["pre.sh", "acmrs.sh"], we will need to copy them into the [/root/cs2-server/cs2-data] folder.

```bash
cp pre.sh /root/cs2-server/cs2-data/pre.sh && cp acmrs.sh /root/cs2-server/cs2-data/acmrs.sh
```


> [!NOTE]
> Highlights information that users should take into account, even when skimming.

> [!TIP]
> there is an rsync shell file that shows an example of how to use rsync to merge folders

> [!IMPORTANT]
> Crucial information necessary for users to succeed.

> [!WARNING]
> Critical content demanding immediate user attention due to potential risks.

> [!CAUTION]
> Negative potential consequences of an action.
