{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  python3,
  bash,
  zip,
}:
let
  src = fetchFromGitHub {
    owner = "patrup";
    repo = "mcp-libre";
    rev = "edc5123dcd740049c54de9bc9abf8d69b2f1293f";
    hash = "sha256-J0oXBvn5Bejnn6p6cc4He6lfk+aFnuMSgxJBGhcS6EE=";
  };

  pythonEnv = python3.withPackages (ps: [
    ps.mcp
    ps.httpx
    ps.pydantic
  ]);
in
stdenvNoCC.mkDerivation {
  pname = "mcp-libreoffice";
  version = "0.1.0";

  inherit src;

  nativeBuildInputs = [ zip ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/mcp-libreoffice $out/bin $out/share/libreoffice/extensions

    # Copy the source module
    cp -r src $out/lib/mcp-libreoffice/

    # Create wrapper script (expects libreoffice to be on PATH)
    cat > $out/bin/mcp-libreoffice << EOF
#!${bash}/bin/bash
exec ${pythonEnv}/bin/python3 $out/lib/mcp-libreoffice/src/libremcp.py "\$@"
EOF

    chmod +x $out/bin/mcp-libreoffice

    # Build the LibreOffice extension (.oxt)
    pushd plugin
    zip -r $out/share/libreoffice/extensions/libreoffice-mcp-extension.oxt \
      META-INF/ \
      pythonpath/ \
      *.xml \
      *.txt \
      -x "*.pyc" "*/__pycache__/*"
    popd

    runHook postInstall
  '';

  meta = {
    description = "LibreOffice MCP server for AI assistants - create, read, convert documents";
    homepage = "https://github.com/patrup/mcp-libre";
    license = lib.licenses.mit;
    mainProgram = "mcp-libreoffice";
    platforms = lib.platforms.unix;
  };
}
