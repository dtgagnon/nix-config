{ channels, inputs, ... }: _: prev:
{
  karakeep =
    let
      newVersion = "0.23.0";
      newSrcHash = "sha256-SYcJfobuDl2iPXy5qGGG8ukBX/CSboSo/hF2e/8ixVw=";
      newPnpmDepsHash = "sha256-4MSNh2lyl0PFUoG29Tmk3WOZSRnW8NBE3xoppJr8ZNY=";
    in
    prev.karakeep.overrideAttrs (oldAttrs: {
      version = newVersion;
      src = oldAttrs.src.override {
        tag = "v${newVersion}";
        hash = newSrcHash;
      };
      pnpmDeps = oldAttrs.pnpmDeps.overrideAttrs (oldAttrs: {
        hash = newPnpmDepsHash;
      });
    });
}
