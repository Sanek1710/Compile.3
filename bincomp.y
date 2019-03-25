%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern void yyerror(char *s);
extern void yyset_in (FILE *  _in_str );
extern int  yyget_lineno();
extern int  yylex(void);
extern int  yyparse(void);
%}

%union { int num; const char *str; }

%start SRCASM

%token Mov Je Jne Jl Jle Jg Jge Jmp Ret Cmp Tst Call
%token Add Sub Mlt Div Shl Shr And Or Xor Neg Not
%token Code Data Mem 
%token <num> Num Eax Ebx 
%token <str> Mark

%type <num> REG

%%

SRCASM	: CODE
		;

CODE    : CMD
        | CODE CMD
        ;

CMD 	: MOV
		| JMP
		| CMP
		| BINOP
		| UNOOP
		;

MOV		: Mov REG ',' REG
		| Mov REG ',' MEM
		| Mov MEM ',' REG
		| Mov REG ',' Num
		;

JMP 	: Jmp Mark 
		;

CMP 	: Cmp REG ',' REG
		| Tst REG
		;

BINOP   : Add REG ',' REG
		| Sub REG ',' REG
		| Mlt REG ',' REG
		| Div REG ',' REG
		| Shl REG ',' REG
		| Shr REG ',' REG
		| And REG ',' REG
		| Or  REG ',' REG
		| Xor REG ',' REG
		;

UNOOP   : Neg REG
		| Not REG
		;

MEM 	: '[' Mem '+' Num ']'
		| '[' Mem '-' Num ']'
		| '[' Mark ']'
		;

REG     : Eax			{ $$ = $1; }
		| Ebx			{ $$ = $1; }
		;

%%


int
main(int argc, const char *argv[])
{
		FILE *out_file;
  char out_file_name[257];

  if (argc > 1)
  {
    FILE *f = fopen(argv[1], "r");
    if (f == NULL)
    {
      printf("No such file\n");
      return -1;
    }

    int len = strlen(argv[1]);
    strcpy(out_file_name, argv[1]);

    if (len < 4) return -1;

    if (strcmp(out_file_name + len - 4, ".asm"))
    {
      printf("incorrect file extension\n");
      return -1;
    }
    else
    {
      out_file_name[len - 4] = '\0';
      strcat(out_file_name + len - 2, ".bin");
      printf("%s\n", out_file_name);
    }

    yyset_in (f);
  }
  else strcpy(out_file_name, "o.bin");

  out_file = fopen(out_file_name, "w");

  int Res = yyparse();

  fclose(out_file);

  if (Res == 0) 
  {
      printf("OK \n");
  }
  else 
  {
      printf("HE OK\n");
      remove(out_file_name);
  }

  return(Res);
}

void
yyerror(char *s)
{
  fprintf(stderr, "%s\n" , s);
}

int
yywrap()
{
  return(1);
}