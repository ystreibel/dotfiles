#!/bin/sh

echo "Setting up your Mac..."

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to install software if not already installed
install_if_not_installed() {
  software_name="$1"
  install_command="$2"
  if ! command_exists "$software_name"; then
    echo "Installing $software_name..."
    eval "$install_command"
    echo "...$software_name install done!"
  else
    echo "$software_name already installed!"
  fi
}

echo "Setting up Chezmoi..."
install_if_not_installed "chezmoi" 'sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "ystreibel"'

echo "Setting up Powerline fonts..."
font_dir="$HOME/Library/Fonts"  # Default for macOS

if [ "$(uname)" != "Darwin" ]; then
  font_dir="$HOME/.local/share/fonts"  # Linux
  mkdir -p "$font_dir"
fi

echo "Installing Powerline fonts..."
font_name="Roboto Mono for Powerline.ttf"
font_url="https://github.com/powerline/fonts/raw/master/RobotoMono/$font_name"

if [ ! -f "$font_dir/$font_name" ]; then
  echo "Copying fonts..."
  curl -S -o "$font_dir/$font_name" "$font_url"

  if which fc-cache >/dev/null 2>&1 ; then
    echo "Resetting font cache, this may take a moment..."
    fc-cache -f "$font_dir"
  fi

  echo "Powerline fonts installed to $font_dir"
  echo "...Powerline fonts install done!"
else
  echo "Powerline fonts already installed!"
fi

# Check if running on macOS
if [ "$(uname)" = "Darwin" ]; then
  # Set up Homebrew
  echo "Setting up your Homebrew"
  install_if_not_installed "homebrew" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # Update and upgrade Homebrew
  brew update
  brew upgrade

  # Install dependencies using Brewfile
  brew tap homebrew/bundle
  brew bundle --file ./Brewfile
  brew cleanup

  # Clone iTerm2-color-schemes
  echo "Installing iTerm2-color-schemes..."
  git clone https://github.com/mbadolato/iTerm2-Color-Schemes  ~/.config/iterm2/iterm2-color-schemes

  echo "Setting up your iTerm2 profile"
  if test ! "/Applications/iTerm.app"; then
    echo "Copying iTerm2 profile..."
    defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.iterm/"
    defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
    echo "...iTerm2 profile copyed!"
    echo "Load Profile called Default in the iTerm2 settings."
  else
    echo "iTerm2 didn't installed!"
  fi
else
  echo "Setting up Fzf"
  if [ ! -d "$HOME/.fzf" ]; then
    echo "Installing Fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install"
  else
    echo "Fzf already installed!"
  fi
fi

if [ -n "$BASH_VERSION" ]; then
  oh_my_bash_path="$HOME/.oh-my-bash"
  oh_my_bash_installer_url="https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh"

  echo "Setting up Oh My Bash..."
  if [ ! -f "$oh_my_bash_path/oh-my-bash.sh" ]; then
    echo "Installing OhMyBash..."
    /bin/sh -c "$(curl -fsSL $oh_my_bash_installer_url)"

    source "$HOME/.bashrc"
    echo "...OhMyBash install done!"
  else
    echo "OhMyBash already installed!"
  fi
fi

if [ -n "$ZSH_VERSION" ]; then
  oh_my_zsh_path="$HOME/.oh-my-zsh"
  oh_my_zsh_installer_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh"

  echo "Setting up Oh My Zsh..."
  if [ ! -f "$oh_my_zsh_path/oh-my-zsh.sh" ]; then
    echo "Installing OhMyZsh..."
    /bin/sh -c "$(curl -fsSL $oh_my_zsh_installer_url)"

    zsh_custom_plugins="${ZSH_CUSTOM:-$oh_my_zsh_path/custom}/plugins"
    zsh_autocomplete_plugin="$zsh_custom_plugins/zsh-autocomplete"
    zsh_autosuggestions_plugin="$zsh_custom_plugins/zsh-autosuggestions"
    zsh_syntax_highlighting_plugin="$zsh_custom_plugins/zsh-syntax-highlighting"

    install_zsh_plugin() {
      plugin_name="$1"
      plugin_url="$2"
      plugin_path="$3"

      if [ ! -d "$plugin_path" ]; then
        echo "Cloning $plugin_name..."
        git clone "$plugin_url" "$plugin_path"
        echo "...$plugin_name clone done!"
      fi
    }

    echo "Installing zsh plugins..."
    install_zsh_plugin "zsh-autocomplete" "https://github.com/marlonrichert/zsh-autocomplete" "$zsh_autocomplete_plugin"
    install_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions" "$zsh_autosuggestions_plugin"
    install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$zsh_syntax_highlighting_plugin"
    echo "...zsh plugins install done!"

    source "$HOME/.zshrc"
    echo "...OhMyZsh install done!"
  else
    echo "OhMyZsh already installed!"
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
