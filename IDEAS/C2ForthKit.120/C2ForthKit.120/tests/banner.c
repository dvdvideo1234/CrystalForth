
/* ===========================================================================

        File:           BANNER.C

        Test:           printf() and simple arrays / pointers

        Author:         MSD 98/07/17

        Results:        A strange poem in BIG letters should scroll up the
                        display.

=========================================================================== */

#define VERSION "BANNER 1.4 19980717"
#define EOL "\r\n"

#include <stdio.h>
#include <ctype.h>
#include <conio.h>

unsigned char   char_matrix[] =
        {
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,      /* ' ' */
                0x20, 0x20, 0x20, 0x20, 0x20, 0x00, 0x20, 0x00,      /* '!' */
                0x50, 0x50, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00,      /* '"' */
                0x50, 0x50, 0xF8, 0x50, 0xF8, 0x50, 0x50, 0x00,      /* '#' */
                0x20, 0x78, 0xA0, 0x70, 0x28, 0xF0, 0x20, 0x00,      /* '$' */
                0xC0, 0xC8, 0x10, 0x20, 0x40, 0x98, 0x18, 0x00,      /* '%' */
                0x40, 0xA0, 0xA0, 0x40, 0xA8, 0x90, 0x68, 0x00,      /* '&' */
                0x30, 0x30, 0x10, 0x20, 0x00, 0x00, 0x00, 0x00,      /* ''' */
                0x20, 0x40, 0x80, 0x80, 0x80, 0x40, 0x20, 0x00,      /* '(' */
                0x20, 0x10, 0x08, 0x08, 0x08, 0x10, 0x20, 0x00,      /* ' ' */
                0x20, 0xa8, 0x70, 0x20, 0x70, 0xa8, 0x20, 0x00,      /* '*' */
                0x00, 0x20, 0x20, 0x70, 0x20, 0x20, 0x00, 0x00,      /* '+' */
                0x00, 0x00, 0x00, 0x30, 0x30, 0x10, 0x20, 0x00,      /* ',' */
                0x00, 0x00, 0x00, 0x70, 0x00, 0x00, 0x00, 0x00,      /* '-' */
                0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x30, 0x00,      /* '.' */
                0x00, 0x08, 0x10, 0x20, 0x40, 0x80, 0x00, 0x00,      /* '/' */
                0x70, 0x88, 0x98, 0xA8, 0xC8, 0x88, 0x70, 0x00,      /* '0' */
                0x20, 0x60, 0x20, 0x20, 0x20, 0x20, 0x70, 0x00,      /* '1' */
                0x70, 0x88, 0x08, 0x30, 0x40, 0x80, 0xF8, 0x00,      /* '2' */
                0xF8, 0x10, 0x20, 0x30, 0x08, 0x88, 0x70, 0x00,      /* '3' */
                0x10, 0x30, 0x50, 0x90, 0xF8, 0x10, 0x10, 0x00,      /* '4' */
                0xF8, 0x80, 0xF0, 0x08, 0x08, 0x88, 0x70, 0x00,      /* '5' */
                0x38, 0x40, 0x80, 0xF0, 0x88, 0x88, 0x70, 0x00,      /* '6' */
                0xF8, 0x08, 0x10, 0x20, 0x40, 0x40, 0x40, 0x00,      /* '7' */
                0x70, 0x88, 0x88, 0x70, 0x88, 0x88, 0x70, 0x00,      /* '8' */
                0x70, 0x88, 0x88, 0x78, 0x08, 0x10, 0xE0, 0x00,      /* '9' */
                0x00, 0x60, 0x60, 0x00, 0x60, 0x60, 0x00, 0x00,      /* ':' */
                0x00, 0x60, 0x60, 0x00, 0x60, 0x60, 0x40, 0x00,      /* ';' */
                0x10, 0x20, 0x40, 0x80, 0x40, 0x20, 0x10, 0x00,      /* '<' */
                0x00, 0x00, 0xF8, 0x00, 0xF8, 0x00, 0x00, 0x00,      /* '=' */
                0x40, 0x20, 0x10, 0x08, 0x10, 0x20, 0x40, 0x00,      /* '>' */
                0x70, 0x88, 0x10, 0x20, 0x20, 0x00, 0x20, 0x00,      /* '?' */
                0x70, 0x88, 0xA8, 0xB8, 0xB0, 0x80, 0x78, 0x00,      /* '@' */
                0x20, 0x70, 0x88, 0x88, 0xF8, 0x88, 0x88, 0x00,      /* 'A' */
                0xF0, 0x88, 0x88, 0xF0, 0x88, 0x88, 0xF0, 0x00,      /* 'B' */
                0x70, 0x88, 0x80, 0x80, 0x80, 0x88, 0x70, 0x00,      /* 'C' */
                0xF0, 0x48, 0x48, 0x48, 0x48, 0x48, 0xF0, 0x00,      /* 'D' */
                0xF8, 0x80, 0x80, 0xF0, 0x80, 0x80, 0xF8, 0x00,      /* 'E' */
                0xF8, 0x80, 0x80, 0xF0, 0x80, 0x80, 0x80, 0x00,      /* 'F' */
                0x78, 0x80, 0x80, 0x80, 0x98, 0x88, 0x78, 0x00,      /* 'G' */
                0x88, 0x88, 0x88, 0xF8, 0x88, 0x88, 0x88, 0x00,      /* 'H' */
                0x70, 0x20, 0x20, 0x20, 0x20, 0x20, 0x70, 0x00,      /* 'I' */
                0x08, 0x08, 0x08, 0x08, 0x08, 0x88, 0x78, 0x00,      /* 'J' */
                0x88, 0x90, 0xA0, 0xC0, 0xA0, 0x90, 0x88, 0x00,      /* 'K' */
                0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0xF8, 0x00,      /* 'L' */
                0x88, 0xD8, 0xA8, 0xA8, 0x88, 0x88, 0x88, 0x00,      /* 'M' */
                0x88, 0x88, 0xC8, 0xA8, 0x98, 0x88, 0x88, 0x00,      /* 'N' */
                0x70, 0x88, 0x88, 0x88, 0x88, 0x88, 0x70, 0x00,      /* 'O' */
                0xF0, 0x88, 0x88, 0xF0, 0x80, 0x80, 0x80, 0x00,      /* 'P' */
                0x70, 0x88, 0x88, 0x88, 0xA8, 0x90, 0x68, 0x00,      /* 'Q' */
                0xF0, 0x88, 0x88, 0xF0, 0xA0, 0x90, 0x88, 0x00,      /* 'R' */
                0x70, 0x88, 0x80, 0x70, 0x08, 0x88, 0x70, 0x00,      /* 'S' */
                0xF8, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x00,      /* 'T' */
                0x88, 0x88, 0x88, 0x88, 0x88, 0x88, 0x70, 0x00,      /* 'U' */
                0x88, 0x88, 0x88, 0x88, 0x88, 0x50, 0x20, 0x00,      /* 'V' */
                0x88, 0x88, 0x88, 0xA8, 0xA8, 0xD8, 0x88, 0x00,      /* 'W' */
                0x88, 0x88, 0x50, 0x20, 0x50, 0x88, 0x88, 0x00,      /* 'X' */
                0x88, 0x88, 0x50, 0x20, 0x20, 0x20, 0x20, 0x00,      /* 'Y' */
                0xF8, 0x08, 0x10, 0x20, 0x40, 0x80, 0xF8, 0x00,      /* 'Z' */
                0x78, 0x40, 0x40, 0x40, 0x40, 0x40, 0x78, 0x00,      /* '[' */
                0x00, 0x80, 0x40, 0x20, 0x10, 0x08, 0x00, 0x00,      /* '\' */
                0xF0, 0x10, 0x10, 0x10, 0x10, 0x10, 0xF0, 0x00,      /* ']' */
                0x00, 0x00, 0x20, 0x50, 0x88, 0x00, 0x00, 0x00,      /* '^' */
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF8,      /* '_' */
        };

