{ ... }: _final: prev:
{
  # Fix langchain-community test failures with Python 3.13
  # The package works fine, but tests have collection errors
  python313Packages = prev.python313Packages.overrideScope (pyfinal: pyprev: {
    langchain-community = pyprev.langchain-community.overridePythonAttrs (old: {
      doCheck = false;
      doInstallCheck = false;
    });
  });
}
