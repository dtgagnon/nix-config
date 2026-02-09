# @tracking: feature
# @reason: Add which-key popup showing available keybindings on incomplete key sequences
# @check: verify patch applies cleanly after aerc version bumps in nixpkgs
{ ... }:
_final: prev: {
  aerc = prev.aerc.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./0001-feat-add-which-key-popup.patch
    ];
  });
}
