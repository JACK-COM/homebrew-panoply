class Locket < Formula
  include Language::Python::Shebang

  desc "Keeps an AI agent's memory from holding the same fact twice"
  homepage "https://github.com/JACK-COM/locket"
  url "https://github.com/JACK-COM/locket/archive/refs/tags/v0.1.6.tar.gz"
  sha256 "35e74140dc48cc3e0ca521935925918e05e2b709aac4040112c00bd279f03ac0"
  license "MIT"

  depends_on "python@3.14"

  def install
    libexec.install Dir["src/locket/*"]
    rewrite_shebang detected_python_shebang, libexec/"locket.py"
    (bin/"locket").write_env_script libexec/"locket.py", LOCKET_PACKAGED: "1"
  end

  def caveats
    <<~EOS
      To finish, ask your agent to run:
        locket help install
      and follow it. It registers the hooks with your consent;
      `locket doctor` checks the install.

      `locket find` ranks by meaning when ollama serves nomic-embed-text:
        brew install ollama && ollama pull nomic-embed-text
    EOS
  end

  test do
    # memscan's own selftest needs no embedder; memfind's reaches for ollama,
    # which the test sandbox cannot, so `locket selftest` is left to `doctor`
    assert_match "selftest ok", shell_output("#{libexec}/memscan.py selftest 2>&1")
    assert_match version.to_s, shell_output("#{bin}/locket --version")
    assert_match "# Install Locket", shell_output("#{bin}/locket help install")
    fact = "The tide gauge at the north pier is read at dawn and at dusk by the harbourmaster.\n"
    (testpath/"store/one.md").write fact
    (testpath/"store/two.md").write fact
    (testpath/"store/locket.json").write "{}\n"
    assert_match "two.md", shell_output("#{bin}/locket audit #{testpath}/store")
  end
end
