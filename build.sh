echo 'Running Flex ...'
flex -o build/lex.yy.c src/prolog.l

echo 'Running bison ...'
bison -dy src/prolog.y -o build/prolog.tab.c

echo 'Compile...'
# compile without output
gcc build/*.c -lfl -lm -g -o prolog.exe > /dev/null 2>&1

echo '\nRunning Program...'
./prolog.exe < test/one.pl

echo '\nDeleting generated files...'

rm -rf build/*

echo 'DONE.'
