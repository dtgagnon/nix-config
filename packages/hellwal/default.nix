{ lib
, stdenv
, makeWrapper
, fetchFromGitHub
}:
let
  pname = "hellwal";
  version = "1.0.4";
  hash = "sha256-M+b49KhbzvwpMvnfiNe4yy50aUjrGXEajLMmiXEOCgE=";
in
stdenv.mkDerivation (finalAttrs: {
  inherit pname version;
  src = fetchFromGitHub {
    owner = "danihek";
    repo = "hellwal";
    tag = "v${finalAttrs.version}";
    inherit hash;
  };
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    install -Dm755 hellwal -t $out/bin
    mkdir -p $out/share/docs/hellwal
    cp -r templates themes $out/share/docs/hellwal
  '';
  meta = {
    homepage = "https://github.com/danihek/hellwal";
    description = "Fast, extensible color palette generator";
    longDescription = ''
      Pywal-like color palette generator, but faster and in C.
    '';
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ danihek ];
    mainProgram = "hellwal";
  };
})
