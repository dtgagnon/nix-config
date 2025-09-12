{ ... }: final: prev:
{
  davfs2 = prev.davfs2.overrideAttrs (old: rec{
    version = "1.7.2";
    src = prev.fetchurl {
      url = "mirror://savannah/davfs2/davfs2-${version}.tar.gz";
      sha256 = "sha256-G9wrsjWp8uVGpqE8VZ7PQ8ZEB+PESX13uOw/YvS4TkY=";
    };
    patches = builtins.filter
      (patch:
        !(patch ? name && patch.name == "neon-34.patch")
      )
      (old.patches or [ ]);
  });
}
