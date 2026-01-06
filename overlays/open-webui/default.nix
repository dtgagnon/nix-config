{ ... }:
final: prev:
let
  # Use final so we pick up python package overrides from later overlays.
  pyPkgs = final.python3Packages;
  psycopgDrivers = builtins.filter (drv: drv != null) [
    (if pyPkgs ? psycopg then pyPkgs.psycopg else null)
    (if pyPkgs ? psycopg2 then pyPkgs.psycopg2 else null)
    (if builtins.hasAttr "psycopg2-binary" pyPkgs then pyPkgs."psycopg2-binary" else null)
  ];

  extendPythonAttrs =
    old:
    old
    // {
      propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ psycopgDrivers;
      pythonPath = (old.pythonPath or [ ]) ++ psycopgDrivers;
    };
in
{
  # open-webui declares a runtime dep on rapidocr-onnxruntime which is not packaged.
  # Disable runtime dep checks; also try to strip the dep if present.
  # Handle both top-level package and python3Packages variant just in case.
  open-webui = prev.open-webui.overrideAttrs (
    old:
    extendPythonAttrs (
      old
      // {
        pythonRuntimeDepsCheck = false;
        pythonRemoveDeps = (old.pythonRemoveDeps or [ ]) ++ [ "rapidocr-onnxruntime" ];
        pythonImportsCheck = (old.pythonImportsCheck or [ ]) ++ [ "open_webui" ];
      }
    )
  );

  python3Packages = prev.python3Packages.overrideScope (pyfinal: pyprev: {
    extract-msg = pyprev.extract-msg.overridePythonAttrs (old: {
      pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "beautifulsoup4" ];
      pythonRuntimeDepsCheck = false;
    });
  });

  python313Packages = prev.python313Packages.overrideScope (pyfinal: pyprev: {
    extract-msg = pyprev.extract-msg.overridePythonAttrs (old: {
      pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "beautifulsoup4" ];
      pythonRuntimeDepsCheck = false;
    });
  });
}
