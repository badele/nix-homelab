{ lib, pkgs, ... }:
{

  # Install the emacs configuration from this https://github.com/badele/idem#quick-install repository
  programs.emacs.enable = true;

  services.emacs = {
    enable = true;
    client.enable = true;
    defaultEditor = true;
  };

  home.activation.installIdemConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    IDEM_REPO_URL="https://github.com/badele/idem"
    IDEM_REPO_PATH="$HOME/ghq/github.com/badele/idem"
    IDEM_STATE_DIR="$HOME/.local/state/idem"
    IDEM_BOOTSTRAP_MARKER="$IDEM_STATE_DIR/doom-bootstrap.done"
    IDEM_BOOTSTRAP_LOG="$IDEM_STATE_DIR/doom-bootstrap.log"
    export PATH="${
      lib.makeBinPath [
        pkgs.bash
        pkgs.coreutils
        pkgs.emacs
        pkgs.findutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.gawk
        pkgs.git
      ]
    }:$PATH"

    if [ ! -d "$IDEM_REPO_PATH/.git" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "$HOME/ghq/github.com/badele"
      ${pkgs.git}/bin/git clone "$IDEM_REPO_URL" "$IDEM_REPO_PATH"
    fi

    if [ ! -f "$IDEM_BOOTSTRAP_MARKER" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "$IDEM_STATE_DIR"

      if [ ! -x "$IDEM_REPO_PATH/bootstrap/doom-install.sh" ]; then
        echo "WARNING: bootstrap/doom-install.sh not found or not executable in $IDEM_REPO_PATH" >&2
      elif (cd "$IDEM_REPO_PATH" && PAGER=cat DOOMPAGER=cat ./bootstrap/doom-install.sh >"$IDEM_BOOTSTRAP_LOG" 2>&1); then
        ${pkgs.coreutils}/bin/touch "$IDEM_BOOTSTRAP_MARKER"
      else
        echo "WARNING: doom bootstrap failed; see $IDEM_BOOTSTRAP_LOG" >&2
      fi
    fi
  '';

  # All neovim plugins list from the https://github.com/badele/idem project
  home.packages = with pkgs; [
    # Language support packages are now in separate files:
    # - nix/home-manager/features/language/ansible.nix
    # - nix/home-manager/features/language/bash.nix
    # - nix/home-manager/features/language/c.nix
    # - nix/home-manager/features/language/d2.nix
    # - nix/home-manager/features/language/go.nix
    # - nix/home-manager/features/language/javascript.nix
    # - nix/home-manager/features/language/latex.nix
    # - nix/home-manager/features/language/ledger.nix
    # - nix/home-manager/features/language/lua.nix
    # - nix/home-manager/features/language/markdown.nix
    # - nix/home-manager/features/language/nix.nix
    # - nix/home-manager/features/language/openscad.nix
    # - nix/home-manager/features/language/python.nix
    # - nix/home-manager/features/language/rust.nix
    # - nix/home-manager/features/language/scala.nix
    # - nix/home-manager/features/language/terraform.nix
    # - nix/home-manager/features/language/yaml.nix
  ];
}
