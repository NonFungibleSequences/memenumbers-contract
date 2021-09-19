with (import <nixpkgs> { });
let
  pkgs = import (builtins.fetchGit rec {
    name = "dapptools-${rev}";
    url = https://github.com/dapphub/dapptools;
    rev = "07ebf6437551b2474cdafbf0e2f102c3008f3423"; # Sept 8, 2021 - hevm/0.48.1
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
