{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "chatgpt-webview";
  version = "1.0.0";
  src = ./.;
  buildInputs = [ pkgs.webkitgtk ];
  dontUnpack = true;

  buildPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/chatgpt-webview <<EOF
    #!/bin/sh
    ${pkgs.webkitgtk}/bin/MiniBrowser "https://chatgpt.com"
    EOF
    chmod +x $out/bin/chatgpt-webview
  '';

  installPhase = ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/chatgpt-webview.desktop <<EOF
    [Desktop Entry]
    Name=ChatGPT Webview
    Exec=$out/bin/chatgpt-webview
    Terminal=false
    Type=Application
    Icon=web-browser
    EOF
  '';
}
