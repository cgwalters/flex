/* libmain - flex run-time support library "main" function */

/* $Header: /cvsroot/flex/flex/libmain.c,v 1.3 1993/04/14 22:41:55 vern Exp $ */

extern int yylex();

int main( argc, argv )
int argc;
char *argv[];
	{
	return yylex();
	}
