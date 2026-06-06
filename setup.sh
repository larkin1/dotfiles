#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf "Welcome to the theme setup process\n\n"

echo "Updating submodules..."

if ! git -C "$SCRIPT_DIR" submodule update --init --remote; then
  echo "Warning: failed to update submodules, continuing..." >&2
fi

echo "Switching to main branch in modules..."

if ! git -C "$SCRIPT_DIR" submodule foreach git switch main; then
  echo "Warning: failed to update submodules, continuing..." >&2
fi

echo "Finished updating submodules!"

echo "Checking dependencies..."
if ! command -v pacman &>/dev/null; then
  echo "Pacman not found... This script is for Arch-based systems only. Please install Arch (or ur cringe)" >&2
  exit 1
fi

verifypacman=(
  qt5ct qt6ct papirus-icon-theme catppuccin-gtk-theme-mocha 
  frameworkintegration hyprland hyprpaper hypridle waybar grim slurp 
  satty wl-clipboard cliphist dunst ghostty yazi fuzzel 
  noto-fonts-emoji ttf-jetbrains-mono-nerd libnotify fd 
  bluez bluez-libs bluez-utils jq plocate cava
)
verifyaur=(
  darkly-bin rose-pine-hyprcursor bemoji
)

notpacman=()
notaur=()

for item in "${verifypacman[@]}"; do
  if ! pacman -Q "$item" &> /dev/null; then
    notpacman+=("$item")
  fi
done
for item in "${verifyaur[@]}"; do
  if ! pacman -Q "$item" &> /dev/null; then
    notaur+=("$item")
  fi
done

if [ ${#notpacman[@]} -ne 0 ]; then
  echo "You seem to be missing some potentially wanted dependencies from the official repos:"
  for item in "${notpacman[@]}"; do
    echo "$item"
  done
  echo
  read -r -p "Would you like to install them now? [Y/n] " confirm
  case "$confirm" in
    [nN]*)
      echo "Skipping installation..."
      ;;
    *)
      echo "Now installing..."
      sudo pacman -S --needed --noconfirm "${notpacman[@]}"
      ;;
  esac
else
  echo "All official repo dependencies already installed!"
fi

if [ ${#notaur[@]} -ne 0 ]; then
  echo "You seem to be missing some potentially wanted dependencies from the aur:"
  for item in "${notaur[@]}"; do
    echo "$item"
  done
  echo
  read -r -p "Would you like to install them now? [Y/n] " confirm
  case "$confirm" in
    [nN]*)
      echo "Skipping installation..."
      ;;
    *)
      echo "Now installing..."
      if command -v yay &>/dev/null; then
        yay -S --needed --noconfirm "${notaur[@]}"
      elif command -v paru &>/dev/null; then
        paru -S --needed --noconfirm "${notaur[@]}"
      else
        echo "No AUR helper found (yay/paru). Install AUR packages manually: ${notaur[*]}"
      fi
      ;;
  esac
else
  echo "All aur dependencies already installed!"
fi


echo "Checking config folder..."
configd="$HOME/.config"
mkdir -p "$configd"
folders=(
  # "qt5ct" "qt6ct" "gtk-3.0" "gtk-4.0"
  "hypr"
  "dunst"
  "fuzzel"
  "ghostty"
  "nvim"
  "starship"
  "waybar"
  "yazi"
  "cava"
)
existing=()

for item in "${folders[@]}"; do
  if [ -e "$configd/$item" ]; then
    existing+=("$configd/$item")
  fi
done

if [ ${#existing[@]} -ne 0 ]; then
  echo "Looks like you already have some configs set up:"
  for item in "${existing[@]}"; do
    echo "$item"
  done
  echo
  read -r -p "Would you like to remove them? [y/N] " confirm
  case "$confirm" in
    [yY]*)
      echo "Removing now..."
      rm -rf -- "${existing[@]}"
      ;;
    *)
      echo "Ok, please manually remove or rename your existing configs and try again."
      echo -e "Conflicts:\n${existing[@]}"
      exit 1
      ;;
  esac
else 
  echo "All good! you don't seem to have configs already set up."
fi

echo "Now creating symbolic links between this folder and the config folder."

for i in "${folders[@]}"; do
  src="$SCRIPT_DIR/$i"
  dest="$configd/$i"

  if [ ! -e "$src" ]; then
    echo "Warning: source '$src' does not exist, skipping."
    continue
  fi

  if [ -L "$dest" ] && [ ! -e "$dest" ]; then
    rm "$dest"
  fi

  if [ -L "$dest" ]; then
    ln -sfn "$src" "$dest"
    echo "Updated symlink: $dest -> $src"
  elif [ -e "$dest" ]; then
    echo "Skipping '$dest' because it already exists and is not a symlink."
  else
    ln -s "$src" "$dest"
    echo "Created symlink: $dest -> $src"
  fi
done

echo "Finished making links, if you move this folder, please remember to re-run this script"
echo "Current folder location: $SCRIPT_DIR"
echo "All done!"

printf "\n\nChecking for additional submodule setup scripts...\n"

found_setups=()
for setup_script in "$SCRIPT_DIR"/*/setup.sh; do
  [ -f "$setup_script" ] || continue
  [ "$setup_script" = "$SCRIPT_DIR/setup.sh" ] && continue
  module_name=$(basename "$(dirname "$setup_script")")
  found_setups+=("$module_name")
done

if [ ${#found_setups[@]} -ne 0 ]; then
  echo "Note: The following submodules have setup scripts that you may want to run manually:"
  for module in "${found_setups[@]}"; do
    echo "  ./$module/setup.sh"
  done
  echo "Run them if you haven't already for full functionality."
fi
