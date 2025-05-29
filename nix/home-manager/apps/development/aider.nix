{ pkgs, ... }:

# Use my-aider command instead of aider-chat

{
  home.packages = [ pkgs.aider-chat-full ];

  programs.git = { ignores = [ ".aider*" ]; };

  home.file = {
    ".aider.conf.yml" = {
      source = (pkgs.formats.yaml { }).generate "aider.conf.yml" {
        dark-mode = true;
        git = false;
        auto-commits = false;
        dirty-commits = false;

        # List models with `my-aider-models` command
        model = "openai/claude-sonnet-4";
        weak-model = "openai/gpt-4.1";
        show-model-warnings = false;
      };
    };

    ".aider.model.settings.yml" = {
      source = (pkgs.formats.yaml { }).generate "aider.model.settings.yml" [
        {
          name = "openai/claude-sonnet-4";
          edit_format = "diff";
          weak_model_name = "openai/gpt-4.1";
          use_repo_map = true;
          overeager = true;

          extra_params = {
            extra_headers = {
              Editor-Version = "Aider/0.83";
              Copilot-Integration-Id = "vscode-chat";
            };
          };
        }
        {
          name = "openai/gpt-4.1";
          edit_format = "diff";
          weak_model_name = "openai/gpt-4.1";
          use_repo_map = true;
          overeager = true;

          extra_params = {
            extra_headers = {
              Editor-Version = "Aider/0.83";
              Copilot-Integration-Id = "vscode-chat";
            };
          };
        }
      ];
    };
  };
}
