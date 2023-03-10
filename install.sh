#!/bin/sh

echo "Setting up your Mac..."

echo "Setting up Chezmoi..."
if test ! "$(which chezmoi)"; then
  echo "Installing Chezmoi..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "ystreibel"
  echo "...Chezmoi install done!"
else
  echo "Chezmoi already installed!"
fi

if test "$(uname)" = "Darwin" ; then
  echo "Setting up your Homebrew"
  # Check for Homebrew and install if we don't have it
  if test ! "$(which brew)"; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo "...Homebrew install done!"
  else
    echo "Homebrew already installed!"
  fi

  # Update Homebrew recipes
  brew update

  # Upgrade any already-installed formulae.
  brew upgrade

  # Install all our dependencies with bundle (See Brewfile)
  brew tap homebrew/bundle
  brew bundle --file ./Brewfile

  brew cleanup
fi

if [ -n "$BASH_VERSION" ]; then

  echo "Setting up Fzf"
  if test ! "$HOME/.fzf.bash"; then
    echo "Installing Fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install"
  else
    echo "Fzf already installed!"
  fi

  echo "Setting up Oh My Bash..."
  # Check for Oh My Zsh and install if we don't have it
  if [ ! -f "$HOME/.oh-my-bash/oh-my-bash.sh" ]; then
    echo "Installing OhMyBash..."
    /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"

    echo "Installing zsh Agnoster theme"
    if [ ! -f "$HOME/.oh-my-bash/custom/themes/agnoster" ]; then
      git clone https://github.com/agnoster/agnoster-zsh-theme.git "$HOME/.oh-my-bash/custom/themes/agnoster"
      echo "...zsh agnostert theme install done!"
    else
      echo "Zsh agnostert theme already installed!"
    fi
    source "$HOME/.bashrc"
    echo "...OhMyBash install done!"
  else
    echo "OhMyBash already installed!"
  fi
else
  echo "Setting up Oh My Zsh..."
  # Check for Oh My Zsh and install if we don't have it
  if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    echo "Installing OhMyZsh..."
    /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
    echo "Installing zsh plugins..."
    if test ! "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"; then
      echo "Cloning zsh-autosuggestions..."
      git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
      echo "...zsh-autosuggestions clone done!"
    fi
    if test ! "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"; then
      echo "Cloning zsh-syntax-highlighting..."
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
      echo "...zsh-syntax-highlighting clone done!"
    fi
    echo "...zsh plugins install done!"
    source "$HOME/.zshrc"
    echo "...OhMyZsh install done!"
  else
    echo "OhMyZsh already installed!"
  fi
fi

echo "Setting up Powerline fonts..."
# Check for Powerline fonts  and install if we don't have it

if test "$(uname)" = "Darwin" ; then
  # MacOS
  font_dir="$HOME/Library/Fonts"
else
  # Linux
  font_dir="$HOME/.local/share/fonts"
  mkdir -p "$font_dir"
fi

echo "Installing Powerline fonts..."
if [ ! -f "$font_dir/Roboto\ Mono\ for\ Powerline.ttf" ]; then
  echo "Copying fonts..."
  curl -S -o "$font_dir/Roboto Mono for Powerline.ttf" https://github.com/powerline/fonts/raw/master/RobotoMono/Roboto%20Mono%20for%20Powerline.ttf

  # Reset font cache on Linux
  if which fc-cache >/dev/null 2>&1 ; then
      echo "Resetting font cache, this may take a moment..."
      fc-cache -f "$font_dir"
  fi
  echo "Powerline fonts installed to $font_dir"

  echo "...Powerline fonts install done!"
else
  echo "Powerline fonts already installed!"
fi

if test "$(uname)" = "Darwin" ; then
  echo "Setting up your iTerm2 profile"
  if test ! "/Applications/iTerm.app"; then
    echo "Copying iTerm2 profile..."
    cp "$HOME/.iterm/iTermProfile.json" "$HOME/Library/Application Support/iTerm2/DynamicProfiles/"
    echo "...iTerm2 profile copyed!"
    echo "Load Profile called Default in the iTerm2 settings."
  else
    echo "iTerm2 didn't installed!"
  fi
fi

echo "Setting up your ssh key"
github_settings_url="https://github.com/settings/keys"
bitbucket_settings_url="https://scm.corp.myscript.com/plugins/servlet/ssh/account/keys"
ssh_public_key_file="${HOME}/.ssh/id_ed25519.pub"
ssh_config_file="$HOME/.ssh/config"

if [ -f "${ssh_public_key_file}" ]; then
  echo "ssh public key already created."
else
  echo "Generating a new SSH key for GitHub..."
  read -p "Enter your email account: " email
  ssh-keygen -t ed25519 -C "${email}" -f "${ssh_public_key_file}"
  eval "$(ssh-agent -s)"

  touch "${ssh_config_file}"
  printf 'Host *\n AddKeysToAgent yes\n UseKeychain yes\n IdentityFile %s' "${ssh_public_key_file}" | tee "${ssh_config_file}"

  ssh-add -K "${ssh_public_key_file}"

  echo "Register the public ssh key in github account"
  if test ! "$(which firefox)"; then
    firefox "${github_settings_url}"
  else
    echo "Add key to github ${github_settings_url}"
  fi
  cat "${ssh_public_key_file}"
  read -p "Confirm that this key is registered on github before continuing...[<Space>]" -n 1 -r

  echo "Register the public ssh key in bitbucket account"
  if test ! "$(which firefox)"; then
    firefox "${bitbucket_settings_url}"
  else
    echo "Add key to bitbucket ${bitbucket_settings_url}"
  fi
  cat "${ssh_public_key_file}"
  read -p "Confirm that this key is registered on bitbucket before continuing...[<Space>]" -n 1 -r
fi
