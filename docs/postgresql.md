## Issues

### WARNING: database "XXX" has a collation version mismatch

**Error**

```text
WARNING:  database "<DBNAME>" has a collation version mismatch
DETAIL:  The database was created using collation version 2.40, but the operating system provides version 2.42.
HINT:  Rebuild all objects in this database that use the default collation and run ALTER DATABASE <DBNAME> REFRESH COLLATION VERSION, or build PostgreSQL with the right library version.
```

**Fix**

```bash
sudo -u postgres psql DBNAME -c "\\c"
sudo -u postgres psql DBNAME -c "REINDEX DATABASE <DBNAME>"
sudo -u postgres psql DBNAME -c "REFRESH COLLATION VERSION"
```
