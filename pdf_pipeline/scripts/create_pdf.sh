#!/bin/bash
# This script is located in vaults/pdf_pipeline/scripts

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PIPELINE_DIR="${SCRIPT_DIR}/.."
BUILD_DIR="${SCRIPT_DIR}/../../build"
REPO_ROOT="${SCRIPT_DIR}/../.."

export TEXINPUTS="${PIPELINE_DIR}/assets/logos:${REPO_ROOT}/assets/Fonts:"
export LUAFONTDIR="${PIPELINE_DIR}/assets/Fonts"
export MERMAID_FILTER_CONFIG="${PIPELINE_DIR}/config/mermaid-config.json"
export MERMAID_FILTER_MERMAID_CSS="${PIPELINE_DIR}/config/mermaid.css"
export MERMAID_BIN="${REPO_ROOT}/node_modules/.bin/mmdc"
export MERMAID_OUTPUT_DIR="${BUILD_DIR}/mermaid_images"

check_usage() {
    if [ -z "$1" ]; then
        echo "Usage: $0 <input_file> [toc]"
        exit 1
    fi
}

setup_paths() {
    local input_file="$1"
    IN_FILE="$input_file"
    IN_DIR="$(dirname "${IN_FILE}")"
    PDF_DIR="${IN_DIR}/pdf"
    FILE_BASENAME="$(basename "${IN_FILE}" .md)"
    TEX_FILE="${BUILD_DIR}/${FILE_BASENAME}.tex"
    PANDOC_LOG="${BUILD_DIR}/pandoc_output.log"
    LATEXMK_LOG="${BUILD_DIR}/latexmk_full_output.log"
    LUALATEX_LOG="${BUILD_DIR}/${FILE_BASENAME}.log"
    MERMAID_SUBDIR="${MERMAID_OUTPUT_DIR}/mermaid-images"  # Nested dir for pandocfilters
    mkdir -p "${PDF_DIR}" || { echo "Failed to create ${PDF_DIR}"; exit 1; }
    mkdir -p "${BUILD_DIR}" || { echo "Failed to create ${BUILD_DIR}"; exit 1; }
    mkdir -p "${MERMAID_SUBDIR}" || { echo "Failed to create ${MERMAID_SUBDIR}"; exit 1; }
}

print_log_locations() {
    echo "📜 Log files:"
    echo "  - Pandoc: ${PANDOC_LOG}"
    echo "  - latexmk: ${LATEXMK_LOG}"
    if [ -f "${LUALATEX_LOG}" ]; then
        echo "  - lualatex: ${LUALATEX_LOG}"
    else
        echo "  - lualatex: ${LUALATEX_LOG} (not yet generated)"
    fi
}

generate_tex() {
    local toc="$1"
    local template="${PIPELINE_DIR}/latex/template.latex"
    local pandoc_cmd="pandoc \"${IN_FILE}\" --from markdown --template=\"${template}\" --filter=\"${PIPELINE_DIR}/latex/filters/pandoc-mermaid.py\" --filter=\"${PIPELINE_DIR}/latex/filters/pandoc-minted.py\" --highlight-style=pygments --trace --data-dir=\"${REPO_ROOT}\" --metadata output_dir=\"${MERMAID_OUTPUT_DIR}\" --verbose"
    if [ -n "$toc" ]; then
        pandoc_cmd+=" --toc"
    fi
    echo "📝 Generating LaTeX from ${IN_FILE}..."
    # Check if mmdc is installed
    if ! command -v "${MERMAID_BIN}" >/dev/null 2>&1; then
        echo "❌ Mermaid CLI (mmdc) not found at ${MERMAID_BIN}. Install with: npm install --prefix ${REPO_ROOT} @mermaid-js/mermaid-cli" >&2
        exit 1
    fi
    eval "$pandoc_cmd -o \"${TEX_FILE}\"" > "${PANDOC_LOG}" 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ Pandoc failed for ${IN_FILE}."
        print_log_locations
        cat "${PANDOC_LOG}" >&2
        exit 1
    fi
    if [ ! -s "${TEX_FILE}" ]; then
        echo "❌ Generated ${TEX_FILE} is empty or missing."
        print_log_locations
        exit 1
    fi
}

generate_pdf() {
    (
      cd "${PIPELINE_DIR}" || exit 1
      latexmk -verbose -pdf -pdflatex="lualatex -shell-escape -interaction=batchmode -halt-on-error -output-directory=${BUILD_DIR} %O %S" -output-directory="${BUILD_DIR}" "${TEX_FILE}"
    ) > "${LATEXMK_LOG}" 2>&1
    if [ $? -ne 0 ]; then
        echo "⚠️ latexmk encountered issues."
        print_log_locations
        cat "${LATEXMK_LOG}" >&2
        exit 1
    fi
}

move_pdf() {
    local pdf_file="${BUILD_DIR}/${FILE_BASENAME}.pdf"
    if [ -f "${pdf_file}" ]; then
        mv "${pdf_file}" "${PDF_DIR}/"
        if [ $? -ne 0 ]; then
            echo "❌ Error moving PDF for ${IN_FILE}."
            print_log_locations
            exit 1
        else
            echo "✅ PDF successfully created: ${PDF_DIR}/${FILE_BASENAME}.pdf"
        fi
    else
        echo "❌ No PDF generated at ${pdf_file}."
        print_log_locations
        exit 1
    fi
}

main() {
    check_usage "$1"
    setup_paths "$1"
    echo "Starting conversion for ${IN_FILE}..."
    generate_tex "$2"
    generate_pdf
    move_pdf
}

main "$1" "$2"

