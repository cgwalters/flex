/* parse.y - parser for flex input */

/*
 * Copyright (c) 1987, the University of California
 * 
 * The United States Government has rights in this work pursuant to
 * contract no. DE-AC03-76SF00098 between the United States Department of
 * Energy and the University of California.
 * 
 * This program may be redistributed.  Enhancements and derivative works
 * may be created provided the new works, if made available to the general
 * public, are made available for use by anyone.
 */

%token CHAR NUMBER SECTEND SCDECL XSCDECL WHITESPACE NAME PREVCCL

%{

#include "flexdef.h"

#ifndef lint
static char rcsid[] =
    "@(#) $Header: /cvsroot/flex/flex/parse.y,v 1.5 1989/05/19 14:09:39 vern Exp $ (LBL)";
#endif

int pat, scnum, eps, headcnt, trailcnt, anyccl, lastchar, i, actvp, rulelen;
int trlcontxt, xcluflg, cclsorted, varlength, variable_trail_rule;
char clower();

static int madeany = false;  /* whether we've made the '.' character class */

%}

%%
goal            :  initlex sect1 sect1end sect2 initforrule
			{ /* add default rule */
			int def_rule;

			pat = cclinit();
			cclnegate( pat );

			def_rule = mkstate( -pat );

			finish_rule( def_rule, variable_trail_rule, 0, 0 );

			for ( i = 1; i <= lastsc; ++i )
			    scset[i] = mkbranch( scset[i], def_rule );

			if ( spprdflt )
			    fputs( "YY_FATAL_ERROR( \"flex scanner jammed\" )",
				   temp_action_file );
			else
			    fputs( "ECHO", temp_action_file );

			fputs( ";\n\tYY_BREAK\n", temp_action_file );
			}
		;

initlex         :
			{
			/* initialize for processing rules */

			/* create default DFA start condition */
			scinstal( "INITIAL", false );
			}
		;
			
sect1		:  sect1 startconddecl WHITESPACE namelist1 '\n'
		|
		|  error '\n'
			{ synerr( "unknown error processing section 1" ); }
		;

sect1end	:  SECTEND
		;

startconddecl   :  SCDECL
			{
			/* these productions are separate from the s1object
			 * rule because the semantics must be done before
			 * we parse the remainder of an s1object
			 */

			xcluflg = false;
			}
		
		|  XSCDECL
			{ xcluflg = true; }
		;

namelist1	:  namelist1 WHITESPACE NAME
			{ scinstal( nmstr, xcluflg ); }

		|  NAME
			{ scinstal( nmstr, xcluflg ); }

		|  error
                        { synerr( "bad start condition list" ); }
		;

sect2           :  sect2 initforrule flexrule '\n'
		|
		;

initforrule     :
			{
			/* initialize for a parse of one rule */
			trlcontxt = variable_trail_rule = varlength = false;
			trailcnt = headcnt = rulelen = 0;
			current_state_type = STATE_NORMAL;
			new_rule();
			}
		;

flexrule        :  scon '^' re eol 
                        {
			pat = link_machines( $3, $4 );
			finish_rule( pat, variable_trail_rule,
				     headcnt, trailcnt );

			for ( i = 1; i <= actvp; ++i )
			    scbol[actvsc[i]] =
				mkbranch( scbol[actvsc[i]], pat );

			if ( ! bol_needed )
			    {
			    bol_needed = true;

			    if ( performance_report )
				fprintf( stderr,
			"'^' operator results in sub-optimal performance\n" );
			    }
			}

		|  scon re eol 
                        {
			pat = link_machines( $2, $3 );
			finish_rule( pat, variable_trail_rule,
				     headcnt, trailcnt );

			for ( i = 1; i <= actvp; ++i )
			    scset[actvsc[i]] = 
				mkbranch( scset[actvsc[i]], pat );
			}

                |  '^' re eol 
			{
			pat = link_machines( $2, $3 );
			finish_rule( pat, variable_trail_rule,
				     headcnt, trailcnt );

			/* add to all non-exclusive start conditions,
			 * including the default (0) start condition
			 */

			for ( i = 1; i <= lastsc; ++i )
			    if ( ! scxclu[i] )
				scbol[i] = mkbranch( scbol[i], pat );

			if ( ! bol_needed )
			    {
			    bol_needed = true;

			    if ( performance_report )
				fprintf( stderr,
			"'^' operator results in sub-optimal performance\n" );
			    }
			}

                |  re eol 
			{
			pat = link_machines( $1, $2 );
			finish_rule( pat, variable_trail_rule,
				     headcnt, trailcnt );

			for ( i = 1; i <= lastsc; ++i )
			    if ( ! scxclu[i] )
				scset[i] = mkbranch( scset[i], pat );
			}

                |  error
			{ synerr( "unrecognized rule" ); }
		;

