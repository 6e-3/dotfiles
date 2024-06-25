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

## Installation Options

You can customize the installation by setting environment variables.

### ▼ Environment variables

- **DOTFILES_BRANCH**
  - Specity the branch for download.
- **DOTFILES_DOWNLOADER**
  - Specify the downloader to use the for downloading this repository.
  - Available commands:
    - git
    - curl
    - wget
  - If not specified, the commands available in the above order are used for download.
