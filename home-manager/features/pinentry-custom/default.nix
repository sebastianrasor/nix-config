{ pkgs, config, ... }:
let
  pinentry-custom = pkgs.writeShellScriptBin "pinentry-custom" ''
    #!/bin/sh
    
    GETPASS_COMMAND='echo -n "" | ${pkgs.bemenu}/bin/bemenu -x indicator -p "Passphrase:"'

    DESC=""

    echo "OK Pleased to meet you"
    while read command args; do
        command=$(echo "$command" | ${pkgs.coreutils-full}/bin/tr '[:lower:]' '[:upper:]')
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
                ${pkgs.libnotify}/bin/notify-send -w "$DESC"
                echo "OK"
            ;;
            "BYE")
                echo "$DESC" | ${pkgs.gnugrep}/bin/grep -i 'unlock the card' 1>/dev/null 2>&1 && ${pkgs.libnotify}/bin/notify-send -t 5000 "Touch your security key"
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
