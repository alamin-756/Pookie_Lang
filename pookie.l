%{
#include "pookie.tab.h"
#include <stdlib.h>
#include <string.h>

int yywrap() { return 1; }
%}

%%
start { return START; }
end { return END; }
num { return NUMTYPE; }
text { return TEXTTYPE; }
show { return SHOW; }
loop { return LOOP; }
while { return WHILE; }
if { return IF; }
else { return ELSE; }
pookie_break { return BREAK; }
pookie_continue { return CONTINUE; }

[0-9]+ { yylval.num = atoi(yytext); return NUMBER; }

\"[^\"]*\" {
    yylval.str = strdup(yytext+1);
    yylval.str[strlen(yylval.str)-1] = 0;
    return STRING;
}

"==" return EQ;
"!=" return NEQ;
"<=" return LE;
">=" return GE;
"<" return LT;
">" return GT;

"+" return PLUS;
"-" return MINUS;
"*" return MULT;
"/" return DIV;
"%" return MOD;
"=" return ASSIGN;

";" return SEMICOLON;
"(" return LPAREN;
")" return RPAREN;
"{" return LBRACE;
"}" return RBRACE;

[a-zA-Z_][a-zA-Z0-9_]* { yylval.str=strdup(yytext); return ID; }

[ \t\n]+ ;
#.* ;
%%