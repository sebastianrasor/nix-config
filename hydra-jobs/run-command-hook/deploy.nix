{ writeShellScript, ... }:
writeShellScript "deploy-server" ''
  if [ -f /run/deploy-server.stdin ]; then
    echo switch > /run/deploy-server.stdin
  fi
''
