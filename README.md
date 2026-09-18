# Homebrew Tap

Casks for [greyshepherd](https://github.com/greyshepherd) apps.

## Hazmat

A hosts file manager for Apple Silicon Macs. Profiles compose from shared
fragments and switch from the menu bar.

```sh
brew tap greyshepherd/tap
brew install --cask hazmat
```

Hazmat updates itself from inside the app, so a cask bump here is only needed
for a fresh install or an explicit `brew upgrade --cask hazmat`.

### Uninstalling

```sh
brew uninstall --cask hazmat            # keeps profiles and preferences
brew uninstall --zap --cask hazmat      # removes those too
```

Uninstalling removes the privileged helper, but a block Hazmat wrote to
`/etc/hosts` stays there — nothing is left to strip it. Turn the block off in
the app first, or delete the lines between the `# >>> hazmat:managed v1 >>>`
markers afterwards.
