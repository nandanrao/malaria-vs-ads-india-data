PDF := $(patsubst src/%.md,pdf/%.pdf,$(wildcard src/*.md))
HTML := $(patsubst src/%.md,html/%.html,$(wildcard src/*.md))

all : $(PDF) $(HTML)

pdf/%.pdf :: src/%.md
	marp --theme /home/nandan/Documents/me/marp-theme/nandan.css $^ --pdf --engine /home/nandan/Documents/me/marp-theme/nandan.js --allow-local-files -o $@

html/%.html : src/%.md
	marp --theme /home/nandan/Documents/me/marp-theme/nandan.css $^ --html --engine /home/nandan/Documents/me/marp-theme/nandan.js --allow-local-files -o $@

clobber :
	rm -f $(PDF)
	rm -f $(HTML)
