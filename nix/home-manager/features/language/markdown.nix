{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Markdown
    marksman
    nodePackages.markdownlint-cli
  ];
}
