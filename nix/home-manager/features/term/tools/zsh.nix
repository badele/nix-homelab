# ███████╗███████╗██╗  ██╗
# ╚══███╔╝██╔════╝██║  ██║
#   ███╔╝ ███████╗███████║
#  ███╔╝  ╚════██║██╔══██║
# ███████╗███████║██║  ██║
# ╚══════╝╚══════╝╚═╝  ╚═╝

# https://unix.stackexchange.com/a/71258/41707
# 1) .zshenv is always sourced. It often contains exported variables that should be available to other programs. For example, $PATH, $EDITOR, and $PAGER are often set in .zshenv. Also, you can set $ZDOTDIR in .zshenv to specify an alternative location for the rest of your zsh configuration.
# 2) .zprofile is for login shells. It is basically the same as .zlogin except that it's sourced before .zshrc whereas .zlogin is sourced after .zshrc. According to the zsh documentation, ".zprofile is meant as an alternative to .zlogin for ksh fans; the two are not intended to be used together, although this could certainly be done if desired."
# 3) .zshrc is for interactive shells. You set options for the interactive shell there with the setopt and unsetopt commands. You can also load shell modules, set your history options, change your prompt, set up zle and completion, et cetera. You also set any variables that are only used in the interactive shell (e.g. $LS_COLORS).
# 4) .zlogin is for login shells. It is sourced on the start of a login shell but after .zshrc, if the shell is also interactive. This file is often used to start X using startx. Some systems start X on boot, so this file is not always very useful.
# 5) .zlogout is sometimes used to clear and reset the terminal. It is called when exiting, not when opening.

{ config, pkgs, lib, ... }:
let
  xprop = "${pkgs.xorg.xprop}/bin/xprop";
