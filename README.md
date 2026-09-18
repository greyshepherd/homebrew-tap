# Homebrew Tap

Casks for [greyshepherd](https://github.com/greyshepherd) apps.

## Hazmat

A hosts file manager for Apple Silicon Macs. Profiles compose from shared
fragments and switch from the menu bar.

```sh
brew tap greyshepherd/tap
brew install --cask hazmat
```

Hazmat updates itself from inside the app. This tap also reads the newest
release once a day and bumps the cask to it, so `brew install` and `brew
upgrade` name the newest published build.

### Bumping

`Scripts/bump-hazmat.sh` writes the newest release into `Casks/hazmat.rb`, and
the daily workflow runs it. Run it by hand to reach a fresh install sooner.

### Uninstalling

```sh
brew uninstall --cask hazmat            # keeps profiles and preferences
brew uninstall --zap --cask hazmat      # removes those too
```

Uninstalling removes the privileged helper, but a block Hazmat wrote to
`/etc/hosts` stays there — nothing is left to strip it. Turn the block off in
the app first, or delete the lines between the `# >>> hazmat:managed v1 >>>`
markers afterwards.
