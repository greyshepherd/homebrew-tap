cask "hazmat" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/greyshepherd/hazmat/releases/download/v#{version}/Hazmat-#{version}.dmg"
  name "Hazmat"
  desc "Hosts file manager with switchable profiles of shared fragments"
  homepage "https://github.com/greyshepherd/hazmat"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "Hazmat.app"

  uninstall launchctl: "com.greyshepherd.hazmat.daemon",
            quit:      "com.greyshepherd.hazmat"

  zap trash: [
    "~/Library/Application Support/Hazmat",
    "~/Library/Caches/com.greyshepherd.hazmat",
    "~/Library/HTTPStorages/com.greyshepherd.hazmat",
    "~/Library/Preferences/com.greyshepherd.hazmat.plist",
  ]

  caveats <<~EOS
    The helper that writes /etc/hosts is installed from inside the app, and only
    the first apply asks for your password. Uninstalling removes the helper, but
    a block Hazmat wrote to /etc/hosts stays there, so turn the block off in the
    app before uninstalling.
  EOS
end
