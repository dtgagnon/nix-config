{ lib, ... }:

rec {
  ## Create a static website derivation.
  ##
  ## ```nix
  ## lib.spirenix.mkStaticWebsite pkgs {
  ##   name = "my-site";
  ##   src = ./site;
  ## }
  ## ```
  ##
  #@ Pkgs -> { name: String, src: Path, buildInputs?: List, buildPhase?: String, meta?: Attrs } -> Derivation
  mkStaticWebsite =
    pkgs:
    {
      name,
      src,
      buildInputs ? [ ],
      buildPhase ? "",
      meta ? { },
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit name src buildInputs;

      buildPhase = ''
        runHook preBuild
        ${buildPhase}
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r * $out/
        runHook postInstall
      '';

      meta = {
        description = "Static website: ${name}";
      } // meta;
    };

  ## Create a website from Nix-generated HTML/CSS content.
  ##
  ## ```nix
  ## lib.spirenix.mkGeneratedWebsite pkgs {
  ##   name = "dashboard";
  ##   html = ''<!DOCTYPE html>...'';
  ##   css = ''body { ... }'';
  ## }
  ## ```
  ##
  #@ Pkgs -> { name: String, html: String, css?: String, assets?: Attrs, meta?: Attrs } -> Derivation
  mkGeneratedWebsite =
    pkgs:
    {
      name,
      html,
      css ? null,
      assets ? { },
      meta ? { },
    }:
    let
      inherit (pkgs) writeTextFile;

      htmlFile = writeTextFile {
        name = "index.html";
        text = html;
      };

      cssFile =
        if css != null then
          writeTextFile {
            name = "style.css";
            text = css;
          }
        else
          null;
    in
    pkgs.stdenvNoCC.mkDerivation {
      inherit name;

      dontUnpack = true;

      installPhase = ''
        mkdir -p $out
        cp ${htmlFile} $out/index.html
        ${lib.optionalString (cssFile != null) "cp ${cssFile} $out/style.css"}
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: file: "cp ${file} $out/${name}") assets)}
      '';

      meta = {
        description = "Generated static website: ${name}";
      } // meta;
    };

  ## Create a website using a static site generator (Hugo, Zola, etc.).
  ##
  ## ```nix
  ## lib.spirenix.mkWebsiteFromGenerator pkgs {
  ##   name = "blog";
  ##   src = ./blog-source;
  ##   generator = "hugo";
  ## }
  ## ```
  ##
  #@ Pkgs -> { name: String, src: Path, generator: String } -> Derivation
  mkWebsiteFromGenerator =
    pkgs:
    {
      name,
      src,
      generator,
      ...
    }@args:
    let
      generatorConfigs = {
        hugo = {
          buildInputs = [ pkgs.hugo ];
          buildPhase = "hugo --minify";
          postBuild = "mv public/* .";
        };
        zola = {
          buildInputs = [ pkgs.zola ];
          buildPhase = "zola build";
          postBuild = "mv public/* .";
        };
      };

      config = generatorConfigs.${generator} or (throw "Unknown generator: ${generator}. Supported: hugo, zola");
    in
    mkStaticWebsite pkgs (args // config);
}
