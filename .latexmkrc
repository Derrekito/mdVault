# Use lualatex for PDF generation
$pdflatex = 'lualatex -synctex=1 -interaction=nonstopmode -file-line-error %O %S';

# Tell latexmk to use PDF mode
$pdf_mode = 1;

# Clean up extra files after compilation
$clean_ext = 'aux bbl blg idx ilg ind lof log lot out toc synctex.gz fls fdb_latexmk';

# Force latexmk to always look for changes before recompiling
$recorder = 1;

# Enable shell escape to allow external scripts to run, which is necessary for packages like minted
$latex = 'lualatex -shell-escape %O %S';
$pdflatex = 'lualatex -shell-escape %O %S';

# Use the .latexmkrc file directory as the base for relative paths
$ENV{'TEXINPUTS'} = '.:';

# Custom dependency and rule for generating figures or other files, if needed
add_cus_dep('fig', 'pdf', 0, 'fig2pdf');
sub fig2pdf {
    system("mpost -interaction=nonstopmode $_[0].fig");
}

# PDF viewer setting, uncomment and modify if necessary
# If you're using a PDF viewer that can auto-refresh, you can set it here
# $pdf_previewer = "start evince";

# Clean up even more files
$clean_full_ext = 'aux bbl blg idx ilg ind lof log lot out toc synctex.gz fls fdb_latexmk brf nav snm';

