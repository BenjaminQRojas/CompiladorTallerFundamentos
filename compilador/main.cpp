#include <iostream>
using namespace std;

extern int yyparse();

int main() {
    cout << "Ingresa una operación: ";
    yyparse();
    return 0;
}

void yyerror(const char *s) {
    cerr << "Error: " << s << endl;
}