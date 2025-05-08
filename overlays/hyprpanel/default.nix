{ inputs, ... }: _: prev: {
  hyprpanel = inputs.hyprpanel.packages.${prev.system}.default;
}
