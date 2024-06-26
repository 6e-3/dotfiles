# Dotfiles

## Installation

### ▼ One-Liner

``` shell
curl -fsSL https://raw.githubusercontent.com/6e-3/dotfiles/trunk/install.sh | bash
```

With initialization:

``` shell
curl -fsSL https://raw.githubusercontent.com/6e-3/dotfiles/trunk/install.sh | bash -s init
```

### ▼ Run Install Script

You can `git clone` this repository to `~/.dotfiles` and run install script.

``` shell
git clone https://github.com/6e-3/dotfiles.git ~/.dotfiles
```

- Run the script directly
  - `~/.dotfiles/install.sh`
- Using make
  - `cd ~/.dotfiles && make install`

With initialization:

- Run the script directly
  - `~/.dotfiles/install.sh init`
- Using make
  - `cd ~/.dotfiles && make init && make install`

## Installation Options

You can customize the installation by setting environment variables.

### ▼ Environment Variables

- `DOTFILES_BRANCH`
  - Specity the branch for download.
- `DOTFILES_DOWNLOADER`
  - Specify the downloader to use the for downloading this repository.
  - Available commands:
    - git
    - curl
    - wget
  - If not specified, the commands available in the above order are used for download.

## Uninstallation

``` shell
cd ~/.dotfiles && make uninstall
```
