CC=g++
CCFLAGS=-Wall -Wextra -fno-exceptions -Wno-format -std=c++1y
CCLIBS=-lfl
BINNAME=prolog
SRC=src
SRCGEN=build
INC=include


all: generate
	$(CC) $(CCFLAGS) -o $(BINNAME) $(SRCGEN)/*.c -I $(INC)  $(CCLIBS)

generate: $(SRCGEN)/prolog.tab.c $(SRCGEN)/lex.yy.c

$(SRCGEN)/prolog.tab.c: .FORCE
	bison -v -d -o $(SRCGEN)/prolog.tab.c $(SRC)/prolog.y

$(SRCGEN)/lex.yy.c: .FORCE
		flex -o $(SRCGEN)/lex.yy.c $(SRC)/prolog.l

clean:
	rm -f $(BINNAME) $(SRCGEN)/*

dirs:
	mkdir $(SRCGEN)


.PHONY: all clean generate dirs .FORCE
FORCE:
