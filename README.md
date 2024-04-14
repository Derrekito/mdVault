# About
Convert your markdown files to PDF with syntax highlighting and LaTeX support using this script.

# Prerequisites

This project requires several tools and packages, including Node.js, Puppeteer, Python for Pygments, and TeX Live with the `texlive-pictures` package for LaTeX processing. Here are the instructions to install these prerequisites on different operating systems.

## Installing Node.js and npm

### For Ubuntu/Debian

```bash
sudo apt update
sudo apt install nodejs npm
```

## For Arch Linux

```bash
sudo pacman -Sy nodejs npm
```

## Installing Puppeteer

Ensure Node.js and npm are installed, then run:

```bash
npm install puppeteer --unsafe-perm=true
```

## Installing TeX Live and `texlive-pictures`

### For Debian-based systems (Ubuntu, Debian)

```bash
sudo apt update
sudo apt install texlive-full texlive-pictures
```

### For Arch Linux

```bash
sudo pacman -Syu texlive-most texlive-pictures
```

## Installing Pygments (Required for Syntax Highlighting)

### For Arch Linux

```bash
sudo pacman -Syu python-pygments
```

### For Ubuntu/Debian

```bash
sudo apt update
sudo apt install python3-pygments
```
# Using Frontmatter in Markdown Files

Frontmatter in Markdown files is used to specify metadata that can be utilized by Pandoc during the document generation process. This metadata can influence how the document is rendered, add necessary information, and customize the output. Below is an explanation of each field in the frontmatter and how it affects the document conversion process.

## Frontmatter Fields

- **author**:
  - Type: List
  - Description: Names of the authors involved in the document creation.
  - Example:
    ```yaml
    author:
      - FirstName LastName
    ```

- **email**:
  - Type: String
  - Description: Contact email address for correspondence.
  - Example: `email: yourEmail@domain.com`

- **secnum**:
  - Type: Boolean
  - Description: Enables or disables section numbering in the document.
  - Example: `secnum: false`

- **title**:
  - Type: String
  - Description: The title of the document.
  - Example: `title: "example"`

- **toc**:
  - Type: Boolean
  - Description: Whether to include a table of contents.
  - Example: `toc: false`

- **logo**:
  - Type: Boolean
  - Description: Include a logo in the document if set to true.
  - Example: `logo: true`

- **rev**:
  - Type: String or Number
  - Description: Revision number of the document.
  - Example: `rev: 0.1`

- **bib**:
  - Type: Boolean
  - Description: Enables or disables bibliography processing.
  - Example: `bib: false`

- **abstract**:
  - Type: String
  - Description: A brief summary of the document.
  - Example: `abstract: Some example abstract`

- **date**:
  - Type: Date
  - Description: The date the document is published or compiled.
  - Example: `date: 2024-10-28`

## Frontmatter Usage

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

# Building the PDF

## Makefile Usage

- To generate PDFs from Markdown files using the provided `Makefile`, run the following commands:

```bash
# Converts all Markdown files to PDF and
# ensures PDF directories are created.
make all
```

- To clean up auxiliary files (`.aux`, `.log`, etc.), use

```bash
# Cleans up build and .trash directories, and auxiliary files.
make clean
```

- To remove all PDF files and clean up auxiliary files, use

```bash
# Removes all generated PDF files and cleans up auxiliary files.
make distclean
```

## Direct Usage

To use this script to create PDFs from Markdown files, ensure all prerequisites are met and follow these steps:

1. Place your Markdown files in the designated directory.
2. Run the script using the command:
```bash
./create_pdf.sh <input_file.md> [toc]
```
	- `<input_file.md>`: This is the path to your Markdown file.
    - `[toc]`: Optional. Include this if you want a table of contents.

The script will check for the necessary dependencies, install any missing ones, generate a LaTeX file from the Markdown, and compile it into a PDF. The PDF will be placed in a directory named `pdf` within the directory containing your input file.

# Troubleshooting

- Ensure all paths in the script are correct and accessible.
- Check the `pandoc_error.log` file if the PDF generation fails for detailed error messages.
- Ensure you have write permissions in the directories used by the script.

# Contributing

Contributions are welcome. Please fork the repository and submit a pull request with your enhancements.