void    bannerchr(      int     c,
                        int     i )
{
        int j;
        int b;

        c &= 0x7F;
        c -= 32;

        b = *( char_matrix + ( 8 * c ) + i );

        for     ( j=0 ; j<6 ; j++ )
        {
                printf( ( b & 0x80 ) ? "#" : " " );
                b <<= 1;
        }
}

void    bannerstr(      char    *s )
{
        int i;
        char *p;

        if ( kbhit() ) return;

        for     ( i=0 ; i<8 ; i++ )
        {
                for     ( p=s ; *p ; p++ )
                        bannerchr( toupper(*p), i );

                printf(EOL);
        }
}

void    kbempty(        void )
{
        while ( kbhit() ) getchar();
}

void    main(           void )
{
        int i = 1;

        printf("\nHello\n");

        kbempty();

        while   ( !kbhit() )
        {
                printf("\n\n%d: %s\n\n\n",i++,VERSION);
                bannerstr("Take");
                bannerstr("from");
                bannerstr("the");
                bannerstr("goblin");
                bannerstr("his");
                bannerstr("crinkly");
                bannerstr("face,");
                bannerstr("His");
                bannerstr("pointed");
                bannerstr("ears");
                bannerstr("from");
                bannerstr("the");
                bannerstr("gnome;");
                bannerstr("Borrow");
                bannerstr("the");
                bannerstr("nose");
                bannerstr("of");
                bannerstr("a");
                bannerstr("leprechaun");
                bannerstr("And");
                bannerstr("smuggle");
                bannerstr("it");
                bannerstr("carefully");
                bannerstr("home.");
                bannerstr("Sew");
                bannerstr("bawkie");
                bannerstr("fingers");
                bannerstr("to");
                bannerstr("banshee");
                bannerstr("wrist;");
                bannerstr("Stitch");
                bannerstr("gossamer");
                bannerstr("vellum");
                bannerstr("between.");
                bannerstr("Fit");
                bannerstr("legs");
                bannerstr("to");
                bannerstr("straddle");
                bannerstr("with");
                bannerstr("knees");
                bannerstr("atwist");
                bannerstr("From");
                bannerstr("a");
                bannerstr("body");
                bannerstr("of");
                bannerstr("velveteen.");
        }

        kbempty();
}

