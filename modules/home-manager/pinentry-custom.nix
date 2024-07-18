{ lib, pkgs, config, ... }:
let
  pinentry-custom = pkgs.writeShellScriptBin "pinentry-custom" ''
    #!/bin/sh
    
    GETPASS_COMMAND='echo -n "" | ${lib.getExe pkgs.bemenu} -x indicator -p "Passphrase:"'

    DESC=""

    echo "OK Pleased to meet you"
    while read command args; do
        command=$(echo "$command" | ${lib.getExe' pkgs.coreutils-full "tr"} '[:lower:]' '[:upper:]')
        case $command in
            "GETPIN")
                echo "D $(eval "$GETPASS_COMMAND")"
                echo "OK"
            ;;
            "SETDESC")
                DESC="$args"
                echo "OK"
            ;;
            "CONFIRM")
                ${lib.getExe' pkgs.libnotify "notify-send"} -w "$DESC"
                echo "OK"
            ;;
            "BYE")
                echo "OK closing connection"
                break
            ;;
            *)
                echo "OK"
            ;;
        esac
    done
    
    exit 0
  '';
in
{
  services.gpg-agent.pinentryPackage = pinentry-custom;
}
