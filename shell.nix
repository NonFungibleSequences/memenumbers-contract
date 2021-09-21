with (import <nixpkgs> { });
let
  pkgs = import (builtins.fetchGit rec {
    name = "dapptools-${rev}";
    url = https://github.com/dapphub/dapptools;
    rev = "0bccaa359e082fef842c3790cdec91dbdf17bf11"; # master @ 2021-09-12
  }) {};

in
  pkgs.mkShell {
    src = null;
    name = "dapptools-template";
    buildInputs = with pkgs; [
      pkgs.dapp
      pkgs.seth
      pkgs.go-ethereum-unlimited
      pkgs.hevm

      nodePackages.yarn
    ];
  }
