# Kanidm

> [!TIP]
> `just` supports autocompletion, you can use `TAB` for listing just `kanidm`
> commands

## User

### Creating a new user

1. Enter the `nix-homelab` project environment

2. Log in as the IDM admin

> [!NOTE]
> Password copied to clipboard, you can paste after `just kanidm-login`

```bash
just kanidm-login
```

3. Create a new user:

   Define the username, display name, and optionally an email address:

   ```bash
   just kanidm-user-add "<USERNAME>" "<DISPLAYNAME>" "[EMAIL]"
   ```

   ```
   ```

### Reset user password

```bash
just kanidm-reset-user-password "<USERNAME>"
```

## OAuth2

### List OAuth2

```bash
just kanidm-login
```

### Show basic secret

```bash
kanidm system oauth2 show-basic-secret "<OAUTHNAME>"
```
