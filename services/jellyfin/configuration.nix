{ modulesPath, pkgs, ... }:
let
  # Define Cloudwatch service config
  cloudwatchAgentConfig = pkgs.writeText "cloudwatch-agent-config.json" ''
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/messages",
                "log_group_name": "/ec2/jellyfin",
                "log_stream_name": "messages",
                "timestamp_format": "%b %d %H:%M:%S"
              }
            ]
          }
        }
      }
    }
  '';
in
{
  # AWS specific
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];
  ec2.hvm = true;

  # General
  system.stateVersion = "25.05";
  time.timeZone = "Europe/London";

  services.fail2ban = {
    enable = true;
    maxretry = 5;
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
    ];
  };

  environment.systemPackages = with pkgs; [
    neovim
    amazon-cloudwatch-agent
    # jellyfin
    # jellyfin-web
    # jellyfin-ffmpeg
  ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Logging
  # Forward journald logs to /var/log/messages
  services.journald.extraConfig = ''
    ForwardToSyslog=yes
  '';
  services.rsyslogd.enable = true;

  services.amazon-cloudwatch-agent = {
    enable = true;
    configurationFile = cloudwatchAgentConfig;
  };

  # Wireguard
  networking.nat = {
    enable = true;
    externalInterface = "ens5";
    internalInterfaces = [ "wg0" ];
  };

  networking.nameservers = [
    "8.8.8.8" # Google Public DNS
    "8.8.4.4" # Google Public DNS
    "1.1.1.1" # Cloudflare Public DNS
    "1.0.0.1" # Cloudflare Public DNS
  ];

  # Ensure the Cloudwatch is brought up automatically
  systemd.services.amazon-cloudwatch-agent.after = [ "multi-user.target" ];
  systemd.services.amazon-cloudwatch-agent.wantedBy = [ "multi-user.target" ];
}
