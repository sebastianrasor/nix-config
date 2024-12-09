# SPDX-FileCopyrightText: 2024 Sebastian Rasor <https://www.sebastianrasor.com/contact>
#
# SPDX-License-Identifier: MIT

{ ... }:
{
  services.restic.backups = {
    gdrive = {
      paths = [ "/home/sebastian" ];
      user = "sebastian";
      extraBackupArgs = [ "--exclude=/home/sebastian/videos" ];
      repository = "rclone:gdrive:/backups";
      initialize = true; # initializes the repo, don't set if you want manual control
      passwordFile = "/home/sebastian/.config/restic-password";
    };
  };
}
