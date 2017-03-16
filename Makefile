all: prolog.tab.c lex.yy.c
	g++ build/prolog.tab.c build/lex.yy.c -o prolog.exec -lfl

prolog.tab.c:
	bison -o build/prolog.tab.c -v -d prolog.y

lex.yy.c:
	flex -o build/lex.yy.c prolog.l

clean:
	rm prolog.exec build/*
