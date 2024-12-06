%{
#include "parser.tab.h" // Definiciones del parser generado por Bison
#include <stdlib.h>
#include <string.h>
%}

%%

"var"          { return VAR; }
"if"           { return IF; }
"print"        { return PRINT; }
"true"         { return TRUE; }
"false"        { return FALSE; }

// Números enteros
[0-9]+         { 
    yylval.ival = atoi(yytext); 
    return NUMBER; 
}

// Identificadores: letras, guiones bajos y números (después de la primera letra)
[a-zA-Z_][a-zA-Z_0-9]* {
    yylval.sval = strdup(yytext); 
    return IDENTIFIER; 
}

// Operadores y comparadores
"=="           { return EQUAL; }
"!="           { return NOT_EQUAL; }
"<"            { return LESS; }
">"            { return GREATER; }
"<="           { return LESS_EQUAL; }
">="           { return GREATER_EQUAL; }
"="            { return ASSIGN; }

// Símbolos de puntuación
"("            { return '('; }
")"            { return ')'; }
"{"            { return '{'; }
"}"            { return '}'; }
";"            { return ';'; }

// Ignorar espacios en blanco y saltos de línea
[ \t\n]+       { /* Ignorar */ }

// Caracteres no reconocidos
.              { 
    return yytext[0]; 
}

%%

// Finalización del archivo de entrada
int yywrap() {
    return 1;
}