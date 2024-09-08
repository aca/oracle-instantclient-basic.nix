{
  description = "oracle-instantclient-basic";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    allSystems = [
      "x86_64-linux" # 64-bit Intel/AMD Linux
      "aarch64-linux" # 64-bit ARM Linux
      "x86_64-darwin" # 64-bit Intel macOS
      "aarch64-darwin" # 64-bit ARM macOS
    ];
    forAllSystems = f:
      nixpkgs.lib.genAttrs allSystems (system:
        f {
          inherit system;
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    packages = forAllSystems ({
      system,
      pkgs,
      ...
    }: let
      inherit (pkgs.lib) optional optionals optionalString;
      inherit (pkgs) stdenv fetchurl;

      components = ["basic"];
      # components = ["basic" "sdk" "sqlplus" "tools"];
      pname = "oracle-instantclient";
      version =
        {
          x86_64-linux = "23.4.0.24.05";
          aarch64-linux = "19.10.0.0.0";
          x86_64-darwin = "19.8.0.0.0";
          aarch64-darwin = "19.8.0.0.0";
        }
        .${stdenv.hostPlatform.system};

      directory =
        {
          x86_64-linux = "2340000";
          aarch64-linux = "191000";
          x86_64-darwin = "198000";
          aarch64-darwin = "198000";
        }
        .${stdenv.hostPlatform.system};

# https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-basiclite-linux.x64-23.4.0.24.05.zip
# https://download.oracle.com/otn_software/linux/instantclient/2340000/instantclient-basiclite-linux.x64-23.4.0.24.05dbru.zip
      # hashes per component and architecture
      hashes =
        {
          x86_64-linux = {
            basic = "sha256-Y4Nb9DO2s+ISCC371VZigw0hBNccx+dQzs2gOXJv6VY=";
            basiclite = "";
            sdk = "sha256-TIBFi1jHLJh+SUNFvuL7aJpxh61hG6gXhFIhvdPgpts=";
            sqlplus = "sha256-mF9kLjhZXe/fasYDfmZrYPL2CzAp3xDbi624RJDA4lM=";
            tools = "sha256-ay8ynzo1fPHbCg9GoIT5ja//iZPIZA2yXI/auVExiRY=";
            odbc = "sha256-3M6/cEtUrIFzQay8eHNiLGE+L0UF+VTmzp4cSBcrzlk=";
          };
          aarch64-linux = {
            basic = "sha256-DNntH20BAmo5kOz7uEgW2NXaNfwdvJ8l8oMnp50BOsY=";
            basiclite = "";
            sdk = "sha256-8VpkNyLyFMUfQwbZpSDV/CB95RoXfaMr8w58cRt/syw=";
            sqlplus = "sha256-iHcyijHhAvjsAqN9R+Rxo2R47k940VvPbScc2MWYn0Q=";
            tools = "sha256-4QY0EwcnctwPm6ZGDZLudOFM4UycLFmRIluKGXVwR0M=";
            odbc = "sha256-T+RIIKzZ9xEg/E72pfs5xqHz2WuIWKx/oRfDrQbw3ms=";
          };
          x86_64-darwin = {
            basic = "sha256-V+1BmPOhDYPNXdwkcsBY1MOwt4Yka66/a7/HORzBIIc=";
            basiclite = "";
            sdk = "sha256-D6iuTEQYqmbOh1z5LnKN16ga6vLmjnkm4QK15S/Iukw=";
            sqlplus = "sha256-08uoiwoKPZmTxLZLYRVp0UbN827FXdhOukeDUXvTCVk=";
            tools = "sha256-1xFFGZapFq9ogGQ6ePSv4PrXl5qOAgRZWAp4mJ5uxdU=";
            odbc = "sha256-S6+5P4daK/+nXwoHmOkj4DIkHtwdzO5GOkCCI612bRY=";
          };
          aarch64-darwin = {
            basic = "sha256-V+1BmPOhDYPNXdwkcsBY1MOwt4Yka66/a7/HORzBIIc=";
            basiclite = "";
            sdk = "sha256-D6iuTEQYqmbOh1z5LnKN16ga6vLmjnkm4QK15S/Iukw=";
            sqlplus = "sha256-08uoiwoKPZmTxLZLYRVp0UbN827FXdhOukeDUXvTCVk=";
            tools = "sha256-1xFFGZapFq9ogGQ6ePSv4PrXl5qOAgRZWAp4mJ5uxdU=";
            odbc = "sha256-S6+5P4daK/+nXwoHmOkj4DIkHtwdzO5GOkCCI612bRY=";
          };
        }
        .${stdenv.hostPlatform.system};

      # rels per component and architecture, optional
      rels =
        {
          aarch64-darwin = {
            basic = "1";
            tools = "1";
          };
        }
        .${stdenv.hostPlatform.system}
        or {};

      # suffix
      suffix =
        {
          aarch64-darwin = {
            basic = ".dmg";
          };
          x86_64-linux = {
            basic = ".zip";
            basiclite = ".zip";
          };
        }
        .${stdenv.hostPlatform.system}
        or {};

      # convert platform to oracle architecture names
      arch =
        {
          x86_64-linux = "linux.x64";
          aarch64-linux = "linux.arm64";
          x86_64-darwin = "macos.x64";
          aarch64-darwin = "macos.x64";
        }
        .${stdenv.hostPlatform.system};

      shortArch =
        {
          x86_64-linux = "linux";
          aarch64-linux = "linux";
          x86_64-darwin = "mac";
          aarch64-darwin = "mac";
        }
        .${stdenv.hostPlatform.system};

      # calculate the filename of a single zip file
      srcFilename = component: arch: version: rel: suffix:
        "instantclient-${component}-${arch}-${version}"
        + (optionalString (rel != "") "-${rel}")
        + "${suffix}";

      fetcher = srcFilename: hash:
        fetchurl {
          url = "https://download.oracle.com/otn_software/${shortArch}/instantclient/${directory}/${srcFilename}";
          sha256 = hash;
        };

      # assemble srcs
      # srcs = components:

      extLib = stdenv.hostPlatform.extensions.sharedLibrary;
    in rec {
      basic = pkgs.stdenv.mkDerivation {
        inherit pname version;
        srcs = map (component: (fetcher (srcFilename component arch version rels.${component} or "" suffix.${component} or "dbru.zip") hashes.${component} or "")) ["basic"];
        outputs = ["out" "dev" "lib"];
        unpackCmd =
          if (arch == "macos.arm64")
          then "7zz x $curSrc -aoa -oinstantclient"
          else "unzip $curSrc; rm -rf META-INF";

        buildInputs =
          [stdenv.cc.cc.lib]
          ++ optional stdenv.isLinux pkgs.libaio;

        installPhase = ''
          mkdir -p "$out/"{bin,include,lib,"share/java","share/${pname}-${version}/demo/"} $lib/lib
          # install -Dm755 {adrci,genezi,uidrvci,sqlplus,exp,expdp,imp,impdp} $out/bin
          install -Dm755 {adrci,genezi,uidrvci} $out/bin

          # cp to preserve symlinks
          cp -P *${extLib}* $lib/lib

          # install -Dm644 *.jar $out/share/java
          # install -Dm644 sdk/include/* $out/include
          # install -Dm644 sdk/demo/* $out/share/${pname}-${version}/demo

          # install -Dm644 *.jar $out/share/java
          # install -Dm644 sdk/include/* $out/include
          # install -Dm644 sdk/demo/* $out/share/${pname}-${version}/demo

          # provide alias
          # ln -sfn $out/bin/sqlplus $out/bin/sqlplus64
          ln -sfn $out/bin/sqlplus $out/bin/sqlplus64
        '';

        postFixup = optionalString stdenv.isDarwin ''
          for exe in "$out/bin/"* ; do
            if [ ! -L "$exe" ]; then
              install_name_tool -add_rpath "$lib/lib" "$exe"
            fi
          done
        '';

        nativeBuildInputs =
          [pkgs.makeWrapper]
          ++ optional stdenv.isLinux [pkgs.autoPatchelfHook]
          ++ optional stdenv.isDarwin [pkgs.fixDarwinDylibNames]
          ++ optional (arch != "macos.arm64") [pkgs.unzip]
          ++ optional (arch == "macos.arm64") [pkgs._7zz];
      };
      basiclite = pkgs.stdenv.mkDerivation {
        inherit pname version ;
        srcs = map (component: (fetcher (srcFilename component arch version rels.${component} or "" suffix.${component} or "dbru.zip") hashes.${component} or "")) ["basiclite"];
        outputs = ["out" "dev" "lib"];
        unpackCmd =
          if (arch == "macos.arm64")
          then "7zz x $curSrc -aoa -oinstantclient"
          else "unzip $curSrc; rm -rf META-INF";

        buildInputs =
          [stdenv.cc.cc.lib]
          ++ optional stdenv.isLinux pkgs.libaio;

        installPhase = ''
          mkdir -p "$out/"{bin,include,lib,"share/java","share/${pname}-${version}/demo/"} $lib/lib
          # install -Dm755 {adrci,genezi,uidrvci,sqlplus,exp,expdp,imp,impdp} $out/bin
          # install -Dm755 {adrci,genezi,uidrvci} $out/bin

          # cp to preserve symlinks
          cp -P *${extLib}* $lib/lib

          # install -Dm644 *.jar $out/share/java
          # install -Dm644 sdk/include/* $out/include
          # install -Dm644 sdk/demo/* $out/share/${pname}-${version}/demo

          # install -Dm644 *.jar $out/share/java
          # install -Dm644 sdk/include/* $out/include
          # install -Dm644 sdk/demo/* $out/share/${pname}-${version}/demo

          # provide alias
          # ln -sfn $out/bin/sqlplus $out/bin/sqlplus64
          # ln -sfn $out/bin/sqlplus $out/bin/sqlplus64
        '';

        postFixup = optionalString stdenv.isDarwin ''
          for exe in "$out/bin/"* ; do
            if [ ! -L "$exe" ]; then
              install_name_tool -add_rpath "$lib/lib" "$exe"
            fi
          done
        '';

        nativeBuildInputs =
          [pkgs.makeWrapper]
          ++ optional stdenv.isLinux [pkgs.autoPatchelfHook]
          ++ optional stdenv.isDarwin [pkgs.fixDarwinDylibNames]
          ++ optional (arch != "macos.arm64") [pkgs.unzip]
          ++ optional (arch == "macos.arm64") [pkgs._7zz];
      };
      default = basic;
    });
  };
}
