/* yylex - scanner front-end for flex */

/*
 * Copyright (c) 1989 The Regents of the University of California.
 * All rights reserved.
 *
 * This code is derived from software contributed to Berkeley by
 * Vern Paxson.
 * 
 * The United States Government has rights in this work pursuant to
 * contract no. DE-AC03-76SF00098 between the United States Department of
 * Energy and the University of California.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

#ifndef lint

static char copyright[] =
    "@(#) Copyright (c) 1989 The Regents of the University of California.\n";
static char CR_continuation[] = "@(#) All rights reserved.\n";

static char rcsid[] =
    "@(#) $Header: /cvsroot/flex/flex/yylex.c,v 1.7 1989/05/25 11:47:15 vern Exp $ (LBL)";

#endif

#include "flexdef.h"
#include "parse.h"

/* yylex - scan for a regular expression token
 *
 * synopsis
 *
 *   token = yylex();
 *
 *     token - return token found
 */

int yylex()

    {
    int toktype;
    static int beglin = false;

    if ( eofseen )
	toktype = EOF;
    else
	toktype = flexscan();

    if ( toktype == EOF )
	{
	eofseen = 1;

	if ( sectnum == 1 )
	    {
	    synerr( "unexpected EOF" );
	    sectnum = 2;
	    toktype = SECTEND;
	    }

	else if ( sectnum == 2 )
	    {
	    sectnum = 3;
	    toktype = SECTEND;
	    }

	else
	    toktype = 0;
	}

    if ( trace )
	{
	if ( beglin )
	    {
	    fprintf( stderr, "%d\t", num_rules + 1 );
	    beglin = 0;
	    }

	switch ( toktype )
	    {
	    case '<':
	    case '>':
	    case '^':
	    case '$':
	    case '"':
	    case '[':
	    case ']':
	    case '{':
	    case '}':
	    case '|':
	    case '(':
	    case ')':
	    case '-':
	    case '/':
	    case '\\':
	    case '?':
	    case '.':
	    case '*':
	    case '+':
	    case ',':
		(void) putc( toktype, stderr );
		break;

	    case '\n':
		(void) putc( '\n', stderr );

		if ( sectnum == 2 )
		    beglin = 1;

		break;

	    case SCDECL:
		fputs( "%s", stderr );
		break;

	    case XSCDECL:
		fputs( "%x", stderr );
		break;

	    case WHITESPACE:
		(void) putc( ' ', stderr );
		break;

	    case SECTEND:
		fputs( "%%\n", stderr );

		/* we set beglin to be true so we'll start
		 * writing out numbers as we echo rules.  flexscan() has
		 * already assigned sectnum
		 */

		if ( sectnum == 2 )
		    beglin = 1;

		break;

	    case NAME:
		fprintf( stderr, "'%s'", nmstr );
		break;

	    case CHAR:
		switch ( yylval )
		    {
		    case '<':
		    case '>':
		    case '^':
		    case '$':
		    case '"':
		    case '[':
		    case ']':
		    case '{':
		    case '}':
		    case '|':
		    case '(':
		    case ')':
		    case '-':
		    case '/':
		    case '\\':
		    case '?':
		    case '.':
		    case '*':
		    case '+':
		    case ',':
			fprintf( stderr, "\\%c", yylval );
			break;

		    case 1:
		    case 2:
		    case 3:
		    case 4:
		    case 5:
		    case 6:
		    case 7:
		    case 8:
		    case 9:
		    case 10:
		    case 11:
		    case 12:
		    case 13:
		    case 14:
		    case 15:
		    case 16:
		    case 17:
		    case 18:
		    case 19:
		    case 20:
		    case 21:
		    case 22:
		    case 23:
		    case 24:
		    case 25:
		    case 26:
		    case 27:
		    case 28:
		    case 29:
		    case 30:
		    case 31:
		    case 127:
			fprintf( stderr, "\\%.3o", yylval );
			break;

		    default:
			(void) putc( yylval, stderr );
			break;
		    }
			
		break;

	    case NUMBER:
		fprintf( stderr, "%d", yylval );
		break;

	    case PREVCCL:
		fprintf( stderr, "[%d]", yylval );
		break;

	    case 0:
		fprintf( stderr, "End Marker" );
		break;

	    default:
		fprintf( stderr, "*Something Weird* - tok: %d val: %d\n",
			 toktype, yylval );
		break;
	    }
	}
	    
    return ( toktype );
    }
