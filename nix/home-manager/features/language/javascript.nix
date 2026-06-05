{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # JavaScript/TypeScript
    nodejs
    yarn
    deno
    eslint
    prettier

    # JSON
    vscode-langservers-extracted
    fixjson

    # Dockerfile
    dockerfile-language-server
  ];
}
