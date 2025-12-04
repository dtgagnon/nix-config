{ channels, ... }: _: _:
{
  inherit (channels.masterpkgs)
    antigravity
    davfs2
    discord
    immich
    nushell nushellPlugins
    ;
}
