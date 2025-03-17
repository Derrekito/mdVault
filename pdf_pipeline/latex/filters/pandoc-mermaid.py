#!/usr/bin/env python3
"""
Pandoc filter for converting Mermaid diagrams in Markdown to images using the Mermaid CLI (mmdc).
Uses metadata for output directory configuration.
"""

import os
import sys
import subprocess
import hashlib
import shutil  # Added this import
from typing import Optional, List

from pandocfilters import toJSONFilter, Para, Image, RawBlock
from pandocfilters import get_filename4code, get_caption, get_extension

# Constants
MERMAID_BIN = os.path.expanduser(os.environ.get('MERMAID_BIN', 'mmdc'))
PUPPETEER_CFG = os.environ.get('PUPPETEER_CFG', None)


def get_file_hash(content: str) -> str:
    """Generate a SHA-256 hash of the given content."""
    return hashlib.sha256(content.encode('utf-8')).hexdigest()


def mermaid(key: str, value: List, format_: str, meta: dict) -> Optional[dict]:
    """
    Process Mermaid code blocks and convert them to images.
    """
    if key != 'CodeBlock':
        return None

    [[ident, classes, keyvals], code] = value
    if "mermaid" not in classes:
        return None

    try:
        caption, typef, keyvals = get_caption(keyvals)
        output_dir = meta['output_dir']['c']  # Use output_dir from meta

        # Build mmdc command with inline config
        cmd = [MERMAID_BIN]
        filetype = None
        for k, v in keyvals:
            if k in MMDC_OPTIONS:
                cmd.extend([MMDC_OPTIONS[k], v])
                if k == 'outputFormat':
                    filetype = v
            elif k in MMDC_FLAGS and v.lower() in ('true', 'yes', '1'):
                cmd.append(MMDC_FLAGS[k])

        filetype = filetype or get_extension(format_, "png", html="svg", latex="png")
        try:
            os.makedirs(output_dir, exist_ok=True)
        except PermissionError:
            sys.stderr.write(f"Error: Cannot create output directory '{output_dir}'. Check permissions.\n")
            return RawBlock('html', f'<!-- Mermaid failed: Permission denied for {output_dir} -->')

        filename = os.path.join(output_dir, get_filename4code("mermaid", code))
        src = filename + '.mmd'
        dest = filename + '.' + filetype
        code_hash = get_file_hash(code)

        # Check cache
        hash_file = filename + '.hash'
        should_generate = True
        if os.path.isfile(dest) and os.path.isfile(hash_file):
            with open(hash_file, 'r', encoding='utf-8') as f:
                cached_hash = f.read().strip()
            should_generate = cached_hash != code_hash

        if should_generate:
            with open(src, 'w', encoding='utf-8') as f:
                f.write(code)

            cmd.extend(["-i", src, "-o", dest])
            if 'puppeteer' not in [k for k, _ in keyvals]:
                if PUPPETEER_CFG:
                    cmd.extend(["-p", PUPPETEER_CFG])
                if os.path.isfile('.puppeteer.json'):
                    cmd.extend(["-p", ".puppeteer.json"])

            try:
                result = subprocess.run(cmd, check=True, capture_output=True, text=True)
                with open(hash_file, 'w', encoding='utf-8') as f:
                    f.write(code_hash)
                sys.stderr.write(f'Created image {dest}\n')
            except subprocess.CalledProcessError as e:
                sys.stderr.write(f"Error generating {dest}: Return code {e.returncode}\n")
                sys.stderr.write(f"Stdout: {e.stdout}\nStderr: {e.stderr}\n")
                return RawBlock('html', f'<!-- Mermaid rendering failed: {e.stderr} -->')
            finally:
                if os.path.isfile(src):
                    os.remove(src)

        return Para([Image([ident, [], keyvals], caption, [dest, typef])])
    except Exception as e:
        sys.stderr.write(f"Unexpected error processing Mermaid block: {str(e)}\n")
        return RawBlock('html', f'<!-- Mermaid processing failed: {str(e)} -->')


def main():
    """Run the Pandoc filter."""
    if not shutil.which(MERMAID_BIN):
        sys.stderr.write(f"Error: Mermaid CLI '{MERMAID_BIN}' not found in PATH. Install with 'npm install -g @mermaid-js/mermaid-cli'.\n")
        sys.exit(1)

    # When run as a filter, use meta['output_dir'] directly
    toJSONFilter(mermaid)


# Supported mmdc options with values
MMDC_OPTIONS = {
    'theme': '--theme',
    'width': '--width',
    'height': '--height',
    'background': '--backgroundColor',
    'scale': '--scale',
    'config': '--configFile',
    'outputFormat': '--outputFormat',
    'cssFile': '--cssFile',
    'puppeteer': '--puppeteerConfigFile'
}

# Flags without values
MMDC_FLAGS = {
    'pdfFit': '--pdfFit',
    'quiet': '--quiet'
}

if __name__ == "__main__":
    main()
