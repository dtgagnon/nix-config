{ ... }: _final: prev: {
  # open-webui declares a runtime dep on rapidocr-onnxruntime which is not packaged.
  # Disable runtime dep checks; also try to strip the dep if present.
  # Handle both top-level package and python3Packages variant just in case.
  open-webui = prev.open-webui.overrideAttrs (old: {
    pythonRuntimeDepsCheck = false;
    pythonRemoveDeps = (old.pythonRemoveDeps or []) ++ [ "rapidocr-onnxruntime" ];
    pythonImportsCheck = (old.pythonImportsCheck or []) ++ [ "open_webui" ];
  });

  python3Packages = prev.python3Packages.overrideScope (_: p: {
    "open-webui" = (p."open-webui" or prev.open-webui).overridePythonAttrs (old: {
      pythonRuntimeDepsCheck = false;
      pythonRemoveDeps = (old.pythonRemoveDeps or []) ++ [ "rapidocr-onnxruntime" ];
      pythonImportsCheck = (old.pythonImportsCheck or []) ++ [ "open_webui" ];
    });
  });
}
