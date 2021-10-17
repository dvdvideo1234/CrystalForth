// TSEPOS 85 44 37 //
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ======================================================================

#define BANNER_TEXT     "C2FPOST : Post Processor for C 2 Forth Convertor"
#define COPYRIGHT_TEXT  "(c) 1999 Microprocessor Engineering Limited"
#define VERSION_NUMBER  "1.00"

#define BLOCKSIZE       512

// ======================================================================

char nextchar( FILE *fp )
{
        char    c = fgetc(fp);
        if ( c == 13 ) return nextchar( fp );
        else return c;
}

int ReadLine( FILE *fp, char *buff )
{
        int     p=0;
        char    c;

        do                                      // kill leading space
        {
                c = fgetc( fp );
        } while ( (c==9) || (c==32) );
        ungetc( c,fp );

        do
        {
                c = nextchar( fp );
                if ( c == 9 ) c = 32;
                buff[p++] = c;
        } while ( (c!=10 ) && (!feof(fp)));
        return p;
}

void WriteLine( FILE *fp, char *buff, int len )
{
        fwrite( buff, 1, len, fp );
}

void WriteChar( FILE *fp, char c )
{
        fputc(c,fp);
}

// ======================================================================

int main( int argc, char *argv[] )
{
        char    t[256];
        int     p;

        FILE    *sptr = fopen( argv[1], "rb" );
        FILE    *dptr = fopen( argv[2], "wb" );

        int     opos = 0;

        do
        {
                p = ReadLine( sptr, t );

                if ( p != 1 )
                {
retry:
                        if ( (opos+p) < BLOCKSIZE )
                        {
                                WriteLine( dptr, t, p );
                                opos+=p;
                        }
                        else
                        {
                                while ( opos<(BLOCKSIZE) )
                                {
                                        WriteChar( dptr, 10 );
                                        opos++;
                                }
                                opos = 0;
                                goto retry;
                        }
                }
        } while (!feof(sptr));


        while ( opos<(BLOCKSIZE-1) )
        {
                WriteChar( dptr, 10 );
                opos++;
        }
        WriteChar( dptr, 10 );
        opos = 0;


        fclose(sptr);
        fclose(dptr);
        return 0;
}

// ======================================================================

