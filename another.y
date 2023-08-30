%{
int yylex(void);
void yyerror(char*);
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "another.h"



typedef struct {
    char name[33];
    char type; 
    bool ini;
    int size;
    int scope;
    char* data; 
}Node;

typedef struct{
    int size;
    Node** vars;
    int nextIndex;
}variableTable;




static variableTable varsTable;
static int scopeCounter;

void iniVarsTable(void);

void addVar(char*, char);
void appendArrayVariables(char*);
int checkVarExists(char*);
char checkVarType(char*);
void addToTable(Node*);
char* addParan(char*);
void endFile(void);
void startFile(void);
void appendFile(char* s);
char* getArrItem(char*);
void assignArr(char*, char*);
char* makeArrConst(char*);
char* arrOp(char*,char*,char);
void printExp(char*);

void scopeDepthInc();
void scopeDepthDec();
void scopeVarTableClean(int);

exp_node* createExpression(exp_node* l_val, exp_node* r_val, char op);
exp_node* handleDotProduct(exp_node*, exp_node*);

extern int yylineno;


%}



%union {
    exp_node *exp;
        char* val;
}

%token <val> ID
%left DOTP 
%left MUL DIV
%left PLUS MINUS
%token <val> NUM
%token INTDEF ARRDEF BEGINS ENDS ASSIGN IF THEN WHILE DO PRINT
%left EQUAL GTEQ LTEQ NOTEQ GT LT
%token LPAR RPAR INDEX SQRBRL SQRBRR SEMICOLON COMMA

%type program block statement_list statement declarator conditional loop
%type <val> identifier variable_list variable number assignment rel_ops cond arr_item arr_constant expression_list print
%type <exp> expression simple_expression


%%

program         :   {startFile(); } block   {endFile();}
                ;

block           : BEGINS {scopeDepthInc(); appendFile("{\n");} statement_list ENDS {scopeDepthDec(); appendFile("}\n");}
                ;

statement_list  : statement {;}
                | statement_list statement {;}
                ;
                
statement       :   declarator SEMICOLON {;}
                |   assignment SEMICOLON { appendFile(";\n");;}
                |   conditional {;}
                |   loop
                |   print SEMICOLON {;}
                ;

declarator      :   INTDEF variable_list {addVar($2,'i'); appendFile("int "); appendFile($2); appendFile(";\n"); }
                |   ARRDEF  variable_list {addVar($2,'a'); appendArrayVariables($2); }
                ;

assignment      :   variable ASSIGN expression {if(checkVarExists($1)==-1) yyerror("Var not exists");appendFile($1); appendFile("="); appendFile($3->val); free($1);} 
                |   arr_item ASSIGN expression {assignArr($1,$3->val); }
                ;

conditional     :   IF LPAR cond RPAR THEN {appendFile("if("); appendFile($3); appendFile(")");} block
                ;

loop            :   WHILE LPAR cond RPAR DO {appendFile("while("); appendFile($3); appendFile(")");} block   
                ;

print           :   PRINT expression_list {printExp($2);}
                ;

variable_list   :   variable { $$ = strdup($1); free($1);}
                |   variable_list COMMA variable {$$ = strdup(strcat(strcat($1,","),$3)); free($3);}
                ;

expression_list :   expression {$$ = strdup($1->val);}
                |   expression_list COMMA expression {$$ = strdup(strcat(strcat($1,","),$3->val));}
                ;


simple_expression: variable {$$ = (exp_node*)malloc(sizeof(exp_node)); $$->val = strdup($1); $$->type = checkVarType($1); free($1);}
                | arr_item  {$$ = (exp_node*)malloc(sizeof(exp_node)); $$->val = getArrItem($1); $$->type = 'i';}
                | number  {$$ = (exp_node*)malloc(sizeof(exp_node)); $$->val = strdup($1); $$->type ='i'; free($1);}
                | LPAR expression RPAR {$$ = (exp_node*)malloc(sizeof(exp_node)); $$->val = addParan($2->val); $$->type = $2->type;}
                | arr_constant {$$ = (exp_node*)malloc(sizeof(exp_node)); $$->val = strdup($1); $$->type = 'a';} 
                ;

