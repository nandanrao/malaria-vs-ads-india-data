#!/bin/sh

latex mnm-paper.tex
mv mnm-paper.pdf "facebook-ads-vs-malaria-2021-$(git rev-parse --short HEAD).pdf"
