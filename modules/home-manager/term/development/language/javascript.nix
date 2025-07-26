{ pkgs, ... }: {
  home.packages = with pkgs; [
    # JavaScript/TypeScript
    nodejs
    yarn
    deno
    nodePackages.eslint
    nodePackages.prettier

    # JSON
    vscode-langservers-extracted
    nodePackages.fixjson
    nodePackages.jsonlint

    # Dockerfile
    nodePackages.dockerfile-language-server-nodejs
  ];
}
