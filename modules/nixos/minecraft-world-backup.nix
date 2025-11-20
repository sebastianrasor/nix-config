{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  minecraftWorldBackupScript = pkgs.writeShellApplication {
    name = "minecraft-world-backup";
    runtimeInputs = with pkgs; [
      gzip
      jq
      gnutar
      websocat
    ];
    text = ''
      function websocat_msmp() {
        websocat -H 'Authorization: Bearer ${config.sebastianrasor.minecraft-server.serverProperties.management-server-secret}' --jsonrpc ws://${config.sebastianrasor.minecraft-server.serverProperties.management-server-host}:${toString config.sebastianrasor.minecraft-server.serverProperties.management-server-port} 2>/dev/null
      }

      function msmp_method() {
        response="$(echo "$@" | websocat_msmp)"
        if [ "$(echo "$response" | jq -s '. | all(.error == null)')" != "true" ]; then
          echo "Minecraft Server Management Protocol error:"
          echo "$response" | jq
          exit 1
        fi

        echo "$response"
      }

      current_datetime="$(date +"%FT%H:%M:%S%:z")"
      current_epoch="$(date -d "$current_datetime" +%s)"

      echo "Starting Minecraft game server world backup at $current_datetime"

      if [ -L /media/minecraft-server-backups/world/latest ]; then
        previous_datetime="$(basename "$(readlink -f /media/minecraft-server-backups/world/latest)" .tar.gz)"
        previous_epoch="$(date -d "$previous_datetime" +%s)"

        if (( (current_epoch - previous_epoch) < (24 * 60 * 60 - 10 * 60) )); then
          echo "Backup exists within last 24 hours, exiting."
          exit 0
        fi
      fi

      if [ "$(msmp_method minecraft:server/status | jq '.result.started')" != "true" ]; then
        echo "Minecraft game server not online, exiting."
        exit 7
      fi

      if [ "$(msmp_method minecraft:players | jq '.result | length')" != "0" ]; then
        echo "Online player count is greater than zero, exiting."
        exit 0
      fi

      previous_autosave_enabled="$(msmp_method minecraft:serversettings/autosave | jq '.result')"
      echo "Original autosave enabled state: $previous_autosave_enabled"

      function cleanup() {
        if [ -e "/media/minecraft-server-backups/world/$current_datetime.tar.gz" ]; then
          echo "Removing /media/minecraft-server-backups/world/$current_datetime.tar.gz"
          rm -f "/media/minecraft-server-backups/world/$current_datetime.tar.gz"
        fi

        if [ -e "/media/minecraft-server-backups/world/latest" ]; then
          echo "Removing /media/minecraft-server-backups/world/latest"
          rm -f "/media/minecraft-server-backups/world/latest"
        fi

        if [ -n "$previous_datetime" ]; then
          echo "Linking /media/minecraft-server-backups/world/latest -> /media/minecraft-server-backups/world/$previous_datetime.tar.gz"
          ln -sf "./$previous_datetime.tar.gz" /media/minecraft-server-backups/world/latest
        fi

        echo "Restoring original autosave enabled state: $previous_autosave_enabled"
        msmp_method minecraft:serversettings/autosave/set "$previous_autosave_enabled"
      }

      echo "Disabling autosave"
      if [ "$(msmp_method minecraft:serversettings/autosave/set false | jq '.result')" != "false" ]; then
        echo "Failed to disable autosave, cleaning up and exiting."
        cleanup
        exit 1
      fi

      echo "Performing manual save"
      if [ "$(msmp_method minecraft:server/save true | jq -s '.[] | select(.result==true or .method=="minecraft:notification/server/saved")' | jq -s '. | length')" != "2" ]; then
        echo "Could not confirm successful manual save, cleaning up and exiting."
        cleanup
        exit 1
      fi

      echo "Archiving world directory"
      if ! tar -C /nix/persist/var/lib/minecraft -czf "/media/minecraft-server-backups/world/$current_datetime.tar.gz" world; then
        echo "Failed to archive world, cleaning up and exiting."
        cleanup
        exit 1
      fi

      # lol this shouldn't happen
      if ! [ -f "/media/minecraft-server-backups/world/$current_datetime.tar.gz" ]; then
        echo "Archive somehow vanished, cleaning up and exiting."
        cleanup
        exit 1
      fi

      echo "Linking /media/minecraft-server-backups/world/latest -> /media/minecraft-server-backups/world/$current_datetime.tar.gz"
      if ! ln -sf "./$current_datetime.tar.gz" /media/minecraft-server-backups/world/latest; then
        echo "Failed to create symlink, cleaning up and exiting."
        cleanup
        exit 1
      fi

      echo "Restoring original autosave enabled state: $previous_autosave_enabled"
      if [ "$(msmp_method minecraft:serversettings/autosave/set "$previous_autosave_enabled" | jq '.result')" != "$previous_autosave_enabled" ]; then
        echo "Failed to restore autosave enabled state."
        echo "Trying again via /run/minecraft-server.stdin (no further tracking beyond this point)"
        echo save-on > /run/minecraft-server.stdin
      fi

      echo "Backup completed"
    '';
  };
in
{
  options = {
    sebastianrasor.minecraft-world-backup = {
      enable = lib.mkEnableOption "Minecraft game server world backup";
    };
  };

  config = lib.mkIf config.sebastianrasor.minecraft-world-backup.enable {
    fileSystems."/media/minecraft-server-backups" = lib.mkIf config.sebastianrasor.unas.enable {
      device = "${config.sebastianrasor.unas.host}:${config.sebastianrasor.unas.basePath}/Minecraft_Server_Backups";
      fsType = "nfs";
    };

    systemd = {
      services.minecraft-world-backup = {
        description = "Minecraft game server world backup service";
        unitConfig = {
          RequiresMountsFor = "/media/minecraft-server-backups";
        };
        serviceConfig = {
          Type = "oneshot";
          User = config.systemd.services.minecraft-server.serviceConfig.User;
          ExecStart = lib.getExe minecraftWorldBackupScript;
        };
      };
      timers.minecraft-world-backup = {
        description = "Minecraft game server world backup timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/15";
        };
      };
    };
  };
}