in
{
  imports = [
  ];

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      dotDir = ".config/zsh";

      history = {
        size = 100000;
        save = 100000;
        share = true;
        extended = true;
        ignoreDups = true;
        ignoreSpace = true;
        expireDuplicatesFirst = true;
        path = "${config.xdg.dataHome}/zsh/zsh_history";
      };

      oh-my-zsh = {
        enable = true;
        plugins = [
          "gcloud"
          "gpg-agent"
          "direnv"
          "fzf"
          "grc"
          "golang"
          "sudo"
          "docker"
          "ripgrep"
          "fd"
          "kubectl"
          "helm"
          "terraform"
          "pass"
          "history-substring-search"
        ];
      };

      plugins = [
        {
          name = "zsh-fast-syntax-highlighting";
          src = pkgs.zsh-fast-syntax-highlighting;
          file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
        }
      ];

      profileExtra = ''
        setopt no_beep                                              # no beep
        setopt rm_star_wait                                             # wait 10 seconds before running `rm *`
        setopt hist_ignore_dups                                         # ignore history duplication
        setopt hist_expire_dups_first                                   # remove oldest duplicate commands from the history first
        setopt hist_ignore_space                                        # don't save commands beginning with spaces to history
        setopt append_history                                           # append to the end of the history file
        setopt inc_append_history                                       # always be saving history (not just when the shell exits)
        setopt no_flowcontrol                                          # Disable ^S and ^Q (freeze & resume flowcontro)

        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'       # Case insensitive tab completion
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"       # Colored completion (different colors for dirs/files/etc)
        zstyle ':completion:*' rehash true                              # automatically find new executables in path

        # Speed up completions
        mkdir -p "$(dirname ~/.cache/zsh/completion-cache)"
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "~/.cache/zsh/completion-cache"
        zstyle ':completion:*' accept-exact '*(N)'
        zstyle ':completion:*' menu select

        function _calc_latency() {
            FIBER_SPEED=200000000

            if [ -z $1 ]; then
                echo "Usage: $0 <Distance Km>"
                return 1
            fi

            RESULT=$(eva "$${1}*1000/$${FIBER_SPEED}*1000*2") # Meters * lightspeed * 1000 ms * 2 (round trip)
            echo "$RESULT ms"
        }

        ##############################################################################
        # broot
        ##############################################################################

        # Wallpapers selector
        function brw () {
         br -c ":gw"
        }

        # Filter
        function brf () {
         br -h -c "/$1"
        }

        # Load some files if exists
        test -d "~/.kube" && export KUBECONFIG=$(ls -1 ~/.kube/*.yml | tr " " ":") # Kubernetes contexts
        test -f ~/.nix-profile/etc/grc.zsh  && source ~/.nix-profile/etc/grc.zsh
      '';

      initExtra = ''
        ##############################################################################
        # keys binding
        ##############################################################################

        # Fix zoxide widget (register widget for CTRL+J shortcut)
        function fzf-zoxide() {
          eval "ji"
          zle accept-line
        }
        zle -N fzf-zoxide

        # FZF & Z
        bindkey "^R"     fzf-history-widget ## [CTRL-R] Show FZF histories
        bindkey "^T"     fzf-file-widget ## [CTRL-T] Show FZF files
        bindkey "^F"     fzf-cd-widget ## [CTRL-F] Goto FZF selected folder
        bindkey "^J"    fzf-zoxide ## [CTRL-J] zoxide autojump ZFS list
        bindkey "^G"    _navi_widget ## [CTRL-G] Show local navi
      '';

      shellAliases = with pkgs;{
        # Nix
        nfmt = "nixpkgs-fmt .";
        ns = "nix-shell";
        nsp = "nix-shell --pure";

        # My tools
        calc_latency = "_calc_latency"; ## Compute approximatively internet latency
        toclipboard = "${xclip} -selection clipboard"; ## Copy output to clipboard
        get_i3_window_name = "${xprop} | grep CLASS | cut -d\",\" -f2 | sed 's/\"//g'";

        # Tools
        calc = "eva"; ## launch calc computing (eva)
        fd = "fd"; ## find files alternative (fd)
        pup = "up"; ## pipe output (we can run linux command in realtime)
        diga = "dog A CNAME MX TXT AAAA NS"; ## dig DNS resolution alternative (dog)
        dig = "dog A"; ## dig DNS resolution alternative (dog)
        hexyl = "hexyl --border none"; ## hexdump alternative
        #br="broot"; ## File manager        

        # ZSH
        my-zkeys = "cat $HOME/.config/zsh/.zprofile | grep -Eo '# \[.*' | sed 's/# //g'";

        # ps & top  alternative
        psc = "procs --sortd cpu";
        psm = "procs --sortd mem";
        psr = "procs --sortd read";
        psw = "procs --sortd write";

        topc = "procs -W 1 --sortd cpu";
        topm = "procs -W 1 --sortd mem";
        topr = "procs -W 1 --sortd read";
        topw = "procs -W 1 --sortd write";

        # Disk size
        dua = "dua i"; ## | Interactive disk size(dua)
        dut = "dust"; ## | Show tree disk size (ordered by big file) (dust)

        # SSH
        sk = "sh -o StrictHostKeyChecking=no"; ## ssh without host verification        

        # cat alternative
        cat = "bat --style=plain"; ## cat alternative (bat)

        # ls alternative
        la = "exa --color=always -a";
        ll = "exa --color=always -alh";
        ls = "exa --color=always";

        # Folder
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        cdw = "cd ${config.programs.zsh.sessionVariables.WORK}";
        cdp = "cd ${config.programs.zsh.sessionVariables.PRIVATE}";
        cdg = "cd ~/ghq";
        cdb = "cd ~/ghq/github.com/badele";
        cdn = "cd ~/ghq/github.com/badele/nix-config";

        # git
        gs = "git status"; ## git status
        gl = "git log"; ## git log
        gd = "git diff"; ## git diff
        gds = "git diff --staged"; ## git diff
        gcb = "git checkout";
        gbl = "git branch"; ## git branch
        gbm = "git blame"; ## git blame
        ga = "git add"; ## git add
        gc = "git commit -m"; ## git commit
        gss = "git stash"; ## git stash
        gsl = "git stash list"; ## git stash list
        gsp = "git stash pop"; ## git stash pop
        gpl = "git pull"; ## git pull
        gph = "git push"; ## git push

        # yadm
        ys = "yadm status"; ## yadm status
        yl = "yadm log"; ## yadm log
        yd = "yadm diff"; ## yadm diff
        yds = "yadm diff --staged"; ## yadm diff
        ybl = "yadm branch"; ## yadm branch
        ybm = "yadm blame"; ## yadm blame
        ya = "yadm add"; ## yadm add
        yc = "yadm commit -m"; ## yadm commit
        ypl = "yadm pull"; ## yadm pull
        yph = "yadm push"; ## yadm push

        # pass
        pps = "pass git status"; ## pass status
        pl = "pass git log"; ## pass log
        pd = "pass git diff"; ## pass diff
        pds = "pass git diff"; ## pass diff
        pbl = "pass git branch"; ## pass branch
        pbm = "pass git blame"; ## pass blame
        pa = "pass git add"; ## pass add
        pc = "pass git commit -m"; ## pass commit
        ppl = "pass git pull"; ## pass pull
        pph = "pass git push"; ## pass push

        # Trash
        # rm="${trash-put}"; ## alternative rm (push file to trash)
        # trm="${trash-put}"; ## push file to trash
        # tls="${trash-list}"; ## list trash files
        # tre="${trash-restore}"; ## restore file from trash
        # tem="${trash-empty}"; ## delete all files from trash

        # Cloud & co
        #unalias kubectl # Disable clourify for using P10K plugin
        a = "aws"; ## aws alias
        g = "gcloud"; ## gcloud alias
        k = "kubectl"; ## kubectl alias
        kcc = "kubectl config current-context";
        h = "helm"; ## helm alias

        vim = "nvim"; ## alternative vim (nvim)

        # navi
        lnavi = "navi --path $PRIVATE/cheats"; ## Show cheat commands
        lpnavi = "navi --print --path $PRIVATE/cheats"; ## Show cheat commands

        # Date & Time
        clock = "peaclock --config-dir ~/.config/peaclock"; ## Show terminal clock

        # Color
        grep = "grep --color=auto";
        ip = "ip -color=auto";
      };

      sessionVariables = {

        # NixOS experimental support
        NIX_CONFIG = "extra-experimental-features = nix-command flakes repl-flake";

        PATH = lib.concatStringsSep ":" [
          "${config.home.homeDirectory}/.local/bin"
          "\${PATH}"
        ];

        TERMINAL = "${pkgs.wezterm}/bin/wezterm";
        EDITOR = "${pkgs.neovim}/bin/nvim";

        # Private folderss
        WORK = "${config.home.homeDirectory}/work/projects";
        PRIVATE = "${config.home.homeDirectory}/private/projects";

        # Colors
        GREP_COLORS = "ms=01;31:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36";

        # less & Man color
        LESS_TERMCAP_mb = "\$(tput bold; tput setaf 2)"; # green
        LESS_TERMCAP_md = "\$(tput bold; tput setaf 6)"; # cyan
        LESS_TERMCAP_me = "\$(tput sgr0)";
        LESS_TERMCAP_so = "\$(tput bold; tput setaf 3; tput setab 4)"; # yellow on blue
        LESS_TERMCAP_se = "\$(tput rmso; tput sgr0)";
        LESS_TERMCAP_us = "\$(tput smul; tput bold; tput setaf 4)"; # purple
        LESS_TERMCAP_ue = "\$(tput rmul; tput sgr0)";
        LESS_TERMCAP_mr = "\$(tput rev)";
        LESS_TERMCAP_mh = "\$(tput dim)";
        LESS_TERMCAP_ZN = "\$(tput ssubm)";
        LESS_TERMCAP_ZV = "\$(tput rsubm)";
        LESS_TERMCAP_ZO = "\$(tput ssupm)";
        LESS_TERMCAP_ZW = "\$(tput rsupm)";

        # TODO
        # GNUPGHOME="${config.xdg.configHome}/gnupg";

        # # GPG
        # export SSH_AUTH_SOCK=$(gpgconf –list-dirs agent-ssh-socket)
        # export GPG_USERID=00F421C4C5377BA39820E13F6B95E13DE469CC5D
        # export GPG_BACKUP_DIR=/mnt/usb-black-disk/freefilesync/famille/bruno/home/security/gpg
        # export TELEPORT_USE_LOCAL_SSH_AGENT="false"

        # # AGE
        # export AGE_PUBLIC_KEY="age1xmunmxy9u93gclsc962ctcswawa8w73vqjwe0csykhwth46qpv3qun3657"
        # export AGE_PRIVATE_FILE="~/.age/secret-key.txt"
      };

    };
  };
}
