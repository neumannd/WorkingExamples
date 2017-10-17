#!/bin/bash

echo "knitr::spin('example01.R')" > generate_html_documentation.R
echo "knitr::spin('example02.R')" >> generate_html_documentation.R
echo "knitr::spin('example03.R')" >> generate_html_documentation.R
echo "knitr::spin('example04.R')" >> generate_html_documentation.R

Rscript ./generate_html_documentation.R
