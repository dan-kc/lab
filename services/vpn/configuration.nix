{ modulesPath, pkgs, ... }:
let
  # This must match the name set in AWS Secrets Manager
  wireguardPrivateKeySecretId = "/vpn/wg-private-key";

  # This path should be accessible only by root and WireGuard process
  wireguardPrivateKeyPath = "/run/secrets/wireguard/private_key";

  # Region we are deploying to
  region = "eu-west-2";

  # Define script to fetch wireguard secret key from AWS Secret Manager
  fetchWireguardSecretScript = pkgs.writeShellScript "fetch-wireguard-secret" ''
    set -euo pipefail

    # Ensure the directory exists and has correct permissions
    mkdir -p "$(dirname ${wireguardPrivateKeyPath})"
    chmod 0700 "$(dirname ${wireguardPrivateKeyPath})"

    # Fetch the the private key
    ${pkgs.awscli2}/bin/aws secretsmanager get-secret-value \
      --secret-id "${wireguardPrivateKeySecretId}" \
      --query SecretString \
      --output text > "${wireguardPrivateKeyPath}"

    # Ensure the private key file has very restrictive permissions (read-only for root)
    chmod 0400 "${wireguardPrivateKeyPath}"
  '';

  # Define Cloudwatch service config
  cloudwatchAgentConfig = pkgs.writeText "cloudwatch-agent-config.json" ''
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/messages",
                "log_group_name": "/ec2/vpn",
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
    allowedUDPPorts = [
      51820
    ];
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    awscli2
    neovim
    amazon-cloudwatch-agent
  ];

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

  # Secrets
  systemd.services.fetch-wireguard-secret = {
    description = "Fetch WireGuard private key from AWS Secrets Manager";
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ]; # Ensure it's part of the standard boot process
    requires = [ "network-online.target" ]; # Explicit dependency on network being up
    serviceConfig = {
      Type = "oneshot"; # Runs once and exits
      RemainAfterExit = true;
      ExecStart = "${fetchWireguardSecretScript}";
      User = "root"; # Script needs root to write to /run/secrets
      # Add this if you want to avoid AWS credentials being logged or if awscli needs it
      Environment = [ "AWS_REGION=${region}" ];
    };
  };

  # Wireguard
  networking.nat = {
    enable = true;
    externalInterface = "ens5";
    internalInterfaces = [ "wg0" ];
  };

  networking.wireguard = {
    interfaces = {
      wg0 = {
        mtu = 1380; # Should fix where it doesn't work on other networks
        listenPort = 51820;
        privateKeyFile = wireguardPrivateKeyPath;
        ips = [ "10.0.0.1/24" ]; # sets the server's internal VPN IP to 10.0.0.1 and declares that the server considers the entire 10.0.0.0/24 network to be directly attached to its wg0 interface.
        peers = [
          {
            publicKey = "LQGeLXhrMKUuRuLJKyx4xDW+uIk1Qrw6JV810QouTno=";
            allowedIPs = [ "10.0.0.2/32" ];
          }
        ];
      };
    };
  };

  # Explicitly define DNS servers globally
  networking.nameservers = [
    "8.8.8.8"   # Google Public DNS
    "8.8.4.4"   # Google Public DNS
    "1.1.1.1"   # Cloudflare Public DNS
    "1.0.0.1"   # Cloudflare Public DNS
  ];

  # Enable IP forwarding for the VPN to route traffic
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  # Ensure the WireGuard interface is brought up automatically
  systemd.services.wg-quick-wg0.wantedBy = [ "multi-user.target" ];

  # Ensure the Cloudwatch is brought up automatically
  systemd.services.amazon-cloudwatch-agent.after = [ "multi-user.target" ];
  systemd.services.amazon-cloudwatch-agent.wantedBy = [ "multi-user.target" ];

  # Make WireGuard service depend on our secret fetcher
  systemd.services.wg-quick-wg0.after = [ "fetch-wireguard-secret.service" ];
  systemd.services.wg-quick-wg0.requires = [ "fetch-wireguard-secret.service" ];
}
