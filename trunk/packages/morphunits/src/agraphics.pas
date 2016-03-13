{
    This file is part of the Free Pascal run time library.
    Copyright (c) 2004 Karoly Balogh for Genesi S.a.r.l. <www.genesi.lu>

    graphics.library interface unit for MorphOS/PowerPC

    Based on work of Nils Sjoholm member of the Amiga RTL
    development team.

    MorphOS port was done on a free Pegasos II/G4 machine
    provided by Genesi S.a.r.l. <www.genesi.lu>

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}
{$PACKRECORDS 2}

unit agraphics;

interface

uses exec, hardware, utility;

const
    BITSET      = $8000;
    BITCLR      = 0;

type
    pRectangle = ^tRectangle;
    tRectangle = record
        MinX,MinY       : Word;
        MaxX,MaxY       : Word;
    end;

    pRect32 = ^tRect32;
    tRect32 = record
        MinX,MinY       : Longint;
        MaxX,MaxY       : Longint;
    end;

    pPoint = ^tPoint;
    tPoint = record
        x,y     : Word;
    end;

    TPLANEPTR = PByte;

    pBitMap = ^tBitMap;
    tBitMap = record
        BytesPerRow     : Word;
        Rows            : Word;
        Flags           : Byte;
        Depth           : Byte;
        pad             : Word;
        Planes          : Array [0..7] of TPLANEPTR;
    end;
{* flags for AllocBitMap, etc. *}
const
     BMB_CLEAR       = 0;
     BMB_DISPLAYABLE = 1;
     BMB_INTERLEAVED = 2;
     BMB_STANDARD    = 3;
     BMB_MINPLANES   = 4;

     BMF_CLEAR       = (1 shl BMB_CLEAR);
     BMF_DISPLAYABLE = (1 shl BMB_DISPLAYABLE);
     BMF_INTERLEAVED = (1 shl BMB_INTERLEAVED);
     BMF_STANDARD    = (1 shl BMB_STANDARD);
     BMF_MINPLANES   = (1 shl BMB_MINPLANES);

{* the following are for GetBitMapAttr() *}
     BMA_HEIGHT      = 0;
     BMA_DEPTH       = 4;
     BMA_WIDTH       = 8;
     BMA_FLAGS       = 12;


