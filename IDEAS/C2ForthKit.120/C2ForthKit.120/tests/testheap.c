/* TSEPOS 19 29 19 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <conio.h>

#define	FALSE           0
#define	TRUE		(!FALSE)

#define min(a, b)       (((a) < (b)) ? (a) : (b))

/* ========================================================================= */

#define APPTITLE        "HeapTest(C) 1.00 SJC\r\n\r\n"
#define EscapeKey       0x1B
#define VerboseKey      0x20
#define BlockSlots      4096
#define MaxBlockSize    1024

#define PatternBlockSize        MaxBlockSize + 0x0100

unsigned char           *Pattern;

int             WantVerbose = TRUE;

unsigned int    InitialSeed;
unsigned int    RandSeed;

unsigned int    ActionNumber;

typedef struct  tagBlockRec
{
        unsigned int    Size;
        unsigned char  *Addr;
} BlockRec;

BlockRec        Blocks[BlockSlots];

/* ========================================================================= */

unsigned int    size( unsigned char *Address )
{
        return MaxBlockSize;
}

/* ========================================================================= */

#define RandA   24298
#define RandC   99991
#define RandM   199017


unsigned int    Rand( void )
{
        RandSeed = (RandSeed * RandA + RandC) % RandM;
        return RandSeed;
}


unsigned int    Rand1n( unsigned int Scale )
{

        unsigned int    rc;
        unsigned int    rc2;

        rc = Rand() % Scale;
        rc++;

        if ( Scale > RandM )
        {
                rc2 = Scale/RandM;
                if (rc2) rc=rc*rc2;
        }

        return rc;
}


void    Randomise( void )
{
        RandSeed = 0;
}

/* ========================================================================= */

void    VerbosePrint( char *string )
{
        if (WantVerbose) printf( "%s", string );
}


void    ToggleVerbosity( void )
{
        if (WantVerbose) WantVerbose = FALSE;
        else WantVerbose = TRUE;
}

void    aborttest( char *text )
{
        printf("%s\r\n", text);
        exit(0);
}

/* ========================================================================= */

void    IncActionNumber( void )
{
        ActionNumber++;
}

void    SayActionNumber( unsigned int WantCRLF )
{

        if ( !(ActionNumber%100) || WantVerbose )
        {
                if (WantCRLF) printf("\r\n");
                printf("0x%08X ", ActionNumber);
        }

}

/* ========================================================================= */

void    PatternFill( void )
{
        int     l;

        if (!Pattern)
        {
                Pattern = (unsigned char *)malloc(PatternBlockSize);
                if (!Pattern) aborttest("Bad pattern fill");
                for (l=0 ; l<PatternBlockSize ; l++)
                        Pattern[l] = (unsigned char)l&255;
        }
}

void    PatternFree( void )
{
        if (Pattern)
        {
                free(Pattern);
                Pattern=NULL;
        }
}

unsigned int    PatternOffset( unsigned char *address )
{
        unsigned int rc;

        rc = (unsigned int)address;

        while ( !(rc&15) ) rc=rc>>4;
        return (rc&15);
}

void    BlockFill( BlockRec *This )
{
        if ( (This->Addr) && (This->Size) )
                memcpy( This->Addr, Pattern+PatternOffset(This->Addr), This->Size);
}


unsigned int    Difference( unsigned char *src1, unsigned char *src2, unsigned int len )
{
        int     offset = 0;

        while (len--)
        {
                if (*src1++ != *src2++) return offset;
                offset++;
        }
        return offset;
}

void    pBlockTest( unsigned int offset, unsigned char *address, unsigned int size )
{
        if ( (address) && (size) )
        {
                if ( memcmp(Pattern+offset, address, size) )
                {
                        printf("\r\n Bad Compare of 0x%08X with 0x%08X"
                               " size 0x%08X offset %08X",
                                Pattern+offset, address, size,
                                Difference(Pattern+offset, address, size));
                        aborttest(" ");
                }
        }
}

void    BlockTest( BlockRec *This )
{
        pBlockTest( PatternOffset(This->Addr), This->Addr, This->Size );
}

void    MovedTest( unsigned char *OldAddr, unsigned int OldSize, BlockRec *This )
{
        pBlockTest( PatternOffset(OldAddr), This->Addr, min( OldSize, This->Size ) );
}

/* ========================================================================= */

void    SayBlockSize( unsigned int size )
{
        if (WantVerbose) printf("0x%08X ", size);
}


void    SayBlock( BlockRec *This )
{
        if (WantVerbose)
        {
                SayBlockSize( This->Size );
                if ( (This->Addr) && (This->Size) )
                        SayBlockSize(size(This->Addr));
                else
                        printf(" at 0x%08X", This->Addr );
        }
}

void    SayBlockNo( unsigned int bn )
{
        if (WantVerbose) printf("[0x%08X]", bn);
}

/* ========================================================================= */

