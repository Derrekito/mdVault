# About

Convert your markdown files to PDF with syntax highlighting and LaTeX support using this script. This project provides both a manual setup for local environments and a Docker-based solution for a consistent, up-to-date TeX Live environment.

## Prerequisites

This project requires several tools and packages, including Node.js, Puppeteer, Python for Pygments, and TeX Live with the texlive-pictures package for LaTeX processing. You can either install these manually on your system or use the provided Docker container.

### Option 1: Manual Installation

#### Installing Node.js and npm

**For Ubuntu/Debian**

```bash
sudo apt update
sudo apt install nodejs npm
```

**For Arch Linux**

```bash
sudo pacman -Sy nodejs npm
```

#### Installing Puppeteer

Ensure Node.js and npm are installed, then run:

```bash
sudo npm i -g puppeteer --unsafe-perm=true
```

#### Installing mermaid-filter

```bash
sudo npm i -g mermaid-filter
node /usr/local/lib/node_modules/mermaid-filter/node_modules/puppeteer/install.js
```

#### Installing TeX Live and texlive-pictures

**For Debian-based systems (Ubuntu, Debian)**

```bash
sudo apt update
sudo apt install texlive-full texlive-pictures
```

**For Arch Linux**

```bash
sudo pacman -Syu texlive-most texlive-pictures
```

#### Installing Pygments (Required for Syntax Highlighting)

Choose one of the following installation paths or another method appropriate for your system.

**For Arch Linux**

```bash
sudo pacman -Syu python-pygments
```

**For Ubuntu/Debian**

```bash
sudo apt update
sudo apt install python3-pygments
```

**For pip**

```bash
sudo pip3 install pygments
```

### Option 2: Using Docker

The provided Dockerfile creates a container with all dependencies pre-installed, including TeX Live 2024 (the latest version as of March 2025), Pygments 2.19.1+, Node.js, Puppeteer, and mermaid-filter. This ensures a consistent and up-to-date environment without relying on Ubuntu's older TeX Live 2021.

#### Prerequisites for Docker

Install Docker on your system:

- Ubuntu/Debian: `sudo apt install docker.io`
- Arch Linux: `sudo pacman -S docker`
- Ensure Docker is running: `sudo systemctl start docker`

#### Dockerfile Overview

The Docker image is built from ubuntu:22.04 and includes:

- TeX Live 2024: Installed from the official CTAN source for the latest LaTeX tools (latexmk 4.85, minted 2.9).
- Pygments: Installed via pip3 for the latest version (2.19.1+), ensuring pygmentize is available for minted.
- Node.js and npm: Installed with Puppeteer and mermaid-filter for diagram support.
- Pandoc: For Markdown-to-LaTeX conversion.

#### Building and Running the Docker Container

Clone the repository (once uploaded):

```bash
git clone https://github.com/Derrekito/docker-latex
cd docker-latex
```

Build the Docker image:

```bash
./manage_docker.sh build
```

Run the container with your project directory mounted:

```bash
./manage_docker.sh run ~/path/to/your/project
```

This mounts `~/path/to/your/project` to `/app` inside the container and starts an interactive shell.

Compile your Markdown files inside the container:

```bash
make
```

#### Managing the Docker Container

- Stop the container: `./manage_docker.sh stop`
- Remove the container: `./manage_docker.sh clean-container`
- Remove the image: `./manage_docker.sh clean-image`
- Check status: `./manage_docker.sh status`
- Compile directly: `./manage_docker.sh compile ~/path/to/your/project`

## Using Frontmatter in Markdown Files

Frontmatter in Markdown files is used to specify metadata that can be utilized by Pandoc during the document generation process. This metadata can influence how the document is rendered, add necessary information, and customize the output. Below is an explanation of each field in the frontmatter and how it affects the document conversion process.

### Frontmatter Fields

**author:**

- Type: List
- Description: Names of the authors involved in the document creation.
- Example:

```yaml
author:
  - FirstName LastName
```

**email:**

- Type: String
- Description: Contact email address for correspondence.
- Example: `email: yourEmail@domain.com`

**secnum:**

- Type: Boolean
- Description: Enables or disables section numbering in the document.
- Example: `secnum: false`

**title:**

- Type: String
- Description: The title of the document.
- Example: `title: "example"`

**toc:**

- Type: Boolean
- Description: Whether to include a table of contents.
- Example: `toc: false`

**logo:**

- Type: Boolean
- Description: Include a logo in the document if set to true.
- Example: `logo: true`

**rev:**

- Type: String or Number
- Description: Revision number of the document.
- Example: `rev: 0.1`

**bib:**

- Type: Boolean
- Description: Enables or disables bibliography processing.
- Example: `bib: false`

**abstract:**

- Type: String
- Description: A brief summary of the document.
- Example: `abstract: Some example abstract`

**date:**

- Type: Date
- Description: The date the document is published or compiled.
- Example: `date: 2024-10-28`

### Frontmatter Usage

To use these fields, include them at the top of your Markdown file enclosed in triple dashes. Here is an example of how frontmatter might look in your Markdown file:

```yaml
---
author:
  - FirstName LastName
email: yourEmail@domain.com
secnum: false
title: "example"
toc: false
logo: true
rev: 0.1
bib: false
abstract: Some example abstract
date: 2024-10-28
---
```

## Building the PDF

### Using Docker (Recommended)

Build the Docker image:

```bash
./manage_docker.sh build
```

Run the container with your project directory:

```bash
./manage_docker.sh run ~/path/to/your/project
```

Inside the container, use the Makefile:

```bash
make all  # Convert all Markdown files to PDF
make clean  # Clean auxiliary files
make distclean  # Remove PDFs and clean
```

The compile command can also be used directly:

```bash
./manage_docker.sh compile ~/path/to/your/project
```

### Makefile Usage (Manual or Docker)

The provided Makefile automates the conversion of Markdown files to PDFs, with support for frontmatter-based table of contents and dependency checking. Below are the available targets:

Build all PDFs:

```bash
make all
```

- Finds all .md files in the content directory (excluding Excalidraw subdirectories).
- Ensures pdf subdirectories exist for each Markdown file's location.
- Converts each .md file to a PDF in its respective pdf subdirectory using pdf_pipeline/scripts/create_pdf.sh.
- Includes a table of contents (TOC) if toc: true is in the frontmatter; skips TOC otherwise.
- Skips conversion if the PDF is up-to-date (based on file timestamps).

Check dependencies:

```bash
make check-deps
```

- Runs pdf_pipeline/scripts/check_deps.sh to verify required tools (e.g., Pandoc, Pygments) are installed.

Ensure PDF directories:

```bash
make ensure_pdf_dirs
```

- Creates pdf subdirectories for each Markdown file's parent directory if they don't exist.

Clean auxiliary files:

```bash
make clean
```

- Removes build and .trash directories if they exist, cleaning up intermediate files.

Remove all PDFs and clean:

```bash
make distclean
```

- Runs clean to remove auxiliary files.
- Deletes all .pdf files in the content directory (excluding those in pdf_pipeline/latex).
- Removes pandoc_error.log.

#### Example Workflow

```bash
# Build all PDFs
make all

# Clean up after building
make clean

# Start fresh by removing everything
make distclean
```

### Direct Usage (Manual Setup)

To use the script to create PDFs from Markdown files without Docker, ensure all prerequisites are met and follow these steps:

1. Place your Markdown files in the designated directory.
2. Run the script using the command:

```bash
./create_pdf.sh <input_file.md> [toc]
```

- `<input_file.md>`: Path to your Markdown file.
- `[toc]`: Optional. Include this for a table of contents.

The script will check for dependencies, install any missing ones, generate a LaTeX file from the Markdown, and compile it into a PDF. The PDF will be placed in a pdf directory within the input file's directory.

## Development

This section outlines the project organization and the purpose of each major directory. The structure is designed to separate content, build artifacts, and pipeline scripts for flexibility and maintainability.

### Project Structure

```
/project_root
├── build/              # Temporary build artifacts
├── content/            # Markdown source files and related assets
│   ├── <subdirs>/      # Various content subdirectories (e.g., personal, work)
│   │   ├── pdf/       # Generated PDF outputs
│   │   └── ...        # Other content-specific files (e.g., images, scripts)
│   └── Excalidraw/    # Excluded from PDF generation
├── pdf_pipeline/       # Tools and configurations for PDF generation
│   ├── assets/        # Static assets for PDFs
│   │   ├── Fonts/    # Custom fonts
│   │   └── logos/    # Logo images
│   ├── config/       # Configuration files (e.g., Pandoc settings)
│   ├── latex/        # LaTeX-related files
│   │   ├── build/    # LaTeX build artifacts
│   │   ├── filters/  # Custom Pandoc filters
│   │   └── includes/ # LaTeX includes (e.g., preamble)
│   ├── scripts/      # Build scripts
│   │   └── build/    # Additional build utilities
│   └── _minted-*/    # Minted cache directories for syntax highlighting
└── Makefile           # Build automation
```

### Directory Purposes

**build/:**

- Stores temporary files generated during the PDF build process (e.g., .aux, .log). Removed by make clean.

**content/:**

- Contains all Markdown source files organized into subdirectories (e.g., personal notes, work documents).
- Each subdirectory may have a pdf/ folder where generated PDFs are stored.
- The Excalidraw/ subdirectory is excluded from PDF generation to avoid processing non-Markdown files.

**pdf_pipeline/:**

- Houses the tools and assets needed to convert Markdown to PDF.
- assets/: Static resources like fonts and logos for document customization.
- config/: Settings for Pandoc or other tools (if applicable).
- latex/: LaTeX-specific files, including build outputs, custom filters, and includes.
- scripts/: Shell scripts like create_pdf.sh and check_deps.sh for PDF generation and dependency checks.
- \_minted-\*/: Cache directories created by the minted package for syntax highlighting; automatically generated during compilation.

**Makefile:**

- Automates the build process, from dependency checking to PDF generation and cleanup.

This structure keeps your content separate from the build pipeline, allowing you to easily update the conversion process without touching your source files.

## Troubleshooting

**Docker Issues:**

- Ensure Docker is running: `sudo systemctl status docker`.
- Check network connectivity if the image fails to build (TeX Live 2024 download can be slow).
- Verify pygmentize and latexmk versions inside the container:

```bash
pygmentize -V  # Should be 2.19.1+
latexmk --version  # Should be 4.85
```

**Minting Errors:** If you see Missing Pygments output:

- Ensure your Makefile includes -shell-escape in the LaTeX command (handled by create_pdf.sh in this setup).
- Create and set permissions for the cache directory:

```bash
mkdir -p _minted-<docname>
chmod 777 _minted-<docname>
```

**Manual Setup:** Check pandoc_error.log if PDF generation fails.

- Ensure write permissions in your project directory.

## Contributing

Contributions are welcome. Please fork the repository at https://github.com/<username>/<repo>.git and submit a pull request with your enhancements.
