#!/bin/bash

echo "Checking and installing dependencies..."

# Get the script's directory (pdf_pipeline/scripts/) and project root (vaults/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"  # vaults/
FILTER_DIR="$PROJECT_ROOT/pdf_pipeline/latex/filters"
FILTER_PATH="$FILTER_DIR/pandoc-mermaid.py"

# Function to detect if we're in Docker or a container
is_docker() {
  [ -f /.dockerenv ] || [ -f /run/.containerenv ]
}

# Function to check if a command exists
check_command() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Function to install system packages based on distro (host only)
install_system_package() {
  local pkg="$1"          # Display name (e.g., "latexmk")
  local ubuntu_pkg="$2"   # Ubuntu package name
  local fedora_pkg="$3"   # Fedora package name
  local arch_pkg="$4"     # Arch package name

  echo "Installing $pkg..."
  if [ -f /etc/debian_version ]; then
    sudo apt-get update && sudo apt-get install -y "$ubuntu_pkg" || {
      echo "Failed to install $pkg with apt-get."
      exit 1
    }
  elif [ -f /etc/fedora-release ]; then
    sudo dnf install -y "$fedora_pkg" || {
      echo "Failed to install $pkg with dnf."
      exit 1
    }
  elif [ -f /etc/arch-release ]; then
    sudo pacman -Syu --noconfirm "$arch_pkg" || {
      echo "Failed to install $pkg with pacman."
      exit 1
    }
  else
    echo "Unsupported OS. Please install $pkg manually."
    exit 1
  fi
  echo "$pkg installed successfully."
}

# Function to check system dependencies
check_system_deps() {
  echo "Checking system dependencies..."

  # Define dependencies: command, ubuntu pkg, fedora pkg, arch pkg
  local deps=(
    "make:make:make:make"
    "pandoc:pandoc:pandoc:pandoc"
    "latexmk:texlive-latexmk:texlive-latexmk:texlive-bin"
    "lualatex:texlive-luatex:texlive-luatex:texlive-core"
    "python3:python3:python3:python"
    "pip:python3-pip:python3-pip:python-pip"
    "node:nodejs:nodejs:nodejs"
    "npm:npm:npm:npm"
    "jq:jq:jq:jq"
  )

  if is_docker; then
    local missing=()
    for dep in "${deps[@]}"; do
      IFS=':' read -r cmd _ _ _ <<< "$dep"
      if ! check_command "$cmd"; then
        missing+=("$cmd")
      fi
    done
    if [ "${#missing[@]}" -gt 0 ]; then
      echo "ERROR: The following system dependencies are missing in Docker:"
      for dep in "${missing[@]}"; do
        echo "  - $dep"
      done
      echo "Update your Dockerfile to include these dependencies and rebuild the image."
      exit 1
    fi
  else
    for dep in "${deps[@]}"; do
      IFS=':' read -r cmd ubuntu_pkg fedora_pkg arch_pkg <<< "$dep"
      if ! check_command "$cmd"; then
        echo "$cmd is missing."
        install_system_package "$cmd" "$ubuntu_pkg" "$fedora_pkg" "$arch_pkg"
      fi
    done
  fi
}

