_: _final: prev:
{
  python311Packages = prev.python311Packages // {
    protobuf = prev.python311Packages.protobuf4;
  };
}
