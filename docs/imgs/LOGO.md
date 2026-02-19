# nix-homelab logo

## generate

```bash
nix shell github:badele/splitans nixpkgs#chafa nixpkgs#bit-logo nixpkgs#ansilove

chafa -f symbols --symbols "[ █▄■▀]"  --colors none  --size 120 --font-ratio 0.5 -w 1  nix-homelab-logo.png --invert > logo.ans
bit -font 8bitfortress  -scale -1 "NIX HOMELAB" >> logo-utf8.ans
splitans -W 120 logo-utf8.ans > logo.neo
splitans -f neotex -E cp437 -F ansi -S logo.neo > logo.ans
ansilove -S -o nix-homelab-logo.png logo.ans
```

## Source

- Tools
  - [ansilove](https://github.com/ansilove/ansilove)
  - [chafa](https://github.com/hpjansson/chafa)
  - [bit](https://github.com/superstarryeyes/bit)
  - [icy_draw](https://github.com/mkrueger/icy_tools)

```
```
