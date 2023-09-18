# gpg

## debugging GPG commit error

```
error: gpg failed to sign the data
fatal: failed to write commit object
```

```
GIT_TRACE=1 git commit
gpg --status-fd=2 -bsau $(GIT_TRACE=1 gc commit 2>&1 | sed -n -e 's/^.*\-bsau //p')
```
