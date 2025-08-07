{ ... }: _final: prev: {
  python3Packages = prev.python3Packages.overrideScope (_f: p: {
    pgvector = p.pgvector.overridePythonAttrs (_old: {
      doCheck = false;
      doInstallCheck = false;
    });
  });
}
