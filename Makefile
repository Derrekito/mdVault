# Find all Markdown files
MD_FILES := $(shell find . -name '*.md' ! -path '*/Excalidraw/*')

# Define PDF file paths based on MD_FILES
PDF_FILES := $(patsubst %.md, %_pdf, $(MD_FILES))

# Default target
all: ensure_pdf_dirs convert_md_to_pdf

# Ensure there is a pdf directory in each directory with Markdown files
ensure_pdf_dirs:
	@echo "Ensuring PDF directories exist..."
	@for file in $(MD_FILES); do \
		dir=$$(dirname "$$file"); \
		mkdir -p "$${dir}/pdf"; \
	done
	@echo "...done"
# Convert Markdown files to PDF if necessary
convert_md_to_pdf: $(PDF_FILES)

$(PDF_FILES): %_pdf : %.md
	@pdf="$$(dirname "$<")/pdf/$$(basename "$<" .md).pdf"; \
	if [ ! -f "$$pdf" ] || [ "$<" -nt "$$pdf" ]; then \
		echo "Converting $< to PDF..."; \
		if grep -q '^---$$' "$<" && grep -q 'toc: true' "$<"; then \
			echo "Including TOC for $<"; \
			./create_pdf.sh "$<" 1;\
		else \
			./create_pdf.sh "$<" 0;\
		fi; \
	else \
		echo "Skipping $$pdf, already up to date."; \
	fi


# Clean up auxiliary files
#@find . -type f \( -name '*.aux' -o -name '*.fdb_latexmk' -o -name '*.fls' -o -name '*.log' -o -name '*.tex' \) -delete
clean:
	@echo "Cleaning up auxiliary files..."
	@if [ -d "./build" ]; then rm -rf ./build; fi
	@if [ -d "./.trash" ]; then rm -rf ./.trash; fi

# Additional target to remove PDFs and auxiliary files
#@find . -type f -path '*/pdf/*.pdf' -delete
distclean: clean
	@echo "Removing all PDF files..."
	@find . -type f \( -name '*.pdf' \) -delete
	@echo "Cleanup complete."

.PHONY: all ensure_pdf_dirs convert_md_to_pdf clean distclean
