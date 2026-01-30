{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Lua
    lua51Packages.lua
    lua-language-server
    stylua
    luaformatter
    luajitPackages.luacheck
    luajitPackages.luarocks
    luajitPackages.jsregexp
    selene
  ];
}
