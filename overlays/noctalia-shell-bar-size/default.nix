{ ... }: _final: prev:
{
  noctalia-shell = prev.noctalia-shell.overrideAttrs (oldAttrs: {
    postPatch =
      (oldAttrs.postPatch or "")
      + ''
        # Increase bar dimensions in Style.qml
        substituteInPlace Commons/Style.qml \
          --replace-fail 'case "mini": return barIsVertical ? 22 : 20' \
                         'case "mini": return barIsVertical ? 32 : 30' \
          --replace-fail 'case "compact": return barIsVertical ? 27 : 25' \
                         'case "compact": return barIsVertical ? 40 : 38' \
          --replace-fail 'case "comfortable": return barIsVertical ? 39 : 37' \
                         'case "comfortable": return barIsVertical ? 55 : 53' \
          --replace-fail 'default: return barIsVertical ? 33 : 31' \
                         'default: return barIsVertical ? 48 : 46'
      '';
  });
}
