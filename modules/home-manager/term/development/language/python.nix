{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pipenv
    poetry
    ruff
    uv

    (python313.withPackages (
      ps: with ps; [
        pip
        requests

        # Used by VIDE project (https://github.com/badele/vide)
        pycodestyle
        pydocstyle
        pylint
        mypy
        vulture
        mdformat

        # Used by IDEM project (https://github.com/badele/idem)
        black
        pyflakes
        pytest
      ]
    ))
  ];
}
