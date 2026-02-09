# @tracking: workaround
# @reason: gtts has a click version conflict on nixos-unstable (pinned to stable click);
#          samsungtvws fails to build on nixos-unstable
# @check: evaluate gtts and samsungtvws from base nixpkgs without this overlay
{ channels, ... }: _final: prev:
{
  python3Packages = prev.python3Packages.overrideScope (_pyfinal: pyprev: {
    gtts = pyprev.gtts.overridePythonAttrs (old: {
      propagatedBuildInputs = (builtins.filter (pkgs: pkgs.pname != "click") (old.propagatedBuildInputs or [ ])) ++ [ channels.stablepkgs.python3Packages.click ];
    });
    samsungtvws = channels.masterpkgs.samsungtvws;
  });
}
