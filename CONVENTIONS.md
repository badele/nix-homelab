## Nix

### Content format creation

- Convert nix attributes to JSON `(builtins.toJSON <ATTRNAME>)`
- Convert nix attributes to YAML `(pkgs.formats.yaml { }).generate "SOMETHING"`
- write text content to nix variable
  `VARNAME = "${pkgs.writeText "<FILENAME>" (builtins.toJSON <ATTRNAME>)}";`

### File creation

- Write to home file with `home.file.<FILENAME>` nix function
- Write to /etc with `environment.etc."<FILENAME>".text = ''content'';`
