3. Where are Workshop Maps saved?
In CS2, workshop maps are handled differently than CS:GO. They are no longer tucked away in a simple maps/workshop folder by default.

Location: They are typically stored in:
.../game/csgo/maps/workshop/<MAP_ID>/<MAP_NAME>.vpk

The "Shared" Problem: If you use CS2_HOST_WORKSHOP_MAP in your environment variables, the server will try to download them into the /home/steam/cs2-dedicated/... path.

The Fix: Since your base game is Read-Only, the download will fail. You have two choices:

Shared Maps: Mount a shared writable maps folder to all three servers:
- /opt/cs2-servers/shared-maps:/home/steam/cs2-dedicated/game/csgo/maps/workshop:rw
Benefit: If Server A downloads "de_dust2_workshop", Server B can use it instantly without re-downloading.

Instance Maps: Map a unique workshop folder for each (better if they use totally different maps):
- /opt/cs2-servers/scrim-5v5/maps:/home/steam/cs2-dedicated/game/csgo/maps/workshop:rw

Important Setup Tip
To get the Base Game files in the first place, you must run one container without the :ro flag initially.

Start one container with /opt/cs2-servers/base-game as :rw.

Let it finish the 30GB+ download.

Stop it, change the mount to :ro in your Compose file, and spin up all three.

/opt/cs2-servers/
├── base-game/               # One 30GB install (Shared, Read-Only)
├── scrim-5v5/               # Server 1 Instance Files
│   ├── cfg/
│   └── addons/swiftly/      # Scrim plugins & Swiftly DB
├── warmup-dm/               # Server 2 Instance Files
│   ├── cfg/
│   └── addons/swiftly/      # DM plugins & Swiftly DB
└── one-v-one/               # Server 3 Instance Files
    ├── cfg/
    └── addons/swiftly/      # 1v1 plugins & Swiftly DB
