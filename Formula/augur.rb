class Augur < Formula
  include Language::Python::Shebang

  desc "Asks a decision model typed questions and returns calibrated probabilities"
  homepage "https://github.com/JACK-COM/augur"
  url "https://github.com/JACK-COM/augur/archive/refs/tags/v0.6.1.tar.gz"
  sha256 "471691c1dce5311b429aa2a7ccfdadf19d0ba6c4c218a3baea4e72daf9612403"
  license "MIT"

  depends_on "python@3.14"

  def install
    libexec.install Dir["src/augur/*"]
    rewrite_shebang detected_python_shebang, libexec/"augur.py"
    (bin/"augur").write_env_script libexec/"augur.py", AUGUR_PACKAGED: "1"
  end

  def caveats
    <<~EOS
      To finish, run:
        augur configure backend
      which asks where your model runs and saves it once it answers.
      The default backend, jev, needs only your TypeSafe API key:
        augur configure backend jev --store-key
      Or ask your agent to run `augur help install` and follow it.
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