scon            :  '<' namelist2 '>'
		;

namelist2       :  namelist2 ',' NAME
                        {
			if ( (scnum = sclookup( nmstr )) == 0 )
			    synerr( "undeclared start condition" );

			else
			    actvsc[++actvp] = scnum;
			}

		|  NAME
			{
			if ( (scnum = sclookup( nmstr )) == 0 )
			    synerr( "undeclared start condition" );
			else
			    actvsc[actvp = 1] = scnum;
			}

		|  error
			{ synerr( "bad start condition list" ); }
		;

eol             :  '$'
                        {
			if ( trlcontxt )
			    {
			    synerr( "trailing context used twice" );
			    $$ = mkstate( SYM_EPSILON );
			    }
			else
			    {
			    trlcontxt = true;

			    if ( ! varlength )
				headcnt = rulelen;

			    ++rulelen;
			    trailcnt = 1;

			    eps = mkstate( SYM_EPSILON );
			    $$ = link_machines( eps, mkstate( '\n' ) );
			    }
			}

		|
		        {
		        $$ = mkstate( SYM_EPSILON );

			if ( trlcontxt )
			    {
			    if ( varlength && headcnt == 0 )
				/* both head and trail are variable-length */
				variable_trail_rule = true;
			    else
				trailcnt = rulelen;
			    }
		        }
		;

re              :  re '|' series
                        {
			varlength = true;

			$$ = mkor( $1, $3 );
			}

		|  re2 series
			{
			if ( transchar[lastst[$2]] != SYM_EPSILON )
			    /* provide final transition \now/ so it
			     * will be marked as a trailing context
			     * state
			     */
			    $2 = link_machines( $2, mkstate( SYM_EPSILON ) );

			mark_beginning_as_normal( $2 );
			current_state_type = STATE_NORMAL;

			if ( varlength && headcnt == 0 )
			    { /* variable trailing context rule */
			    /* mark the first part of the rule as the accepting
			     * "head" part of a trailing context rule
			     */
			    /* by the way, we didn't do this at the beginning
			     * of this production because back then
			     * current_state_type was set up for a trail
			     * rule, and add_accept() can create a new
			     * state ...
			     */
			    add_accept( $1, num_rules | YY_TRAILING_HEAD_MASK );
			    }

			$$ = link_machines( $1, $2 );
			}

		|  series
			{ $$ = $1; }
		;


re2		:  re '/'
			{
			/* this rule is separate from the others for "re" so
			 * that the reduction will occur before the trailing
			 * series is parsed
			 */

			if ( trlcontxt )
			    synerr( "trailing context used twice" );
			else
			    trlcontxt = true;

			if ( varlength )
			    /* we hope the trailing context is fixed-length */
			    varlength = false;
			else
			    headcnt = rulelen;

			rulelen = 0;

			current_state_type = STATE_TRAILING_CONTEXT;
			$$ = $1;
			}
		;

series          :  series singleton
                        {
			/* this is where concatenation of adjacent patterns
			 * gets done
			 */
			$$ = link_machines( $1, $2 );
			}

		|  singleton
			{ $$ = $1; }
		;

