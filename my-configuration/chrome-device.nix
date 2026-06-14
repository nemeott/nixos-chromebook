# chrome-device.nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  cb-ucm-conf = pkgs.alsa-ucm-conf.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "WeirdTreeThing";
      repo = "alsa-ucm-conf-cros";
      rev = "a4e92135fd49e669b5ce096439289e05e25ae90c";
      hash = "sha256-3TpzjmWuOn8+eIdj0BUQk2TeAU7BzPBi3FxAmZ3zkN8=";
    };

    patches = [ ]; # TODO: Is it legal to clear the patches? (maybe since I only need my audio config?)

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/alsa/ucm2
      # Start with everything from the standard package
      cp -r ${pkgs.alsa-ucm-conf}/share/alsa/ucm2/* $out/share/alsa/ucm2/
      # Our $out is writable but the copied files inherit read-only permissions, fix that
      chmod -R u+w $out/share/alsa/ucm2

      # Overlay WeirdTreeThing files on top
      cp -r ucm2/* $out/share/alsa/ucm2/

      # Add name variant copies
      cp -r ucm2/conf.d/sof-rt5682 $out/share/alsa/ucm2/conf.d/sofrt5682
      cp -r ucm2/conf.d/sof-rt5682 $out/share/alsa/ucm2/conf.d/tgl_rt5682_def
      cp ucm2/conf.d/sof-rt5682/sof-rt5682.conf $out/share/alsa/ucm2/conf.d/sof-rt5682/Google-Voxel-rev3.conf
      cp ucm2/conf.d/sof-rt5682/sof-rt5682.conf $out/share/alsa/ucm2/conf.d/tgl_rt5682_def/Google-Voxel-rev3.conf

      runHook postInstall
    '';
  });
in
{
  services.keyd = {
    enable = true;
    keyboards.internal = {
      ids = [
        "k:0001:0001"
        "k:18d1:5044"
        "k:18d1:5052"
        "k:0000:0000"
        "k:18d1:5050"
        "k:18d1:504c"
        "k:18d1:503c"
        "k:18d1:5030"
        "k:18d1:503d"
        "k:18d1:505b"
        "k:18d1:5057"
        "k:18d1:502b"
        "k:18d1:5061"
      ];
      settings = {
        main = {
          f1 = "back";
          f2 = "forward";
          f3 = "refresh";
          f4 = "f11";
          f5 = "scale";
          f6 = "brightnessdown";
          f7 = "brightnessup";
          f8 = "mute";
          f9 = "volumedown";
          f10 = "volumeup";
          back = "back";
          forward = "forward";
          refresh = "refresh";
          zoom = "f11";
          scale = "scale";
          brightnessdown = "brightnessdown";
          brightnessup = "brightnessup";
          mute = "mute";
          volumedown = "volumedown";
          volumeup = "volumeup";
          sleep = "coffee";
        };
        meta = {
          f1 = "f1";
          f2 = "f2";
          f3 = "f3";
          f4 = "f4";
          f5 = "f5";
          f6 = "f6";
          f7 = "f7";
          f8 = "f8";
          f9 = "f9";
          f10 = "f10";
          back = "f1";
          forward = "f2";
          refresh = "f3";
          zoom = "f4";
          scale = "f5";
          brightnessdown = "f6";
          brightnessup = "f7";
          mute = "f8";
          volumedown = "f9";
          volumeup = "f10";
          sleep = "f12";
        };
        alt = {
          backspace = "delete";
          meta = "capslock";
          brightnessdown = "kbdillumdown";
          brightnessup = "kbdillumup";
          f6 = "kbdillumdown";
          f7 = "kbdillumup";
        };
        control = {
          f5 = "print";
          scale = "print";
        };
        controlalt = {
          backspace = "C-A-delete";
        };
      };
    };
  };

  boot = {
    extraModprobeConfig = ''
      options snd-intel-dspcfg dsp_driver=3
    '';
  };

  environment = {
    systemPackages = [ pkgs.sof-firmware ];
    sessionVariables.ALSA_CONFIG_UCM2 = "${cb-ucm-conf}/share/alsa/ucm2";
  };

  services.pipewire.wireplumber.extraConfig = {
    "51-alsa-headroom" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "node.name" = "~alsa_output.*"; } ];
          actions = {
            update-props = {
              "api.alsa.headroom" = 4096;
            };
          };
        }
      ];
    };
  };

  system.replaceDependencies.replacements = [
    {
      original = pkgs.alsa-ucm-conf;
      replacement = cb-ucm-conf;
    }
  ];
}
