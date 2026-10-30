class Grille < Formula
  include Language::Python::Shebang

  desc "Shows an agent only the pages that answer its question, withholding injections"
  homepage "https://github.com/JACK-COM/grille"
  url "https://github.com/JACK-COM/grille/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "48d9577cd5dde75f328b874c4ed205b558b588bfc97945d91b120a90c8466f1a"
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
