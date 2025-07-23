class Ocrs < Formula
  desc "OCR HTTP service using macOS Vision Framework"
  homepage "https://github.com/EnjoyWT/ocrl"
  url "https://github.com/EnjoyWT/ocrl/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "4d93e8fbe1995a78a7dcc059ffdc299ab8818c36a34c48291a001ccd63af0c70"
  license "MIT"
  
  depends_on :macos => :monterey
  depends_on :xcode => ["13.0", :build]
  
  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/ocrs" => "ocrs"
    (etc/"ocrs").mkpath
    (etc/"ocrs/config.json").write <<~EOS
      {
        "host": "0.0.0.0",
        "port": 7321,
        "log_level": "info",
        "max_file_size": "10MB"
      }
    EOS
  end

  def post_install
    (var/"ocrs").mkpath
    (var/"log").mkpath
  end

  service do
    run [opt_bin/"ocrs"]
    working_dir var/"ocrs"
    log_path var/"log/ocrs.log"
    error_log_path var/"log/ocrs.error.log"
    keep_alive true
  end

  test do
    port = free_port
    pid = fork do
      ENV["PORT"] = port.to_s
      exec bin/"ocrs"
    end
    sleep 3
    begin
      output = shell_output("curl -s http://localhost:#{port}/health")
      assert_match "healthy", output
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
