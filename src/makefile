all: jvmc

jvmc: parser.o scanner.o main.o

parser.o: parser.tab.cc
	bison -d -v parser.yy
	g++ -o parser.o -c parser.yy 

scanner.o: lex.yy.cc parser.tab.hh
	flex lexer.ll
	g++ -o scanner.o -c lex.yy.cc

main.o: main.cpp
	g++ -o main.o main.cpp


clean:
	rm -rf *.o