# Function to check and install Python dependencies
setup_python() {
  if ! check_command "python3"; then
    echo "ERROR: python3 is missing."
    exit 1
  fi
  if ! check_command "pip"; then
    echo "ERROR: pip is missing."
    exit 1
  fi

  cd "$PROJECT_ROOT" || { echo "Failed to switch to project root ($PROJECT_ROOT)"; exit 1; }

  # Check custom Mermaid filter
  if [ ! -f "$FILTER_PATH" ]; then
    echo "ERROR: Custom Mermaid filter not found at $FILTER_PATH."
    echo "This is a project-specific file required for the pipeline."
    echo "Please ensure pdf_pipeline/latex/filters/pandoc-mermaid.py exists."
    exit 1
  fi

  local py_packages=("pandocfilters" "pygments")
  local is_arch=false
  if [ -f /etc/arch-release ]; then
    is_arch=true
  fi

  if is_docker; then
    local missing=()
    for pkg in "${py_packages[@]}"; do
      if ! python3 -c "import $pkg" >/dev/null 2>&1; then
        missing+=("$pkg")
      fi
    done
    if [ "${#missing[@]}" -gt 0 ]; then
      echo "ERROR: The following Python packages are missing in Docker:"
      for pkg in "${missing[@]}"; do
        echo "  - $pkg"
      done
      echo "Update your Dockerfile to include these dependencies and rebuild the image."
      exit 1
    fi
    if [ -f "requirements.txt" ]; then
      echo "WARNING: Found requirements.txt in Docker at $PROJECT_ROOT/requirements.txt. Ensure the image includes all required dependencies."
    fi
  else
    if [ "$is_arch" = true ]; then
      echo "Detected Arch Linux. Using virtual environment as required by PEP 668."
    fi

    # Set up virtual environment
    if [ ! -d "venv" ] || [ ! -f "venv/bin/activate" ]; then
      echo "Creating Python virtual environment..."
      python3 -m venv venv || { echo "Failed to create virtual environment."; exit 1; }
      source venv/bin/activate || { echo "Failed to activate virtual environment."; exit 1; }
    else
      if [ -z "$VIRTUAL_ENV" ]; then
        echo "Activating existing Python virtual environment..."
        source venv/bin/activate || { echo "Failed to activate virtual environment."; exit 1; }
      fi
    fi

    # Check and install Python packages
    local need_install=false
    for pkg in "${py_packages[@]}"; do
      if ! python3 -c "import $pkg" >/dev/null 2>&1; then
        echo "Python package $pkg is missing."
        need_install=true
      fi
    done

    if [ "$need_install" = true ]; then
      echo "Installing missing Python packages in venv..."
      for pkg in "${py_packages[@]}"; do
        if ! python3 -c "import $pkg" >/dev/null 2>&1; then
          echo "Installing $pkg..."
          pip install --quiet "$pkg" 2>/dev/null || { echo "Failed to install $pkg."; exit 1; }
          echo "$pkg installed."
        fi
      done
    fi

    # Handle requirements.txt
    if [ -f "requirements.txt" ]; then
      echo "Found requirements.txt. Checking if dependencies are satisfied..."
      # Adjust version checks based on your requirements.txt
      if pip freeze | grep -q "pandocfilters" && pip freeze | grep -q "Pygments"; then
        echo "Dependencies in requirements.txt are already satisfied."
      else
        echo "Installing dependencies from requirements.txt..."
        pip install --quiet -r requirements.txt 2>/dev/null || {
          echo "Failed to install dependencies from requirements.txt."
          if [ "$is_arch" = true ]; then
            echo "This may be due to an externally managed environment (PEP 668)."
            echo "Verify that 'venv' is correctly set up and activated."
          fi
          exit 1
        }
        echo "Dependencies from requirements.txt installed."
      fi
    fi
  fi
}

# Function to check and install Node.js dependencies
setup_npm() {
  if ! check_command "node"; then
    echo "ERROR: node is missing."
    exit 1
  fi
  if ! check_command "npm"; then
    echo "ERROR: npm is missing."
    exit 1
  fi
  npm -v >/dev/null 2>&1 || { echo "ERROR: npm is installed but not working properly."; exit 1; }
  if ! check_command "jq"; then
    echo "ERROR: jq is required to parse package.json, but it's not installed."
    if is_docker; then
      echo "Update your Dockerfile to include jq (e.g., 'apt-get install jq')."
    else
      echo "Please install jq (e.g., 'apt-get install jq', 'dnf install jq', 'pacman -S jq')."
    fi
    exit 1
  fi

  cd "$PROJECT_ROOT" || { echo "Failed to switch to project root ($PROJECT_ROOT)"; exit 1; }

  local npm_packages=("@mermaid-js/mermaid-cli@10.9.1")  # Only mmdc for pandoc-mermaid.py

  if is_docker; then
    local missing=()
    if [ -d "node_modules" ]; then
      for pkg in "${npm_packages[@]}"; do
        local pkg_name=$(echo "$pkg" | cut -d@ -f1)
        if [ ! -d "node_modules/$pkg_name" ]; then
          missing+=("$pkg_name")
        fi
      done
    else
      missing=("${npm_packages[@]/@*/}")
    fi
    if [ "${#missing[@]}" -gt 0 ]; then
      echo "ERROR: The following Node.js packages are missing in Docker:"
      for pkg in "${missing[@]}"; do
        echo "  - $pkg"
      done
      echo "Update your Dockerfile to include these dependencies and rebuild the image."
      exit 1
    fi
    # Check mmdc specifically
    if ! "$PROJECT_ROOT/node_modules/.bin/mmdc" --version >/dev/null 2>&1; then
      echo "ERROR: mmdc (Mermaid CLI) not found in Docker at $PROJECT_ROOT/node_modules/.bin/mmdc."
      echo "Update your Dockerfile to include @mermaid-js/mermaid-cli@10.9.1."
      exit 1
    fi
  else
    # Check and install Node.js packages
    local need_install=false
    if [ -d "node_modules" ]; then
      for pkg in "${npm_packages[@]}"; do
        local pkg_name=$(echo "$pkg" | cut -d@ -f1)
        if [ ! -d "node_modules/$pkg_name" ]; then
          echo "Node.js package $pkg_name is missing."
          need_install=true
        fi
      done
    else
      echo "node_modules directory missing. Marking packages for install..."
      need_install=true
    fi

    if [ "$need_install" = true ]; then
      if [ ! -f "package.json" ]; then
        echo "No package.json found. Creating one..."
        npm init -y >/dev/null 2>&1 || { echo "Failed to create package.json."; exit 1; }
      fi
      echo "Installing Mermaid CLI (@mermaid-js/mermaid-cli)..."
      npm install "${npm_packages[@]}" --save-exact || { echo "Failed to install Mermaid CLI."; exit 1; }
      echo "Mermaid CLI installed."
    fi

    # Verify mmdc
    if ! "$PROJECT_ROOT/node_modules/.bin/mmdc" --version >/dev/null 2>&1; then
      echo "ERROR: mmdc (Mermaid CLI) not installed correctly at $PROJECT_ROOT/node_modules/.bin/mmdc."
      echo "Try running: npm install @mermaid-js/mermaid-cli@10.9.1 --prefix $PROJECT_ROOT"
      exit 1
    fi
  fi
}

