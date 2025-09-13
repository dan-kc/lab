{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixos-generators = {
    url = "github:nix-community/nixos-generators";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      nixos-generators,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixos-generators.packages.x86_64-linux.default
          nil
          nixfmt-rfc-style
          terraform-ls
          awscli2
          opentofu
          nodePackages.prettier
          packer
        ];
      };

      # nix run github:NixOS/amis#upload-ami -- --prefix "vpn-" --s3-bucket lab-images-jmkzsh1u9r2vsxdqtmq5hmrjur --image-info ./result/nix-support/image-info.json
      packages.${system} = {
        vpn = nixos-generators.nixosGenerate {
          inherit system;
          inherit pkgs;
          format = "amazon";
          modules = [
            { system.stateVersion = "25.11"; }
            { nix.registry.nixpkgs.flake = nixpkgs; }
            ./services/vpn/configuration.nix
          ];
        };
      };
    };
}
