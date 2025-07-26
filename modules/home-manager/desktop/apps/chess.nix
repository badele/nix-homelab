# Graphics
{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Game
    pychess # Chess game

    # Database
    chessx # Chess database application
    scid-vs-pc # Chess database application

    # Engine
    stockfish # Strong open-source chess engine
    lc0 # Neural network based chess engine

    # TUI
    chess-tui
  ];
}