expression      : simple_expression {;}
                | expression PLUS simple_expression {$$ = createExpression($1, $3, '+');}
                | expression MINUS simple_expression {$$ = createExpression($1, $3, '-');}
                | expression MUL simple_expression {$$ = createExpression($1, $3, '*');}
                | expression DIV simple_expression {$$ = createExpression($1, $3, '/');}
                | expression DOTP simple_expression {$$ = handleDotProduct($1,$3);}
                ;

variable            :   identifier {;}
                    ;


arr_item            : variable INDEX simple_expression {$$ = strdup(strcat(strcat($1,","),$3->val));} 
                    ;


cond            :   expression rel_ops expression {$$ = strdup(strcat(strcat($1->val,$2),$3->val));}
                ;

rel_ops         :   EQUAL   {$$ = strdup("==");}
                |   GTEQ    {$$ = strdup(">=");}
                |   LTEQ    {$$ = strdup("<=");}
                |   NOTEQ   {$$ = strdup("!=");}
                |   GT  {$$ = strdup(">");}
                |   LT  {$$ = strdup("<");}
                ;


identifier      :   ID { $$ = strdup($1);}
                ;

number          :   NUM { $$ = strdup($1);}
                ;



arr_constant    :   SQRBRL expression_list SQRBRR {$$ = makeArrConst($2);}
                ;



%%




char* addParan(char* exp){
    int size = strlen(exp);
    char* newexp = (char*)malloc(sizeof(char)*(size + 3));
    newexp[0] = '(';
    newexp[1] = '\0';
    strcat(newexp, exp);
    newexp[size+1] = ')';
    newexp[size+2] = '\0';
    return newexp; 
}

void iniVarsTable(void){
    varsTable.size = 25;
    varsTable.nextIndex = 0;
    varsTable.vars = (Node**)malloc(sizeof(Node*)*25);
}


void assignArr(char* arr,char* exp){
    printf("In assignArr: %s , arr: %s\n",exp, arr);
    char* arrName = strtok(arr,",");
    char* arrIndex = strtok(NULL,",");
    int index = checkVarExists(arrName);
    if(index == -1){ yyerror("arr not initialized!\n");}
    appendFile("arrIndexAssign(&");
    appendFile(arrName);
    appendFile(", ");
    appendFile(arrIndex);
    appendFile(",");
    appendFile(exp);
    appendFile(")");
}


char* getArrItem(char* exp){
    char* arr = strtok(exp,",");
    exp = strtok(NULL,",");
    int size = (strlen(exp) + 14);
    char* str = (char *)malloc(size*sizeof(char)+1);
    str[0] = '\0';
    int index = checkVarExists(arr);
    if(index == -1){yyerror("var not Exists\n");}
    if(varsTable.vars[index]->type != 'a'){yyerror("var is not indexable\n");}
    str = strcat(str, "getArrVal(");
    str = strcat(str, arr);
    str = strcat(str, ", ");
    str = strcat(str, exp);
    str = strcat(str, ")");

        printf("\nIn GetArrItem:%s\n",exp);

    return str;
}

void addToTable(Node* node){
    if(varsTable.nextIndex == varsTable.size){
        varsTable.vars = (Node**)realloc(varsTable.vars, sizeof(Node*)*varsTable.size*2);
        varsTable.size *= 2;
    }
    varsTable.vars[varsTable.nextIndex] = node;
    varsTable.nextIndex++;
}


void printExp(char* exp){
    char* str, *temp; 
    int count = 1; 
    int inside_parentheses = 0;
    for (int i = 0; exp[i]; i++) {
        if (exp[i] == '(') {
            inside_parentheses++;
        } else if (exp[i] == ')') {
            inside_parentheses--;
        } else if (exp[i] == ',' && !inside_parentheses) {
            count++;
        }
    }
    int len = 14 + count*4 + strlen(exp);

    temp = (char*)malloc(sizeof(char)*count*4);
    temp[0] = '\0';
    for(int i=0; i < count-1; i++){
        strcat(temp,"%d, ");
    }
    strcat(temp,"%d");
    str = (char*)malloc(sizeof(char)*len);

    sprintf(str,"printf(\"%s\\n\",%s);\n",temp,exp);
    free(temp);
    appendFile(str);
    free(str);
}


char** Parser(char* names){
    int count = 1; 
    for (int i = 0; names[i]; i++) {
        if (names[i] == ',') count++; 
    }
    
    char** result = (char**)malloc((count + 1) * sizeof(char*));
    
    int index = 0;
    char* token = strtok(names, ",");
    while (token) {
        result[index] = strdup(token); 
        token = strtok(NULL, ",");
        index++;
    }
    result[index] = NULL; 

    return result;
}

