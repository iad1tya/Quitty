class Quitty < Formula
  desc "macOS system optimization and cleanup utility"
  homepage "https://github.com/iad1tya/Quitty"
  url "https://github.com/iad1tya/Quitty/releases/download/v1.0.0/Quitty.zip"
  sha256 "a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890"
  license "MIT"

  depends_on :macos

  def install
    # Download and extract the app
    system "curl", "-L", url, "-o", "quitty.zip"
    system "unzip", "quitty.zip"
    
    # Install the app to Applications folder
    app_path = "Quitty.app"
    if File.exist?(app_path)
      prefix.install app_path
    else
      odie "Quitty.app not found in downloaded archive"
    end
    
    # Clean up
    system "rm", "quitty.zip"
  end

  def post_install
    # Create a symlink in /Applications for easier access
    app_path = prefix/"Quitty.app"
    target_path = "/Applications/Quitty.app"
    
    if File.exist?(target_path)
      FileUtils.rm_f(target_path)
    end
    
    FileUtils.ln_s(app_path, target_path) unless File.exist?(target_path)
    
    ohai "Quitty has been installed to #{app_path}"
    ohai "A symlink has been created in #{target_path}"
    ohai "You can now launch Quitty from your Applications folder"
  end

  def uninstall
    # Remove symlink from Applications
    FileUtils.rm_f("/Applications/Quitty.app")
  end

  test do
    # Basic test to check if app exists
    assert_predicate prefix/"Quitty.app", :exist?
  end

  caveats do
    <<~EOS
      Quitty has been installed and is available in your Applications folder.
      
      To run Quitty:
        - Open it from Applications folder, or
        - Run: open #{prefix}/Quitty.app
      
      The app will quit when you close the main window.
      
      Installation command: brew install quitty
    EOS
  end
end
