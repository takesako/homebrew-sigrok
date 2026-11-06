class Micronucleus < Formula
  desc "ATtiny USB bootloader with a strong emphasis on bootloader compactness"
  homepage "https://github.com/micronucleus/micronucleus"
  url "https://github.com/micronucleus/micronucleus/archive/refs/tags/v2.6.tar.gz"
  sha256 "586d7bb1c064fe93dc5fc5b5ae0651641cd7fa8272b06cfd11feb6a0b2a06b9c"
  license "GPL-2.0-or-later"
  revision 1
  head "https://github.com/micronucleus/micronucleus.git", branch: "master"

  depends_on "pkgconf" => :build
  depends_on "libusb-compat"

  def install
    if build.stable?
      # The v2.6 tag still reports itself as 2.5
      inreplace "commandline/library/micronucleus_lib.h",
                /^#define MICRONUCLEUS_COMMANDLINE_VERSION .*$/,
                "#define MICRONUCLEUS_COMMANDLINE_VERSION (\"micronucleus-cli version: #{version}\")"
    end

    cd "commandline" do
      # Override the Makefile's flags, which call `brew list` and hardcode gcc
      system "make", "CC=#{ENV.cc}",
                     "USBFLAGS=#{Utils.safe_popen_read("pkgconf", "--cflags", "libusb").chomp}",
                     "USBLIBS=#{Utils.safe_popen_read("pkgconf", "--libs", "libusb").chomp}"
      bin.install "micronucleus"
    end
  end

  test do
    assert_match "micronucleus-cli version", shell_output("#{bin}/micronucleus --help")
  end
end
