/* libmain - flex run-time support library "main" function */

/* $Header: /cvsroot/flex/flex/libmain.c,v 1.2 1990/05/26 16:50:08 vern Exp $ */

extern int yylex();

int main( argc, argv )
int argc;
char *argv[];

    {
    return yylex();
    }