{ structures used by and constructed by windowlib.a }
{ understood by rom software }
type
    pClipRect = ^tClipRect;
    tClipRect = record
        Next    : pClipRect;    { roms used to find next ClipRect }
        prev    : pClipRect;    { ignored by roms, used by windowlib }
        lobs    : Pointer;      { ignored by roms, used by windowlib (LayerPtr)}
        BitMap  : pBitMap;
        bounds  : tRectangle;    { set up by windowlib, used by roms }
        _p1,
        _p2     : Pointer;    { system reserved }
        reserved : Longint;     { system use }
        Flags   : Longint;      { only exists in layer allocation }
    end;

    pLayer = ^tLayer;
    tLayer = record
        front,
        back            : pLayer;       { ignored by roms }
        ClipRect        : pClipRect;  { read by roms to find first cliprect }
        rp              : Pointer;      { (RastPortPtr) ignored by roms, I hope }
        bounds          : tRectangle;    { ignored by roms }
        reserved        : Array [0..3] of Byte;
        priority        : Word;        { system use only }
        Flags           : Word;        { obscured ?, Virtual BitMap? }
        SuperBitMap     : pBitMap;
        SuperClipRect   : pClipRect;  { super bitmap cliprects if
                                                VBitMap != 0}
                                        { else damage cliprect list for refresh }
        Window          : Pointer;      { reserved for user interface use }
        Scroll_X,
        Scroll_Y        : Word;
        cr,
        cr2,
        crnew           : pClipRect;  { used by dedice }
        SuperSaveClipRects : pClipRect; { preallocated cr's }
        cliprects      : pClipRect;  { system use during refresh }
        LayerInfo       : Pointer;      { points to head of the list }
        Lock            : tSignalSemaphore;
        BackFill        : pHook;
        reserved1       : Cardinal;
        ClipRegion      : Pointer;
        saveClipRects   : Pointer;      { used to back out when in trouble}
        Width,
        Height          : smallint;
        reserved2       : Array [0..17] of Byte;
        { this must stay here }
        DamageList      : Pointer;      { list of rectangles to refresh
                                                through }
    end;

const

{ internal cliprect flags }

    CR_NEEDS_NO_CONCEALED_RASTERS       = 1;
    CR_NEEDS_NO_LAYERBLIT_DAMAGE        = 2;


{ defines for code values for getcode }

    ISLESSX     = 1;
    ISLESSY     = 2;
    ISGRTRX     = 4;
    ISGRTRY     = 8;


{------ Font Styles ------------------------------------------------}

    FS_NORMAL           = 0;    { normal text (no style bits set) }
    FSB_EXTENDED        = 3;    { extended face (wider than normal) }
    FSF_EXTENDED        = 8;
    FSB_ITALIC          = 2;    { italic (slanted 1:2 right) }
    FSF_ITALIC          = 4;
    FSB_BOLD            = 1;    { bold face text (ORed w/ shifted) }
    FSF_BOLD            = 2;
    FSB_UNDERLINED      = 0;    { underlined (under baseline) }
    FSF_UNDERLINED      = 1;

    FSB_COLORFONT       = 6;       { this uses ColorTextFont structure }
    FSF_COLORFONT       = $40;
    FSB_TAGGED          = 7;       { the TextAttr is really an TTextAttr, }
    FSF_TAGGED          = $80;


{------ Font Flags -------------------------------------------------}
    FPB_ROMFONT         = 0;    { font is in rom }
    FPF_ROMFONT         = 1;
    FPB_DISKFONT        = 1;    { font is from diskfont.library }
    FPF_DISKFONT        = 2;
    FPB_REVPATH         = 2;    { designed path is reversed (e.g. left) }
    FPF_REVPATH         = 4;
    FPB_TALLDOT         = 3;    { designed for hires non-interlaced }
    FPF_TALLDOT         = 8;
    FPB_WIDEDOT         = 4;    { designed for lores interlaced }
    FPF_WIDEDOT         = 16;
    FPB_PROPORTIONAL    = 5;    { character sizes can vary from nominal }
    FPF_PROPORTIONAL    = 32;
    FPB_DESIGNED        = 6;    { size is "designed", not constructed }
    FPF_DESIGNED        = 64;
    FPB_REMOVED         = 7;    { the font has been removed }
    FPF_REMOVED         = 128;

{***** TextAttr node, matches text attributes in RastPort *********}

type

    pTextAttr = ^tTextAttr;
    tTextAttr = record
        ta_Name : PChar;       { name of the font }
        ta_YSize : Word;       { height of the font }
        ta_Style : Byte;        { intrinsic font style }
        ta_Flags : Byte;        { font preferences and flags }
    end;

    pTTextAttr = ^tTTextAttr;
    tTTextAttr = record
        tta_Name : PChar;       { name of the font }
        tta_YSize : Word;       { height of the font }
        tta_Style : Byte;        { intrinsic font style }
        tta_Flags : Byte;        { font preferences AND flags }
        tta_Tags  : pTagItem;     { extended attributes }
    end;

{***** Text Tags **************************************************}
CONST
  TA_DeviceDPI  =  (1+TAG_USER);    { Tag value is Point union: }
                                        { Hi Longint XDPI, Lo Longint YDPI }

  MAXFONTMATCHWEIGHT  =    32767;   { perfect match from WeighTAMatch }



{***** TextFonts node *********************************************}
Type

    pTextFont = ^tTextFont;
    tTextFont = record
        tf_Message      : tMessage;      { reply message for font removal }
                                        { font name in LN \    used in this }
        tf_YSize        : Word;        { font height     |    order to best }
        tf_Style        : Byte;         { font style      |    match a font }
        tf_Flags        : Byte;         { preferences and flags /    request. }
        tf_XSize        : Word;        { nominal font width }
        tf_Baseline     : Word; { distance from the top of char to baseline }
        tf_BoldSmear    : Word;        { smear to affect a bold enhancement }

        tf_Accessors    : Word;        { access count }

        tf_LoChar       : Byte;         { the first character described here }
        tf_HiChar       : Byte;         { the last character described here }
        tf_CharData     : Pointer;      { the bit character data }

        tf_Modulo       : Word; { the row modulo for the strike font data }
        tf_CharLoc      : Pointer; { ptr to location data for the strike font }
                                        { 2 words: bit offset then size }
        tf_CharSpace    : Pointer; { ptr to words of proportional spacing data }
        tf_CharKern     : Pointer;      { ptr to words of kerning data }
    end;


{----- tfe_Flags0 (partial definition) ----------------------------}
CONST
 TE0B_NOREMFONT = 0;       { disallow RemFont for this font }
 TE0F_NOREMFONT = $01;

Type

   pTextFontExtension = ^tTextFontExtension;
   tTextFontExtension = record              { this structure is read-only }
    tfe_MatchWord  : Word;                { a magic cookie for the extension }
    tfe_Flags0     : Byte;                 { (system private flags) }
    tfe_Flags1     : Byte;                 { (system private flags) }
    tfe_BackPtr    : pTextFont;          { validation of compilation }
    tfe_OrigReplyPort : pMsgPort;        { original value in tf_Extension }
    tfe_Tags       : pTagItem;              { Text Tags for the font }
    tfe_OFontPatchS,                       { (system private use) }
    tfe_OFontPatchK : Pointer;             { (system private use) }
    { this space is reserved for future expansion }
   END;

{***** ColorTextFont node *****************************************}
{----- ctf_Flags --------------------------------------------------}
CONST
 CT_COLORMASK  =  $000F;  { mask to get to following color styles }
 CT_COLORFONT  =  $0001;  { color map contains designer's colors }
 CT_GREYFONT   =  $0002;  { color map describes even-stepped }
                                { brightnesses from low to high }
 CT_ANTIALIAS  =  $0004;  { zero background thru fully saturated char }

 CTB_MAPCOLOR  =  0;      { map ctf_FgColor to the rp_FgPen IF it's }
 CTF_MAPCOLOR  =  $0001;  { is a valid color within ctf_Low..ctf_High }

{----- ColorFontColors --------------------------------------------}
Type
   pColorFontColors = ^tColorFontColors;
   tColorFontColors = record
    cfc_Reserved,                 { *must* be zero }
    cfc_Count   : Word;          { number of entries in cfc_ColorTable }
    cfc_ColorTable : Pointer;     { 4 bit per component color map packed xRGB }
   END;

{----- ColorTextFont ----------------------------------------------}

   pColorTextFont = ^tColorTextFont;
   tColorTextFont = record
    ctf_TF      : tTextFont;
    ctf_Flags   : Word;          { extended flags }
    ctf_Depth,          { number of bit planes }
    ctf_FgColor,        { color that is remapped to FgPen }
    ctf_Low,            { lowest color represented here }
    ctf_High,           { highest color represented here }
    ctf_PlanePick,      { PlanePick ala Images }
    ctf_PlaneOnOff : Byte;     { PlaneOnOff ala Images }
    ctf_ColorFontColors : pColorFontColors; { colors for font }
    ctf_CharData : Array[0..7] of Pointer;    {pointers to bit planes ala tf_CharData }
   END;

{***** TextExtent node ********************************************}

   pTextExtent = ^tTextExtent;
   tTextExtent = record
    te_Width,                   { same as TextLength }
    te_Height : Word;          { same as tf_YSize }
    te_Extent : tRectangle;      { relative to CP }
   END;


const

    COPPER_MOVE = 0;    { pseude opcode for move #XXXX,dir }
    COPPER_WAIT = 1;    { pseudo opcode for wait y,x }
    CPRNXTBUF   = 2;    { continue processing with next buffer }
    CPR_NT_LOF  = $8000; { copper instruction only for Longint frames }
    CPR_NT_SHT  = $4000; { copper instruction only for long frames }
    CPR_NT_SYS  = $2000; { copper user instruction only }
type

{ Note: The combination VWaitAddr and HWaitAddr replace a three way
        union in C.  The three possibilities are:

        nxtList : CopListPtr;  or

        VWaitPos : Longint;
        HWaitPos : Longint;  or

        DestAddr : Longint;
        DestData : Longint;
}

    pCopIns = ^tCopIns;
    tCopIns = record
        OpCode  : smallint; { 0 = move, 1 = wait }
        VWaitAddr : smallint; { vertical or horizontal wait position }
        HWaitData : smallint; { destination Pointer or data to send }
    end;

{ structure of cprlist that points to list that hardware actually executes }

    pcprlist = ^tcprlist;
    tcprlist = record
        Next    : pcprlist;
        start   : psmallint;       { start of copper list }
        MaxCount : smallint;       { number of long instructions }
    end;

    pCopList = ^tCopList;
    tCopList = record
        Next    : pCopList;     { next block for this copper list }
        CopList : pCopList;    { system use }
        ViewPort : Pointer;    { system use }
        CopIns  : pCopIns;    { start of this block }
        CopPtr  : pCopIns;    { intermediate ptr }
        CopLStart : psmallint;     { mrgcop fills this in for Long Frame}
        CopSStart : psmallint;     { mrgcop fills this in for Longint Frame}
        Count   : smallint;        { intermediate counter }
        MaxCount : smallint;       { max # of copins for this block }
        DyOffset : smallint;       { offset this copper list vertical waits }
        SLRepeat : Word;
        Flags    : Word;
    end;

    pUCopList = ^tUCopList;
    tUCopList = record
        Next    : pUCopList;
        FirstCopList : pCopList;      { head node of this copper list }
        CopList : pCopList;           { node in use }
    end;

    pcopinit = ^tcopinit;
    tcopinit = record
        vsync_hblank : array [0..1] of word;
        diagstrt : Array [0..11] of word;
        fm0      : array [0..1] of word;
        diwstart : array [0..9] of word;
        bplcon2  : array [0..1] of word;
        sprfix   : array [0..(2*8)] of word;
        sprstrtup : Array [0..(2*8*2)] of Word;
        wait14    : array [0..1] of word;
        norm_hblank : array [0..1] of word;
        jump        : array [0..1] of word;
        wait_forever : array [0..5] of word;
        sprstop : Array [0..7] of Word;
    end;



    pAreaInfo = ^tAreaInfo;
    tAreaInfo = record
        VctrTbl : Pointer;      { ptr to start of vector table }
        VctrPtr : Pointer;      { ptr to current vertex }
        FlagTbl : Pointer;      { ptr to start of vector flag table }
        FlagPtr : Pointer;      { ptrs to areafill flags }
        Count   : smallint;        { number of vertices in list }
        MaxCount : smallint;       { AreaMove/Draw will not allow Count>MaxCount}
        FirstX,
        FirstY  : smallint;        { first point for this polygon }
    end;

    pTmpRas = ^tTmpRas;
    tTmpRas = record
        RasPtr  : Pointer;
        Size    : Longint;
    end;

{ unoptimized for 32bit alignment of pointers }

    pGelsInfo = ^tGelsInfo;
    tGelsInfo = record
        sprRsrvd        : Shortint; { flag of which sprites to reserve from
                                  vsprite system }
        Flags   : Byte;       { system use }
        gelHead,
        gelTail : Pointer; { (VSpritePtr) dummy vSprites for list management}

    { pointer to array of 8 WORDS for sprite available lines }

        nextLine : Pointer;

    { pointer to array of 8 pointers for color-last-assigned to vSprites }

        lastColor : Pointer;
        collHandler : Pointer;  { (collTablePtr) Pointeres of collision routines }
        leftmost,
        rightmost,
        topmost,
        bottommost      : smallint;
        firstBlissObj,
        lastBlissObj    : Pointer;    { system use only }
    end;

    pRastPort = ^tRastPort;
    tRastPort = record
        Layer           : pLayer;      { LayerPtr }
        BitMap          : pBitMap;      { BitMapPtr }
        ArePointern        : Pointer;      { ptr to areafill pattern }
        TmpRas          : pTmpRas;
        AreaInfo        : pAreaInfo;
        GelsInfo        : pGelsInfo;
        Mask            : Byte;         { write mask for this raster }
        FgPen           : Shortint;         { foreground pen for this raster }
        BgPen           : Shortint;         { background pen         }
        AOlPen          : Shortint;         { areafill outline pen }
        DrawMode        : Shortint; { drawing mode for fill, lines, and text }
        AreaPtSz        : Shortint;         { 2^n words for areafill pattern }
        linpatcnt       : Shortint; { current line drawing pattern preshift }
        dummy           : Shortint;
        Flags           : Word;        { miscellaneous control bits }
        LinePtrn        : Word;        { 16 bits for textured lines }
        cp_x,
        cp_y            : smallint;        { current pen position }
        minterms        : Array [0..7] of Byte;
        PenWidth        : smallint;
        PenHeight       : smallint;
        Font            : pTextFont;      { (TextFontPtr) current font Pointer }
        AlgoStyle       : Byte;         { the algorithmically generated style }
        TxFlags         : Byte;         { text specific flags }
        TxHeight        : Word;        { text height }
        TxWidth         : Word;        { text nominal width }
        TxBaseline      : Word;        { text baseline }
        TxSpacing       : smallint;        { text spacing (per character) }
        RP_User         : Pointer;
        longreserved    : Array [0..1] of Cardinal;
        wordreserved    : Array [0..6] of Word;        { used to be a node }
        reserved        : Array [0..7] of Byte;         { for future use }
    end;

const

{ drawing modes }

    JAM1        = 0;    { jam 1 color into raster }
    JAM2        = 1;    { jam 2 colors into raster }
    COMPLEMENT  = 2;    { XOR bits into raster }
    INVERSVID   = 4;    { inverse video for drawing modes }

{ these are the flag bits for RastPort flags }

    FRST_DOT    = $01;  { draw the first dot of this line ? }
    ONE_DOT     = $02;  { use one dot mode for drawing lines }
    DBUFFER     = $04;  { flag set when RastPorts are double-buffered }

             { only used for bobs }

    AREAOUTLINE = $08;  { used by areafiller }
    NOCROSSFILL = $20;  { areafills have no crossovers }

{ there is only one style of clipping: raster clipping }
{ this preserves the continuity of jaggies regardless of clip window }
{ When drawing into a RastPort, if the ptr to ClipRect is nil then there }
{ is no clipping done, this is dangerous but useful for speed }


Const
    CleanUp     = $40;
    CleanMe     = CleanUp;

    BltClearWait        = 1;    { Waits for blit to finish }
    BltClearXY          = 2;    { Use Row/Bytes per row method }

        { Useful minterms }

    StraightCopy        = $C0;  { Vanilla copy }
    InvertAndCopy       = $30;  { Invert the source before copy }
    InvertDest          = $50;  { Forget source, invert dest }


 {      mode coercion definitions }

const
{  These flags are passed (in combination) to CoerceMode() to determine the
 * type of coercion required.
 }

{  Ensure that the mode coerced to can display just as many colours as the
 * ViewPort being coerced.
 }
    PRESERVE_COLORS = 1;

{  Ensure that the mode coerced to is not interlaced. }
    AVOID_FLICKER   = 2;

{  Coercion should ignore monitor compatibility issues. }
    IGNORE_MCOMPAT  = 4;


    BIDTAG_COERCE   = 1; {  Private }

const

{ VSprite flags }
{ user-set VSprite flags: }

    SUSERFLAGS  = $00FF;        { mask of all user-settable VSprite-flags }
    VSPRITE_f   = $0001;        { set if VSprite, clear if Bob }
                                { VSPRITE had to be changed for name conflict }
    SAVEBACK    = $0002;        { set if background is to be saved/restored }
    OVERLAY     = $0004;        { set to mask image of Bob onto background }
    MUSTDRAW    = $0008;        { set if VSprite absolutely must be drawn }

{ system-set VSprite flags: }

    BACKSAVED   = $0100;        { this Bob's background has been saved }
    BOBUPDATE   = $0200;        { temporary flag, useless to outside world }
    GELGONE     = $0400;        { set if gel is completely clipped (offscreen) }
    VSOVERFLOW  = $0800;        { VSprite overflow (if MUSTDRAW set we draw!) }

{ Bob flags }
{ these are the user flag bits }

    BUSERFLAGS  = $00FF;        { mask of all user-settable Bob-flags }
    SAVEBOB     = $0001;        { set to not erase Bob }
    BOBISCOMP   = $0002;        { set to identify Bob as AnimComp }

{ these are the system flag bits }

    BWAITING    = $0100;        { set while Bob is waiting on 'after' }
    BDRAWN      = $0200;        { set when Bob is drawn this DrawG pass}
    BOBSAWAY    = $0400;        { set to initiate removal of Bob }
    BOBNIX      = $0800;        { set when Bob is completely removed }
    SAVEPRESERVE = $1000;       { for back-restore during double-buffer}
    OUTSTEP     = $2000;        { for double-clearing if double-buffer }

{ defines for the animation procedures }

    ANFRACSIZE  = 6;
    ANIMHALF    = $0020;
    RINGTRIGGER = $0001;


{ UserStuff definitions
 *  the user can define these to be a single variable or a sub-structure
 *  if undefined by the user, the system turns these into innocuous variables
 *  see the manual for a thorough definition of the UserStuff definitions
 *
 }

type

    VUserStuff  = smallint;        { Sprite user stuff }
    BUserStuff  = smallint;        { Bob user stuff }
    AUserStuff  = smallint;        { AnimOb user stuff }

{********************** GEL STRUCTURES **********************************}

    pVSprite = ^tVSprite;
    tVSprite = record

{ --------------------- SYSTEM VARIABLES ------------------------------- }
{ GEL linked list forward/backward pointers sorted by y,x value }

        NextVSprite     : pVSprite;
        PrevVSprite     : pVSprite;

{ GEL draw list constructed in the order the Bobs are actually drawn, then
 *  list is copied to clear list
 *  must be here in VSprite for system boundary detection
 }

        DrawPath        : pVSprite;     { pointer of overlay drawing }
        ClearPath       : pVSprite;     { pointer for overlay clearing }

{ the VSprite positions are defined in (y,x) order to make sorting
 *  sorting easier, since (y,x) as a long Longint
 }

        OldY, OldX      : smallint;        { previous position }

{ --------------------- COMMON VARIABLES --------------------------------- }

        Flags           : smallint;        { VSprite flags }


{ --------------------- USER VARIABLES ----------------------------------- }
{ the VSprite positions are defined in (y,x) order to make sorting
 *  sorting easier, since (y,x) as a long Longint
 }

        Y, X            : smallint;        { screen position }

        Height  : smallint;
        Width   : smallint;        { number of words per row of image data }
        Depth   : smallint;        { number of planes of data }

        MeMask  : smallint;        { which types can collide with this VSprite}
        HitMask : smallint;        { which types this VSprite can collide with}

        ImageData       : Pointer;      { pointer to VSprite image }

{ borderLine is the one-dimensional logical OR of all
 *  the VSprite bits, used for fast collision detection of edge
 }

        BorderLine      : Pointer; { logical OR of all VSprite bits }
        CollMask        : Pointer; { similar to above except this is a matrix }

{ pointer to this VSprite's color definitions (not used by Bobs) }

        SprColors       : Pointer;

        VSBob   : Pointer;      { (BobPtr) points home if this VSprite
                                   is part of a Bob }

{ planePick flag:  set bit selects a plane from image, clear bit selects
 *  use of shadow mask for that plane
 * OnOff flag: if using shadow mask to fill plane, this bit (corresponding
 *  to bit in planePick) describes whether to fill with 0's or 1's
 * There are two uses for these flags:
 *      - if this is the VSprite of a Bob, these flags describe how the Bob
 *        is to be drawn into memory
 *      - if this is a simple VSprite and the user intends on setting the
 *        MUSTDRAW flag of the VSprite, these flags must be set too to describe
 *        which color registers the user wants for the image
 }

        PlanePick       : Shortint;
        PlaneOnOff      : Shortint;

        VUserExt        : VUserStuff;   { user definable:  see note above }
    end;




{ dBufPacket defines the values needed to be saved across buffer to buffer
 *  when in double-buffer mode
 }

    pDBufPacket = ^tDBufPacket;
    tDBufPacket = record
        BufY,
        BufX    : Word;        { save other buffers screen coordinates }
        BufPath : pVSprite;   { carry the draw path over the gap }

{ these pointers must be filled in by the user }
{ pointer to other buffer's background save buffer }

        BufBuffer : Pointer;
    end;





    pBob = ^tBob;
    tBob = record
{ blitter-objects }

{ --------------------- SYSTEM VARIABLES --------------------------------- }

{ --------------------- COMMON VARIABLES --------------------------------- }

        Flags   : smallint; { general purpose flags (see definitions below) }

{ --------------------- USER VARIABLES ----------------------------------- }

        SaveBuffer : Pointer;   { pointer to the buffer for background save }

{ used by Bobs for "cookie-cutting" and multi-plane masking }

        ImageShadow : Pointer;

{ pointer to BOBs for sequenced drawing of Bobs
 *  for correct overlaying of multiple component animations
 }
        Before  : pBob; { draw this Bob before Bob pointed to by before }
        After   : pBob; { draw this Bob after Bob pointed to by after }

        BobVSprite : pVSprite;        { this Bob's VSprite definition }

        BobComp : Pointer; { (AnimCompPtr) pointer to this Bob's AnimComp def }

        DBuffer : Pointer;        { pointer to this Bob's dBuf packet }

        BUserExt : BUserStuff;  { Bob user extension }
    end;

    pAnimComp = ^tAnimComp;
    tAnimComp = record

{ --------------------- SYSTEM VARIABLES --------------------------------- }

{ --------------------- COMMON VARIABLES --------------------------------- }

        Flags   : smallint;        { AnimComp flags for system & user }

{ timer defines how long to keep this component active:
 *  if set non-zero, timer decrements to zero then switches to nextSeq
 *  if set to zero, AnimComp never switches
 }

        Timer   : smallint;

{ --------------------- USER VARIABLES ----------------------------------- }
{ initial value for timer when the AnimComp is activated by the system }

        TimeSet : smallint;

{ pointer to next and previous components of animation object }

        NextComp        : pAnimComp;
        PrevComp        : pAnimComp;

{ pointer to component component definition of next image in sequence }

        NextSeq : pAnimComp;
        PrevSeq : pAnimComp;

        AnimCRoutine : Pointer; { Pointer of special animation procedure }

        YTrans  : smallint; { initial y translation (if this is a component) }
        XTrans  : smallint; { initial x translation (if this is a component) }

        HeadOb  : Pointer; { AnimObPtr }

        AnimBob : pBob;
    end;

    pAnimOb = ^tAnimOb;
    tAnimOb = record

{ --------------------- SYSTEM VARIABLES --------------------------------- }

        NextOb,
        PrevOb  : pAnimOb;

{ number of calls to Animate this AnimOb has endured }

        Clock   : Longint;

        AnOldY,
        AnOldX  : smallint;        { old y,x coordinates }

{ --------------------- COMMON VARIABLES --------------------------------- }

        AnY,
        AnX     : smallint;        { y,x coordinates of the AnimOb }

{ --------------------- USER VARIABLES ----------------------------------- }

        YVel,
        XVel    : smallint;        { velocities of this object }
        YAccel,
        XAccel  : smallint;        { accelerations of this object }

        RingYTrans,
        RingXTrans      : smallint;        { ring translation values }

        AnimORoutine    : Pointer;      { Pointer of special animation
                                          procedure }

        HeadComp        : pAnimComp;  { pointer to first component }

        AUserExt        : AUserStuff;       { AnimOb user extension }
    end;

    ppAnimOb = ^pAnimOb;


{ ************************************************************************ }

const

    B2NORM      = 0;
    B2SWAP      = 1;
    B2BOBBER    = 2;

{ ************************************************************************ }

type

{ a structure to contain the 16 collision procedure addresses }

    collTable = Array [0..15] of Pointer;
    pcollTable = ^collTable;

const

{   These bit descriptors are used by the GEL collide routines.
 *  These bits are set in the hitMask and meMask variables of
 *  a GEL to describe whether or not these types of collisions
 *  can affect the GEL.  BNDRY_HIT is described further below;
 *  this bit is permanently assigned as the boundary-hit flag.
 *  The other bit GEL_HIT is meant only as a default to cover
 *  any GEL hitting any other; the user may redefine this bit.
 }

    BORDERHIT   = 0;

{   These bit descriptors are used by the GEL boundry hit routines.
 *  When the user's boundry-hit routine is called (via the argument
 *  set by a call to SetCollision) the first argument passed to
 *  the user's routine is the Pointer of the GEL involved in the
 *  boundry-hit, and the second argument has the appropriate bit(s)
 *  set to describe which boundry was surpassed
 }

    TOPHIT      = 1;
    BOTTOMHIT   = 2;
    LEFTHIT     = 4;
    RIGHTHIT    = 8;

Type
 pExtendedNode = ^tExtendedNode;
 tExtendedNode = record
  xln_Succ,
  xln_Pred  : pNode;
  xln_Type  : Byte;
  xln_Pri   : Shortint;
  xln_Name  : PChar;
  xln_Subsystem : Byte;
  xln_Subtype   : Byte;
  xln_Library : Longint;
  xln_Init : Pointer;
 END;

CONST
 SS_GRAPHICS   =  $02;

 VIEW_EXTRA_TYPE       =  1;
 VIEWPORT_EXTRA_TYPE   =  2;
 SPECIAL_MONITOR_TYPE  =  3;
 MONITOR_SPEC_TYPE     =  4;

type

{ structure used by AddTOFTask }

    pIsrvstr = ^tIsrvstr;
    tIsrvstr = record
        is_Node : tNode;
        Iptr    : pIsrvstr;     { passed to srvr by os }
        code    : Pointer;
        ccode   : Pointer;
        Carg    : Pointer;
    end;

Type
 pAnalogSignalInterval = ^tAnalogSignalInterval;
 tAnalogSignalInterval = record
  asi_Start,
  asi_Stop  : Word;
 END;

 pSpecialMonitor = ^tSpecialMonitor;
 tSpecialMonitor = record
  spm_Node      : tExtendedNode;
  spm_Flags     : Word;
  do_monitor,
  reserved1,
  reserved2,
  reserved3     : Pointer;
  hblank,
  vblank,
  hsync,
  vsync : tAnalogSignalInterval;
 END;


 pMonitorSpec = ^tMonitorSpec;
 tMonitorSpec = record
    ms_Node     : tExtendedNode;
    ms_Flags    : Word;
    ratioh,
    ratiov      : Longint;
    total_rows,
    total_colorclocks,
    DeniseMaxDisplayColumn,
    BeamCon0,
    min_row     : Word;
    ms_Special  : pSpecialMonitor;
    ms_OpenCount : Word;
    ms_transform,
    ms_translate,
    ms_scale    : Pointer;
    ms_xoffset,
    ms_yoffset  : Word;
    ms_LegalView : tRectangle;
    ms_maxoscan,       { maximum legal overscan }
    ms_videoscan  : Pointer;      { video display overscan }
    DeniseMinDisplayColumn : Word;
    DisplayCompatible      : Cardinal;
    DisplayInfoDataBase    : tList;
    DisplayInfoDataBaseSemaphore : tSignalSemaphore;
    ms_MrgCop,
    ms_LoadView,
    ms_KillView  : Longint;
 END;

const
  TO_MONITOR            =  0;
  FROM_MONITOR          =  1;
  STANDARD_XOFFSET      =  9;
  STANDARD_YOFFSET      =  0;

  MSB_REQUEST_NTSC      =  0;
  MSB_REQUEST_PAL       =  1;
  MSB_REQUEST_SPECIAL   =  2;
  MSB_REQUEST_A2024     =  3;
  MSB_DOUBLE_SPRITES    =  4;
  MSF_REQUEST_NTSC      =  1;
  MSF_REQUEST_PAL       =  2;
  MSF_REQUEST_SPECIAL   =  4;
  MSF_REQUEST_A2024     =  8;
  MSF_DOUBLE_SPRITES    =  16;


{ obsolete, v37 compatible definitions follow }
  REQUEST_NTSC          =  1;
  REQUEST_PAL           =  2;
  REQUEST_SPECIAL       =  4;
  REQUEST_A2024         =  8;

  DEFAULT_MONITOR_NAME  : PChar =  'default.monitor';
  NTSC_MONITOR_NAME     : PChar =  'ntsc.monitor';
  PAL_MONITOR_NAME      : PChar =  'pal.monitor';
  STANDARD_MONITOR_MASK =  ( REQUEST_NTSC OR REQUEST_PAL ) ;

  STANDARD_NTSC_ROWS    =  262;
  STANDARD_PAL_ROWS     =  312;
  STANDARD_COLORCLOCKS  =  226;
  STANDARD_DENISE_MAX   =  455;
  STANDARD_DENISE_MIN   =  93 ;
  STANDARD_NTSC_BEAMCON =  $0000;
  STANDARD_PAL_BEAMCON  =  DISPLAYPAL ;

  SPECIAL_BEAMCON       = ( VARVBLANK OR LOLDIS OR VARVSYNC OR VARHSYNC OR VARBEAM OR CSBLANK OR VSYNCTRUE);

  MIN_NTSC_ROW    = 21   ;
  MIN_PAL_ROW     = 29   ;
  STANDARD_VIEW_X = $81  ;
  STANDARD_VIEW_Y = $2C  ;
  STANDARD_HBSTRT = $06  ;
  STANDARD_HSSTRT = $0B  ;
  STANDARD_HSSTOP = $1C  ;
  STANDARD_HBSTOP = $2C  ;
  STANDARD_VBSTRT = $0122;
  STANDARD_VSSTRT = $02A6;
  STANDARD_VSSTOP = $03AA;
  STANDARD_VBSTOP = $1066;

  VGA_COLORCLOCKS = (STANDARD_COLORCLOCKS/2);
  VGA_TOTAL_ROWS  = (STANDARD_NTSC_ROWS*2);
  VGA_DENISE_MIN  = 59   ;
  MIN_VGA_ROW     = 29   ;
  VGA_HBSTRT      = $08  ;
  VGA_HSSTRT      = $0E  ;
  VGA_HSSTOP      = $1C  ;
  VGA_HBSTOP      = $1E  ;
  VGA_VBSTRT      = $0000;
  VGA_VSSTRT      = $0153;
  VGA_VSSTOP      = $0235;
  VGA_VBSTOP      = $0CCD;

  VGA_MONITOR_NAME  : PChar    =  'vga.monitor';

{ NOTE: VGA70 definitions are obsolete - a VGA70 monitor has never been
 * implemented.
 }
  VGA70_COLORCLOCKS = (STANDARD_COLORCLOCKS/2) ;
  VGA70_TOTAL_ROWS  = 449;
  VGA70_DENISE_MIN  = 59;
  MIN_VGA70_ROW     = 35   ;
  VGA70_HBSTRT      = $08  ;
  VGA70_HSSTRT      = $0E  ;
  VGA70_HSSTOP      = $1C  ;
  VGA70_HBSTOP      = $1E  ;
  VGA70_VBSTRT      = $0000;
  VGA70_VSSTRT      = $02A6;
  VGA70_VSSTOP      = $0388;
  VGA70_VBSTOP      = $0F73;

  VGA70_BEAMCON     = (SPECIAL_BEAMCON XOR VSYNCTRUE);
  VGA70_MONITOR_NAME  : PChar  =      'vga70.monitor';

  BROADCAST_HBSTRT  =      $01  ;
  BROADCAST_HSSTRT  =      $06  ;
  BROADCAST_HSSTOP  =      $17  ;
  BROADCAST_HBSTOP  =      $27  ;
  BROADCAST_VBSTRT  =      $0000;
  BROADCAST_VSSTRT  =      $02A6;
  BROADCAST_VSSTOP  =      $054C;
  BROADCAST_VBSTOP  =      $1C40;
  BROADCAST_BEAMCON =      ( LOLDIS OR CSBLANK );
  RATIO_FIXEDPART   =      4;
  RATIO_UNITY       =      16;



Type
    pRasInfo = ^tRasInfo;
    tRasInfo = record    { used by callers to and InitDspC() }
        Next    : pRasInfo;     { used for dualpf }
        BitMap  : pBitMap;
        RxOffset,
        RyOffset : smallint;       { scroll offsets in this BitMap }
    end;


    pView = ^tView;
    tView = record
        ViewPort        : Pointer;      { ViewPortPtr }
        LOFCprList      : pcprlist;   { used for interlaced and noninterlaced }
        SHFCprList      : pcprlist;   { only used during interlace }
        DyOffset,
        DxOffset        : smallint;        { for complete View positioning }
                                { offsets are +- adjustments to standard #s }
        Modes           : WORD;        { such as INTERLACE, GENLOC }
    end;

{ these structures are obtained via GfxNew }
{ and disposed by GfxFree }
Type
       pViewExtra = ^tViewExtra;
       tViewExtra = record
        n : tExtendedNode;
        View     : pView;       { backwards link }   { view in C-Includes }
        Monitor : pMonitorSpec; { monitors for this view }
        TopLine : Word;
       END;


    pViewPort = ^tViewPort;
    tViewPort = record
        Next    : pViewPort;
        ColorMap : Pointer; { table of colors for this viewport }        { ColorMapPtr }
                          { if this is nil, MakeVPort assumes default values }
        DspIns  : pCopList;   { user by MakeView() }
        SprIns  : pCopList;   { used by sprite stuff }
        ClrIns  : pCopList;   { used by sprite stuff }
        UCopIns : pUCopList;  { User copper list }
        DWidth,
        DHeight : smallint;
        DxOffset,
        DyOffset : smallint;
        Modes   : Word;
        SpritePriorities : Byte;        { used by makevp }
        reserved : Byte;
        RasInfo : pRasInfo;
    end;


{ this structure is obtained via GfxNew }
{ and disposed by GfxFree }

 pViewPortExtra = ^tViewPortExtra;
 tViewPortExtra = record
  n : tExtendedNode;
  ViewPort     : pViewPort;      { backwards link }   { ViewPort in C-Includes }
  DisplayClip  : tRectangle;  { makevp display clipping information }
        { These are added for V39 }
  VecTable     : Pointer;                { Private }
  DriverData   : Array[0..1] of Pointer;
  Flags        : WORD;
  Origin       : Array[0..1] of tPoint;  { First visible point relative to the DClip.
                                         * One for each possible playfield.
                                         }
  cop1ptr,                  { private }
  cop2ptr      : Cardinal;   { private }
 END;


    pColorMap = ^tColorMap;
    tColorMap = record
        Flags   : Byte;
        CType   : Byte;         { This is "Type" in C includes }
        Count   : Word;
        ColorTable      : Pointer;
        cm_vpe  : pViewPortExtra;
        LowColorBits : Pointer;
        TransparencyPlane,
        SpriteResolution,
        SpriteResDefault,
        AuxFlags         : Byte;
        cm_vp            : pViewPort;   { ViewPortPtr }
        NormalDisplayInfo,
        CoerceDisplayInfo : Pointer;
        cm_batch_items   : pTagItem;
        VPModeID         : Cardinal;
        PalExtra         : Pointer;
        SpriteBase_Even,
        SpriteBase_Odd,
        Bp_0_base,
        Bp_1_base        : Word;
    end;

{ if Type == 0 then ColorMap is V1.2/V1.3 compatible }
{ if Type != 0 then ColorMap is V36       compatible }
{ the system will never create other than V39 type colormaps when running V39 }

CONST
 COLORMAP_TYPE_V1_2     = $00;
 COLORMAP_TYPE_V1_4     = $01;
 COLORMAP_TYPE_V36      = COLORMAP_TYPE_V1_4;    { use this definition }
 COLORMAP_TYPE_V39      = $02;


{ Flags variable }
 COLORMAP_TRANSPARENCY   = $01;
 COLORPLANE_TRANSPARENCY = $02;
 BORDER_BLANKING         = $04;
 BORDER_NOTRANSPARENCY   = $08;
 VIDEOCONTROL_BATCH      = $10;
 USER_COPPER_CLIP        = $20;


CONST
 EXTEND_VSTRUCT = $1000;  { unused bit in Modes field of View }


{ defines used for Modes in IVPargs }

CONST
 GENLOCK_VIDEO  =  $0002;
 LACE           =  $0004;
 SUPERHIRES     =  $0020;
 PFBA           =  $0040;
 EXTRA_HALFBRITE=  $0080;
 GENLOCK_AUDIO  =  $0100;
 DUALPF         =  $0400;
 HAM            =  $0800;
 EXTENDED_MODE  =  $1000;
 VP_HIDE        =  $2000;
 SPRITES        =  $4000;
 HIRES          =  $8000;

 VPF_A2024      =  $40;
 VPF_AGNUS      =  $20;
 VPF_TENHZ      =  $20;

 BORDERSPRITES   = $40;

 CMF_CMTRANS   =  0;
 CMF_CPTRANS   =  1;
 CMF_BRDRBLNK  =  2;
 CMF_BRDNTRAN  =  3;
 CMF_BRDRSPRT  =  6;

 SPRITERESN_ECS       =   0;
{ ^140ns, except in 35ns viewport, where it is 70ns. }
 SPRITERESN_140NS     =   1;
 SPRITERESN_70NS      =   2;
 SPRITERESN_35NS      =   3;
 SPRITERESN_DEFAULT   =   -1;

{ AuxFlags : }
 CMAB_FULLPALETTE = 0;
 CMAF_FULLPALETTE = 1;
 CMAB_NO_INTERMED_UPDATE = 1;
 CMAF_NO_INTERMED_UPDATE = 2;
 CMAB_NO_COLOR_LOAD = 2;
 CMAF_NO_COLOR_LOAD = 4;
 CMAB_DUALPF_DISABLE = 3;
 CMAF_DUALPF_DISABLE = 8;

Type
    pPaletteExtra = ^tPaletteExtra;
    tPaletteExtra = record                            { structure may be extended so watch out! }
        pe_Semaphore  : tSignalSemaphore;                { shared semaphore for arbitration     }
        pe_FirstFree,                                   { *private*                            }
        pe_NFree,                                       { number of free colors                }
        pe_FirstShared,                                 { *private*                            }
        pe_NShared    : WORD;                           { *private*                            }
        pe_RefCnt     : Pointer;                        { *private*                            }
        pe_AllocList  : Pointer;                        { *private*                            }
        pe_ViewPort   : pViewPort;                    { back pointer to viewport             }
        pe_SharableColors : WORD;                       { the number of sharable colors.       }
    end;
{ flags values for ObtainPen }
Const
 PENB_EXCLUSIVE = 0;
 PENB_NO_SETCOLOR = 1;

 PENF_EXCLUSIVE = 1;
 PENF_NO_SETCOLOR = 2;

{ obsolete names for PENF_xxx flags: }

 PEN_EXCLUSIVE = PENF_EXCLUSIVE;
 PEN_NO_SETCOLOR = PENF_NO_SETCOLOR;

{ precision values for ObtainBestPen : }

 PRECISION_EXACT = -1;
 PRECISION_IMAGE = 0;
 PRECISION_ICON  = 16;
 PRECISION_GUI   = 32;


{ tags for ObtainBestPen: }
 OBP_Precision = $84000000;
 OBP_FailIfBad = $84000001;

{ From V39, MakeVPort() will return an error if there is not enough memory,
 * or the requested mode cannot be opened with the requested depth with the
 * given bitmap (for higher bandwidth alignments).
 }

 MVP_OK        =  0;       { you want to see this one }
 MVP_NO_MEM    =  1;       { insufficient memory for intermediate workspace }
 MVP_NO_VPE    =  2;       { ViewPort does not have a ViewPortExtra, and
                                 * insufficient memory to allocate a temporary one.
                                 }
 MVP_NO_DSPINS =  3;       { insufficient memory for intermidiate copper
                                 * instructions.
                                 }
 MVP_NO_DISPLAY = 4;       { BitMap data is misaligned for this viewport's
                                 * mode and depth - see AllocBitMap().
                                 }
 MVP_OFF_BOTTOM = 5;       { PRIVATE - you will never see this. }

{ From V39, MrgCop() will return an error if there is not enough memory,
 * or for some reason MrgCop() did not need to make any copper lists.
 }

 MCOP_OK       =  0;       { you want to see this one }
 MCOP_NO_MEM   =  1;       { insufficient memory to allocate the system
                                 * copper lists.
                                 }
 MCOP_NOP      =  2;       { MrgCop() did not merge any copper lists
                                 * (eg, no ViewPorts in the list, or all marked as
                                 * hidden).
                                 }
Type
    pDBufInfo = ^tDBufInfo;
    tDBufInfo = record
        dbi_Link1   : Pointer;
        dbi_Count1  : Cardinal;
        dbi_SafeMessage : tMessage;         { replied to when safe to write to old bitmap }
        dbi_UserData1   : Pointer;                     { first user data }

        dbi_Link2   : Pointer;
        dbi_Count2  : Cardinal;
        dbi_DispMessage : tMessage; { replied to when new bitmap has been displayed at least
                                                        once }
        dbi_UserData2 : Pointer;                  { second user data }
        dbi_MatchLong : Cardinal;
        dbi_CopPtr1,
        dbi_CopPtr2,
        dbi_CopPtr3   : Pointer;
        dbi_BeamPos1,
        dbi_BeamPos2  : WORD;
    end;



   {   include define file for graphics display mode IDs.   }


const

   INVALID_ID                   =   NOT 0;

{ With all the new modes that are available under V38 and V39, it is highly
 * recommended that you use either the asl.library screenmode requester,
 * and/or the V39 graphics.library function BestModeIDA().
 *
 * DO NOT interpret the any of the bits in the ModeID for its meaning. For
 * example, do not interpret bit 3 ($4) as meaning the ModeID is interlaced.
 * Instead, use GetDisplayInfoData() with DTAG_DISP, and examine the DIPF_...
 * flags to determine a ModeID's characteristics. The only exception to
 * this rule is that bit 7 ($80) will always mean the ModeID is
 * ExtraHalfBright, and bit 11 ($800) will always mean the ModeID is HAM.
 }

{ normal identifiers }

   MONITOR_ID_MASK              =   $FFFF1000;

   DEFAULT_MONITOR_ID           =   $00000000;
   NTSC_MONITOR_ID              =   $00011000;
   PAL_MONITOR_ID               =   $00021000;

{ the following 22 composite keys are for Modes on the default Monitor.
 * NTSC & PAL "flavors" of these particular keys may be made by or'ing
 * the NTSC or PAL MONITOR_ID with the desired MODE_KEY...
 *
 * For example, to specifically open a PAL HAM interlaced ViewPort
 * (or intuition screen), you would use the modeid of
 * (PAL_MONITOR_ID OR HAMLACE_KEY)
 }

   LORES_KEY                     =  $00000000;
   HIRES_KEY                     =  $00008000;
   SUPER_KEY                     =  $00008020;
   HAM_KEY                       =  $00000800;
   LORESLACE_KEY                 =  $00000004;
   HIRESLACE_KEY                 =  $00008004;
   SUPERLACE_KEY                 =  $00008024;
   HAMLACE_KEY                   =  $00000804;
   LORESDPF_KEY                  =  $00000400;
   HIRESDPF_KEY                  =  $00008400;
   SUPERDPF_KEY                  =  $00008420;
   LORESLACEDPF_KEY              =  $00000404;
   HIRESLACEDPF_KEY              =  $00008404;
   SUPERLACEDPF_KEY              =  $00008424;
   LORESDPF2_KEY                 =  $00000440;
   HIRESDPF2_KEY                 =  $00008440;
   SUPERDPF2_KEY                 =  $00008460;
   LORESLACEDPF2_KEY             =  $00000444;
   HIRESLACEDPF2_KEY             =  $00008444;
   SUPERLACEDPF2_KEY             =  $00008464;
   EXTRAHALFBRITE_KEY            =  $00000080;
   EXTRAHALFBRITELACE_KEY        =  $00000084;
{ New for AA ChipSet (V39) }
   HIRESHAM_KEY                  =  $00008800;
   SUPERHAM_KEY                  =  $00008820;
   HIRESEHB_KEY                  =  $00008080;
   SUPEREHB_KEY                  =  $000080a0;
   HIRESHAMLACE_KEY              =  $00008804;
   SUPERHAMLACE_KEY              =  $00008824;
   HIRESEHBLACE_KEY              =  $00008084;
   SUPEREHBLACE_KEY              =  $000080a4;
{ Added for V40 - may be useful modes for some games or animations. }
   LORESSDBL_KEY                 =  $00000008;
   LORESHAMSDBL_KEY              =  $00000808;
   LORESEHBSDBL_KEY              =  $00000088;
   HIRESHAMSDBL_KEY              =  $00008808;


{ VGA identifiers }

   VGA_MONITOR_ID                =  $00031000;

   VGAEXTRALORES_KEY             =  $00031004;
   VGALORES_KEY                  =  $00039004;
   VGAPRODUCT_KEY                =  $00039024;
   VGAHAM_KEY                    =  $00031804;
   VGAEXTRALORESLACE_KEY         =  $00031005;
   VGALORESLACE_KEY              =  $00039005;
   VGAPRODUCTLACE_KEY            =  $00039025;
   VGAHAMLACE_KEY                =  $00031805;
   VGAEXTRALORESDPF_KEY          =  $00031404;
   VGALORESDPF_KEY               =  $00039404;
   VGAPRODUCTDPF_KEY             =  $00039424;
   VGAEXTRALORESLACEDPF_KEY      =  $00031405;
   VGALORESLACEDPF_KEY           =  $00039405;
   VGAPRODUCTLACEDPF_KEY         =  $00039425;
   VGAEXTRALORESDPF2_KEY         =  $00031444;
   VGALORESDPF2_KEY              =  $00039444;
   VGAPRODUCTDPF2_KEY            =  $00039464;
   VGAEXTRALORESLACEDPF2_KEY     =  $00031445;
   VGALORESLACEDPF2_KEY          =  $00039445;
   VGAPRODUCTLACEDPF2_KEY        =  $00039465;
   VGAEXTRAHALFBRITE_KEY         =  $00031084;
   VGAEXTRAHALFBRITELACE_KEY     =  $00031085;
{ New for AA ChipSet (V39) }
   VGAPRODUCTHAM_KEY             =  $00039824;
   VGALORESHAM_KEY               =  $00039804;
   VGAEXTRALORESHAM_KEY          =  VGAHAM_KEY;
   VGAPRODUCTHAMLACE_KEY         =  $00039825;
   VGALORESHAMLACE_KEY           =  $00039805;
   VGAEXTRALORESHAMLACE_KEY      =  VGAHAMLACE_KEY;
   VGAEXTRALORESEHB_KEY          =  VGAEXTRAHALFBRITE_KEY;
   VGAEXTRALORESEHBLACE_KEY      =  VGAEXTRAHALFBRITELACE_KEY;
   VGALORESEHB_KEY               =  $00039084;
   VGALORESEHBLACE_KEY           =  $00039085;
   VGAEHB_KEY                    =  $000390a4;
   VGAEHBLACE_KEY                =  $000390a5;
{ These ModeIDs are the scandoubled equivalents of the above, with the
 * exception of the DualPlayfield modes, as AA does not allow for scandoubling
 * dualplayfield.
 }
   VGAEXTRALORESDBL_KEY          =  $00031000;
   VGALORESDBL_KEY               =  $00039000;
   VGAPRODUCTDBL_KEY             =  $00039020;
   VGAEXTRALORESHAMDBL_KEY       =  $00031800;
   VGALORESHAMDBL_KEY            =  $00039800;
   VGAPRODUCTHAMDBL_KEY          =  $00039820;
   VGAEXTRALORESEHBDBL_KEY       =  $00031080;
   VGALORESEHBDBL_KEY            =  $00039080;
   VGAPRODUCTEHBDBL_KEY          =  $000390a0;

{ a2024 identifiers }

   A2024_MONITOR_ID              =  $00041000;

   A2024TENHERTZ_KEY             =  $00041000;
   A2024FIFTEENHERTZ_KEY         =  $00049000;

{ prototype identifiers (private) }

   PROTO_MONITOR_ID              =  $00051000;


{ These monitors and modes were added for the V38 release. }

   EURO72_MONITOR_ID             =  $00061000;

   EURO72EXTRALORES_KEY          =  $00061004;
   EURO72LORES_KEY               =  $00069004;
   EURO72PRODUCT_KEY             =  $00069024;
   EURO72HAM_KEY                 =  $00061804;
   EURO72EXTRALORESLACE_KEY      =  $00061005;
   EURO72LORESLACE_KEY           =  $00069005;
   EURO72PRODUCTLACE_KEY         =  $00069025;
   EURO72HAMLACE_KEY             =  $00061805;
   EURO72EXTRALORESDPF_KEY       =  $00061404;
   EURO72LORESDPF_KEY            =  $00069404;
   EURO72PRODUCTDPF_KEY          =  $00069424;
   EURO72EXTRALORESLACEDPF_KEY   =  $00061405;
   EURO72LORESLACEDPF_KEY        =  $00069405;
   EURO72PRODUCTLACEDPF_KEY      =  $00069425;
   EURO72EXTRALORESDPF2_KEY      =  $00061444;
   EURO72LORESDPF2_KEY           =  $00069444;
   EURO72PRODUCTDPF2_KEY         =  $00069464;
   EURO72EXTRALORESLACEDPF2_KEY  =  $00061445;
   EURO72LORESLACEDPF2_KEY       =  $00069445;
   EURO72PRODUCTLACEDPF2_KEY     =  $00069465;
   EURO72EXTRAHALFBRITE_KEY      =  $00061084;
   EURO72EXTRAHALFBRITELACE_KEY  =  $00061085;
{ New AA modes (V39) }
   EURO72PRODUCTHAM_KEY          =  $00069824;
   EURO72PRODUCTHAMLACE_KEY      =  $00069825;
   EURO72LORESHAM_KEY            =  $00069804;
   EURO72LORESHAMLACE_KEY        =  $00069805;
   EURO72EXTRALORESHAM_KEY       =  EURO72HAM_KEY;
   EURO72EXTRALORESHAMLACE_KEY   =  EURO72HAMLACE_KEY ;
   EURO72EXTRALORESEHB_KEY       =  EURO72EXTRAHALFBRITE_KEY;
   EURO72EXTRALORESEHBLACE_KEY   =  EURO72EXTRAHALFBRITELACE_KEY;
   EURO72LORESEHB_KEY            =  $00069084;
   EURO72LORESEHBLACE_KEY        =  $00069085;
   EURO72EHB_KEY                 =  $000690a4;
   EURO72EHBLACE_KEY             =  $000690a5;
{ These ModeIDs are the scandoubled equivalents of the above, with the
 * exception of the DualPlayfield modes, as AA does not allow for scandoubling
 * dualplayfield.
 }
   EURO72EXTRALORESDBL_KEY       =  $00061000;
   EURO72LORESDBL_KEY            =  $00069000;
   EURO72PRODUCTDBL_KEY          =  $00069020;
   EURO72EXTRALORESHAMDBL_KEY    =  $00061800;
   EURO72LORESHAMDBL_KEY         =  $00069800;
   EURO72PRODUCTHAMDBL_KEY       =  $00069820;
   EURO72EXTRALORESEHBDBL_KEY    =  $00061080;
   EURO72LORESEHBDBL_KEY         =  $00069080;
   EURO72PRODUCTEHBDBL_KEY       =  $000690a0;


   EURO36_MONITOR_ID             =  $00071000;

{ Euro36 modeids can be ORed with the default modeids a la NTSC and PAL.
 * For example, Euro36 SuperHires is
 * (EURO36_MONITOR_ID OR SUPER_KEY)
 }

   SUPER72_MONITOR_ID            =  $00081000;

{ Super72 modeids can be ORed with the default modeids a la NTSC and PAL.
 * For example, Super72 SuperHiresLace (80$600) is
 * (SUPER72_MONITOR_ID OR SUPERLACE_KEY).
 * The following scandoubled Modes are the exception:
 }
   SUPER72LORESDBL_KEY           =  $00081008;
   SUPER72HIRESDBL_KEY           =  $00089008;
   SUPER72SUPERDBL_KEY           =  $00089028;
   SUPER72LORESHAMDBL_KEY        =  $00081808;
   SUPER72HIRESHAMDBL_KEY        =  $00089808;
   SUPER72SUPERHAMDBL_KEY        =  $00089828;
   SUPER72LORESEHBDBL_KEY        =  $00081088;
   SUPER72HIRESEHBDBL_KEY        =  $00089088;
   SUPER72SUPEREHBDBL_KEY        =  $000890a8;


{ These monitors and modes were added for the V39 release. }

   DBLNTSC_MONITOR_ID            =  $00091000;

   DBLNTSCLORES_KEY              =  $00091000;
   DBLNTSCLORESFF_KEY            =  $00091004;
   DBLNTSCLORESHAM_KEY           =  $00091800;
   DBLNTSCLORESHAMFF_KEY         =  $00091804;
   DBLNTSCLORESEHB_KEY           =  $00091080;
   DBLNTSCLORESEHBFF_KEY         =  $00091084;
   DBLNTSCLORESLACE_KEY          =  $00091005;
   DBLNTSCLORESHAMLACE_KEY       =  $00091805;
   DBLNTSCLORESEHBLACE_KEY       =  $00091085;
   DBLNTSCLORESDPF_KEY           =  $00091400;
   DBLNTSCLORESDPFFF_KEY         =  $00091404;
   DBLNTSCLORESDPFLACE_KEY       =  $00091405;
   DBLNTSCLORESDPF2_KEY          =  $00091440;
   DBLNTSCLORESDPF2FF_KEY        =  $00091444;
   DBLNTSCLORESDPF2LACE_KEY      =  $00091445;
   DBLNTSCHIRES_KEY              =  $00099000;
   DBLNTSCHIRESFF_KEY            =  $00099004;
   DBLNTSCHIRESHAM_KEY           =  $00099800;
   DBLNTSCHIRESHAMFF_KEY         =  $00099804;
   DBLNTSCHIRESLACE_KEY          =  $00099005;
   DBLNTSCHIRESHAMLACE_KEY       =  $00099805;
   DBLNTSCHIRESEHB_KEY           =  $00099080;
   DBLNTSCHIRESEHBFF_KEY         =  $00099084;
   DBLNTSCHIRESEHBLACE_KEY       =  $00099085;
   DBLNTSCHIRESDPF_KEY           =  $00099400;
   DBLNTSCHIRESDPFFF_KEY         =  $00099404;
   DBLNTSCHIRESDPFLACE_KEY       =  $00099405;
   DBLNTSCHIRESDPF2_KEY          =  $00099440;
   DBLNTSCHIRESDPF2FF_KEY        =  $00099444;
   DBLNTSCHIRESDPF2LACE_KEY      =  $00099445;
   DBLNTSCEXTRALORES_KEY         =  $00091200;
   DBLNTSCEXTRALORESHAM_KEY      =  $00091a00;
   DBLNTSCEXTRALORESEHB_KEY      =  $00091280;
   DBLNTSCEXTRALORESDPF_KEY      =  $00091600;
   DBLNTSCEXTRALORESDPF2_KEY     =  $00091640;
   DBLNTSCEXTRALORESFF_KEY       =  $00091204;
   DBLNTSCEXTRALORESHAMFF_KEY    =  $00091a04;
   DBLNTSCEXTRALORESEHBFF_KEY    =  $00091284;
   DBLNTSCEXTRALORESDPFFF_KEY    =  $00091604;
   DBLNTSCEXTRALORESDPF2FF_KEY   =  $00091644;
   DBLNTSCEXTRALORESLACE_KEY     =  $00091205;
   DBLNTSCEXTRALORESHAMLACE_KEY  =  $00091a05;
   DBLNTSCEXTRALORESEHBLACE_KEY  =  $00091285;
   DBLNTSCEXTRALORESDPFLACE_KEY  =  $00091605;
   DBLNTSCEXTRALORESDPF2LACE_KEY =  $00091645;

   DBLPAL_MONITOR_ID             =  $000a1000;

   DBLPALLORES_KEY               =  $000a1000;
   DBLPALLORESFF_KEY             =  $000a1004;
   DBLPALLORESHAM_KEY            =  $000a1800;
   DBLPALLORESHAMFF_KEY          =  $000a1804;
   DBLPALLORESEHB_KEY            =  $000a1080;
   DBLPALLORESEHBFF_KEY          =  $000a1084;
   DBLPALLORESLACE_KEY           =  $000a1005;
   DBLPALLORESHAMLACE_KEY        =  $000a1805;
   DBLPALLORESEHBLACE_KEY        =  $000a1085;
   DBLPALLORESDPF_KEY            =  $000a1400;
   DBLPALLORESDPFFF_KEY          =  $000a1404;
   DBLPALLORESDPFLACE_KEY        =  $000a1405;
   DBLPALLORESDPF2_KEY           =  $000a1440;
   DBLPALLORESDPF2FF_KEY         =  $000a1444;
   DBLPALLORESDPF2LACE_KEY       =  $000a1445;
   DBLPALHIRES_KEY               =  $000a9000;
   DBLPALHIRESFF_KEY             =  $000a9004;
   DBLPALHIRESHAM_KEY            =  $000a9800;
   DBLPALHIRESHAMFF_KEY          =  $000a9804;
   DBLPALHIRESLACE_KEY           =  $000a9005;
   DBLPALHIRESHAMLACE_KEY        =  $000a9805;
   DBLPALHIRESEHB_KEY            =  $000a9080;
   DBLPALHIRESEHBFF_KEY          =  $000a9084;
   DBLPALHIRESEHBLACE_KEY        =  $000a9085;
   DBLPALHIRESDPF_KEY            =  $000a9400;
   DBLPALHIRESDPFFF_KEY          =  $000a9404;
   DBLPALHIRESDPFLACE_KEY        =  $000a9405;
   DBLPALHIRESDPF2_KEY           =  $000a9440;
   DBLPALHIRESDPF2FF_KEY         =  $000a9444;
   DBLPALHIRESDPF2LACE_KEY       =  $000a9445;
   DBLPALEXTRALORES_KEY          =  $000a1200;
   DBLPALEXTRALORESHAM_KEY       =  $000a1a00;
   DBLPALEXTRALORESEHB_KEY       =  $000a1280;
   DBLPALEXTRALORESDPF_KEY       =  $000a1600;
   DBLPALEXTRALORESDPF2_KEY      =  $000a1640;
   DBLPALEXTRALORESFF_KEY        =  $000a1204;
   DBLPALEXTRALORESHAMFF_KEY     =  $000a1a04;
   DBLPALEXTRALORESEHBFF_KEY     =  $000a1284;
   DBLPALEXTRALORESDPFFF_KEY     =  $000a1604;
   DBLPALEXTRALORESDPF2FF_KEY    =  $000a1644;
   DBLPALEXTRALORESLACE_KEY      =  $000a1205;
   DBLPALEXTRALORESHAMLACE_KEY   =  $000a1a05;
   DBLPALEXTRALORESEHBLACE_KEY   =  $000a1285;
   DBLPALEXTRALORESDPFLACE_KEY   =  $000a1605;
   DBLPALEXTRALORESDPF2LACE_KEY  =  $000a1645;


{ Use these tags for passing to BestModeID() (V39) }

   SPECIAL_FLAGS = $100E;
   { Original:
     SPECIAL_FLAGS = DIPF_IS_DUALPF OR DIPF_IS_PF2PRI OR DIPF_IS_HAM OR DIPF_IS_EXTRAHALFBRITE;
     ( Mu?te aufgrund eines Fehler in PCQ ge?ndert werden )
   }


   BIDTAG_DIPFMustHave     = $80000001;      { mask of the DIPF_ flags the ModeID must have }
                                { Default - NULL }
   BIDTAG_DIPFMustNotHave  = $80000002;      { mask of the DIPF_ flags the ModeID must not have }
                                { Default - SPECIAL_FLAGS }
   BIDTAG_ViewPort         = $80000003;      { ViewPort for which a ModeID is sought. }
                                { Default - NULL }
   BIDTAG_NominalWidth     = $80000004;      { \ together make the aspect ratio and }
   BIDTAG_NominalHeight    = $80000005;      { / override the vp->Width/Height. }
                                { Default - SourceID NominalDimensionInfo,
                                 * or vp->DWidth/Height, or (640 * 200),
                                 * in that preferred order.
                                 }
   BIDTAG_DesiredWidth     = $80000006;      { \ Nominal Width and Height of the }
   BIDTAG_DesiredHeight    = $80000007;      { / returned ModeID. }
                                { Default - same as Nominal }
   BIDTAG_Depth            = $80000008;      { ModeID must support this depth. }
                                { Default - vp->RasInfo->BitMap->Depth or 1 }
   BIDTAG_MonitorID        = $80000009;      { ModeID must use this monitor. }
                                { Default - use best monitor available }
   BIDTAG_SourceID         = $8000000a;      { instead of a ViewPort. }
                                { Default - VPModeID(vp) if BIDTAG_ViewPort is
                                 * specified, else leave the DIPFMustHave and
                                 * DIPFMustNotHave values untouched.
                                 }
   BIDTAG_RedBits        =  $8000000b;      { \                            }
   BIDTAG_BlueBits       =  $8000000c;      {  > Match up from the database }
   BIDTAG_GreenBits      =  $8000000d;      { /                            }
                                            { Default - 4 }
   BIDTAG_GfxPrivate     =  $8000000e;      { Private }


const

{ bplcon0 defines }

    MODE_640    = $8000;
    PLNCNTMSK   = $7;           { how many bit planes? }
                                { 0 = none, 1->6 = 1->6, 7 = reserved }
    PLNCNTSHFT  = 12;           { bits to shift for bplcon0 }
    PF2PRI      = $40;          { bplcon2 bit }
    COLORON     = $0200;        { disable color burst }
    DBLPF       = $400;
    HOLDNMODIFY = $800;
    INTERLACE   = 4;            { interlace mode for 400 }

{ bplcon1 defines }

    PFA_FINE_SCROLL             = $F;
    PFB_FINE_SCROLL_SHIFT       = 4;
    PF_FINE_SCROLL_MASK         = $F;

{ display window start and stop defines }

    DIW_HORIZ_POS       = $7F;  { horizontal start/stop }
    DIW_VRTCL_POS       = $1FF; { vertical start/stop }
    DIW_VRTCL_POS_SHIFT = $7;

{ Data fetch start/stop horizontal position }

    DFTCH_MASK  = $FF;

{ vposr bits }

    VPOSRLOF    = $8000;

  {   include define file for displayinfo database }

{ the "public" handle to a DisplayInfoRecord }
Type

 DisplayInfoHandle = Pointer;

{ datachunk type identifiers }

CONST
 DTAG_DISP            =   $80000000;
 DTAG_DIMS            =   $80001000;
 DTAG_MNTR            =   $80002000;
 DTAG_NAME            =   $80003000;
 DTAG_VEC             =   $80004000;      { internal use only }

Type

  pQueryHeader = ^tQueryHeader;
  tQueryHeader = record
   tructID,                    { datachunk type identifier }
   DisplayID,                  { copy of display record key   }
   SkipID,                     { TAG_SKIP -- see tagitems.h }
   Length  :  Cardinal;         { length of local data in double-longwords }
  END;

  pDisplayInfo = ^tDisplayInfo;
  tDisplayInfo = record
   Header : tQueryHeader;
   NotAvailable : Word;    { IF NULL available, else see defines }
   PropertyFlags : Cardinal;  { Properties of this mode see defines }
   Resolution : tPoint;     { ticks-per-pixel X/Y                 }
   PixelSpeed : Word;     { aproximation in nanoseconds         }
   NumStdSprites : Word;  { number of standard amiga sprites    }
   PaletteRange : Word;   { distinguishable shades available    }
   SpriteResolution : tPoint; { std sprite ticks-per-pixel X/Y    }
   pad : Array[0..3] of Byte;
   RedBits     : Byte;
   GreenBits   : Byte;
   BlueBits    : Byte;
   pad2        : array [0..4] of Byte;
   reserved : Array[0..1] of Cardinal;    { terminator }
  END;

{ availability }

CONST
 DI_AVAIL_NOCHIPS        =$0001;
 DI_AVAIL_NOMONITOR      =$0002;
 DI_AVAIL_NOTWITHGENLOCK =$0004;

{ mode properties }

 DIPF_IS_LACE          =  $00000001;
 DIPF_IS_DUALPF        =  $00000002;
 DIPF_IS_PF2PRI        =  $00000004;
 DIPF_IS_HAM           =  $00000008;

 DIPF_IS_ECS           =  $00000010;      {      note: ECS modes (SHIRES, VGA, AND **
                                                 PRODUCTIVITY) do not support      **
                                                 attached sprites.                 **
                                                                                        }
 DIPF_IS_AA            =  $00010000;      { AA modes - may only be available
                                                ** if machine has correct memory
                                                ** type to support required
                                                ** bandwidth - check availability.
                                                ** (V39)
                                                }
 DIPF_IS_PAL           =  $00000020;
 DIPF_IS_SPRITES       =  $00000040;
 DIPF_IS_GENLOCK       =  $00000080;

 DIPF_IS_WB            =  $00000100;
 DIPF_IS_DRAGGABLE     =  $00000200;
 DIPF_IS_PANELLED      =  $00000400;
 DIPF_IS_BEAMSYNC      =  $00000800;

 DIPF_IS_EXTRAHALFBRITE = $00001000;

{ The following DIPF_IS_... flags are new for V39 }
  DIPF_IS_SPRITES_ATT           =  $00002000;      { supports attached sprites }
  DIPF_IS_SPRITES_CHNG_RES      =  $00004000;      { supports variable sprite resolution }
  DIPF_IS_SPRITES_BORDER        =  $00008000;      { sprite can be displayed in the border }
  DIPF_IS_SCANDBL               =  $00020000;      { scan doubled }
  DIPF_IS_SPRITES_CHNG_BASE     =  $00040000;
                                                   { can change the sprite base colour }
  DIPF_IS_SPRITES_CHNG_PRI      =  $00080000;
                                                                                        { can change the sprite priority
                                                                                        ** with respect to the playfield(s).
                                                                                        }
  DIPF_IS_DBUFFER       =  $00100000;      { can support double buffering }
  DIPF_IS_PROGBEAM      =  $00200000;      { is a programmed beam-sync mode }
  DIPF_IS_FOREIGN       =  $80000000;      { this mode is not native to the Amiga }

Type
 pDimensionInfo =^tDimensionInfo;
 tDimensionInfo = record
  Header : tQueryHeader;
  MaxDepth,             { log2( max number of colors ) }
  MinRasterWidth,       { minimum width in pixels      }
  MinRasterHeight,      { minimum height in pixels     }
  MaxRasterWidth,       { maximum width in pixels      }
  MaxRasterHeight : Word;      { maximum height in pixels     }
  Nominal,              { "standard" dimensions        }
  MaxOScan,             { fixed, hardware dependant    }
  VideoOScan,           { fixed, hardware dependant    }
  TxtOScan,             { editable via preferences     }
  StdOScan  : tRectangle; { editable via preferences     }
  pad  : Array[0..13] of Byte;
  reserved : Array[0..1] of Longint;          { terminator }
 END;

 pMonitorInfo = ^tMonitorInfo;
 tMonitorInfo = record
  Header : tQueryHeader;
  Mspc   : pMonitorSpec;         { pointer to monitor specification  }
  ViewPosition,                    { editable via preferences          }
  ViewResolution : tPoint;          { standard monitor ticks-per-pixel  }
  ViewPositionRange : tRectangle;   { fixed, hardware dependant }
  TotalRows,                       { display height in scanlines       }
  TotalColorClocks,                { scanline width in 280 ns units    }
  MinRow        : Word;            { absolute minimum active scanline  }
  Compatibility : smallint;           { how this coexists with others     }
  pad : Array[0..31] of Byte;
  MouseTicks    : tPoint;
  DefaultViewPosition : tPoint;
  PreferredModeID : Cardinal;
  reserved : Array[0..1] of Cardinal;          { terminator }
 END;

{ monitor compatibility }

CONST
 MCOMPAT_MIXED =  0;       { can share display with other MCOMPAT_MIXED }
 MCOMPAT_SELF  =  1;       { can share only within same monitor }
 MCOMPAT_NOBODY= -1;       { only one viewport at a time }

 DISPLAYNAMELEN = 32;

Type
 pNameInfo = ^tNameInfo;
 tNameInfo = record
  Header : tQueryHeader;
  Name   : Array[0..DISPLAYNAMELEN-1] of Char;
  reserved : Array[0..1] of Cardinal;          { terminator }
 END;


{****************************************************************************}

{ The following VecInfo structure is PRIVATE, for our use only
 * Touch these, and burn! (V39)
 }
Type
 pVecInfo = ^tVecInfo;
 tVecInfo = record
        Header  : tQueryHeader;
        Vec     : Pointer;
        Data    : Pointer;
        vi_Type : WORD;               { Type in C Includes }
        pad     : Array[0..2] of WORD;
        reserved : Array[0..1] of Cardinal;
 end;


CONST
 VTAG_END_CM            = $00000000;
 VTAG_CHROMAKEY_CLR     = $80000000;
 VTAG_CHROMAKEY_SET     = $80000001;
 VTAG_BITPLANEKEY_CLR   = $80000002;
 VTAG_BITPLANEKEY_SET   = $80000003;
 VTAG_BORDERBLANK_CLR   = $80000004;
 VTAG_BORDERBLANK_SET   = $80000005;
 VTAG_BORDERNOTRANS_CLR = $80000006;
 VTAG_BORDERNOTRANS_SET = $80000007;
 VTAG_CHROMA_PEN_CLR    = $80000008;
 VTAG_CHROMA_PEN_SET    = $80000009;
 VTAG_CHROMA_PLANE_SET  = $8000000A;
 VTAG_ATTACH_CM_SET     = $8000000B;
 VTAG_NEXTBUF_CM        = $8000000C;
 VTAG_BATCH_CM_CLR      = $8000000D;
 VTAG_BATCH_CM_SET      = $8000000E;
 VTAG_NORMAL_DISP_GET   = $8000000F;
 VTAG_NORMAL_DISP_SET   = $80000010;
 VTAG_COERCE_DISP_GET   = $80000011;
 VTAG_COERCE_DISP_SET   = $80000012;
 VTAG_VIEWPORTEXTRA_GET = $80000013;
 VTAG_VIEWPORTEXTRA_SET = $80000014;
 VTAG_CHROMAKEY_GET     = $80000015;
 VTAG_BITPLANEKEY_GET   = $80000016;
 VTAG_BORDERBLANK_GET   = $80000017;
 VTAG_BORDERNOTRANS_GET = $80000018;
 VTAG_CHROMA_PEN_GET    = $80000019;
 VTAG_CHROMA_PLANE_GET  = $8000001A;
 VTAG_ATTACH_CM_GET     = $8000001B;
 VTAG_BATCH_CM_GET      = $8000001C;
 VTAG_BATCH_ITEMS_GET   = $8000001D;
 VTAG_BATCH_ITEMS_SET   = $8000001E;
 VTAG_BATCH_ITEMS_ADD   = $8000001F;
 VTAG_VPMODEID_GET      = $80000020;
 VTAG_VPMODEID_SET      = $80000021;
 VTAG_VPMODEID_CLR      = $80000022;
 VTAG_USERCLIP_GET      = $80000023;
 VTAG_USERCLIP_SET      = $80000024;
 VTAG_USERCLIP_CLR      = $80000025;
{ The following tags are V39 specific. They will be ignored (returing error -3) by
        earlier versions }
 VTAG_PF1_BASE_GET             =  $80000026;
 VTAG_PF2_BASE_GET             =  $80000027;
 VTAG_SPEVEN_BASE_GET          =  $80000028;
 VTAG_SPODD_BASE_GET           =  $80000029;
 VTAG_PF1_BASE_SET             =  $8000002a;
 VTAG_PF2_BASE_SET             =  $8000002b;
 VTAG_SPEVEN_BASE_SET          =  $8000002c;
 VTAG_SPODD_BASE_SET           =  $8000002d;
 VTAG_BORDERSPRITE_GET         =  $8000002e;
 VTAG_BORDERSPRITE_SET         =  $8000002f;
 VTAG_BORDERSPRITE_CLR         =  $80000030;
 VTAG_SPRITERESN_SET           =  $80000031;
 VTAG_SPRITERESN_GET           =  $80000032;
 VTAG_PF1_TO_SPRITEPRI_SET     =  $80000033;
 VTAG_PF1_TO_SPRITEPRI_GET     =  $80000034;
 VTAG_PF2_TO_SPRITEPRI_SET     =  $80000035;
 VTAG_PF2_TO_SPRITEPRI_GET     =  $80000036;
 VTAG_IMMEDIATE                =  $80000037;
 VTAG_FULLPALETTE_SET          =  $80000038;
 VTAG_FULLPALETTE_GET          =  $80000039;
 VTAG_FULLPALETTE_CLR          =  $8000003A;
 VTAG_DEFSPRITERESN_SET        =  $8000003B;
 VTAG_DEFSPRITERESN_GET        =  $8000003C;

{ all the following tags follow the new, rational standard for videocontrol tags:
 * VC_xxx,state         set the state of attribute 'xxx' to value 'state'
 * VC_xxx_QUERY,&var    get the state of attribute 'xxx' and store it into the longword
 *                      pointed to by &var.
 *
 * The following are new for V40:
 }

 VC_IntermediateCLUpdate       =  $80000080;
        { default=true. When set graphics will update the intermediate copper
         * lists on color changes, etc. When false, it won't, and will be faster.
         }
 VC_IntermediateCLUpdate_Query =  $80000081;

 VC_NoColorPaletteLoad         =  $80000082;
        { default = false. When set, graphics will only load color 0
         * for this ViewPort, and so the ViewPort's colors will come
         * from the previous ViewPort's.
         *
         * NB - Using this tag and VTAG_FULLPALETTE_SET together is undefined.
         }
 VC_NoColorPaletteLoad_Query   =  $80000083;

 VC_DUALPF_Disable             =  $80000084;
        { default = false. When this flag is set, the dual-pf bit
           in Dual-Playfield screens will be turned off. Even bitplanes
           will still come from the first BitMap and odd bitplanes
           from the second BitMap, and both R[xy]Offsets will be
           considered. This can be used (with appropriate palette
           selection) for cross-fades between differently scrolling
           images.
           When this flag is turned on, colors will be loaded for
           the viewport as if it were a single viewport of depth
           depth1+depth2 }
 VC_DUALPF_Disable_Query       =  $80000085;


const

    SPRITE_ATTACHED     = $80;

type

    pSimpleSprite = ^tSimpleSprite;
    tSimpleSprite = record
        posctldata      : Pointer;
        height          : Word;
        x,y             : Word;        { current position }
        num             : Word;
    end;

    pExtSprite = ^tExtSprite;
    tExtSprite = record
        es_SimpleSprite : tSimpleSprite;         { conventional simple sprite structure }
        es_wordwidth    : WORD;                 { graphics use only, subject to change }
        es_flags        : WORD;                 { graphics use only, subject to change }
    end;

const
{ tags for AllocSpriteData() }
 SPRITEA_Width          = $81000000;
 SPRITEA_XReplication   = $81000002;
 SPRITEA_YReplication   = $81000004;
 SPRITEA_OutputHeight   = $81000006;
 SPRITEA_Attached       = $81000008;
 SPRITEA_OldDataFormat  = $8100000a;      { MUST pass in outputheight if using this tag }

{ tags for GetExtSprite() }
 GSTAG_SPRITE_NUM = $82000020;
 GSTAG_ATTACHED   = $82000022;
 GSTAG_SOFTSPRITE = $82000024;

{ tags valid for either GetExtSprite or ChangeExtSprite }
 GSTAG_SCANDOUBLED     =  $83000000;      { request "NTSC-Like" height if possible. }


Type
    pBitScaleArgs = ^tBitScaleArgs;
    tBitScaleArgs = record
    bsa_SrcX, bsa_SrcY,                 { source origin }
    bsa_SrcWidth, bsa_SrcHeight,        { source size }
    bsa_XSrcFactor, bsa_YSrcFactor,     { scale factor denominators }
    bsa_DestX, bsa_DestY,               { destination origin }
    bsa_DestWidth, bsa_DestHeight,      { destination size result }
    bsa_XDestFactor, bsa_YDestFactor : Word;   { scale factor numerators }
    bsa_SrcBitMap,                           { source BitMap }
    bsa_DestBitMap : pBitMap;              { destination BitMap }
    bsa_Flags   : Cardinal;              { reserved.  Must be zero! }
    bsa_XDDA, bsa_YDDA : Word;         { reserved }
    bsa_Reserved1,
    bsa_Reserved2 : Longint;
   END;

  {    tag definitions for GetRPAttr, SetRPAttr     }

const
 RPTAG_Font            =  $80000000;      { get/set font }
 RPTAG_APen            =  $80000002;      { get/set apen }
 RPTAG_BPen            =  $80000003;      { get/set bpen }
 RPTAG_DrMd            =  $80000004;      { get/set draw mode }
 RPTAG_OutlinePen      =  $80000005;      { get/set outline pen. corrected case. }
 RPTAG_WriteMask       =  $80000006;      { get/set WriteMask }
 RPTAG_MaxPen          =  $80000007;      { get/set maxpen }

 RPTAG_DrawBounds      =  $80000008;      { get only rastport draw bounds. pass &rect }




TYPE

 pRegionRectangle = ^tRegionRectangle;
 tRegionRectangle = record
    Next, Prev  : pRegionRectangle;
    bounds      : tRectangle;
 END;

 pRegion = ^tRegion;
 tRegion = record
    bounds      : tRectangle;
    RegionRectangle  : pRegionRectangle;
 END;

type

    pGfxBase = ^tGfxBase;
    tGfxBase = record
        LibNode         : tLibrary;
        ActiView        : pView;      { ViewPtr }
        copinit         : pcopinit; { (copinitptr) ptr to copper start up list }
        cia             : Pointer;      { for 8520 resource use }
        blitter         : Pointer;      { for future blitter resource use }
        LOFlist         : Pointer;
        SHFlist         : Pointer;
        blthd,
        blttl           : pbltnode;
        bsblthd,
        bsblttl         : pbltnode;      { Previous four are (bltnodeptr) }
        vbsrv,
        timsrv,
        bltsrv          : tInterrupt;
        TextFonts       : tList;
        DefaultFont     : pTextFont;      { TextFontPtr }
        Modes           : Word;        { copy of current first bplcon0 }
        VBlank          : Shortint;
        Debug           : Shortint;
        BeamSync        : smallint;
        system_bplcon0  : smallint; { it is ored into each bplcon0 for display }
        SpriteReserved  : Byte;
        bytereserved    : Byte;
        Flags           : Word;
        BlitLock        : smallint;
        BlitNest        : smallint;

        BlitWaitQ       : tList;
        BlitOwner       : pTask;      { TaskPtr }
        TOF_WaitQ       : tList;
        DisplayFlags    : Word;        { NTSC PAL GENLOC etc}

                { Display flags are determined at power on }

        SimpleSprites   : Pointer;      { SimpleSpritePtr ptr }
        MaxDisplayRow   : Word;        { hardware stuff, do not use }
        MaxDisplayColumn : Word;       { hardware stuff, do not use }
        NormalDisplayRows : Word;
        NormalDisplayColumns : Word;

        { the following are for standard non interlace, 1/2 wb width }

        NormalDPMX      : Word;        { Dots per meter on display }
        NormalDPMY      : Word;        { Dots per meter on display }
        LastChanceMemory : pSignalSemaphore;     { SignalSemaphorePtr }
        LCMptr          : Pointer;
        MicrosPerLine   : Word;        { 256 time usec/line }
        MinDisplayColumn : Word;
        ChipRevBits0    : Byte;
        MemType         : Byte;
        crb_reserved  :  Array[0..3] of Byte;
        monitor_id  : Word;             { normally null }
        hedley  : Array[0..7] of Cardinal;
        hedley_sprites  : Array[0..7] of Cardinal;     { sprite ptrs for intuition mouse }
        hedley_sprites1 : Array[0..7] of Cardinal;            { sprite ptrs for intuition mouse }
        hedley_count    : smallint;
        hedley_flags    : Word;
        hedley_tmp      : smallint;
        hash_table      : Pointer;
        current_tot_rows : Word;
        current_tot_cclks : Word;
        hedley_hint     : Byte;
        hedley_hint2    : Byte;
        nreserved       : Array[0..3] of Cardinal;
        a2024_sync_raster : Pointer;
        control_delta_pal : Word;
        control_delta_ntsc : Word;
        current_monitor : pMonitorSpec;
        MonitorList     : tList;
        default_monitor : pMonitorSpec;
        MonitorListSemaphore : pSignalSemaphore;
        DisplayInfoDataBase : Pointer;
        TopLine      : Word;
        ActiViewCprSemaphore : pSignalSemaphore;
        UtilityBase  : Pointer;           { for hook AND tag utilities   }
        ExecBase     : Pointer;              { to link with rom.lib }
        bwshifts     : Pointer;
        StrtFetchMasks,
        StopFetchMasks,
        Overrun,
        RealStops    : Pointer;
        SpriteWidth,                    { current width (in words) of sprites }
        SpriteFMode  : WORD;            { current sprite fmode bits    }
        SoftSprites,                    { bit mask of size change knowledgeable sprites }
        arraywidth   : Shortint;
        DefaultSpriteWidth : WORD;      { what width intuition wants }
        SprMoveDisable : Shortint;
        WantChips,
        BoardMemType,
        Bugs         : Byte;
        gb_LayersBase : Pointer;
        ColorMask    : Cardinal;
        IVector,
        IData        : Pointer;
        SpecialCounter : Cardinal;         { special for double buffering }
        DBList       : Pointer;
        MonitorFlags : WORD;
        ScanDoubledSprites,
        BP3Bits      : Byte;
        MonitorVBlank  : tAnalogSignalInterval;
        natural_monitor  : pMonitorSpec;
        ProgData     : Pointer;
        ExtSprites   : Byte;
        pad3         : Byte;
        GfxFlags     : WORD;
        VBCounter    : Cardinal;
        HashTableSemaphore  : pSignalSemaphore;
        HWEmul       : Array[0..8] of Pointer;
    end;

const

    NTSC        = 1;
    GENLOC      = 2;
    PAL         = 4;
    TODA_SAFE   = 8;

    BLITMSG_FAULT = 4;

{ bits defs for ChipRevBits }
   GFXB_BIG_BLITS = 0 ;
   GFXB_HR_AGNUS  = 0 ;
   GFXB_HR_DENISE = 1 ;
   GFXB_AA_ALICE  = 2 ;
   GFXB_AA_LISA   = 3 ;
   GFXB_AA_MLISA  = 4 ;      { internal use only. }

   GFXF_BIG_BLITS = 1 ;
   GFXF_HR_AGNUS  = 1 ;
   GFXF_HR_DENISE = 2 ;
   GFXF_AA_ALICE  = 4 ;
   GFXF_AA_LISA   = 8 ;
   GFXF_AA_MLISA  = 16;      { internal use only }

{ Pass ONE of these to SetChipRev() }
   SETCHIPREV_A   = GFXF_HR_AGNUS;
   SETCHIPREV_ECS = (GFXF_HR_AGNUS OR GFXF_HR_DENISE);
   SETCHIPREV_AA  = (GFXF_AA_ALICE OR GFXF_AA_LISA OR SETCHIPREV_ECS);
   SETCHIPREV_BEST= $ffffffff;

{ memory type }
   BUS_16         = 0;
   NML_CAS        = 0;
   BUS_32         = 1;
   DBL_CAS        = 2;
   BANDWIDTH_1X   = (BUS_16 OR NML_CAS);
   BANDWIDTH_2XNML= BUS_32;
   BANDWIDTH_2XDBL= DBL_CAS;
   BANDWIDTH_4X   = (BUS_32 OR DBL_CAS);

{ GfxFlags (private) }
   NEW_DATABASE   = 1;

   GRAPHICSNAME   : PChar  = 'graphics.library';


var
  GfxBase : Pointer = nil;


function BltBitMap(srcBitMap : pBitMap location 'a0'; xSrc : LongInt location 'd0'; ySrc : LongInt location 'd1'; destBitMap : pBitMap location 'a1'; xDest : LongInt location 'd2'; yDest : LongInt location 'd3'; xSize : LongInt location 'd4'; ySize : LongInt location 'd5'; minterm : CARDINAL location 'd6'; mask : CARDINAL location 'd7'; tempA : pCHAR location 'a2') : LongInt;
SysCall GfxBase 030;

procedure BltTemplate(source : pWORD location 'a0'; xSrc : LongInt location 'd0'; srcMod : LongInt location 'd1'; destRP : pRastPort location 'a1'; xDest : LongInt location 'd2'; yDest : LongInt location 'd3'; xSize : LongInt location 'd4'; ySize : LongInt location 'd5');
SysCall GfxBase 036;

procedure ClearEOL(rp : pRastPort location 'a1');
SysCall GfxBase 042;

procedure ClearScreen(rp : pRastPort location 'a1');
SysCall GfxBase 048;

function TextLength(rp : pRastPort location 'a1'; string1 : STRPTR location 'a0'; count : CARDINAL location 'd0') : INTEGER;
SysCall GfxBase 054;

function GfxText(rp : pRastPort location 'a1'; string1: STRPTR location 'a0'; count : CARDINAL location 'd0') : LongInt;
SysCall GfxBase 060;

function SetFont(rp : pRastPort location 'a1'; textFont : pTextFont location 'a0') : LongInt;
SysCall GfxBase 066;

function OpenFont(textAttr : pTextAttr location 'a0') : pTextFont;
SysCall GfxBase 072;

procedure CloseFont(textFont : pTextFont location 'a1');
SysCall GfxBase 078;

function AskSoftStyle(rp : pRastPort location 'a1') : CARDINAL;
SysCall GfxBase 084;

function SetSoftStyle(rp : pRastPort location 'a1'; style : CARDINAL location 'd0'; enable : CARDINAL location 'd1') : CARDINAL;
SysCall GfxBase 090;

procedure AddBob(bob : pBob location 'a0'; rp : pRastPort location 'a1');
SysCall GfxBase 096;

procedure AddVSprite(vSprite : pVSprite location 'a0'; rp : pRastPort location 'a1');
SysCall GfxBase 102;

procedure DoCollision(rp : pRastPort location 'a1');
SysCall GfxBase 108;

procedure DrawGList(rp : pRastPort location 'a1'; vp : pViewPort location 'a0');
SysCall GfxBase 114;

procedure InitGels(head : pVSprite location 'a0'; tail : pVSprite location 'a1'; gelsInfo : pGelsInfo location 'a2');
SysCall GfxBase 120;

procedure InitMasks(vSprite : pVSprite location 'a0');
SysCall GfxBase 126;

procedure RemIBob(bob : pBob location 'a0'; rp : pRastPort location 'a1'; vp : pViewPort location 'a2');
SysCall GfxBase 132;

procedure RemVSprite(vSprite : pVSprite location 'a0');
SysCall GfxBase 138;

procedure SortGList(rp : pRastPort location 'a1');
SysCall GfxBase 150;

procedure AddAnimOb(anOb : pAnimOb location 'a0'; anKey : ppAnimOb location 'a1'; rp : pRastPort location 'a2');
SysCall GfxBase 156;

procedure Animate(anKey : ppAnimOb location 'a0'; rp : pRastPort location 'a1');
SysCall GfxBase 162;

function GetGBuffers(anOb : pAnimOb location 'a0'; rp : pRastPort location 'a1'; flag : LongInt location 'd0') : LongBool;
SysCall GfxBase 168;

procedure InitGMasks(anOb : pAnimOb location 'a0');
SysCall GfxBase 174;

procedure DrawEllipse(rp : pRastPort location 'a1'; xCenter : LongInt location 'd0'; yCenter : LongInt location 'd1'; a : LongInt location 'd2'; b : LongInt location 'd3');
SysCall GfxBase 180;

function AreaEllipse(rp : pRastPort location 'a1'; xCenter : LongInt location 'd0'; yCenter : LongInt location 'd1'; a : LongInt location 'd2'; b : LongInt location 'd3') : LongInt;
SysCall GfxBase 186;

procedure LoadRGB4(vp : pViewPort location 'a0'; Colors : PWord location 'a1'; count : LongInt location 'd0');
SysCall GfxBase 192;

procedure InitRastPort(rp : pRastPort location 'a1');
SysCall GfxBase 198;

procedure InitVPort(vp : pViewPort location 'a0');
SysCall GfxBase 204;

function MrgCop(view : pView location 'a1') : CARDINAL;
SysCall GfxBase 210;

function MakeVPort(view : pView location 'a0'; vp : pViewPort location 'a1') : CARDINAL;
SysCall GfxBase 216;

procedure LoadView(view : pView location 'a1');
SysCall GfxBase 222;

procedure WaitBlit;
SysCall GfxBase 228;

procedure SetRast(rp : pRastPort location 'a1'; pen : CARDINAL location 'd0');
SysCall GfxBase 234;

procedure gfxMove(rp : pRastPort location 'a1'; x : LongInt location 'd0'; y : LongInt location 'd1');
SysCall GfxBase 240;

procedure Draw(rp : pRastPort location 'a1'; x : LongInt location 'd0'; y : LongInt location 'd1');
SysCall GfxBase 246;

function AreaMove(rp : pRastPort location 'a1'; x : LongInt location 'd0'; y : LongInt location 'd1') : LongInt;
SysCall GfxBase 252;

function AreaDraw(rp : pRastPort location 'a1'; x : LongInt location 'd0'; y : LongInt location 'd1') : LongInt;
SysCall GfxBase 258;

function AreaEnd(rp : pRastPort location 'a1') : LongInt;
SysCall GfxBase 264;

procedure WaitTOF;
SysCall GfxBase 270;

procedure QBlit(blit : pbltnode location 'a1');
SysCall GfxBase 276;

procedure InitArea(areaInfo : pAreaInfo location 'a0'; vectorBuffer : POINTER location 'a1'; maxVectors : LongInt location 'd0');
SysCall GfxBase 282;

procedure SetRGB4(vp : pViewPort location 'a0'; index : LongInt location 'd0'; red : CARDINAL location 'd1'; green : CARDINAL location 'd2'; blue : CARDINAL location 'd3');
SysCall GfxBase 288;

procedure QBSBlit(blit : pbltnode location 'a1');
SysCall GfxBase 294;

procedure BltClear(memBlock : Pointer location 'a1'; byteCount : CARDINAL location 'd0'; flags : CARDINAL location 'd1');
SysCall GfxBase 300;

procedure RectFill(rp : pRastPort location 'a1'; xMin : LongInt location 'd0'; yMin : LongInt location 'd1'; xMax : LongInt location 'd2'; yMax : LongInt location 'd3');
SysCall GfxBase 306;

procedure BltPattern(rp : pRastPort location 'a1'; mask : pCHAR location 'a0'; xMin : LongInt location 'd0'; yMin : LongInt location 'd1'; xMax : LongInt location 'd2'; yMax : LongInt location 'd3'; maskBPR : CARDINAL location 'd4');
SysCall GfxBase 312;

function ReadPixel(rp : pRastPort location 'a1'; x : LongInt location 'd0'; y : LongInt location 'd1') : CARDINAL;
SysCall GfxBase 318;

function WritePixel(rp : pRastPort location 'a1'; x : LongInt location 'd0'; y : LongInt location 'd1') : LongInt;
SysCall GfxBase 324;

function Flood(rp : pRastPort location 'a1'; mode : CARDINAL location 'd2'; x : LongInt location 'd0'; y : LongInt location 'd1') : LongBool;
SysCall GfxBase 330;

procedure PolyDraw(rp : pRastPort location 'a1'; count : LongInt location 'd0'; polyTable : PSmallInt location 'a0');
SysCall GfxBase 336;

procedure SetAPen(rp : pRastPort location 'a1'; pen : CARDINAL location 'd0');
SysCall GfxBase 342;

procedure SetBPen(rp : pRastPort location 'a1'; pen : CARDINAL location 'd0');
SysCall GfxBase 348;

procedure SetDrMd(rp : pRastPort location 'a1'; drawMode : CARDINAL location 'd0');
SysCall GfxBase 354;

procedure InitView(view : pView location 'a1');
SysCall GfxBase 360;

procedure CBump(copList : pUCopList location 'a1');
SysCall GfxBase 366;

procedure CMove(copList : pUCopList location 'a1'; destination : POINTER location 'd0'; data : LongInt location 'd1');
SysCall GfxBase 372;

procedure CWait(copList : pUCopList location 'a1'; v : LongInt location 'd0'; h : LongInt location 'd1');
SysCall GfxBase 378;

function VBeamPos : LongInt;
SysCall GfxBase 384;

procedure InitBitMap(bitMap : pBitMap location 'a0'; depth : LongInt location 'd0'; width : LongInt location 'd1'; height : LongInt location 'd2');
SysCall GfxBase 390;

procedure ScrollRaster(rp : pRastPort location 'a1'; dx : LongInt location 'd0'; dy : LongInt location 'd1'; xMin : LongInt location 'd2'; yMin : LongInt location 'd3'; xMax : LongInt location 'd4'; yMax : LongInt location 'd5');
SysCall GfxBase 396;

procedure WaitBOVP(vp : pViewPort location 'a0');
SysCall GfxBase 402;

function GetSprite(sprite : pSimpleSprite location 'a0'; num : LongInt location 'd0') : INTEGER;
SysCall GfxBase 408;

procedure FreeSprite(num : LongInt location 'd0');
SysCall GfxBase 414;

procedure ChangeSprite(vp : pViewPort location 'a0'; sprite : pSimpleSprite location 'a1'; newData : PWord location 'a2');
SysCall GfxBase 420;

procedure MoveSprite(vp : pViewPort location 'a0'; sprite : pSimpleSprite location 'a1'; x : LongInt location 'd0'; y : LongInt location 'd1');
SysCall GfxBase 426;

procedure LockLayerRom(layer : pLayer location 'a5');
SysCall GfxBase 432;

procedure UnlockLayerRom(layer : pLayer location 'a5');
SysCall GfxBase 438;

procedure SyncSBitMap(layer : pLayer location 'a0');
SysCall GfxBase 444;

procedure CopySBitMap(layer : pLayer location 'a0');
SysCall GfxBase 450;

procedure OwnBlitter;
SysCall GfxBase 456;

procedure DisownBlitter;
SysCall GfxBase 462;

function InitTmpRas(tmpRas : pTmpRas location 'a0'; buffer : Pointer location 'a1'; size : LongInt location 'd0') : pTmpRas;
SysCall GfxBase 468;

procedure AskFont(rp : pRastPort location 'a1'; textAttr : pTextAttr location 'a0');
SysCall GfxBase 474;

procedure AddFont(textFont : pTextFont location 'a1');
SysCall GfxBase 480;

procedure RemFont(textFont : pTextFont location 'a1');
SysCall GfxBase 486;

function AllocRaster(width : CARDINAL location 'd0'; height : CARDINAL location 'd1') : TPlanePtr;
SysCall GfxBase 492;

procedure FreeRaster(p : TPlanePtr location 'a0'; width : CARDINAL location 'd0'; height : CARDINAL location 'd1');
SysCall GfxBase 498;

procedure AndRectRegion(region : pRegion location 'a0'; rectangle : pRectangle location 'a1');
SysCall GfxBase 504;

function OrRectRegion(region : pRegion location 'a0'; rectangle : pRectangle location 'a1') : LongBool;
SysCall GfxBase 510;

function NewRegion : pRegion;
SysCall GfxBase 516;

function ClearRectRegion(region : pRegion location 'a0'; rectangle : pRectangle location 'a1') : LongBool;
SysCall GfxBase 522;

procedure ClearRegion(region : pRegion location 'a0');
SysCall GfxBase 528;

procedure DisposeRegion(region : pRegion location 'a0');
SysCall GfxBase 534;

procedure FreeVPortCopLists(vp : pViewPort location 'a0');
SysCall GfxBase 540;

procedure FreeCopList(copList : pCopList location 'a0');
SysCall GfxBase 546;

procedure ClipBlit(srcRP : pRastPort location 'a0'; xSrc : LongInt location 'd0'; ySrc : LongInt location 'd1'; destRP : pRastPort location 'a1'; xDest : LongInt location 'd2'; yDest : LongInt location 'd3'; xSize : LongInt location 'd4'; ySize : LongInt location 'd5'; minterm : CARDINAL location 'd6');
SysCall GfxBase 552;

function XorRectRegion(region : pRegion location 'a0'; rectangle : pRectangle location 'a1') : LongBool;
SysCall GfxBase 558;

procedure FreeCprList(cprList : pcprlist location 'a0');
SysCall GfxBase 564;

function GetColorMap(entries : LongInt location 'd0') : pColorMap;
SysCall GfxBase 570;

procedure FreeColorMap(colorMap : pColorMap location 'a0');
SysCall GfxBase 576;

function GetRGB4(colorMap : pColorMap location 'a0'; entry : LongInt location 'd0') : CARDINAL;
SysCall GfxBase 582;

procedure ScrollVPort(vp : pViewPort location 'a0');
SysCall GfxBase 588;

function UCopperListInit(uCopList : pUCopList location 'a0'; n : LongInt location 'd0') : pCopList;
SysCall GfxBase 594;

procedure FreeGBuffers(anOb : pAnimOb location 'a0'; rp : pRastPort location 'a1'; flag : LongInt location 'd0');
SysCall GfxBase 600;

procedure BltBitMapRastPort(srcBitMap : pBitMap location 'a0'; xSrc : LongInt location 'd0'; ySrc : LongInt location 'd1'; destRP : pRastPort location 'a1'; xDest : LongInt location 'd2'; yDest : LongInt location 'd3'; xSize : LongInt location 'd4'; ySize : LongInt location 'd5'; minterm : CARDINAL location 'd6');
SysCall GfxBase 606;

function OrRegionRegion(srcRegion : pRegion location 'a0'; destRegion : pRegion location 'a1') : LongBool;
SysCall GfxBase 612;

function XorRegionRegion(srcRegion : pRegion location 'a0'; destRegion : pRegion location 'a1') : LongBool;
SysCall GfxBase 618;

function AndRegionRegion(srcRegion : pRegion location 'a0'; destRegion : pRegion location 'a1') : LongBool;
SysCall GfxBase 624;

procedure SetRGB4CM(colorMap : pColorMap location 'a0'; index : LongInt location 'd0'; red : CARDINAL location 'd1'; green : CARDINAL location 'd2'; blue : CARDINAL location 'd3');
SysCall GfxBase 630;

procedure BltMaskBitMapRastPort(srcBitMap : pBitMap location 'a0'; xSrc : LongInt location 'd0'; ySrc : LongInt location 'd1'; destRP : pRastPort location 'a1'; xDest : LongInt location 'd2'; yDest : LongInt location 'd3'; xSize : LongInt location 'd4'; ySize : LongInt location 'd5'; minterm : CARDINAL location 'd6'; bltMask : pCHAR location 'a2');
SysCall GfxBase 636;

function AttemptLockLayerRom(layer : pLayer location 'a5') : LongBool;
SysCall GfxBase 654;

function GfxNew(gfxNodeType : CARDINAL location 'd0') : POINTER;
SysCall GfxBase 660;

procedure GfxFree(gfxNodePtr : POINTER location 'a0');
SysCall GfxBase 666;

procedure GfxAssociate(associateNode : POINTER location 'a0'; gfxNodePtr : POINTER location 'a1');
SysCall GfxBase 672;

procedure BitMapScale(bitScaleArgs : pBitScaleArgs location 'a0');
SysCall GfxBase 678;

function ScalerDiv(factor : CARDINAL location 'd0'; numerator : CARDINAL location 'd1'; denominator : CARDINAL location 'd2') : Integer;
SysCall GfxBase 684;

function TextExtent(rp : pRastPort location 'a1'; string1: pSHORTINT location 'a0'; count : LongInt location 'd0'; textExtent : pTextExtent location 'a2') : INTEGER;
SysCall GfxBase 690;

function TextFit(rp : pRastPort location 'a1'; string1: pSHORTINT location 'a0'; strLen : CARDINAL location 'd0'; textExtent : pTextExtent location 'a2'; constrainingExtent : pTextExtent location 'a3'; strDirection : LongInt location 'd1'; constrainingBitWidth : CARDINAL location 'd2'; constrainingBitHeight : CARDINAL location 'd3') : CARDINAL;
SysCall GfxBase 696;

function GfxLookUp(associateNode : POINTER location 'a0') : POINTER;
SysCall GfxBase 702;

function VideoControl(colorMap : pColorMap location 'a0'; tagarray : pTagItem location 'a1') : LongWord;
SysCall GfxBase 708;

function OpenMonitor(monitorName : pSHORTINT location 'a1'; displayID : CARDINAL location 'd0') : pMonitorSpec;
SysCall GfxBase 714;

function CloseMonitor(monitorSpec : pMonitorSpec location 'a0') : LongBool;
SysCall GfxBase 720;

function FindDisplayInfo(displayID : CARDINAL location 'd0') : POINTER;
SysCall GfxBase 726;

function NextDisplayInfo(displayID : CARDINAL location 'd0') : CARDINAL;
SysCall GfxBase 732;

function GetDisplayInfoData(handle : POINTER location 'a0'; buf : POINTER location 'a1'; size : CARDINAL location 'd0'; tagID : CARDINAL location 'd1'; displayID : CARDINAL location 'd2') : CARDINAL;
SysCall GfxBase 756;

procedure FontExtent(font : pTextFont location 'a0'; fontExtent : pTextExtent location 'a1');
SysCall GfxBase 762;

function ReadPixelLine8(rp : pRastPort location 'a0'; xstart : CARDINAL location 'd0'; ystart : CARDINAL location 'd1'; width : CARDINAL location 'd2'; array1 : PByte location 'a2'; tempRP : pRastPort location 'a1') : LongInt;
SysCall GfxBase 768;

function WritePixelLine8(rp : pRastPort location 'a0'; xstart : CARDINAL location 'd0'; ystart : CARDINAL location 'd1'; width : CARDINAL location 'd2'; array1 : PByte location 'a2'; tempRP : pRastPort location 'a1') : LongInt;
SysCall GfxBase 774;

function ReadPixelArray8(rp : pRastPort location 'a0'; xstart : CARDINAL location 'd0'; ystart : CARDINAL location 'd1'; xstop : CARDINAL location 'd2'; ystop : CARDINAL location 'd3'; array1: PByte location 'a2'; temprp : pRastPort location 'a1') : LongInt;
SysCall GfxBase 780;

function WritePixelArray8(rp : pRastPort location 'a0'; xstart : CARDINAL location 'd0'; ystart : CARDINAL location 'd1'; xstop : CARDINAL location 'd2'; ystop : CARDINAL location 'd3'; array1: PByte location 'a2'; temprp : pRastPort location 'a1') : LongInt;
SysCall GfxBase 786;

function GetVPModeID(vp : pViewPort location 'a0') : LongInt;
SysCall GfxBase 792;

function ModeNotAvailable(modeID : CARDINAL location 'd0') : LongInt;
SysCall GfxBase 798;

function WeighTAMatch(reqTextAttr : pTTextAttr location 'a0'; targetTextAttr : pTextAttr location 'a1'; targetTags : pTagItem location 'a2') : INTEGER;
SysCall GfxBase 804;

procedure EraseRect(rp : pRastPort location 'a1'; xMin : LongInt location 'd0'; yMin : LongInt location 'd1'; xMax : LongInt location 'd2'; yMax : LongInt location 'd3');
SysCall GfxBase 810;

function ExtendFont(font : pTextFont location 'a0'; fontTags : pTagItem location 'a1') : CARDINAL;
SysCall GfxBase 816;

procedure StripFont(font : pTextFont location 'a0');
SysCall GfxBase 822;

function CalcIVG(v : pView location 'a0'; vp : pViewPort location 'a1') : Integer;
SysCall GfxBase 828;

function AttachPalExtra(cm : pColorMap location 'a0'; vp : pViewPort location 'a1') : LongInt;
SysCall GfxBase 834;

function ObtainBestPenA(cm : pColorMap location 'a0'; r : CARDINAL location 'd1'; g : CARDINAL location 'd2'; b : CARDINAL location 'd3'; tags : pTagItem location 'a1') : LongInt;
SysCall GfxBase 840;

procedure SetRGB32(vp : pViewPort location 'a0'; n : CARDINAL location 'd0'; r : CARDINAL location 'd1'; g : CARDINAL location 'd2'; b : CARDINAL location 'd3');
SysCall GfxBase 852;

function GetAPen(rp : pRastPort location 'a0') : CARDINAL;
SysCall GfxBase 858;

function GetBPen(rp : pRastPort location 'a0') : CARDINAL;
SysCall GfxBase 864;

function GetDrMd(rp : pRastPort location 'a0') : CARDINAL;
SysCall GfxBase 870;

function GetOutlinePen(rp : pRastPort location 'a0') : CARDINAL;
SysCall GfxBase 876;

procedure LoadRGB32(vp : pViewPort location 'a0'; VAR table : CARDINAL location 'a1');
SysCall GfxBase 882;

function SetChipRev(want : CARDINAL location 'd0') : CARDINAL;
SysCall GfxBase 888;

procedure SetABPenDrMd(rp : pRastPort location 'a1'; apen : CARDINAL location 'd0'; bpen : CARDINAL location 'd1'; drawmode : CARDINAL location 'd2');
SysCall GfxBase 894;

procedure GetRGB32(cm : pColorMap location 'a0'; firstcolor : CARDINAL location 'd0'; ncolors : CARDINAL location 'd1'; VAR table : CARDINAL location 'a1');
SysCall GfxBase 900;

function AllocBitMap(sizex : CARDINAL location 'd0'; sizey : CARDINAL location 'd1'; depth : CARDINAL location 'd2'; flags : CARDINAL location 'd3'; friend_bitmap : pBitMap location 'a0') : pBitMap;
SysCall GfxBase 918;

procedure FreeBitMap(bm : pBitMap location 'a0');
SysCall GfxBase 924;

function GetExtSpriteA(ss : pExtSprite location 'a2'; tags : pTagItem location 'a1') : LongInt;
SysCall GfxBase 930;

function CoerceMode(vp : pViewPort location 'a0'; monitorid : CARDINAL location 'd0'; flags : CARDINAL location 'd1') : CARDINAL;
SysCall GfxBase 936;

procedure ChangeVPBitMap(vp : pViewPort location 'a0'; bm : pBitMap location 'a1'; db : pDBufInfo location 'a2');
SysCall GfxBase 942;

procedure ReleasePen(cm : pColorMap location 'a0'; n : CARDINAL location 'd0');
SysCall GfxBase 948;

function ObtainPen(cm : pColorMap location 'a0'; n : longint location 'd0'; r : CARDINAL location 'd1'; g : CARDINAL location 'd2'; b : CARDINAL location 'd3'; f : LongInt location 'd4') : CARDINAL;
SysCall GfxBase 954;

function GetBitMapAttr(bm : pBitMap location 'a0'; attrnum : CARDINAL location 'd1') : CARDINAL;
SysCall GfxBase 960;

function AllocDBufInfo(vp : pViewPort location 'a0') : pDBufInfo;
SysCall GfxBase 966;

procedure FreeDBufInfo(dbi : pDBufInfo location 'a1');
SysCall GfxBase 972;

function SetOutlinePen(rp : pRastPort location 'a0'; pen : CARDINAL location 'd0') : CARDINAL;
SysCall GfxBase 978;

function SetWriteMask(rp : pRastPort location 'a0'; msk : CARDINAL location 'd0') : CARDINAL;
SysCall GfxBase 984;

procedure SetMaxPen(rp : pRastPort location 'a0'; maxpen : CARDINAL location 'd0');
SysCall GfxBase 990;

procedure SetRGB32CM(cm : pColorMap location 'a0'; n : CARDINAL location 'd0'; r : CARDINAL location 'd1'; g : CARDINAL location 'd2'; b : CARDINAL location 'd3');
SysCall GfxBase 996;

procedure ScrollRasterBF(rp : pRastPort location 'a1'; dx : LongInt location 'd0'; dy : LongInt location 'd1'; xMin : LongInt location 'd2'; yMin : LongInt location 'd3'; xMax : LongInt location 'd4'; yMax : LongInt location 'd5');
SysCall GfxBase 1002;

function FindColor(cm : pColorMap location 'a3'; r : CARDINAL location 'd1'; g : CARDINAL location 'd2'; b : CARDINAL location 'd3'; maxcolor : LongInt location 'd4') : LongInt;
SysCall GfxBase 1008;

function AllocSpriteDataA(bm : pBitMap location 'a2'; tags : pTagItem location 'a1') : pExtSprite;
SysCall GfxBase 1020;

function ChangeExtSpriteA(vp : pViewPort location 'a0'; oldsprite : pExtSprite location 'a1'; newsprite : pExtSprite location 'a2'; tags : pTagItem location 'a3') : LongInt;
SysCall GfxBase 1026;

procedure FreeSpriteData(sp : pExtSprite location 'a2');
SysCall GfxBase 1032;

procedure SetRPAttrsA(rp : pRastPort location 'a0'; tags : pTagItem location 'a1');
SysCall GfxBase 1038;

procedure GetRPAttrsA(rp : pRastPort location 'a0'; tags : pTagItem location 'a1');
SysCall GfxBase 1044;

function BestModeIDA(tags : pTagItem location 'a0') : CARDINAL;
SysCall GfxBase 1050;

procedure WriteChunkyPixels(rp : pRastPort location 'a0'; xstart : CARDINAL location 'd0'; ystart : CARDINAL location 'd1'; xstop : CARDINAL location 'd2'; ystop : CARDINAL location 'd3'; array1: PByte location 'a2'; bytesperrow : LongInt location 'd4');
SysCall GfxBase 1056;

function OpenFontTagList(textattr : pTextAttr location 'a0'; tags : pTagItem location 'a1') : pTextFont;
SysCall GfxBase 1062;


{ gfxmacros }
procedure BNDRYOFF (w: pRastPort);
procedure InitAnimate (animkey: ppAnimOb);
procedure SetAfPt(w: pRastPort;p: Pointer; n: Byte);
procedure SetDrPt(w: pRastPort;p: Word);
procedure SetOPen(w: pRastPort;c: Byte);
procedure SetWrMsk(w: pRastPort; m: Byte);

procedure SafeSetOutlinePen(w : pRastPort; c : byte);
procedure SafeSetWriteMask( w : pRastPort ; m : smallint ) ;

procedure OFF_DISPLAY (cust: pCustom);
procedure ON_DISPLAY (cust: pCustom);
procedure OFF_SPRITE (cust: pCustom);
procedure ON_SPRITE (cust: pCustom);
procedure OFF_VBLANK (cust: pCustom);
procedure ON_VBLANK (cust: pCustom);

procedure DrawCircle(Rp: PRastPort; xCenter, yCenter, r: LongInt); inline;
function AreaCircle(Rp: PRastPort; xCenter, yCenter, r: SmallInt): LongWord; inline;

function RasSize(w, h: Word): Integer;

function ObtainBestPen(cm : pColorMap; r, g, b: CARDINAL; Tags: array of DWord) : LongInt; inline;
function BestModeID(Tags: array of DWord) : CARDINAL; inline;

{ unit/library initialization }
function InitGraphicsLibrary : boolean;

implementation

procedure BNDRYOFF (w: pRastPort);
begin
  with w^ do Flags := Flags And (Not AREAOUTLINE);
end;

procedure InitAnimate (animkey: ppAnimOb);
begin
  animkey^ := NIL;
end;

procedure SetAfPt(w: pRastPort;p: Pointer; n: Byte);
begin
  with w^ do begin
    ArePointern := p;
    AreaPtSz := n;
  end;
end;

procedure SetDrPt(w: pRastPort;p: Word);
begin
  with w^ do begin
    LinePtrn    := p;
    Flags       := Flags or FRST_doT;
    linpatcnt   := 15;
  end;
end;

procedure SetOPen(w: pRastPort;c: Byte);
begin
  with w^ do begin
    AOlPen  := c;
    Flags   := Flags or AREAOUTLINE;
  end;
end;

{ This function is fine, but For OS39 the SetWriteMask() gfx function
  should be prefered because it SHOULD operate with gfx boards as well.
  At least I hope it does.... }
procedure SetWrMsk(w: pRastPort; m: Byte);
begin
  w^.Mask := m;
end;

procedure SafeSetOutlinePen(w : pRastPort; c : byte);
begin
    IF pGfxBase(GfxBase)^.LibNode.Lib_Version < 39 THEN begin
        w^.AOlPen := c;
        w^.Flags := w^.Flags or AREAOUTLINE;
    end ELSE begin
        c := SetOutlinePen(w,c);
    end;
end;

procedure SafeSetWriteMask( w : pRastPort ; m : smallint ) ;
  VAR x : smallint ;
begin
  IF pGfxBase(GfxBase)^.LibNode.Lib_Version < 39 THEN w^.Mask := BYTE(m)
  ELSE x := SetWriteMask( w, m );
end;

procedure OFF_DISPLAY (cust: pCustom);
begin
    cust^.dmacon := BITCLR or DMAF_RASTER;
end;

procedure ON_DISPLAY (cust: pCustom);
begin
    cust^.dmacon := BITSET or DMAF_RASTER;
end;

procedure OFF_SPRITE (cust: pCustom);
begin
    cust^.dmacon := BITCLR or DMAF_SPRITE;
end;

procedure ON_SPRITE (cust: pCustom);
begin
    cust^.dmacon := BITSET or DMAF_SPRITE;
end;

procedure OFF_VBLANK (cust: pCustom);
begin
    cust^.intena := BITCLR or INTF_VERTB;
end;

procedure ON_VBLANK (cust: pCustom);
begin
    cust^.intena := BITSET or INTF_VERTB;
end;

function RasSize(w, h: Word): Integer; inline;
begin
  RasSize := h * (((w + 15) shr 3) and $FFFE);
end;

procedure DrawCircle(Rp: PRastPort; xCenter, yCenter, r: LongInt); inline;
begin
  DrawEllipse(Rp, xCenter, yCenter, r, r);
end;

function AreaCircle(Rp: PRastPort; xCenter, yCenter, r: SmallInt): LongWord; inline;
begin
  AreaCircle := AreaEllipse(Rp, xCenter, yCenter, r, r);
end;

function ObtainBestPen(cm : pColorMap; r, g, b: CARDINAL; Tags: array of DWord) : LongInt;
begin
  ObtainBestPen := ObtainBestPenA(cm, r, g, b, @Tags);
end;

function BestModeID(Tags: array of DWord) : CARDINAL;
begin
  BestModeID := BestModeIDA(@Tags);
end;

const
  { Change VERSION and LIBVERSION to proper values }
  VERSION : string[2] = '50';
  LIBVERSION : longword = 50;

function InitGraphicsLibrary : boolean;
begin
  InitGraphicsLibrary := Assigned(GfxBase);
end;

initialization
  GfxBase := OpenLibrary(GRAPHICSNAME,LIBVERSION);
finalization
  if Assigned(GfxBase) then
    CloseLibrary(GfxBase);
end.
