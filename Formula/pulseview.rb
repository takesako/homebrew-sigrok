class Pulseview < Formula
  desc "Qt based logic analyzer, oscilloscope and MSO GUI for sigrok"
  homepage "https://sigrok.org/wiki/PulseView"
  url "https://sigrok.org/download/source/pulseview/pulseview-0.4.2.tar.gz"
  sha256 "f042f77a3e1b35bf30666330e36ec38fab8d248c3693c37b7e35d401c3bfabcb"
  license "GPL-3.0-or-later"
  revision 1

  livecheck do
    url "https://sigrok.org/download/source/pulseview/"
    regex(/href=.*?pulseview[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "boost"
  depends_on "glib"
  depends_on "glibmm@2.66"
  depends_on "libsigc++@2"
  depends_on "libsigrok"
  depends_on "libsigrokdecode"
  depends_on "qt@5"

  # Replace obsolete/deprecated Qt methods (needed for Qt 5.15)
  patch do
    url "https://github.com/sigrokproject/pulseview/commit/ae726b70a7ada9a4be5808e00f0c951318479684.patch?full_index=1"
    sha256 "79f8698dafc98566f220d0fa8f61660a58863b7e1e819eb4ce3f60ff857391c3"
  end

  # Workaround for a Boost::serialization / clang issue
  patch do
    url "https://github.com/sigrokproject/pulseview/commit/136b891e7b6b7b1e90095c3622d8cbd19a3ab3a4.patch?full_index=1"
    sha256 "05e8bb4d2da92e7e98d5878e7c37b129692859ac89c9d8021eb19e3a6327fbb2"
  end

  # Fix build with glib >= 2.68 (C++ template behind C linkage)
  patch do
    url "https://github.com/sigrokproject/pulseview/commit/ed643f0b4ac587204a5243451cda181ee1405d62.patch?full_index=1"
    sha256 "c3c09f8646873e23a1bc7ed3d5c77239ce8447dcd33de2a32dd9cfcccdfcd3f8"
  end

  def install
    inreplace "CMakeLists.txt" do |s|
      # Boost.Multiprecision needs C++14 or newer
      s.gsub! "-std=c++11", "-std=c++17"
      # Boost.System is header-only and no longer ships a CMake component
      s.gsub! "set(BOOSTCOMPS filesystem serialization system)", "set(BOOSTCOMPS filesystem serialization)"
    end

    args = %w[
      -DDISABLE_WERROR=TRUE
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    ENV["QT_QPA_PLATFORM"] = "offscreen"
    assert_match version.to_s, shell_output("#{bin}/pulseview --version 2>&1")
  end
end
