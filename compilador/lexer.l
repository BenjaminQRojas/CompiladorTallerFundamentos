%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>

// Declarar `yylval` para asignar valores en el lexer
extern YYSTYPE yylval;
%}

%%

"var"         { return VAR; }
"if"          { return IF; }
"print"       { return PRINT; }
"true"        { return TRUE; }
"false"       { return FALSE; }
[0-9]+        { yylval.ival = atoi(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z_0-9]* { yylval.sval = strdup(yytext); return IDENTIFIER; }
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