singleton       :  singleton '*'
                        {
			varlength = true;

			$$ = mkclos( $1 );
			}
			
		|  singleton '+'
			{
			varlength = true;

			$$ = mkposcl( $1 );
			}

		|  singleton '?'
			{
			varlength = true;

			$$ = mkopt( $1 );
			}

		|  singleton '{' NUMBER ',' NUMBER '}'
			{
			varlength = true;

			if ( $3 > $5 || $3 < 0 )
			    {
			    synerr( "bad iteration values" );
			    $$ = $1;
			    }
			else
			    {
			    if ( $3 == 0 )
				$$ = mkopt( mkrep( $1, $3, $5 ) );
			    else
				$$ = mkrep( $1, $3, $5 );
			    }
			}
				
		|  singleton '{' NUMBER ',' '}'
			{
			varlength = true;

			if ( $3 <= 0 )
			    {
			    synerr( "iteration value must be positive" );
			    $$ = $1;
			    }

			else
			    $$ = mkrep( $1, $3, INFINITY );
			}

		|  singleton '{' NUMBER '}'
			{
			/* the singleton could be something like "(foo)",
			 * in which case we have no idea what its length
			 * is, so we punt here.
			 */
			varlength = true;

			if ( $3 <= 0 )
			    {
			    synerr( "iteration value must be positive" );
			    $$ = $1;
			    }

			else
			    $$ = link_machines( $1, copysingl( $1, $3 - 1 ) );
			}

		|  '.'
			{
			if ( ! madeany )
			    {
			    /* create the '.' character class */
			    anyccl = cclinit();
			    ccladd( anyccl, '\n' );
			    cclnegate( anyccl );

			    if ( useecs )
				mkeccl( ccltbl + cclmap[anyccl],
					ccllen[anyccl], nextecm,
					ecgroup, CSIZE );
			    
			    madeany = true;
			    }

			++rulelen;

			$$ = mkstate( -anyccl );
			}

		|  fullccl
			{
			if ( ! cclsorted )
			    /* sort characters for fast searching.  We use a
			     * shell sort since this list could be large.
			     */
			    cshell( ccltbl + cclmap[$1], ccllen[$1] );

			if ( useecs )
			    mkeccl( ccltbl + cclmap[$1], ccllen[$1],
				    nextecm, ecgroup, CSIZE );
				     
			++rulelen;

			$$ = mkstate( -$1 );
			}

		|  PREVCCL
			{
			++rulelen;

			$$ = mkstate( -$1 );
			}

		|  '"' string '"'
			{ $$ = $2; }

		|  '(' re ')'
			{ $$ = $2; }

		|  CHAR
			{
			++rulelen;

			if ( $1 == '\0' )
			    synerr( "null in rule" );

			if ( caseins && $1 >= 'A' && $1 <= 'Z' )
			    $1 = clower( $1 );

			$$ = mkstate( $1 );
			}
		;

fullccl		:  '[' ccl ']'
			{ $$ = $2; }

		|  '[' '^' ccl ']'
			{
			/* *Sigh* - to be compatible Unix lex, negated ccls
			 * match newlines
			 */
#ifdef NOTDEF
			ccladd( $3, '\n' ); /* negated ccls don't match '\n' */
			cclsorted = false; /* because we added the newline */
#endif
			cclnegate( $3 );
			$$ = $3;
			}
		;

ccl             :  ccl CHAR '-' CHAR
                        {
			if ( $2 > $4 )
			    synerr( "negative range in character class" );

			else
			    {
			    if ( caseins )
				{
				if ( $2 >= 'A' && $2 <= 'Z' )
				    $2 = clower( $2 );
				if ( $4 >= 'A' && $4 <= 'Z' )
				    $4 = clower( $4 );
				}

			    for ( i = $2; i <= $4; ++i )
			        ccladd( $1, i );

			    /* keep track if this ccl is staying in alphabetical
			     * order
			     */
			    cclsorted = cclsorted && ($2 > lastchar);
			    lastchar = $4;
			    }
			
			$$ = $1;
			}

		|  ccl CHAR
		        {
			if ( caseins )
			    if ( $2 >= 'A' && $2 <= 'Z' )
				$2 = clower( $2 );

			ccladd( $1, $2 );
			cclsorted = cclsorted && ($2 > lastchar);
			lastchar = $2;
			$$ = $1;
			}

		|
			{
			cclsorted = true;
			lastchar = 0;
			$$ = cclinit();
			}
		;

string		:  string CHAR
                        {
			if ( caseins )
			    if ( $2 >= 'A' && $2 <= 'Z' )
				$2 = clower( $2 );

			++rulelen;

			$$ = link_machines( $1, mkstate( $2 ) );
			}

		|
			{ $$ = mkstate( SYM_EPSILON ); }
		;

%%

/* synerr - report a syntax error
 *
 * synopsis
 *    char str[];
 *    synerr( str );
 */

synerr( str )
char str[];

    {
    syntaxerror = true;
    fprintf( stderr, "Syntax error at line %d: %s\n", linenum, str );
    }


/* yyerror - eat up an error message from the parser
 *
 * synopsis
 *    char msg[];
 *    yyerror( msg );
 */

yyerror( msg )
char msg[];

    {
    }
