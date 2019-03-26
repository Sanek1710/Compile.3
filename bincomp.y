%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern void yyerror(char *s);
extern void yyset_in (FILE *  _in_str );
extern int  yyget_lineno();
extern int  yylex(void);
extern int  yyparse(void);

FILE *out_file;

void write_code (unsigned short byte_code);
void write_codeh(unsigned char h1, unsigned char h2);
void write_codeq(unsigned char q1, unsigned char q2, unsigned char q3, unsigned char q4);
void write_code_jmp(unsigned char q1, unsigned short addr);

%}

%union { int num; const char *str; }

%start SRCASM

%token Mov Je Jne Jl Jle Jg Jge Jmp Ret Cmp Tst Call
%token Add Sub Mlt Div Shl Shr And Or Xor Neg Not
%token Code Data Mem
%token <num> Num Eax Ebx 
%token <str> Mark

%type <num> REG MEM POINT

%%

SRCASM	: CODE
		;

CODE    : CMD 						{  }
        | CODE CMD
        ;

CMD 	: MOV
		| JMP
		| CMP
		| BINOP
		| UNOOP
		;

MOV		: Mov REG ',' REG 			{ write_codeq(0x0, 0x0,  $2,  $4); }
		| Mov REG ',' MEM 			{ write_codeq(0x1, 0x1,  $2, 0x0); }
		| Mov MEM ',' REG 			{ write_codeq(0x1, 0x2, 0x0,  $4); }
		| Mov REG ',' Num 			{ write_codeq(0x2, 0x4,  $2, 0x0); 
									  write_code($4 >> 16);
									  write_code($4 & 0xFFFF);
									  }
		;

JMP 	: Je   POINT 				{ write_code_jmp(0x8, $2); }
		| Jne  POINT 				{ write_code_jmp(0x9, $2); }
		| Jl   POINT 				{ write_code_jmp(0xA, $2); }
		| Jle  POINT 				{ write_code_jmp(0xB, $2); }
		| Jg   POINT 				{ write_code_jmp(0xC, $2); }
		| Jge  POINT 				{ write_code_jmp(0xD, $2); }
		| Jmp  POINT 				{ write_code_jmp(0xE, $2); }
		| Call POINT 				{ write_code_jmp(0xF, $2); }
		| Ret       				{ write_code(0x0000); }
		;

POINT   : Mark 						{ $$ = 0xFFFFFF; }
		| Mark '+' Num 				{ $$ = 0xFFFFFF; }
		| Mark '-' Num 				{ $$ = 0xFFFFFF; }
		;

CMP 	: Cmp REG ',' REG 			{ write_codeq(0x4, 0xF,  $2, $4); }
		| Tst REG 					{ write_codeq(0x5, 0xF, 0x0, $2); }
		;

BINOP   : Add REG ',' REG 			{ write_codeq(0x4, 0x0, $2, $4); }
		| Sub REG ',' REG 			{ write_codeq(0x4, 0x1, $2, $4); }
		| Mlt REG ',' REG			{ write_codeq(0x4, 0x2, $2, $4); }
		| Div REG ',' REG			{ write_codeq(0x4, 0x3, $2, $4); }
		| Shl REG ',' REG			{ write_codeq(0x4, 0x4, $2, $4); }
		| Shr REG ',' REG			{ write_codeq(0x4, 0x5, $2, $4); }
		| And REG ',' REG			{ write_codeq(0x4, 0x8, $2, $4); }
		| Or  REG ',' REG			{ write_codeq(0x4, 0x9, $2, $4); }
		| Xor REG ',' REG			{ write_codeq(0x4, 0xB, $2, $4); }
		;

UNOOP   : Neg REG 			 		{ write_codeq(0x5, 0xC, 0x0, $2); }
		| Not REG 					{ write_codeq(0x5, 0xD, 0x0, $2); }
		;

MEM 	: '[' Mem '+' Num ']' 		{ $$ = 0xFFFFFF; /**/ }
		| '[' Mem '-' Num ']' 		{ $$ = 0xFFFFFF; /**/ }
		| '[' Mark ']' 				{ $$ = 0xFFFFFF; /**/ }
		;

REG     : Eax						{ $$ = $1; }
		| Ebx						{ $$ = $1; }
		;

%%


int
main(int argc, const char *argv[])
{
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
      strcat(out_file_name + len - 4, ".bin");
      printf("%s\n", out_file_name);
    }

    yyset_in (f);
  }
  else strcpy(out_file_name, "o.bin");

  out_file = fopen(out_file_name, "wb");

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
write_code(unsigned short byte_code)
{
	fwrite((void*)&byte_code, 1, 2, out_file);
}

void 
write_codeh(unsigned char h1, unsigned char h2)
{
	unsigned short byte_code = 0;
	byte_code = (h1 << 8) | (h2 << 0);
	fwrite((void*)&byte_code, 1, 2, out_file);
}

void 
write_codeq(unsigned char q1, unsigned char q2, unsigned char q3, unsigned char q4)
{
	unsigned short byte_code = 0;
	byte_code = (q1 << 12) | (q2 << 8) | (q3 << 4) | (q4 << 0);
	fwrite((void*)&byte_code, 1, 2, out_file);
}

void 
write_code_jmp(unsigned char q1, unsigned short addr)
{
	unsigned short byte_code = 0;

	byte_code = (q1 << 12) | (addr << 0);
	fwrite((void*)&byte_code, 1, 2, out_file);
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