cask "halo" do
  version "0.8.2"
  sha256 "1b7f8374ddc52286575993adfdb726f1156301afa069892c2daec0ddb2972c09"

  url "https://github.com/bayesianhunter/halo/releases/download/v#{version}/Halo-#{version}.zip"
  name "Halo"
  desc "Per-device scrolling, peripheral batteries and diagnostics your agent can use"
  homepage "https://github.com/bayesianhunter/halo"

  livecheck do
    url "https://halo.liuzhekan.com/appcast.xml"
    strategy :sparkle, &:short_version
  end

  # Halo updates itself through Sparkle; brew leaves upgrades of a running copy to it.
  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :tahoe

  app "Halo.app"
  binary "#{appdir}/Halo.app/Contents/MacOS/Halo", target: "halo"

  # Halo's own links into this copy's bundled agent skill go with the app: a link whose whole target, after trailing
  # and doubled slashes are dropped, is exactly that folder. A folder, or a link to anything else, is someone else's
  # and stays. Checked whenever brew removes this copy, so also by `brew reinstall` and by an upgrade of Halo through
  # brew (`brew upgrade halo`, or `--greedy`), after which Halo's Diagnostics offers to add the skill again. The home
  # folder comes from the account record (the field before the shell, as a full name may hold a colon), since Homebrew
  # gives the command a sandbox $HOME of its own. Tools are named by path, so another `id` or `tr` earlier in PATH
  # cannot change the result.
  uninstall_postflight_steps do
    run "/bin/sh",
        args:           [
          "-c",
          "home=$(/usr/bin/id -P); home=${home%:*}; home=${home##*:}; " \
          "case $home in /?*) ;; *) exit 0 ;; esac; " \
          'want=$(printf %s "$1" | /usr/bin/tr -s /); ' \
          'for link in "$home/.agents/skills/halo" "$home/.claude/skills/halo"; do ' \
          '[ -L "$link" ] || continue; ' \
          'target=$(/usr/bin/readlink "$link" | /usr/bin/tr -s /); ' \
          'while [ "$target" != / ] && [ "${target%/}" != "$target" ]; do target=${target%/}; done; ' \
          '[ "$target" = "$want" ] && /bin/rm -f "$link"; ' \
          "done; exit 0",
          "sh",
          "{{appdir}}/Halo.app/Contents/Resources/AgentSkill",
        ],
        must_succeed:   false,
        writable_paths: [".agents/skills", ".claude/skills"],
        writable_base:  :home
  end

  uninstall quit: "com.liuzhekan.Halo"

  # The same places as Footprint.files (Sources/HaloCore/Footprint.swift); the skill links go on uninstall, above.
  # The pairing key and Open at Login are removed by Uninstall Halo… in the app, which also tells the paired Mac
  # when it is connected.
  zap trash: [
    "~/Library/Application Support/Halo",
    "~/Library/Caches/com.liuzhekan.Halo",
    "~/Library/HTTPStorages/com.liuzhekan.Halo",
    "~/Library/HTTPStorages/com.liuzhekan.Halo.binarycookies",
    "~/Library/Preferences/com.liuzhekan.Halo.plist",
    "~/Library/Saved Application State/com.liuzhekan.Halo.savedState",
    "~/Library/WebKit/com.liuzhekan.Halo",
  ]
end
