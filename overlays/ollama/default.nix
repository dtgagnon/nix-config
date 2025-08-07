{ channels, ... }: _final: _prev:
{
  inherit (channels.masterpkgs) ollama;
  # ollama = prev.ollama.overrideAttrs (_oldAttrs: rec {
  #   version = "0.11.2";
  #   src = prev.fetchFromGitHub {
  #     owner = "ollama";
  #     repo = "ollama";
  #     tag = "v${version}";
  #     hash = "sha256-NZaaCR6nD6YypelnlocPn/43tpUz0FMziAlPvsdCb44=";
  #   };
  # });
}
