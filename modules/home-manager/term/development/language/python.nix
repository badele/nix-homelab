{ pkgs, ... }: {
  home.packages = with pkgs; [
    ruff
    (python313.withPackages (ps:
      with ps; [
        pip
        requests

        # Used by VIDE project (https://github.com/badele/vide)
        pycodestyle
        pydocstyle
        pylint
        mypy
        vulture
        mdformat
      ]))
  ];
}
