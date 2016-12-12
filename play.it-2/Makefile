.PHONY: all

all: libplayit2.sh

libplayit2.sh: src/*
	cat src/* > lib/libplayit2.sh

clean:
	rm -f lib/libplayit2.sh

install:
	mkdir -p ~/.local/share/play.it/
	cp lib/libplayit2.sh ~/.local/share/play.it/

uninstall:
	rm -f ~/.local/share/play.it/libplayit2.sh
