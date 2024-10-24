{ channels, ... }: final: prev:
{
  inherit (channels.masterpkgs) wandb;
}
