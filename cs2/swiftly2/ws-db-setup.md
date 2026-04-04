1. Configure the Plugin's config.toml:

In your plugin's configuration file located at addons/swiftlys2/configs/plugins/WeaponSkins/config.toml, ensure the StorageBackend is set to inherit. This tells the plugin to use the global SwiftlyS2 database configuration.

```toml
[Main]
StorageBackend = "inherit"
InventoryUpdateBackend = "hook"
SyncFromDatabaseWhenPlayerJoin = false
ItemLanguages = []
```
