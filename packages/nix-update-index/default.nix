{ lib
, pkgs
, namespace
, ...
}:
let
  inherit (lib.${namespace}) override-meta;

  nix-update-index = pkgs.writeShellScriptBin "nix-update-index" ''
    set -euo pipefail

    filename="index-${pkgs.system}"
    release="https://github.com/Mic92/nix-index-database/releases/latest/download/''${filename}"

    mkdir -p ~/.cache/nix-index

    pushd ~/.cache/nix-index > /dev/null

    ${pkgs.wget}/bin/wget -q -N https://github.com/Mic92/nix-index-database/releases/latest/download/$filename

    ln -f ''${filename} files

    popd > /dev/null
  '';

  new-meta = {
    description = "A helper for downloading the latest nix-index database.";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ dtgagnon ];
  };
in
override-meta new-meta nix-update-index
