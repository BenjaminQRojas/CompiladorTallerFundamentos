%{
#include <iostream>
#include <cstdlib>
using namespace std;

void yyerror(const char *s);
int yylex();
%}

%token NUMBER

%%
calculation:
    calculation '+' calculation { cout << $1 + $3 << endl; }
  | calculation '*' calculation { cout << $1 * $3 << endl; }
  | NUMBER                       { $$ = atoi(yytext); }
  ;
%%