{
  lib,
  python3,
  fetchPypi,
}:
let
  odoorpc = python3.pkgs.buildPythonPackage rec {
    pname = "odoorpc";
    version = "0.10.1";
    format = "setuptools";

    src = fetchPypi {
      pname = "OdooRPC";
      inherit version;
      hash = "sha256-0LxSTFuWB4EWVXW62cE9Ay1vlow8CSdicQRd27tIOqU=";
    };

    # No dependencies - pure Python
    propagatedBuildInputs = [ ];

    # Tests require a running Odoo server
    doCheck = false;

    pythonImportsCheck = [ "odoorpc" ];

    meta = with lib; {
      description = "Python package to pilot Odoo servers through JSON-RPC";
      homepage = "https://github.com/OCA/odoorpc";
      license = licenses.lgpl3Only;
    };
  };
in
python3.withPackages (ps: [ odoorpc ])
