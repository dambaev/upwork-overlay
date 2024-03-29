{ stdenv, fetchurl, dpkg
, glib, gdk-pixbuf, gtk3, xorg, libuuid, ffmpeg, nss, pango, nspr, at-spi2-atk
, alsaLib, cairo, expat, atk, cups, dbus, gcc, systemd, at-spi2-core
, libdrm
, libxkbcommon
, mesa
, lib
}:
let
  # TODO: refactor to map dotted version into version with _
  version = "5.6.9.3";
  version_hash = "5_6_9_3_10c2eb9781db4d7f";
in
stdenv.mkDerivation {
  pname = "upwork";
  version = "${version}";

  src = fetchurl {
    url = "https://upwork-usw2-desktopapp.upwork.com/binaries/v${version_hash}/upwork_${version}_amd64.deb";
    sha256 = "09x3q0h7152kqyq19h837s10m80q09w771pm17p8qhrdk6k4m20b";
  };

  # we will use dpkg to unpack package
  buildInputs = [
    dpkg
    libdrm
    libxkbcommon
    mesa
  ];

  # we will do that manually
  dontUnpack = true;

  libPath = lib.makeLibraryPath [
    glib gdk-pixbuf gtk3 xorg.libxcb libuuid ffmpeg nss pango nspr at-spi2-atk at-spi2-core
    alsaLib cairo expat atk cups dbus gcc systemd
    libdrm
    libxkbcommon
    mesa
    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libXScrnSaver
    ];
  installPhase = ''
    dpkg-deb -x $src $out

    # find all shared libraries and executables and patch path to libc and rpaths
    for file in $(find $out -type f \( -perm /0111 -o -name \*.so\* \) ); do
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$file" || true
      patchelf --set-rpath $libPath:$out/opt/Upwork $file || true
    done
    # app.node is shared library, but renamed, so handle it specifically and it
    # requries libstdc++
    patchelf --set-rpath $libPath:${stdenv.cc.cc.lib}/lib:$out/opt/Upwork $out/opt/Upwork/app.node

    # nixos expects $out/bin and $out/share to exists
    ln -s $out/usr/share $out/share
    mkdir $out/bin
    # Upwork application tries to load app.node from working directory
    cat <<EOF > $out/bin/upwork
    set -e
    cd $out/opt/Upwork
    ./upwork &
    EOF
    chmod a+x $out/bin/upwork
  '';

  # we had done that manually
  dontStrip = true;
  dontPatchELF = true;

  meta = {
    homepage = https://upwork.com;
    description = "Time tracking application";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [];
  };
}
