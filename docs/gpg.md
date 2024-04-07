# gpg

## debugging GPG commit error


### gpg failed to sign the data

Generally you

```
error: gpg failed to sign the data:
[GNUPG:] KEY_CONSIDERED 00F421C4C5377BA39820E13F6B95E13DE469CC5D 1
gpg: skipped "00F421C4C5377BA39820E13F6B95E13DE469CC5D": Unusable secret key
[GNUPG:] INV_SGNR 9 00F421C4C5377BA39820E13F6B95E13DE469CC5D
[GNUPG:] FAILURE sign 54
gpg: signing failed: Unusable secret key
```

### GPG pine problem ?

With below command, you can verify if you can sign the text

```shell
echo "test" | gpg --clearsign
```

Verify if the GPG ID is same of your private GPG key

```
GIT_TRACE=1 git commit
gpg --status-fd=2 -bsau $(GIT_TRACE=1 gc commit 2>&1 | sed -n -e 's/^.*\-bsau //p')
```