void    DoAllocate( BlockRec *This, unsigned int NewSize )
{
        unsigned char *NewBlock;

        VerbosePrint("ALLO ");
        SayBlockSize( NewSize );
        VerbosePrint(" > ");

        NewBlock = malloc( NewSize );
        if (NewBlock)
        {
                This->Addr = NewBlock;
                This->Size = NewSize;
                SayBlock(This);
        }
        else
        {
                VerbosePrint(" FAILED!");
        }
}


void    DoResize( BlockRec *This, unsigned int NewSize )
{
        unsigned char   *newblock;

        VerbosePrint("RESZ ");
        SayBlock( This );
        VerbosePrint(" > ");
        SayBlockSize( NewSize );
        VerbosePrint(" , ");

        newblock = (unsigned char *)realloc( This->Addr, NewSize );

        if (newblock)
        {
                This->Addr = newblock;
                This->Size = NewSize;
                SayBlock( This );
        }
        else
        {
                VerbosePrint(" FAILED!");
        }

}

void    DoFree( BlockRec *This )
{
        VerbosePrint( "FREE " );
        SayBlock( This );
        free( This->Addr );
        This->Addr = NULL;
        This->Size = 0;
}

void    DoSize( BlockRec *This )
{
        VerbosePrint( "SIZE ");
        if ( (This->Addr) && (This->Size) )
        {
                VerbosePrint( "= ");
                SayBlockSize(size(This->Addr));
        }
}

/* ========================================================================= */

void    DoBlock( unsigned int BlockNumber )
{
        unsigned int    OldSize, NewSize;
        unsigned char   *OldAddr;
        BlockRec        *This;


        This = &Blocks[BlockNumber];

        OldSize = This->Size;
        NewSize = Rand1n( MaxBlockSize );

        if ( !OldSize )
        {
                DoAllocate( This, NewSize );
                BlockFill( This );
                BlockTest( This );
        }
        else
        {
                switch( Rand1n(3) )
                {
                case 1:
                        BlockTest( This );
                        DoFree( This );
                        break;
                case 2:
                        BlockTest( This );
                        DoSize( This );
                        break;
                case 3:
                        BlockTest( This );
                        OldAddr = This->Addr;
                        DoResize( This, NewSize );
                        MovedTest( OldAddr, OldSize, This );
                        BlockFill( This );
                        BlockTest( This );
                        break;
                }
        }

}

/* ========================================================================= */

void    InitBlockArray( void )
{
        int     i;

        for ( i=0; i<BlockSlots; i++ )
        {
                Blocks[i].Addr = NULL;
                Blocks[i].Size = 0;
        }
}

void    FreeAll( void )
{
        int     i;

        for ( i=0; i<BlockSlots; i++ )
        {
                if ( (Blocks[i].Addr) && (Blocks[i].Size) )
                {
                        IncActionNumber();
                        SayActionNumber(TRUE);
                        SayBlockNo(i);
                        BlockTest( &Blocks[i] );
                        DoFree( &Blocks[i] );
                }
        }
}

/* ========================================================================= */

void    DisplayStatus( void )
{
}


void    DisplayTotals( void )
{
        int TotalBlocks, TotalSize, i;

        TotalBlocks = TotalSize = 0;

        for( i=0; i<BlockSlots; i++ )
        {
                if ( (Blocks[i].Addr) && (Blocks[i].Size) )
                {
                        TotalBlocks++;
                        TotalSize+=Blocks[i].Size;
                }
        }

        if (TotalSize)
        {
                printf("\r\n0x%08X bytes in 0x%08X blocks", TotalSize, TotalBlocks );
                printf("\r\nAverage is 0x%08X bytes per block\r\n", TotalSize/TotalBlocks) ;
        }
}

/* ========================================================================= */

void    RunTest( void )
{
        int     quit = 0;
        unsigned int    bn;

        while (!quit)
        {
                if (kbhit())
                {
                        switch( getchar() )
                        {
                        case EscapeKey:
                                quit = -1;
                                break;
                        case VerboseKey:
                                ToggleVerbosity();
                                break;
                        }
                        DisplayTotals();
                        DisplayStatus();
                }
                IncActionNumber();
                SayActionNumber(TRUE);
                bn = Rand1n( BlockSlots ) - 1;
                SayBlockNo( bn );
                DoBlock( bn );
        }
}

/* ========================================================================= */

void    TestHeap( void )
{
        Randomise();
        InitBlockArray();
        PatternFill();
        DisplayTotals();
        DisplayStatus();
        RunTest();

        DisplayTotals();
        DisplayStatus();
        FreeAll();

        DisplayTotals();
        DisplayStatus();
        PatternFree();

        DisplayTotals();
        DisplayStatus();
}

/* ========================================================================= */

void    Run( void )
{
        TestHeap();
}

void    RunSeeded( unsigned int Seed )
{
        InitialSeed = Seed;
        RandSeed = Seed;
        Run();
}

/* ========================================================================= */

void    main( void )
{
        printf( APPTITLE );
        RunSeeded( 0 );
        printf("\r\n\r\n\r\nEXIT\r\n\r\n\r\n");
}

