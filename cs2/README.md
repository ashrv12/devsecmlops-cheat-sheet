# CS2 server setup

## Installation

1. We need to create a docker-compose.yml file for the cs2 server + mysql

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

2. When running it from the terminal of your server make sure to put this in a folder called cs2-server

```bash
mkdir cs2-server
```

3. From within the cs2-server folder create a cs2-data volume folder for keeping the cs2 files on the local path

```bash
mkdir cs2-data
```

4. IMPORTANT! You need to chown the folder or change the permissions to the one used in the docker-image

```bash
sudo chown 1000:1000 cs2-data
```

