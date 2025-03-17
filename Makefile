MD_FILES := $(shell find content -name '*.md' ! -path '*/Excalidraw/*')
PDF_FILES := $(patsubst %.md, %_pdf, $(MD_FILES))

all: check-deps ensure_pdf_dirs convert_md_to_pdf

check-deps:
	@echo "Checking dependencies..."
	@pdf_pipeline/scripts/check_deps.sh  # Updated earlier

ensure_pdf_dirs:
	@echo "Ensuring PDF directories exist..."
	@for file in $(MD_FILES); do \
		dir=$$(dirname "$$file"); \
		mkdir -p "$${dir}/pdf"; \
		done

convert_md_to_pdf: $(PDF_FILES)

$(PDF_FILES): %_pdf : %.md
	@pdf="$$(dirname "$<")/pdf/$$(basename "$<" .md).pdf"; \
		if [ ! -f "$$pdf" ] || [ "$<" -nt "$$pdf" ]; then \
		echo "Converting $< to PDF..."; \
		if grep -q '^---$$' "$<" && grep -q 'toc: true' "$<"; then \
		echo "Including TOC for $<"; \
		pdf_pipeline/scripts/create_pdf.sh "$<" 1; \
		else \
		pdf_pipeline/scripts/create_pdf.sh "$<" 0; \
		fi; \
		else \
		echo "Skipping $$pdf, already up to date."; \
		fi
	@echo ""

clean:
	@echo "Cleaning up auxiliary files..."
	@if [ -d "build" ]; then rm -rf build; fi
	@if [ -d ".trash" ]; then rm -rf .trash; fi

distclean: clean
	@echo "Removing all PDF files..."
	@find content -type f -name '*.pdf' ! -path './pdf_pipeline/latex/*' -delete
	@$(RM) pandoc_error.log
	@echo "Cleanup complete."

.PHONY: all check-deps ensure_pdf_dirs convert_md_to_pdf clean distclean