exp_node* handleDotProduct(exp_node* arr1, exp_node* arr2){
    exp_node* exp = (exp_node*)malloc(sizeof(exp_node));
    int size = strlen(arr1->val)+ strlen(arr2->val) + 14;
    char* str = (char *)malloc(sizeof(char)* size );
    str[0] = '\0';
    printf("In handleDotProduct:{\n \tarr1 = %s\n \tarr2 = %s\n",arr1->val,arr2->val);
    if(arr1->type != 'a' || arr2->type != 'a'){yyerror("dot product Only for arrays!\n");}
    strcat(str,"dotProduct(");
    strcat(str,arr1->val);
    strcat(str,",");
    strcat(str,arr2->val);
    strcat(str,")");

    exp->val = str;
    exp->type = 'i';
    return exp;
}

char* makeArrConst(char* exp){
    int count = 1; 
    for (int i = 0; exp[i]; i++) {
        if (exp[i] == ',') count++; 
    }

    char *str = (char*)malloc(sizeof(char)*strlen(exp)+ 27 + count );
    str[0] = '\0';

    sprintf(str, "arrDataInit((int[]){%s}, %d)",exp,count);

    return str;
}

void appendArrayVariables(char* vars) {
    size_t original_length = strlen(vars);
    size_t new_length = original_length * 2;


    char* new_vars = (char*)malloc(new_length + 1);
    new_vars[0] = '\0';
    int index = -1;
    char* token = strtok(vars, ",");
    while (token != NULL) {
        appendFile("arr ");
        appendFile(token);
        appendFile(" ;\n ");


        appendFile("arrInit(&");
        appendFile(token);
        appendFile(");\n");
        index = checkVarExists(token);
        varsTable.vars[index]->ini = 1;
        varsTable.vars[index]->type = 'a';
        token = strtok(NULL, ",");
        if (token != NULL) {
            strcat(new_vars, ",");
        }
    }
}


char* arrOp(char*arr1 ,char* arr2,char op){
    int len = strlen(arr1)+ strlen(arr2) + 17;
    char* str = (char*)malloc(sizeof(char)*len);
    sprintf(str,"combine_arrays(%s,%s,\'%c\')",arr1,arr2,op);
    return str;
}


void addVar(char* names, char type){
    char* duped = strdup(names);
    char** parsed = Parser(duped);
    int parsedSize = 0;
    while (parsed[parsedSize] != NULL) {
        parsedSize++;
    }
    printf("in addVar: parsedSize: %d\n",parsedSize);
    for(int i = 0; i < parsedSize; i++){
        Node* node;
        node = (Node*)malloc(sizeof(Node));
        strcpy(node->name, parsed[i]);
        node->ini = false;
        node->data = NULL;
        node->type = type;
        node->size = 0;
        node->scope = scopeCounter;
        printf("in addVar: the node: ini: %d, data: %s, type: %c, size: %d, name: %s, pointer: %p\n", node->ini, node->data, node->type, node->size, node->name, node);
        addToTable(node);
    }
    free(duped);
    free(parsed);
}

int checkVarExists(char* name){
    for(int i = 0; i < varsTable.nextIndex; i++){
        if(strcmp(name,varsTable.vars[i]->name)==0){
            return i;
        }
    }
    return -1;
}

char checkVarType(char* name){
    int index = checkVarExists(name);
    if(index == -1){return 'n';}
    return varsTable.vars[index]->type;
}

exp_node* createExpression(exp_node* l_val, exp_node* r_val, char op)
{
    exp_node* exp = (exp_node*)malloc(sizeof(exp_node));
    char l_val_type, r_val_type;
    char opstr[2];

    l_val_type = l_val->type;
    r_val_type = r_val->type;

    if(l_val_type != r_val_type)
    {
        yyerror("Attempted Operation between Array and Integer\n");
    }

    if(l_val_type == 'a')
    {
        exp->val = arrOp(l_val->val, r_val->val, op);
        exp->type = 'a';
    }

    if(l_val_type == 'i')
    {
        
        opstr[0] = op;
        opstr[1] = '\0';
        exp->val = strdup(strcat(strcat(l_val->val,opstr),r_val->val));
        exp->type = 'i';
    }
    
    free(l_val->val);
    free(l_val);
    free(r_val->val);
    free(r_val);

    return exp;
}

