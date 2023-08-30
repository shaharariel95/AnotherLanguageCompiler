%{
#include <strings.h>
#include "another.h"
#include "another.tab.h"
int yylex(void);
void yyerror(char *);


%}

%option yylineno

digit   [0-9]
letter  [_A-Za-z]
alnum   [A-Za-z0-9]


%%
"int"                                               {return INTDEF;}
"arr"                                               {return ARRDEF;}
"begin"                                             {return BEGINS;}
"end"                                               {return ENDS;}
"="                                                 {return ASSIGN;}
"if"                                                {return IF;}
"then"                                              {return THEN;}
"while"                                             {return WHILE;}
"do"                                                {return DO;}
"print"                                             {return PRINT;}
{letter}{alnum}*                                    {yylval.val = yytext; return ID;}
"+"                                                 {return PLUS;}
"-"                                                 {return MINUS;}
"*"                                                 {return MUL;}
"/"                                                 {return DIV;}
{digit}+                                            {yylval.val = yytext; return NUM;}
"=="                                                {return EQUAL;}
">="                                                {return GTEQ;}
"<="                                                {return LTEQ;}
"!="                                                {return NOTEQ;}
">"                                                 {return GT;}
"<"                                                 {return LT;}
"("                                                 {return LPAR;}
")"                                                 {return RPAR;}
[@]                                                 { return DOTP;}
":"                                                 {return INDEX;}
"["                                                 {return SQRBRL;}
"]"                                                 {return SQRBRR;}
";"                                                 {return SEMICOLON;}
","                                                 {return COMMA;}
[\n]                                                {yylineno++; }
[ \t\r]                                             ;
.                                                   { fprintf(stderr, "Error: %d\n", atoi(yytext)); yyerror("Lexical error");}

%%
int yywrap(void){
    return 1;
}

