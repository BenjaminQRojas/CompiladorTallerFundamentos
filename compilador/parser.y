%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Declaraciones externas
extern FILE *yyin;
void yyerror(const char *s);
int yylex(void);

// Representación de variables
typedef struct {
    char *name;
    int value;
} Variable;

#define MAX_VARIABLES 100
Variable variables[MAX_VARIABLES];
int variable_count = 0;

// Tipos de nodos del AST
typedef enum { 
    NUMBER_NODE, IDENTIFIER_NODE, BINARY_OP_NODE, ASSIGNMENT_NODE, 
    IF_NODE, PRINT_NODE, BLOCK_NODE 
} NodeType;

typedef struct ASTNode {
    NodeType type;
    union {
        int number_value;
        char *identifier_name;
        struct { struct ASTNode *left, *right; char operator; } binary_op;
        struct { char *name; struct ASTNode *value; } assignment;
        struct { struct ASTNode *condition, *true_block; } if_statement;
        struct ASTNode *print_expression;
        struct { struct ASTNode **statements; int count; } block;
    };
} ASTNode;

// Funciones para crear nodos del AST
ASTNode *create_number_node(int value);
ASTNode *create_identifier_node(const char *name);
ASTNode *create_binary_op_node(char operator, ASTNode *left, ASTNode *right);
ASTNode *create_assignment_node(const char *name, ASTNode *value);
ASTNode *create_if_node(ASTNode *condition, ASTNode *true_block);
ASTNode *create_print_node(ASTNode *expression);
ASTNode *create_block_node(ASTNode **statements, int count);

// Gestión de memoria del AST
void free_ast(ASTNode *node);

// Funciones para manejar variables
int get_variable_value(const char *name);
void set_variable_value(const char *name, int value);

// Evaluación y ejecución del AST
int evaluate_ast(ASTNode *node);
void execute_ast(ASTNode *node);
%}

%union {
    int ival;
    char *sval;
    struct ASTNode *node;
}

%token <sval> IDENTIFIER
%token <ival> NUMBER
%token WHILE IF ELSE PRINT TRUE FALSE VAR
%token EQUAL NOT_EQUAL LESS GREATER LESS_EQUAL GREATER_EQUAL ASSIGN

%type <node> expression line block statement_list program

%left EQUAL NOT_EQUAL LESS GREATER LESS_EQUAL GREATER_EQUAL
%left '+' '-'
%left '*' '/'

%start program

%%

program:
      /* vacío */ { $$ = NULL; /* Asignar NULL en caso de que no haya contenido */ }
    | program line { execute_ast($2); free_ast($2); }
;

line:
      VAR IDENTIFIER ASSIGN expression ';' { $$ = create_assignment_node($2, $4); }
    | IDENTIFIER ASSIGN expression ';'    { $$ = create_assignment_node($1, $3); }
    | IF '(' expression ')' block         { $$ = create_if_node($3, $5); }
    | PRINT '(' expression ')' ';'        { $$ = create_print_node($3); }
;

block:
      '{' statement_list '}' { $$ = create_block_node($2->block.statements, $2->block.count); }
;

statement_list:
      line {
        $$ = create_block_node((ASTNode **)&$1, 1);
    }
    | statement_list line {
        int count = $1->block.count + 1;
        $1->block.statements = realloc($1->block.statements, count * sizeof(ASTNode *));
        $1->block.statements[count - 1] = $2;
        $1->block.count = count;
        $$ = $1;
    }
;

expression:
      NUMBER                       { $$ = create_number_node($1); }
    | IDENTIFIER                   { $$ = create_identifier_node($1); }
    | expression '+' expression    { $$ = create_binary_op_node('+', $1, $3); }
    | expression '-' expression    { $$ = create_binary_op_node('-', $1, $3); }
    | expression '*' expression    { $$ = create_binary_op_node('*', $1, $3); }
    | expression '/' expression    { $$ = create_binary_op_node('/', $1, $3); }
    | expression EQUAL expression  { $$ = create_binary_op_node('=', $1, $3); }
    | expression NOT_EQUAL expression { $$ = create_binary_op_node('!', $1, $3); }
    | expression LESS expression   { $$ = create_binary_op_node('<', $1, $3); }
    | expression GREATER expression { $$ = create_binary_op_node('>', $1, $3); }
    | expression LESS_EQUAL expression { $$ = create_binary_op_node('l', $1, $3); }
    | expression GREATER_EQUAL expression { $$ = create_binary_op_node('g', $1, $3); }
    | '(' expression ')'           { $$ = $2; }
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(int argc, char *argv[]) {
    yyin = argc > 1 ? fopen(argv[1], "r") : stdin;
    yyparse();
    return 0;
}