# Function to check for Fira Code font and install if needed
setup_fira_font() {
  echo "Checking for Fira Code font..."

  local fonts_dir="$PROJECT_ROOT/pdf_pipeline/assets/Fonts"
  local fira_fonts=(
    "FiraCode-Bold.ttf"
    "FiraCode-Light.ttf"
    "FiraCode-Medium.ttf"
    "FiraCode-Regular.ttf"
    "FiraCode-Retina.ttf"
    "FiraCode-SemiBold.ttf"
  )

  check_font_installed() {
    local has_font=false
    if [ "$(uname)" == "Darwin" ]; then
      if find ~/Library/Fonts /Library/Fonts -name "FiraCode*.ttf" -o -name "Fira Code*.ttf" 2>/dev/null | grep -q .; then
        has_font=true
      fi
    elif [ "$(uname)" == "Linux" ]; then
      if find /usr/share/fonts /usr/local/share/fonts ~/.fonts ~/.local/share/fonts -name "FiraCode*.ttf" -o -name "Fira Code*.ttf" 2>/dev/null | grep -q .; then
        has_font=true
      fi
    elif [ "$(uname -s | cut -c 1-10)" == "MINGW32_NT" ] || [ "$(uname -s | cut -c 1-10)" == "MINGW64_NT" ]; then
      if find "/c/Windows/Fonts" -name "FiraCode*.ttf" -o -name "Fira Code*.ttf" 2>/dev/null | grep -q .; then
        has_font=true
      fi
    fi
    [ "$has_font" = true ]
  }

  check_project_fonts() {
    local all_found=true
    for font in "${fira_fonts[@]}"; do
      if [ ! -f "$fonts_dir/$font" ]; then
        all_found=false
        break
      fi
    done
    [ "$all_found" = true ]
  }

  if check_font_installed; then
    return 0
  fi

  if check_project_fonts; then
    return 0
  fi

  echo "Fira Code font not found locally or in project. Downloading..."
  mkdir -p "$fonts_dir" || { echo "Failed to create fonts directory."; exit 1; }

  local fira_version="6.2"
  local fira_url="https://github.com/tonsky/FiraCode/releases/download/${fira_version}/Fira_Code_v${fira_version}.zip"
  local temp_dir=$(mktemp -d)
  local zip_file="$temp_dir/fira_code.zip"

  if check_command "curl"; then
    curl -L -o "$zip_file" "$fira_url" >/dev/null 2>&1 || { echo "Failed to download Fira Code font with curl."; exit 1; }
  elif check_command "wget"; then
    wget -O "$zip_file" "$fira_url" >/dev/null 2>&1 || { echo "Failed to download Fira Code font with wget."; exit 1; }
  else
    echo "Neither curl nor wget is available to download fonts."
    exit 1
  fi

  if check_command "unzip"; then
    unzip -q "$zip_file" -d "$temp_dir" || { echo "Failed to extract Fira Code font."; exit 1; }
  else
    echo "unzip command is not available. Please install unzip."
    exit 1
  fi

  echo "Installing Fira Code font to project directory..."
  for font in "${fira_fonts[@]}"; do
    if [ -f "$temp_dir/ttf/$font" ]; then
      cp "$temp_dir/ttf/$font" "$fonts_dir/" || { echo "Failed to copy $font to project."; exit 1; }
    else
      echo "Warning: Could not find $font in downloaded package."
    fi
  done

  rm -rf "$temp_dir"

  if check_project_fonts; then
    echo "Fira Code fonts successfully installed to project directory."
  else
    echo "Warning: Some Fira Code fonts may not have been installed correctly."
    return 1
  fi
}

# Main execution
main() {
  check_system_deps
  setup_python
  setup_npm
  setup_fira_font

  echo "All dependencies checked and installed where needed."
  echo "Ready to go in $PROJECT_ROOT with custom Mermaid filter at $FILTER_PATH."
}

main
