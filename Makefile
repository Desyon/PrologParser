CC=g++
CCLIBS=-lfl
BINARY=prolog.exe
SRC=src
GENSRC=build

all: generate
	$(CC) $(GENSRC)/*.c $(CCLIBS) -lm -g -o $(BINARY) #> /dev/null 2>&1

generate:
	flex -o $(GENSRC)/lex.yy.c $(SRC)/prolog.l
	bison -dy $(SRC)/prolog.y -o $(GENSRC)/prolog.tab.c

test: all
	./prolog.exe < test/one.pl 

clean:
	rm -rf $(GENSRC)/*

dirs:
	mkdir build
	mkdir include
	mkdir src
