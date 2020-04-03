{ nixpkgs ? import <nixpkgs> {}}:
let
  pkgs = nixpkgs // { config.allowUnfree = true; };
in
pkgs.callPackage ./default.nix { }