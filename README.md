# Brief

This repo contains NixOs overlay for Upwork time tracker application.

# Installation

Suppose, that you store your whole OS config /etc/nixos in git:

```
# mkdir /etc/nixos/overlays
# cd /etc/nixos/overlays
# git submodule add  https://github.com/dambaev/upwork-overlay.git
```

Then, you can add this to your `/etc/nixos/configuration.nix`:

```
{pkgs, lib, ...}:
let
  upwork_overlay = import ./overlays/upwork-overlay/overlay.nix;
in
{
  nix.nixPath =
    # Prepend default nixPath values.
    options.nix.nixPath.default ++
    # Append our nixpkgs-overlays.
    [ "nixpkgs-overlays=/etc/nixos/overlays-compat/" ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ upwork_overlay ];
  environment.systemPackages = with pkgs; [ upwork ]; # now upwork package is in scope
}
```

and then, build and switch config:

```
# nixos-rebuild switch
```

# Updating

When you will want to update your Upwork time tracker application, you can do:

```
# cd /etc/nixos/
# git submodule update --remote
# nixos-rebuild switch
```

And when you are sure, that everything is ok:
```
# git commit overlays/upwork-overlay -m "upwork-overlay: upstream update"
```

# Build and hack

In order to build and hack, you can use:

```
$ nix-build ./shell.nix
$ ./result/bin/upwork
```

and

```
$ nix-shell ./shell.nix
```
