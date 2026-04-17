%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror(const char *s);

/* ========= VARIABLE TABLE ========= */
typedef struct {
    char name[50];
    int val;
    char str[100];
    int isStr;
} Var;

Var vars[100];
int vcount = 0;

int getVal(char* n){
    for(int i=0;i<vcount;i++)
        if(strcmp(vars[i].name,n)==0) return vars[i].val;
    return 0;
}

char* getStr(char* n){
    for(int i=0;i<vcount;i++)
        if(strcmp(vars[i].name,n)==0) return vars[i].str;
    return "";
}

void setVal(char* n,int v){
    for(int i=0;i<vcount;i++){
        if(strcmp(vars[i].name,n)==0){
            vars[i].val=v; vars[i].isStr=0; return;
        }
    }
    strcpy(vars[vcount].name,n);
    vars[vcount].val=v;
    vars[vcount].isStr=0;
    vcount++;
}

void setStr(char* n,char* s){
    for(int i=0;i<vcount;i++){
        if(strcmp(vars[i].name,n)==0){
            strcpy(vars[i].str,s); vars[i].isStr=1; return;
        }
    }
    strcpy(vars[vcount].name,n);
    strcpy(vars[vcount].str,s);
    vars[vcount].isStr=1;
    vcount++;
}

/* ========= AST ========= */
typedef struct Node {
    int type;
    char* name;
    int val;
    char* str;
    struct Node *l,*r,*t,*u,*next;
} Node;

Node* newNode(int t){
    Node* n=malloc(sizeof(Node));
    memset(n,0,sizeof(Node));
    n->type=t;
    return n;
}

Node* root;

/* ========= EXEC ========= */
int exec(Node* n);

int eval(Node* n){
    switch(n->type){
        case '+': return eval(n->l)+eval(n->r);
        case '-': return eval(n->l)-eval(n->r);
        case '*': return eval(n->l)*eval(n->r);
        case '/': return eval(n->l)/eval(n->r);
        case '%': return eval(n->l)%eval(n->r);

        case '<': return eval(n->l)<eval(n->r);
        case '>': return eval(n->l)>eval(n->r);
        case 'l': return eval(n->l)<=eval(n->r);
        case 'g': return eval(n->l)>=eval(n->r);
        case 'e': return eval(n->l)==eval(n->r);
        case 'n': return eval(n->l)!=eval(n->r);

        case 'N': return n->val;
        case 'V': return getVal(n->name);
    }
    return 0;
}

int exec(Node* n){
    while(n){
        switch(n->type){

        case 'D': setVal(n->name,eval(n->l)); break;
        case 'T': setStr(n->name,n->str); break;
        case 'A': setVal(n->name,eval(n->l)); break;

        case 'S': printf("%d\n",eval(n->l)); break;
        case 's': printf("%s\n",n->str); break;
        case 'p':
            for(int i=0;i<vcount;i++){
                if(strcmp(vars[i].name,n->name)==0){
                    if(vars[i].isStr) printf("%s\n",vars[i].str);
                    else printf("%d\n",vars[i].val);
                }
            }
            break;

        case 'I':
            if(eval(n->l)) exec(n->r);
            else if(n->t) exec(n->t);
            break;

        case 'W':
            while(eval(n->l)){
                int res = exec(n->r);
                if(res==1) break;
                if(res==2) continue;
            }
            break;

        case 'F':
            exec(n->l); // init
            while(eval(n->r)){
                int res = exec(n->t);
                if(res==1) break;
                if(res==2){ exec(n->u); continue; }
                exec(n->u); // update
            }
            break;

        case 'B': return 1;
        case 'C': return 2;
        }

        n=n->next;
    }
    return 0;
}
%}

%union {
    int num;
    char* str;
    struct Node* node;
}

%token START END NUMTYPE TEXTTYPE SHOW LOOP WHILE IF ELSE BREAK CONTINUE
%token <num> NUMBER
%token <str> STRING ID
%token EQ NEQ LE GE LT GT PLUS MINUS MULT DIV MOD ASSIGN
%token SEMICOLON LPAREN RPAREN LBRACE RBRACE

%type <node> stmt stmt_list expr

%%

program:
    START stmt_list END { root=$2; exec(root); }
;

stmt_list:
    stmt_list stmt {
        if($1==NULL) $$=$2;
        else{
            Node* t=$1;
            while(t->next) t=t->next;
            t->next=$2;
            $$=$1;
        }
    }
    | { $$=NULL; }
;

stmt:
    NUMTYPE ID ASSIGN expr SEMICOLON { $$=newNode('D'); $$->name=$2; $$->l=$4; }
    | TEXTTYPE ID ASSIGN STRING SEMICOLON { $$=newNode('T'); $$->name=$2; $$->str=$4; }
    | ID ASSIGN expr SEMICOLON { $$=newNode('A'); $$->name=$1; $$->l=$3; }

    | SHOW expr SEMICOLON { $$=newNode('S'); $$->l=$2; }
    | SHOW STRING SEMICOLON { $$=newNode('s'); $$->str=$2; }
    | SHOW ID SEMICOLON { $$=newNode('p'); $$->name=$2; }

    | IF LPAREN expr RPAREN LBRACE stmt_list RBRACE {
        $$=newNode('I'); $$->l=$3; $$->r=$6;
    }
    | IF LPAREN expr RPAREN LBRACE stmt_list RBRACE ELSE LBRACE stmt_list RBRACE {
        $$=newNode('I'); $$->l=$3; $$->r=$6; $$->t=$10;
    }

    | WHILE LPAREN expr RPAREN LBRACE stmt_list RBRACE {
        $$=newNode('W'); $$->l=$3; $$->r=$6;
    }

    | LOOP LPAREN ID ASSIGN expr SEMICOLON expr SEMICOLON ID ASSIGN expr RPAREN LBRACE stmt_list RBRACE {
        $$=newNode('F');
        $$->l=newNode('A'); $$->l->name=$3; $$->l->l=$5;
        $$->r=$7;
        $$->u=newNode('A'); $$->u->name=$9; $$->u->l=$11;
        $$->t=$14;
    }

    | BREAK SEMICOLON { $$=newNode('B'); }
    | CONTINUE SEMICOLON { $$=newNode('C'); }
;

expr:
    expr PLUS expr { $$=newNode('+'); $$->l=$1; $$->r=$3; }
    | expr MINUS expr { $$=newNode('-'); $$->l=$1; $$->r=$3; }
    | expr MULT expr { $$=newNode('*'); $$->l=$1; $$->r=$3; }
    | expr DIV expr { $$=newNode('/'); $$->l=$1; $$->r=$3; }
    | expr MOD expr { $$=newNode('%'); $$->l=$1; $$->r=$3; }

    | expr LT expr { $$=newNode('<'); $$->l=$1; $$->r=$3; }
    | expr GT expr { $$=newNode('>'); $$->l=$1; $$->r=$3; }
    | expr LE expr { $$=newNode('l'); $$->l=$1; $$->r=$3; }
    | expr GE expr { $$=newNode('g'); $$->l=$1; $$->r=$3; }
    | expr EQ expr { $$=newNode('e'); $$->l=$1; $$->r=$3; }
    | expr NEQ expr { $$=newNode('n'); $$->l=$1; $$->r=$3; }

    | LPAREN expr RPAREN { $$=$2; }
    | NUMBER { $$=newNode('N'); $$->val=$1; }
    | ID { $$=newNode('V'); $$->name=$1; }
;

%%

void yyerror(const char *s){
    printf("Syntax Error\n");
}

int main(){
    printf("🔥 FINAL PERFECT Pookie 🔥\n");
    yyparse();
}