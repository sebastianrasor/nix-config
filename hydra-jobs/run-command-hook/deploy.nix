{ writeShellScript, ... }:
writeShellScript "deploy-server" ''
  if [ -p /run/deploy-server.stdin ]; then
    echo switch > /run/deploy-server.stdin
  fi
''
