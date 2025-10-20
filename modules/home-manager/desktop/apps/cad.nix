# Graphics
{ pkgs, ... }: {
  home.packages = with pkgs; [
    openscad # The Programmers Solid 3D CAD Modeller
    librecad # 2D CAD drawing tool based on the community edition of QCad
    solvespace # Parametric 2D/3D CAD
  ];
}
