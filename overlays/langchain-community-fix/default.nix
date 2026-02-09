# @tracking: workaround
# @reason: langchain-community tests have collection errors on Python 3.13
# @check: evaluate langchain-community with doCheck=true on nixos-unstable
{ ... }: _final: prev:
{
  python313Packages = prev.python313Packages.overrideScope (pyfinal: pyprev: {
    langchain-community = pyprev.langchain-community.overridePythonAttrs (old: {
      doCheck = false;
      doInstallCheck = false;
    });
  });
}
