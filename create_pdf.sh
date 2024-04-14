#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export PUPPETEER_EXECUTABLE_PATH=$(which chromium)

# Check if the variable was set and if the file exists
if [ -z "$PUPPETEER_EXECUTABLE_PATH" ] || [ ! -f "$PUPPETEER_EXECUTABLE_PATH" ]; then
    echo "WARNING: Chromium is not found. Mermaid diagrams will fail."
fi

template="${DIR}/latex/template.latex"
toc="$2"

# Function to install Pygments depending on the OS distribution
install_pygments() {
  if grep -q 'ID=arch' /etc/os-release; then
    echo "Arch Linux detected. Installing Pygments using pacman..."
    sudo pacman -Syu python-pygments --noconfirm
  else
    echo "Non-Arch Linux distribution detected. Installing Pygments using pip3..."
    sudo pip3 install pygments
  fi
}

# Check if Pygments is installed
if ! command -v pygmentize &> /dev/null; then
  echo "Pygments is not installed. Installing..."
  install_pygments
  if ! command -v pygmentize &> /dev/null; then
    echo "Failed to install Pygments."
  else
    echo "Pygments installed successfully."
  fi
else
  echo "Pygments is already installed."
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
  echo "WARNING: npm is not installed. Some features might not work."
else
  echo "npm is installed. Checking for required npm packages..."

  # List of npm packages to check and install if necessary
  declare -A npm_packages=(
    [puppeteer]="puppeteer --unsafe-perm=true"
    [mermaid-filter]="mermaid-filter --unsafe-perm=true"
  )

  # Iterate over the npm package list and install missing packages
  for pkg in "${!npm_packages[@]}"; do
    if ! npm list -g | grep -q $pkg; then
      echo "$pkg is not installed. Installing..."
      sudo npm install -g ${npm_packages[$pkg]}
      if [ $? -ne 0 ]; then
        echo "Failed to install $pkg."
      else
        echo "$pkg installed successfully."
      fi
    else
      echo "$pkg is already installed."
    fi
  done
fi

# Ensure an input file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <input_file> [toc]"
  exit 1
fi

IN_FILE="$1"
IN_DIR=$(dirname "${IN_FILE}")
PDF_DIR="${IN_DIR}/pdf"
BUILD_DIR="${DIR}/build"
mkdir -p "${PDF_DIR}"
mkdir -p "${BUILD_DIR}"

FILE_BASENAME=$(basename "${IN_FILE}" .md)
TEX_FILE="${BUILD_DIR}/${FILE_BASENAME}.tex"

# Generate .tex from Markdown
#PANDOC_CMD="pandoc \"${IN_FILE}\" --from markdown --template=\"${template}\" --filter ./latexa/pandoc-minted --highlight-style=pygments --trace --data-dir=\"${DIR}\""
PANDOC_CMD="pandoc \"${IN_FILE}\" --from markdown --template=\"${template}\" -F mermaid-filter --filter ./latex/pandoc-minted --highlight-style=pygments --trace --data-dir=\"${DIR}\""

# Add --toc option if TOC is requested
if [ -n "$toc" ]; then
    PANDOC_CMD+=" --toc"
fi

# Execute Pandoc command to generate .tex file
eval $PANDOC_CMD -o "\"${TEX_FILE}\"" 2>pandoc_error.tmp

# Check if Pandoc command succeeded
if [ $? -ne 0 ]; then
  echo "Error producing LaTeX for ${IN_FILE}. Check pandoc_error.log for details."
  cat pandoc_error.tmp >> pandoc_error.log
  echo "Error occurred in file ${IN_FILE}" >> pandoc_error.log
  rm -f pandoc_error.tmp
  exit 1
fi

# Command to compile the document using latexmk
#eval latexmk -pdf -pdflatex="pdflatex -shell-escape %O %S" -output-directory="${BUILD_DIR}" "${TEX_FILE}" 2>>pandoc_error.tmp

# Correctly specifying the pdflatex command for latexmk
#LATEXMK_CMD="latexmk -pdf -pdflatex=\"pdflatex -shell-escape %O %S\" -output-directory=\"${BUILD_DIR}\" \"${TEX_FILE}\""

LATEXMK_CMD="latexmk -silent -pdf -pdflatex=\"pdflatex -shell-escape -output-directory=${BUILD_DIR} %O %S\" -output-directory=\"${BUILD_DIR}\" \"${TEX_FILE}\""
# Execute the command
eval $LATEXMK_CMD 2>>pandoc_error.tmp

# After successful compilation, move the PDF to the desired directory
if [ $? -eq 0 ]; then
    echo "PDF created successfully for ${IN_FILE}. Moving PDF to ${PDF_DIR}..."
    mv "${BUILD_DIR}/${FILE_BASENAME}.pdf" "${PDF_DIR}/"
    if [ $? -ne 0 ]; then
      echo "Error moving PDF for ${IN_FILE}. Check pandoc_error.log for details."
      echo "Error occurred while moving ${BUILD_DIR}/${FILE_BASENAME}.pdf to ${PDF_DIR}/" >> pandoc_error.log
      exit 1
    else
      echo "PDF moved successfully to ${PDF_DIR}/."
    fi
else
  echo "Error producing PDF for ${IN_FILE}. Check pandoc_error.log for details."
  cat pandoc_error.tmp >> pandoc_error.log
  echo "Error occurred in file ${IN_FILE}" >> pandoc_error.log
  rm -f pandoc_error.tmp
  exit 1
fi

rm -f pandoc_error.tmp
