# ZFS

```console
# Pool info
zfs list

# Show all encryption state
zfs get encryption

# Import pool
zpool import -f <pool>

# Rename zfz pool
zpool export <oldpool>
zpool import <oldpool> <newpool>

# Change zfs key
zfs change-key <pool>
```
