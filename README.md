# nixos-chromebook

A method of setting up audio, keyd, etc on NixOS.

> I am not affiliated with Chrultrabook. Please don't ask them for help regarding NixOS.

> The self-built package may break due to compatibility for NixOS, issues may occur and this isn't all perfect.

## Prerequisites

- Working internet connection
- A [supported](https://docs.chrultrabook.com/docs/firmware/supported-devices.html) Chromebook
- An understanding of Linux command line
- Patience

### Step 1: Create Configuration file(s)

> Note that the configurations are applied to `configuration.nix` located in `/etc/nixos`.

> Running the command `sudo nixos-rebuild switch` will rebuild your installation and apply the changes made.

First things first, for Chromebook-related configuration, we will create `chrome-device.nix`.

```bash
sudo touch /etc/nixos/chrome-device.nix
```

Then at the top of our `configuration.nix` we import `chrome-device.nix`.

```nix
# configuration.nix
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./chrome-device.nix
    ];

    # the rest of your configuration...
}

```

### Step 2: ALSA UCM configuration

Build the package in `chrome-device.nix` and setup Keyd

```nix
# chrome-device.nix
{ config, pkgs, lib, ... }:

let
  cb-ucm-conf = pkgs.alsa-ucm-conf.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "WeirdTreeThing";
      repo = "alsa-ucm-conf-cros";
      rev = "a4e92135fd49e669b5ce096439289e05e25ae90c";
      hash = "sha256-3TpzjmWuOn8+eIdj0BUQk2TeAU7BzPBi3FxAmZ3zkN8=";
    };

    patches = [ ]; # TODO: Is it legal to clear the patches?

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

  # add your audio setup modprobes here

  environment = {
    systemPackages = [ pkgs.sof-firmware ];
    sessionVariables.ALSA_CONFIG_UCM2 = "${cb-ucm-conf}/share/alsa/ucm2";
  };

  # AUDIO SETUP (only tested with unstable)

  system.replaceDependencies.replacements = [
    ({
      original = pkgs.alsa-ucm-conf;
      replacement = cb-ucm-conf;
    })
  ];
}

```

#### Step 2A: Determine versions

You can check your NixOS channel with:

```bash
nix-channel --list
```

CPU generations to determine AVS or SOF for your Chromebook

| AVS        | SOF        |
| ---------- | ---------- |
| Skylake    | Alderlake  |
| Kabylake   | Jasperlake |
| Apollolake | Tigerlake  |
|            | Cometlake  |
|            | Geminilake |
|            | Braswell   |
|            | Baytrail   |

**This fork of the guide is only for SOF.**

#### Step 2B: Configuration based on Step 2A

**SOF Configuration:**

Replace `# AUDIO SETUP (only tested with unstable)` with this:

```nix
# chrome-device.nix
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

```

#### Step 2C: Modprobes

> This directly relies on what CPU generation you have

**SOF** modprobe config for **Alderlake, Jasperlake, Tigerlake, Cometlake, and Geminilake**

```nix
# chrome-device.nix
in
{
  boot = {
    extraModprobeConfig = ''
      options snd-intel-dspcfg dsp_driver=3
    '';
  };

  # additonal configuration...
}

```

**SOF** modprobe config for **Braswell and Baytrail**

```nix
# chrome-device.nix
in
{
  boot = {
    extraModprobeConfig = ''
      options snd-intel-dspcfg dsp_driver=3
      options snd-sof sof_debug=1
    '';
  };

  # additonal configuration...
}

```

### Step 3: Post-Install

From here, you'll need to rebuild your configuration.

```nix
sudo nixos-rebuild switch
```

Changes should apply, you can reboot if necessary.

**Feel free to see my [configuration](/my-configuration/) to see how I did all this!**

### Step 4: Post-Post-Install

Also you need to install `pavucontrol` and switch to the "Pro Audio" mode using it. Results in better audio quality (likely because it is able to use more of the speakers?).
