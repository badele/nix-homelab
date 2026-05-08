{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pipenv
    poetry
    ty
    uv
    ruff
    (python313.withPackages (
      ps: with ps; [
        pip
        requests

        # Used by VIDE and IDEM project
        # - https://github.com/badele/vide
        # - https://github.com/badele/idem
        black
        mdformat
        mypy
        pycodestyle
        pydocstyle
        pyflakes
        pylint
        pytest
        vulture
      ]
    ))
  ];
}
