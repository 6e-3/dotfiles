# Dotfiles

## Installation

### ▼ One-Liner

``` shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/6e-3/dotfiles/trunk/install.sh)"
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
- `DOTFILES_INIT`
  - Execution the initialization with specified.
  - e.g. `DOTFILES_INIT=1`

## Uninstallation

``` shell
cd ~/.dotfiles && make uninstall
```
