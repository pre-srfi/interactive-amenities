FILENAME=template

all:
	ln -sf README.md $(FILENAME).md
	pandoc --from=gfm README.md -o $(FILENAME).html
	pandoc --standalone $(FILENAME).html -o $(FILENAME).pdf
