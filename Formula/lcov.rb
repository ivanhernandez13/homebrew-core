require "language/perl"

class Lcov < Formula
  include Language::Perl::Shebang

  desc "Graphical front-end for GCC's coverage testing tool (gcov)"
  homepage "https://github.com/linux-test-project/lcov"
  url "https://github.com/linux-test-project/lcov/releases/download/v1.16/lcov-1.16.tar.gz"
  sha256 "987031ad5528c8a746d4b52b380bc1bffe412de1f2b9c2ba5224995668e3240b"
  license "GPL-2.0-or-later"
  head "https://github.com/linux-test-project/lcov.git", branch: "master"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_monterey: "bab0e9f810cffad96404c8cd78377925b162ac286a74223f0cd749fe6a008dbc"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "46b38875aa7bb7f7604e95126b03e1a68897aba7e5cb5c59fd97ff831b729d04"
    sha256 cellar: :any_skip_relocation, monterey:       "65a02bd256b693b90435c7b0cc72bc032edbb27225c5e4c511a8bcaf53cd9e10"
    sha256 cellar: :any_skip_relocation, big_sur:        "54ec973afb4d98a5efa8f016f0588fbfd5eb3f0986c8914ce05c71a6b85763bd"
    sha256 cellar: :any_skip_relocation, catalina:       "aa3b34c95a9e00eb9b65735cfd93a57d50703d50e1f07931d48325f9e3fd1a26"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "cdf87e195d48b9cf3311cf86cf7576c08c89893d9dee1b99a55b5e70c2ba3deb"
  end

  uses_from_macos "perl"
  uses_from_macos "zlib"

  resource "JSON" do
    url "https://cpan.metacpan.org/authors/id/I/IS/ISHIGAKI/JSON-4.06.tar.gz"
    sha256 "1137e98a42208d802f3ad94a10855606c0455ddad167ba018557d751f6f7672e"
  end

  resource "PerlIO::gzip" do
    url "https://cpan.metacpan.org/authors/id/N/NW/NWCLARK/PerlIO-gzip-0.20.tar.gz"
    sha256 "4848679a3f201e3f3b0c5f6f9526e602af52923ffa471a2a3657db786bd3bdc5"
  end

  def install
    ENV.prepend_create_path "PERL5LIB", libexec+"lib/perl5"

    resources.each do |r|
      r.stage do
        system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
        system "make"
        system "make", "install"
      end
    end

    inreplace %w[bin/genhtml bin/geninfo bin/lcov],
      "/etc/lcovrc", "#{prefix}/etc/lcovrc"
    system "make", "PREFIX=#{prefix}", "BIN_DIR=#{bin}", "MAN_DIR=#{man}", "install"

    # Disable dynamic selection of perl which may cause segfault when an
    # incompatible perl is picked up.
    # https://github.com/Homebrew/homebrew-core/issues/4936
    rewrite_shebang detected_perl_shebang, *bin.children

    bin.env_script_all_files(libexec/"bin", PERL5LIB: ENV["PERL5LIB"])
  end

  test do
    gcc = ENV.cc
    gcov = "gcov"

    (testpath/"hello.c").write <<~EOS
      #include <stdio.h>
      int main(void)
      {
          puts("hello world");
          return 0;
      }
    EOS

    system gcc, "-g", "-O2", "--coverage", "-o", "hello", "hello.c"
    system "./hello"
    system "#{bin}/lcov", "--gcov-tool", gcov, "--directory", ".", "--capture", "--output-file", "all_coverage.info"

    assert_predicate testpath/"all_coverage.info", :exist?
    assert_includes (testpath/"all_coverage.info").read, testpath/"hello.c"
  end
end
