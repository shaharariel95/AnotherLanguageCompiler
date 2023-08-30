another.exe: lex.yy.c another.tab.c
	gcc -g lex.yy.c another.tab.c -o another.exe

lex.yy.c: another.tab.c another.l
	flex another.l

another.tab.c: another.y
	bison -d another.y

clean:
	rm -f lex.yy.c another.tab.c another.tab.h another.exe