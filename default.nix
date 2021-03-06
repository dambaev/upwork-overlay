{ stdenv, fetchurl, dpkg
, glib, gdk-pixbuf, gtk3, xorg, libuuid, ffmpeg, nss, pango, nspr, at-spi2-atk
, alsaLib, cairo, expat, atk, cups, dbus, gcc, systemd, at-spi2-core
}:
let
  # TODO: refactor to map dotted version into version with _
  version = "5.4.9.6";
  version_hash = "5_4_9_6_2565cdd0547940a2";
in
stdenv.mkDerivation {
  pname = "upwork";
  version = "${version}";

  src = fetchurl {
    url = "https://updates-desktopapp.upwork.com/binaries/v${version_hash}/upwork_${version}_amd64.deb";
    sha256 = "0mi4wm63avm4yfbmksdpqkd0pd7g5xjk8afakg67kvd1njrlcqpz";
  };

  # we will use dpkg to unpack package
  buildInputs = [ dpkg ];

  # we will do that manually
  dontUnpack = true;

  libPath = stdenv.lib.makeLibraryPath [
    glib gdk-pixbuf gtk3 xorg.libxcb libuuid ffmpeg nss pango nspr at-spi2-atk at-spi2-core
    alsaLib cairo expat atk cups dbus gcc systemd
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
    license = stdenv.lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [];
  };
}
