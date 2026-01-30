# Nix

## nix-repl

### Show and debug NixosConfigurations

```bash
just debug-repl
```

### Show all values

Lors d'un `just debug-repl` si vous obtenez des résultats de la forme suivante

```ŧext
[
  { ... }
  { ... }
]
```

Vous pouvez utiliser l'option `:p` afin d'afficher tous les attributs

```bash
just debug-repl
:p NixosConfigurations.xxx.xxx
```

Vous pouvez égallement évaluer avec la commande suivante

```bash
nix eval .#nixosConfigurations.xxx.xxx

## Content and file managment

### Convert nix attribute to file

```
varname = "${pkgs.writeText "<filename>" (builtins.toJSON <attrname>)}";
```

### Write to /etc folder

```
environment.etc."installed-packages".text =
'''
content
''';
```

### Get remote file

```
objname = pkgs.writeText "filename.yml" (
  builtins.readFile (
    builtins.fetchurl {
      url = "https://raw.githubusercontent.com/Kerwood/snmp-exporter-mikrotik/master/snmp.yml";
      sha256 = "sha256-11pmg9z0w7jzlwfgplmd6dvy559pvj1lp024jvbsqddsajfbmqcd";
    }
  )
);
```

## Debug content

### values

```
{...}:
let
    mylist = [ "avalue" "bvalue" ]
in
{
  msg = lib.trace mylist 1;
}
```

### Set

```
{...}:
let
    myset = {a = "avalue"; b = "bvalue";}
in
{
  msg = lib.trace ( builtins.toJSON myset ) 1;
}
```

## Change executable permission without change it

allows adding setuid/setgid bits, capabilities, changing file ownership and
permissions of a program without directly modifying it.

```
{
  # a setuid root program
  doas =
    { setuid = true;
      owner = "root";
      group = "root";
      source = "${pkgs.doas}/bin/doas";
    };

  # a setgid program
  locate =
    { setgid = true;
      owner = "root";
      group = "mlocate";
      source = "${pkgs.locate}/bin/locate";
    };

  # a program with the CAP_NET_RAW capability
  ping =
    { owner = "root";
      group = "root";
      capabilities = "cap_net_raw+ep";
      source = "${pkgs.iputils.out}/bin/ping";
    };
}
```
