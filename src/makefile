all: jvmc

jvmc: scanner.o parser.o driver.o ast.o type.o main.o
	g++ -std=c++11 -o jvmc scanner.o parser.o driver.o ast.o type.o main.o

scanner.o: lex.yy.cc parser.tab.hh scanner.hh
	g++ -std=c++11 -o scanner.o -c lex.yy.cc

lex.yy.cc: lexer.ll
	flex lexer.ll

parser.o: parser.tab.cc parser.tab.hh scanner.hh ast.hh
	g++ -std=c++11 -o parser.o -c parser.tab.cc 

parser.tab.cc: parser.yy
	bison -d -v parser.yy

driver.o: driver.cpp driver.hh 
	g++ -std=c++11 -o driver.o -c driver.cpp

main.o: main.cpp
	g++ -std=c++11 -o main.o -c main.cpp

ast.o: ast.cpp ast.hh
	g++ -std=c++11 -o ast.o -c ast.cpp

type.o: type.cpp type.hh
	g++ -std=c++11 -o type.o -c type.cpp

clean:
	rm -rf *.o