void scopeDepthInc()
{
    scopeCounter++;
}

void scopeDepthDec()
{
    scopeVarTableClean(scopeCounter);
    scopeCounter--;
    if(scopeCounter == 0)
    {
        appendFile("return 0;");
    }
}

void scopeVarTableClean(int currScope)
{
    int tempLen;
    int currVarsCnt = varsTable.nextIndex;

    for(int i=0; i<varsTable.nextIndex; i++)
    {
        if(varsTable.vars[i]->scope == currScope)
        {
            currVarsCnt--;
            if(varsTable.vars[i]->type == 'a')
            {
                char* arr_name = varsTable.vars[i]->name;
                tempLen = strlen(arr_name) + strlen("free(.data);\n") + 1;
                char* freeDataStr = (char*)malloc(sizeof(char)* tempLen);
                sprintf(freeDataStr, "free(%s.data);\n", arr_name);
                appendFile(freeDataStr);

                // tempLen = strlen(arr_name) + strlen("free(&);\n") + 1;
                // char* freeArr = (char*)malloc(sizeof(char)*tempLen);
                // sprintf(freeArr, "free(&%s);\n", arr_name);
                // appendFile(freeArr);

                free(freeDataStr);
                // free(freeArr);
            }
            free(varsTable.vars[i]);
        } 
    }
    varsTable.nextIndex = currVarsCnt;
}



void startFile(void){
    FILE* f = fopen("program.c", "w");
    fprintf(f,  "#include <stdio.h>\n"
                "#include <stdlib.h>\n"
                "#include <string.h>\n"
                "typedef struct{\n int size; int* data;\n  }arr;\n\n"
                "void arrInit(arr* a){\na->size = 0; \na->data = (int *)malloc(sizeof(int));\n}\n\n"
                "void arrIndexAssign(arr *a, int index, int val){\nif(index >= a->size){\na->data = (int *)realloc(a->data, sizeof(int)*(index + 1)); \na->size = index + 1;\n} \na->data[index]=val;}\n\n"
                "int getArrVal(arr a, int index){\nif(index >= a.size){\nexit(1);\n} \nreturn a.data[index];\n}\n\n"
                "void constAssign(arr* a, arr b){\n free(a); \na = &b; \n}\n\n"
                "arr combine_arrays(arr arrL, arr arrR, char op){\nint MAX_SIZE = (arrL.size >= arrR.size) ? arrL.size : arrR.size;\narr* result = (arr* )malloc(sizeof(arr));\nresult->data = (int* )malloc(sizeof(int)*MAX_SIZE);\nresult->size = MAX_SIZE;\nfor (int i = 0; i < MAX_SIZE; i++) {\nint l_val = (i < arrL.size) ? arrL.data[i] : 0;\nint r_val = (i < arrR.size) ? arrR.data[i] : 0;\nswitch(op) {\ncase '+':\nresult->data[i] = l_val + r_val;\nbreak;\ncase '-':\nresult->data[i] = l_val - r_val;\nbreak;\ncase '*':\nresult->data[i] = l_val * r_val;\nbreak;\ncase '/':\nresult->data[i] = (r_val != 0) ? l_val / r_val : 0;  \nbreak;\ndefault: \nresult->data[i] = 0;\n}}return *result;}\n"
                "arr arrDataInit(int* data, int size) { \narr new_arr;\narrInit(&new_arr); \nnew_arr.data = data; \nnew_arr.size = size; \nreturn new_arr; \n}\n\n"
                "int dotProduct(arr arr1, arr arr2){\n int result=0;\n if(arr1.size != arr2.size){return -1;}\n for(int i = 0; i < arr1.size; i++){\n result += arr1.data[i] * arr2.data[i];\n }\n return result;\n}\n\n"
                "\nint main()\n"
            );
    fclose(f);
}

void appendFile(char* s){
    FILE* f = fopen("program.c", "a");
    fprintf(f,"%s",s);
    fclose(f);
}



void endFile(void){
    FILE* f = fopen("program.c", "a");
    fprintf(f,"\n");
    fclose(f);
}

void yyerror(char *s){fprintf(stderr,"ERROR in line %d : '%s'\n",yylineno,s); exit(-1);}

int main(){
    iniVarsTable();
    scopeCounter = 0;
    yyparse ();
    return 0;
}