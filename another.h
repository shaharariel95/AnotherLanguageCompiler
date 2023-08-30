/*
Header file defininf the expression node to be used in Bison
for expression and simple_expression non-terminals
*/

struct exp_node
{
    char *val;
    char type;
};

typedef struct exp_node exp_node;