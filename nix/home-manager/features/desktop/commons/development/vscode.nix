# https://nixos.wiki/wiki/VSCodium
# Available nix VS extensions https://github.com/NixOS/nixpkgs/blob/nixos-22.11/pkgs/applications/editors/vscode/extensions/default.nix
{ config, pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      golang.go
      gruntfuggly.todo-tree
      yzhang.markdown-all-in-one
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "better-comments";
        publisher = "aaron-bond";
        version = "3.0.2";
        sha256 = "sha256-hQmA8PWjf2Nd60v5EAuqqD8LIEu7slrNs8luc3ePgZc=";
      }
      {
        name = "filewatcher";
        publisher = "appulate";
        version = "1.1.7";
        sha256 = "sha256-D6Oh/JIYgaCX/sYC5TnKQj/af4KniVVVTfgmrYm6ueA=";
      }
      {
        name = "vscode-taskexplorer";
        publisher = "spmeesseman";
        version = "2.9.1";
        sha256 = "sha256-m/9wtfNbLKakB5ewOKTgnmQlQbD8804p1a4o4u0+zAk=";
      }
      {
        name = "signageos-vscode-sops";
        publisher = "signageos";
        version = "0.6.1";
        sha256 = "sha256-fHXiIfc+EXGzR1nl9x87nyKVvLGS1zW6hV5D0CxvUCg=";
      }
    ];

    userSettings = {
      "editor.fontFamily" = "'Source Code Pro','Droid Sans Mono', 'monospace', monospace, 'Droid Sans Fallback'";
      "explorer.confirmDragAndDrop" = false;
      "explorer.confirmDelete" = false;
      "workspace-manager.includeGlobPattern" = [
        "~/private"
        "~/work"
      ];
      "git.confirmSync" = false;
      "workbench.editorAssociations" = {
        "*.ipynb" = "jupyter-notebook";
      };
      "yaml.customTags" = [
        "!encrypted/pkcs1-oaep scalar"
        "!vault scalar"
      ];
      "git.suggestSmartCommit" = false;
      "workbench.editor.focusRecentEditorAfterClose" = false;
      "workbench.editor.highlightModifiedTabs" = true;
      "pico8vscodeeditor.pico8fullpath" = "/usr/local/bin/pico8";
      "workbench.colorCustomizations" = {
        "[Default Dark+]" = {
          "tab.activeBackground" = "#2D4D2D";
        };
      };
      "vscodeGoogleTranslate.preferredLanguage" = "French";
      "tabnine.experimentalAutoImports" = true;
      "emeraldwalk.runonsave" = {
        "commands" = [
          {
            "match" = "\\.nix$";
            "cmd" = "echo 'I am a .txt file \${file}.'";
          }
        ];
      };
      "diffEditor.ignoreTrimWhitespace" = false;
    };
  };
}

