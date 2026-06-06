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
    # jsonlint

    # Dockerfile
    dockerfile-language-server
  ];
}
