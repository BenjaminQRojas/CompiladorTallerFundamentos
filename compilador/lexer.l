%{
#include "parser.tab.h"  // Generado por Bison
%}

%%
[0-9]+    { return NUMBER; }  // Detecta números
[+*/-]    { return *yytext; } // Detecta operadores
[ \t\n]+  ;                   // Ignorar espacios
.         { return yytext[0]; } // Otros caracteres
%%