%{
#include <string.h>
#include "parser.tab.h"
%}

%%

"var"         { return VAR; }
"if"          { return IF; }
"print"       { return PRINT; }
"while"       { return WHILE; }
"else"        { return ELSE; }
"true"        { return TRUE; }
"false"       { return FALSE; }
[0-9]+\.[0-9]+  { yylval.fval = atof(yytext); return FLOAT; }
[0-9]+        { yylval.ival = atoi(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z_0-9]*   { yylval.sval = strdup(yytext); return IDENTIFIER; }
"=="          { return EQUAL; }
"!="          { return NOT_EQUAL; }
"<"           { return LESS; }
">"           { return GREATER; }
"<="          { return LESS_EQUAL; }
">="          { return GREATER_EQUAL; }
"="           { return ASSIGN; }
"("           { return '('; }
")"           { return ')'; }
"{"           { return '{'; }
"}"           { return '}'; }
";"           { return ';'; }
[ \t\n]+      { /* Ignorar espacios en blanco */ }
.             { return yytext[0]; }

%%

int yywrap() {
    return 1;
}
