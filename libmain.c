/* libmain - flex run-time support library "main" function */

/* $Header: /cvsroot/flex/flex/libmain.c,v 1.4 1995/09/27 12:47:55 vern Exp $ */

extern int yylex();

int main( argc, argv )
int argc;
char *argv[];
	{
	while ( yylex() != 0 )
		;

	return 0;
	}
