class Augur < Formula
  include Language::Python::Shebang

  desc "Asks a decision model typed questions and returns calibrated probabilities"
  homepage "https://github.com/JACK-COM/augur"
  url "https://github.com/JACK-COM/augur/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "b2f18ccc76c92399edd93184250de09cf838f09d7c88c08ad27bcefac45b9d9b"
  license "MIT"

  depends_on "python@3.14"

  def install
    libexec.install Dir["src/augur/*"]
    rewrite_shebang detected_python_shebang, libexec/"augur.py"
    (bin/"augur").write_env_script libexec/"augur.py", AUGUR_PACKAGED: "1"
  end

  def caveats
    <<~EOS
      To finish, ask your agent to run:
        augur help install
      and follow it. The default backend needs a TypeSafe API key;
      `augur check --live` proves it answers.
    EOS
  end

  test do
    # the selftest stands a stub in for the backend: no network, no key, no model
    assert_match "selftest ok", shell_output("#{bin}/augur selftest")
    assert_match version.to_s, shell_output("#{bin}/augur --version")
    assert_match "# Install Augur", shell_output("#{bin}/augur help install")
    (testpath/".augur/augur.json").write "{\"backnd\": \"laya\"}\n"
    assert_match "did you mean 'backend'", shell_output("HOME=#{testpath} #{bin}/augur check 2>&1", 3)
  end
end
