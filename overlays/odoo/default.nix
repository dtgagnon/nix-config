{ inputs, lib, ... }: _final: prev:
let
  inherit (lib) concatMapStringsSep concatStringsSep escapeShellArg filter optionalString unique;

  addonSources =
    let
      eModsDir = "${inputs.odooAdds}/odoo_e18/addons";
    in
    if builtins.pathExists eModsDir then
      map (name: "${eModsDir}/${name}")
        (lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir eModsDir)))
    else
      [ ];

  rsyncBin = lib.getExe prev.rsync;
in
{
  odoo = prev.odoo.overrideAttrs (old:
    let
      postInstallSnippet = optionalString (addonSources != [ ]) ''
        (
          set -euo pipefail

          set -- "$out"/lib/python*/site-packages/odoo/addons
          addons_dir="$1"
          if [ -z "$addons_dir" ] || [ ! -d "$addons_dir" ]; then
            echo "odoo overlay: unable to locate addons directory under $out" >&2
            exit 1
          fi

          shopt -s nullglob

          for candidate in ${concatMapStringsSep " " (src: escapeShellArg (toString src)) addonSources}; do
            if [ ! -d "$candidate" ]; then
              continue
            fi

            if ! { [ -f "$candidate/__manifest__.py" ] || [ -f "$candidate/__openerp__.py" ]; }; then
              continue
            fi

            name="$(basename "$candidate")"
            dest="$addons_dir/$name"
            if [ -e "$dest" ]; then
              echo "odoo overlay: skipping existing addon $name" >&2
              continue
            fi

            mkdir -p "$dest"
            ${rsyncBin} -a --no-owner --no-group --chmod=u+rwX,go+rX "$candidate/" "$dest/"

            if [ "$name" = "web_responsive" ] && [ -f "$dest/__manifest__.py" ]; then
              sed -i '/"excludes"/d' "$dest/__manifest__.py"
            fi

            find "$dest" \
              -type d \( -name '.git' -o -name '__pycache__' \) -prune -exec rm -rf {} +
          done
        )
      '';

      postInstallSteps = filter (step: step != "") [
        (old.postInstall or "")
        postInstallSnippet
      ];
    in
    {
      # src = prev.fetchFromGitHub {
      #   owner = "OCA";
      #   repo = "OCB";
      #   rev = "18.0";
      #   hash = "sha256-klThuXXNMonE0ess/ChVrKSQtBKnn6dGZuaNL/k/rrI=";
      # };
      patches = (old.patches or [ ]) ++ [
        ./patches/html-editor-guard-intersection.patch
      ];
      nativeBuildInputs = unique ((old.nativeBuildInputs or [ ]) ++ [
        prev.coreutils
        prev.findutils
        prev.rsync
        prev.patch
      ]);
      postInstall = concatStringsSep "\n\n" postInstallSteps;
    }
  );
}
