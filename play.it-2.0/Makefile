.PHONY: all

all: libplayit2.sh

libplayit2.sh: src/*
	cat src/* > libplayit2.sh

clean:
	rm -f libplayit2.sh

install: all
	mkdir -p ~/.local/share/play.it/
	cp libplayit2.sh ~/.local/share/play.it/

uninstall:
	rm -f ~/.local/share/play.it/libplayit2.sh
