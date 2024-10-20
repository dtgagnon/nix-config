{ channels, ... }: _final: prev:
{
  python311Packages = prev.python311Packages // {
    wandb = channels.stablepkgs.python311Packages.wandb;
  };
}
