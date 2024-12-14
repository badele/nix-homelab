# Graphics
{ pkgs, ... }: {
  home.packages = with pkgs; [
    curl # HTTP client
    httpie # Curl alternative
    wget # HTTP client
  ];
}
