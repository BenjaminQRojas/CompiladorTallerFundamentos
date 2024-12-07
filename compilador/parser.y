%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Declaración externa de la función yyin (archivo de entrada) y otras funciones necesarias
extern FILE *yyin;
void yyerror(const char *s);
int yylex(void);

// Estructura que representa una variable
typedef struct {
    char *name;  // Nombre de la variable
    int value;   // Valor de la variable
} Variable;

Variable variables[100];  // Arreglo para almacenar variables
int var_count = 0;        // Contador de variables

// Definición de tipos de nodos para el AST
typedef enum { 
    NODE_TYPE_NUMBER,         // Nodo para números
    NODE_TYPE_IDENTIFIER,     // Nodo para identificadores
    NODE_TYPE_BINARY_OP,      // Nodo para operaciones binarias
    NODE_TYPE_ASSIGNMENT,     // Nodo para asignaciones
    NODE_TYPE_IF,             // Nodo para la sentencia if
    NODE_TYPE_ELSE,           // Nodo para la sentencia else
    NODE_TYPE_PRINT,          // Nodo para la sentencia print
    NODE_TYPE_BLOCK,          // Nodo para bloques de código
    NODE_TYPE_WHILE           // Nodo para la sentencia while
} NodeType;

// Estructura del nodo AST
typedef struct ASTNode {
    NodeType type;  // Tipo del nodo (de la enumeración NodeType)
    union {
        int value;  // Valor de tipo int (para números)
        char *name;  // Nombre del identificador (para variables)
        struct {     // Estructura para la operación binaria
            struct ASTNode *left;
            struct ASTNode *right;
            char op;  // Operador de la operación (por ejemplo, '+', '-', etc.)
        } binary_op;
        struct {     // Estructura para la asignación
            char *name;
            struct ASTNode *value;
        } assignment;
        struct {     // Estructura para la sentencia if
            struct ASTNode *condition;
            struct ASTNode *true_block;
            struct ASTNode *false_block;
        } if_stmt;
        struct ASTNode *expression;  // Nodo para la expresión de print
        struct {     // Estructura para bloques de código
            struct ASTNode **statements;  // Lista de sentencias en el bloque
            int statement_count;          // Contador de sentencias
        } block;
        struct {     // Estructura para la sentencia while
            struct ASTNode *condition;
            struct ASTNode *block;
        } while_stmt;
    };
} ASTNode;

// Funciones para crear nodos AST

// Crea un nodo de número
ASTNode *create_number_node(int value) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_NUMBER;
    node->value = value;
    return node;
}

// Crea un nodo de identificador (variable)
ASTNode *create_identifier_node(char *name) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_IDENTIFIER;
    node->name = strdup(name);
    return node;
}

// Crea un nodo para una operación binaria (por ejemplo, suma, resta)
ASTNode *create_binary_op_node(char op, ASTNode *left, ASTNode *right) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_BINARY_OP;
    node->binary_op.op = op;
    node->binary_op.left = left;
    node->binary_op.right = right;
    return node;
}

// Crea un nodo de asignación (variable = valor)
ASTNode *create_assignment_node(char *name, ASTNode *value) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_ASSIGNMENT;
    node->assignment.name = strdup(name);
    node->assignment.value = value;
    return node;
}

// Crea un nodo para una sentencia if
ASTNode *create_if_node(ASTNode *condition, ASTNode *true_block, ASTNode *false_block) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_IF;
    node->if_stmt.condition = condition;
    node->if_stmt.true_block = true_block;
    node->if_stmt.false_block = false_block;
    return node;
}

// Crea un nodo para una sentencia else
ASTNode *create_else_node(ASTNode *false_block) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_ELSE;
    node->if_stmt.false_block = false_block;
    return node;
}

// Crea un nodo para una sentencia print
ASTNode *create_print_node(ASTNode *expression) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_PRINT;
    node->expression = expression;
    return node;
}

// Crea un nodo para un bloque de código
ASTNode *create_block_node(ASTNode **statements, int count) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_BLOCK;
    node->block.statements = statements;
    node->block.statement_count = count;
    return node;
}

// Crea un nodo para una sentencia while
ASTNode *create_while_node(ASTNode *condition, ASTNode *block) {
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    node->type = NODE_TYPE_WHILE;
    node->while_stmt.condition = condition;
    node->while_stmt.block = block;
    return node;
}

// Función para liberar memoria de los nodos del AST
void free_ast(ASTNode *node) {
    if (node == NULL) return;
    switch (node->type) {
        case NODE_TYPE_BINARY_OP:
            free_ast(node->binary_op.left);
            free_ast(node->binary_op.right);
            break;
        case NODE_TYPE_ASSIGNMENT:
            free(node->assignment.name);
            free_ast(node->assignment.value);
            break;
        case NODE_TYPE_IF:
            free_ast(node->if_stmt.condition);
            free_ast(node->if_stmt.true_block);
            free_ast(node->if_stmt.false_block);
            break;
        case NODE_TYPE_PRINT:
            free_ast(node->expression);
            break;
        case NODE_TYPE_IDENTIFIER:
            free(node->name);
            break;
        case NODE_TYPE_WHILE:
            free_ast(node->while_stmt.condition); 
            free_ast(node->while_stmt.block);     
            break;
        case NODE_TYPE_BLOCK:
            for (int i = 0; i < node->block.statement_count; i++) {
                free_ast(node->block.statements[i]);
            }
            free(node->block.statements);
            break;
        default:
            break;
    }
    free(node);
}

