all: prolog.tab.c lex.yy.c
	g++ prolog.tab.c lex.yy.c -o prolog.exec -lfl

prolog.tab.c:
	bison -d prolog.y

lex.yy.c:
	flex prolog.l

clean:
	rm prolog prolog.tab.h prolog.tab.c lex.yy.c
