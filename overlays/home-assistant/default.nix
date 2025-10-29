{ channels, ... }: _final: prev:
{
  python3Packages = prev.python3Packages.overrideScope (_pyfinal: pyprev: {
    gtts = pyprev.gtts.overridePythonAttrs (old: {
      propagatedBuildInputs = (builtins.filter (pkgs: pkgs.pname != "click") (old.propagatedBuildInputs or [ ])) ++ [ channels.stablepkgs.python3Packages.click ];
    });
  });
}
