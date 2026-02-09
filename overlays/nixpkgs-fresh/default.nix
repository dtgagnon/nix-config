# @tracking: freshness
# @reason: Packages here are intentionally pinned to master for latest upstream versions
{ channels, ... }: _: _:
{
  inherit (channels.masterpkgs)
    antigravity
    ;
}