// Funciones para obtener y asignar valores a las variables
int get_variable_value(char *name) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(variables[i].name, name) == 0) {
            return variables[i].value;
        }
    }
    return 0;
}


void set_variable_value(char *name, int value) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(variables[i].name, name) == 0) {
            variables[i].value = value;
            return;
        }
    }
    variables[var_count].name = strdup(name);
    variables[var_count].value = value;
    var_count++;
}

// Evaluar el AST
int evaluate_ast(ASTNode *node) {
    if (node == NULL) return 0;

    switch (node->type) {
        case NODE_TYPE_NUMBER:
            return node->value;
        case NODE_TYPE_IDENTIFIER:
            return get_variable_value(node->name);
        case NODE_TYPE_BINARY_OP: {
            int left_value = evaluate_ast(node->binary_op.left);
            int right_value = evaluate_ast(node->binary_op.right);
            switch (node->binary_op.op) {
                case '+': return left_value + right_value;
                case '-': return left_value - right_value;
                case '*': return left_value * right_value;
                case '/': return left_value / right_value;
                case '=': return left_value == right_value;
                case '!': return left_value != right_value;
                case '<': return left_value < right_value;
                case '>': return left_value > right_value;
                case 'l': return left_value <= right_value;
                case 'g': return left_value >= right_value;
                default: return 0;
            }
        }
        default:
            return 0;
    }
}

// Ejecutar el AST
void execute_ast(ASTNode *node) {
    if (node == NULL) return;

    switch (node->type) {
        case NODE_TYPE_ASSIGNMENT:
            set_variable_value(node->assignment.name, evaluate_ast(node->assignment.value));
            break;
        case NODE_TYPE_IF:
            if (evaluate_ast(node->if_stmt.condition)) {
                execute_ast(node->if_stmt.true_block);  
            } else if (node->if_stmt.false_block) {
                execute_ast(node->if_stmt.false_block);  
            }
            break;
        case NODE_TYPE_PRINT:
            printf("%d\n", evaluate_ast(node->expression));
            break;
        case NODE_TYPE_BLOCK:
            for (int i = 0; i < node->block.statement_count; i++) {
                execute_ast(node->block.statements[i]);
            }
            break;
        case NODE_TYPE_WHILE:
            while (evaluate_ast(node->while_stmt.condition)) {
                execute_ast(node->while_stmt.block);
            }
            break;
        default:
            break;
    }
}

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
    /* vacío */ { /* No AST is created for an empty program */ }
    | program line { 
        execute_ast($2); 
        free_ast($2); 
    }
;

line:
    VAR IDENTIFIER ASSIGN expression ';'  { $$ = create_assignment_node($2, $4); }
    | IDENTIFIER ASSIGN expression ';'   { $$ = create_assignment_node($1, $3); }
    | IF '(' expression ')' block ELSE block { $$ = create_if_node($3, $5, $7); }
    | IF '(' expression ')' block { $$ = create_if_node($3, $5, NULL); }
    | PRINT '(' expression ')' ';'       { $$ = create_print_node($3); }
    | WHILE '(' expression ')' block    { $$ = create_while_node($3, $5); }
;

block: 
    '{' statement_list '}' { $$ = create_block_node($2->block.statements, $2->block.statement_count); } 
;

statement_list:
    line  { 
        $$ = (ASTNode *)malloc(sizeof(ASTNode));
        $$->type = NODE_TYPE_BLOCK;
        $$->block.statements = (ASTNode **)malloc(sizeof(ASTNode *));
        $$->block.statements[0] = $1;
        $$->block.statement_count = 1;
    }
    | statement_list line  { 
        int count = $1->block.statement_count;
        $1->block.statements = (ASTNode **)realloc($1->block.statements, sizeof(ASTNode *) * (count + 1));
        $1->block.statements[count] = $2;
        $1->block.statement_count++;
        $$ = $1;
    }
;

expression:
    NUMBER  { $$ = create_number_node($1); }
    | IDENTIFIER  { $$ = create_identifier_node($1); }
    | expression '+' expression   { $$ = create_binary_op_node('+', $1, $3); }
    | expression '-' expression   { $$ = create_binary_op_node('-', $1, $3); }
    | expression '*' expression   { $$ = create_binary_op_node('*', $1, $3); }
    | expression '/' expression   { $$ = create_binary_op_node('/', $1, $3); }
    | expression EQUAL expression { $$ = create_binary_op_node('=', $1, $3); }
    | expression NOT_EQUAL expression { $$ = create_binary_op_node('!', $1, $3); }
    | expression LESS expression  { $$ = create_binary_op_node('<', $1, $3); }
    | expression GREATER expression { $$ = create_binary_op_node('>', $1, $3); }
    | expression LESS_EQUAL expression { $$ = create_binary_op_node('l', $1, $3); }
    | expression GREATER_EQUAL expression { $$ = create_binary_op_node('g', $1, $3); }
    | '(' expression ')'   { $$ = $2; }
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(int argc, char *argv[]) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yyparse();

    return 0;
}
