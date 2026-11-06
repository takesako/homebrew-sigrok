# homebrew-sigrok

Homebrew tap for PulseView and a few USB programming tools that are not in homebrew-core. Bottles (prebuilt binaries) are built by GitHub Actions for Apple Silicon Macs, so `brew install` no longer compiles anything on your machine.

| Formula | Version | Notes |
| --- | --- | --- |
| `pulseview` | 0.4.2 | Qt 5 GUI for sigrok, with upstream build fixes backported |
| `micronucleus` | 2.6 | Command line uploader for the ATtiny micronucleus bootloader |
| `cycfx2prog` | 0.47 | Cypress FX2 programmer, patched to write the I2C EEPROM (`eeprom:AX`, `iic:FILE`) |

libsigrok, libsigrokdecode and sigrok-cli come from homebrew-core, which now ships bottles for them. The fx2lafw firmware is installed as part of homebrew-core's libsigrok.

## Install

```sh
brew install schue30/sigrok/pulseview
brew install sigrok-cli
```

Or tap once and use the short names:

```sh
brew tap schue30/sigrok
brew install pulseview micronucleus cycfx2prog
```

## Switching from takesako/sigrok

This tap started as a fork of `takesako/sigrok`, which has its own libsigrok, libsigrokdecode, sigrok-cli and sigrok-firmware-fx2lafw formulae. They install the same files as the homebrew-core versions. Remove them and the old tap before installing from this one:

```sh
brew uninstall --ignore-dependencies pulseview sigrok-cli libsigrok libsigrokdecode sigrok-firmware-fx2lafw
brew untap takesako/sigrok
brew update
brew install schue30/sigrok/pulseview sigrok-cli
```

## Known limitations

PulseView 0.4.2 needs Qt 5. Homebrew has deprecated `qt@5` and plans to disable it on 2027-05-19. PulseView's master branch builds with Qt 6, but it needs libsigrokdecode features that have not been released yet, so it can't use homebrew-core's libsigrokdecode 0.5.3. The PulseView formula moves to Qt 6 once sigrok publishes new releases.

`brew install --HEAD pulseview` is not supported for the same reason.

## Maintaining the tap

Every pull request runs `brew test-bot` on macOS 15 and macOS 26 (both arm64). The bottles it builds are attached to the workflow run. To publish them:

1. Wait until all checks on the pull request pass.
2. Run the "brew pr-pull" workflow from the Actions tab with the pull request number.

The workflow uploads the bottles to a GitHub release, adds the `bottle do` block to the formula, and pushes the result to `master`. Bottles built on macOS 15 also install on later macOS releases.
