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

// Implementación de las funciones para crear nodos del AST

ASTNode *create_number_node(int value) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = NUMBER_NODE;
    node->number_value = value;
    return node;
}

ASTNode *create_identifier_node(const char *name) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = IDENTIFIER_NODE;
    node->identifier_name = strdup(name);
    return node;
}

ASTNode *create_binary_op_node(char operator, ASTNode *left, ASTNode *right) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = BINARY_OP_NODE;
    node->binary_op.operator = operator;
    node->binary_op.left = left;
    node->binary_op.right = right;
    return node;
}

ASTNode *create_assignment_node(const char *name, ASTNode *value) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = ASSIGNMENT_NODE;
    node->assignment.name = strdup(name);
    node->assignment.value = value;
    return node;
}

ASTNode *create_if_node(ASTNode *condition, ASTNode *true_block) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = IF_NODE;
    node->if_statement.condition = condition;
    node->if_statement.true_block = true_block;
    return node;
}

ASTNode *create_print_node(ASTNode *expression) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = PRINT_NODE;
    node->print_expression = expression;
    return node;
}

ASTNode *create_block_node(ASTNode **statements, int count) {
    ASTNode *node = malloc(sizeof(ASTNode));
    node->type = BLOCK_NODE;
    node->block.statements = statements;
    node->block.count = count;
    return node;
}

// Gestión de memoria del AST
void free_ast(ASTNode *node) {
    if (!node) return;
    switch (node->type) {
        case NUMBER_NODE:
        case IDENTIFIER_NODE:
            free(node->identifier_name);
            break;
        case BINARY_OP_NODE:
            free_ast(node->binary_op.left);
            free_ast(node->binary_op.right);
            break;
        case ASSIGNMENT_NODE:
            free(node->assignment.name);
            free_ast(node->assignment.value);
            break;
        case IF_NODE:
            free_ast(node->if_statement.condition);
            free_ast(node->if_statement.true_block);
            break;
        case PRINT_NODE:
            free_ast(node->print_expression);
            break;
        case BLOCK_NODE:
            for (int i = 0; i < node->block.count; i++) {
                free_ast(node->block.statements[i]);
            }
            free(node->block.statements);
            break;
    }
    free(node);
}

// Evaluación y ejecución del AST

int evaluate_ast(ASTNode *node) {
    switch (node->type) {
        case NUMBER_NODE:
            return node->number_value;
        case IDENTIFIER_NODE:
            return get_variable_value(node->identifier_name);
        case BINARY_OP_NODE:
            switch (node->binary_op.operator) {
                case '+':
                    return evaluate_ast(node->binary_op.left) + evaluate_ast(node->binary_op.right);
                case '-':
                    return evaluate_ast(node->binary_op.left) - evaluate_ast(node->binary_op.right);
                case '*':
                    return evaluate_ast(node->binary_op.left) * evaluate_ast(node->binary_op.right);
                case '/':
                    return evaluate_ast(node->binary_op.left) / evaluate_ast(node->binary_op.right);
                case '=':
                    return evaluate_ast(node->binary_op.left) == evaluate_ast(node->binary_op.right);
                case '!':
                    return evaluate_ast(node->binary_op.left) != evaluate_ast(node->binary_op.right);
                case '<':
                    return evaluate_ast(node->binary_op.left) < evaluate_ast(node->binary_op.right);
                case '>':
                    return evaluate_ast(node->binary_op.left) > evaluate_ast(node->binary_op.right);
                case 'l':
                    return evaluate_ast(node->binary_op.left) <= evaluate_ast(node->binary_op.right);
                case 'g':
                    return evaluate_ast(node->binary_op.left) >= evaluate_ast(node->binary_op.right);
                default:
                    return 0;
            }
        case ASSIGNMENT_NODE:
            set_variable_value(node->assignment.name, evaluate_ast(node->assignment.value));
            return 0;
        case IF_NODE:
            if (evaluate_ast(node->if_statement.condition)) {
                execute_ast(node->if_statement.true_block);
            }
            return 0;
        case PRINT_NODE:
            printf("%d\n", evaluate_ast(node->print_expression));
            return 0;
        case BLOCK_NODE:
            for (int i = 0; i < node->block.count; i++) {
                execute_ast(node->block.statements[i]);
            }
            return 0;
        default:
            return 0;
    }
}

void execute_ast(ASTNode *node) {
    evaluate_ast(node);  // Solo evaluamos y ejecutamos la lógica
}

int get_variable_value(const char *name) {
    for (int i = 0; i < variable_count; i++) {
        if (strcmp(variables[i].name, name) == 0) {
            return variables[i].value;
        }
    }
    return 0;  // Devuelve 0 si la variable no se encuentra
}

void set_variable_value(const char *name, int value) {
    for (int i = 0; i < variable_count; i++) {
        if (strcmp(variables[i].name, name) == 0) {
            variables[i].value = value;
            return;
        }
    }
    // Si no existe la variable, la creamos
    variables[variable_count].name = strdup(name);
    variables[variable_count].value = value;
    variable_count++;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror("No se puede abrir el archivo");
            return 1;
        }
    }
    yyparse();
    return 0;
}
