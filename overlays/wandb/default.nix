{ channels, ... }: _final: _prev:
{
  inherit (channels.masterpkgs.python311Packages) wandb;
}
