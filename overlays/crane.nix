{ crane, ... }:
final: _prev: {
  craneLib = crane.mkLib final;
}
