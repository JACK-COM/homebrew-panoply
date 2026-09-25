class Grille < Formula
  include Language::Python::Shebang

  desc "Shows an agent only the pages that answer its question, withholding injections"
  homepage "https://github.com/JACK-COM/grille"
  url "https://github.com/JACK-COM/grille/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "45a3891dbffc393acbb45d59d39629f0786e888d06273cb2a49cba3445a825cb"
  license "MIT"

  depends_on "poppler"
  depends_on "python@3.14"

  def install
    libexec.install Dir["src/grille/*"]
    rewrite_shebang detected_python_shebang, libexec/"grille.py"
    bin.install_symlink libexec/"grille.py" => "grille"
  end

  def caveats
    <<~EOS
      To finish, ask your agent to run:
        grille help install
      and follow it. --decipher needs a chat model you choose, and
      grille reminds you on every run until you set one or turn it off:
        grille configure relay --detect
    EOS
  end

  test do
    # the selftest stands local stand-ins in for the scorer, the relay and the web
    assert_match "selftest ok", shell_output("#{bin}/grille selftest")
    assert_match version.to_s, shell_output("#{bin}/grille --version")
    assert_match "# Install Grille", shell_output("#{bin}/grille help install")
    (testpath/".grille/grille.json").write "{\"relay\": {\"modle\": \"x\"}}\n"
    assert_match "did you mean 'model'", shell_output("HOME=#{testpath} #{bin}/grille check 2>&1", 1)
  end
end
