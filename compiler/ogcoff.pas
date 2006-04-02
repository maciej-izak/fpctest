{
    Copyright (c) 1998-2006 by Peter Vreman

    Contains the binary coff/PE reader and writer

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 ****************************************************************************
}
unit ogcoff;

{$i fpcdefs.inc}

interface

    uses
       { common }
       cclasses,globtype,
       { target }
       systems,
       { assembler }
       cpuinfo,cpubase,aasmbase,assemble,link,
       { output }
       ogbase,
       owbase;

    type
       TCoffObjSection = class(TObjSection)
       private
         orgmempos,
         coffrelocs,
         coffrelocpos : aint;
       public
         secidx   : longint;
         flags    : longword;
         constructor create(const Aname:string;Aalign:shortint;Aoptions:TObjSectionOptions);override;
         procedure addsymsizereloc(ofs:aint;p:TObjSymbol;symsize:aint;reloctype:TObjRelocationType);
         procedure fixuprelocs;override;
       end;

       TDJCoffObjSection = class(TCoffObjSection)
         constructor create(const Aname:string;Aalign:shortint;Aoptions:TObjSectionOptions);override;
       end;

       TPECoffObjSection = class(TCoffObjSection)
         constructor create(const Aname:string;Aalign:shortint;Aoptions:TObjSectionOptions);override;
       end;

       TCoffObjData = class(TObjData)
       private
         win32      : boolean;
       public
         constructor createcoff(const n:string;awin32:boolean;acObjSection:TObjSectionClass);
         destructor  destroy;override;
         procedure CreateDebugSections;override;
         function  sectionname(atype:TAsmSectiontype;const aname:string):string;override;
         procedure writereloc(data,len:aint;p:TObjSymbol;reloctype:TObjRelocationType);override;
         procedure writestab(offset:aint;ps:TObjSymbol;nidx,nother:byte;ndesc:word;p:pchar);override;
         procedure afteralloc;override;
       end;

       TDJCoffObjData = class(TCoffObjData)
         constructor create(const n:string);override;
       end;

       TPECoffObjData = class(TCoffObjData)
         constructor create(const n:string);override;
       end;

       TCoffObjOutput = class(tObjOutput)
       private
         win32   : boolean;
         symidx  : longint;
         FCoffSyms,
         FCoffStrs : tdynamicarray;
         procedure write_symbol(const name:string;value:aint;section:smallint;typ,aux:byte);
         procedure section_write_symbol(p:TObject;arg:pointer);
         procedure section_write_relocs(p:TObject;arg:pointer);
         procedure create_symbols(data:TObjData);
         procedure section_set_datapos(p:TObject;arg:pointer);
         procedure section_set_reloc_datapos(p:TObject;arg:pointer);
         procedure section_write_header(p:TObject;arg:pointer);
         procedure section_write_data(p:TObject;arg:pointer);
       protected
         function writedata(data:TObjData):boolean;override;
       public
         constructor createcoff(AWriter:TObjectWriter;awin32:boolean);
         destructor destroy;override;
       end;

       TDJCoffObjOutput = class(TCoffObjOutput)
         constructor create(AWriter:TObjectWriter);override;
       end;

       TPECoffObjOutput = class(TCoffObjOutput)
         constructor create(AWriter:TObjectWriter);override;
       end;

       TCoffObjInput = class(tObjInput)
       private
         FCoffsyms,
         FCoffStrs : tdynamicarray;
         { Convert symidx -> TObjSymbol }
         FSymTbl   : ^TObjSymbolArray;
         { Convert secidx -> TObjSection }
         FSecCount : smallint;
         FSecTbl   : ^TObjSectionArray;
         win32     : boolean;
         function  GetSection(secidx:longint):TObjSection;
         function  Read_str(strpos:longint):string;
         procedure read_relocs(s:TCoffObjSection);
         procedure read_symbols(objdata:TObjData);
         procedure ObjSections_read_data(p:TObject;arg:pointer);
         procedure ObjSections_read_relocs(p:TObject;arg:pointer);
       protected
         function  readObjData(objdata:TObjData):boolean;override;
       public
         constructor createcoff(awin32:boolean);
         destructor destroy;override;
       end;

       TDJCoffObjInput = class(TCoffObjInput)
         constructor create;override;
       end;

       TPECoffObjInput = class(TCoffObjInput)
         constructor create;override;
       end;

       TCoffExeSection = class(TExeSection)
       private
         win32   : boolean;
       public
         constructor createcoff(const n:string;awin32:boolean);
       end;

       TDJCoffExeSection = class(TCoffExeSection)
         constructor create(const n:string);override;
       end;

       TPECoffExeSection = class(TCoffExeSection)
         constructor create(const n:string);override;
       end;

       TCoffexeoutput = class(texeoutput)
       private
         FCoffsyms,
         FCoffStrs : tdynamicarray;
         win32     : boolean;
         nsects    : smallint;
         nsyms,
         sympos    : aint;
         procedure ExeSections_pass2_header(p:TObject;arg:pointer);
         procedure write_symbol(const name:string;value:aint;section:smallint;typ,aux:byte);
         procedure globalsyms_write_symbol(p:TObject;arg:pointer);
         procedure ExeSections_write_header(p:TObject;arg:pointer);
         procedure ExeSections_write_data(p:TObject;arg:pointer);
       protected
         procedure CalcPos_Header;override;
         procedure CalcPos_Symbols;override;
         function writedata:boolean;override;
       public
         constructor createcoff(awin32:boolean);
       end;

       TDJCoffexeoutput = class(TCoffexeoutput)
         constructor create;override;
       end;

       TPECoffexeoutput = class(TCoffexeoutput)
       private
         idatalabnr : longint;
       public
         constructor create;override;
         function  LoadDLL(const dllname:string):boolean;
         procedure ResolveExternals(const libname:string);override;
       end;

       TObjSymbolrec = record
         sym : TObjSymbol;
         orgsize : aint;
       end;
       TObjSymbolArray = array[0..high(word)] of TObjSymbolrec;
       TObjSectionArray = array[0..high(smallint)] of TObjSection;

       TDJCoffAssembler = class(tinternalassembler)
         constructor create(smart:boolean);override;
       end;

       TPECoffassembler = class(tinternalassembler)
         constructor create(smart:boolean);override;
       end;

       TDJCofflinker = class(tinternallinker)
         constructor create;override;
         procedure DefaultLinkScript;override;
       end;

       TPECofflinker = class(tinternallinker)
         constructor create;override;
         procedure DefaultLinkScript;override;
       end;


implementation

    uses
       cutils,verbose,globals,
       fmodule,aasmtai,aasmdata,
       ogmap;

    const
{$ifdef i386}
       COFF_MAGIC       = $14c;
       COFF_OPT_MAGIC   = $10b;
{$endif i386}
{$ifdef arm}
       COFF_MAGIC       = $1c0;
       COFF_OPT_MAGIC   = $10b;
{$endif arm}
{$ifdef x86_64}
       COFF_MAGIC       = $8664;
       COFF_OPT_MAGIC   = $20b;
{$endif x86_64}

       COFF_FLAG_NORELOCS = $0001;
       COFF_FLAG_EXE      = $0002;
       COFF_FLAG_NOLINES  = $0004;
       COFF_FLAG_NOLSYMS  = $0008;
       COFF_FLAG_AR16WR   = $0080; { 16bit little endian }
       COFF_FLAG_AR32WR   = $0100; { 32bit little endian }
       COFF_FLAG_AR32W    = $0200; { 32bit big endian }
       COFF_FLAG_DLL      = $2000;

       COFF_SYM_GLOBAL   = 2;
       COFF_SYM_LOCAL    = 3;
       COFF_SYM_LABEL    = 6;
       COFF_SYM_FUNCTION = 101;
       COFF_SYM_FILE     = 103;
       COFF_SYM_SECTION  = 104;

       COFF_STYP_REG    = $0000; { "regular": allocated, relocated, loaded }
       COFF_STYP_DSECT  = $0001; { "dummy":  relocated only }
       COFF_STYP_NOLOAD = $0002; { "noload": allocated, relocated, not loaded }
       COFF_STYP_GROUP  = $0004; { "grouped": formed of input sections }
       COFF_STYP_PAD    = $0008;
       COFF_STYP_COPY   = $0010;
       COFF_STYP_TEXT   = $0020;
       COFF_STYP_DATA   = $0040;
       COFF_STYP_BSS    = $0080;

       PE_SUBSYSTEM_WINDOWS_GUI    = 2;
       PE_SUBSYSTEM_WINDOWS_CUI    = 3;
       PE_SUBSYSTEM_WINDOWS_CE_GUI = 9;

       PE_FILE_RELOCS_STRIPPED         = $0001;
       PE_FILE_EXECUTABLE_IMAGE        = $0002;
       PE_FILE_LINE_NUMS_STRIPPED      = $0004;
       PE_FILE_LOCAL_SYMS_STRIPPED     = $0008;
       PE_FILE_AGGRESSIVE_WS_TRIM      = $0010;
       PE_FILE_LARGE_ADDRESS_AWARE     = $0020;
       PE_FILE_16BIT_MACHINE           = $0040;
       PE_FILE_BYTES_REVERSED_LO       = $0080;
       PE_FILE_32BIT_MACHINE           = $0100;
       PE_FILE_DEBUG_STRIPPED          = $0200;
       PE_FILE_REMOVABLE_RUN_FROM_SWAP = $0400;
       PE_FILE_NET_RUN_FROM_SWAP       = $0800;
       PE_FILE_SYSTEM                  = $1000;
       PE_FILE_DLL                     = $2000;
       PE_FILE_UP_SYSTEM_ONLY          = $4000;
       PE_FILE_BYTES_REVERSED_HI       = $8000;

       PE_SCN_CNT_CODE               = $00000020; { Section contains code. }
       PE_SCN_CNT_INITIALIZED_DATA   = $00000040; { Section contains initialized data. }
       PE_SCN_CNT_UNINITIALIZED_DATA = $00000080; { Section contains uninitialized data. }
       PE_SCN_LNK_OTHER              = $00000100; { Reserved. }
       PE_SCN_LNK_INFO               = $00000200; { Section contains comments or some other type of information. }
       PE_SCN_LNK_REMOVE             = $00000800; { Section contents will not become part of image. }
       PE_SCN_LNK_COMDAT             = $00001000; { Section contents comdat. }
       PE_SCN_MEM_FARDATA            = $00008000;
       PE_SCN_MEM_PURGEABLE          = $00020000;
       PE_SCN_MEM_16BIT              = $00020000;
       PE_SCN_MEM_LOCKED             = $00040000;
       PE_SCN_MEM_PRELOAD            = $00080000;
       PE_SCN_ALIGN_MASK             = $00f00000;
       PE_SCN_ALIGN_1BYTES           = $00100000;
       PE_SCN_ALIGN_2BYTES           = $00200000;
       PE_SCN_ALIGN_4BYTES           = $00300000;
       PE_SCN_ALIGN_8BYTES           = $00400000;
       PE_SCN_ALIGN_16BYTES          = $00500000; { Default alignment if no others are specified. }
       PE_SCN_ALIGN_32BYTES          = $00600000;
       PE_SCN_ALIGN_64BYTES          = $00700000;
       PE_SCN_LNK_NRELOC_OVFL        = $01000000; { Section contains extended relocations. }
       PE_SCN_MEM_NOT_CACHED         = $04000000; { Section is not cachable.               }
       PE_SCN_MEM_NOT_PAGED          = $08000000; { Section is not pageable.               }
       PE_SCN_MEM_SHARED             = $10000000; { Section is shareable.                  }
       PE_SCN_MEM_DISCARDABLE        = $02000000;
       PE_SCN_MEM_EXECUTE            = $20000000;
       PE_SCN_MEM_READ               = $40000000;
       PE_SCN_MEM_WRITE              = $80000000;

       PE_DATADIR_ENTRIES = 16;
       PE_DATADIR_EDATA = 0;
       PE_DATADIR_IDATA = 1;
       PE_DATADIR_RSRC = 2;
       PE_DATADIR_PDATA = 3;
       PE_DATADIR_SECURITY = 4;
       PE_DATADIR_RELOC = 5;
       PE_DATADIR_DEBUG = 6;
       PE_DATADIR_DESCRIPTION = 7;
       PE_DATADIR_SPECIAL = 8;
       PE_DATADIR_TLS = 9;
       PE_DATADIR_LOADCFG = 10;
       PE_DATADIR_BOUNDIMPORT = 11;
       PE_DATADIR_IMPORTADDRESSTABLE = 12;
       PE_DATADIR_DELAYIMPORT = 13;

{$ifdef x86_64}
       IMAGE_REL_AMD64_ABSOLUTE    = $0000;  { Reference is absolute, no relocation is necessary }
       IMAGE_REL_AMD64_ADDR64      = $0001;  { 64-bit address (VA). }
       IMAGE_REL_AMD64_ADDR32      = $0002;  { 32-bit address (VA). }
       IMAGE_REL_AMD64_ADDR32NB    = $0003;  { 32-bit address w/o image base (RVA). }
       IMAGE_REL_AMD64_REL32       = $0004;  { 32-bit relative address from byte following reloc }
       IMAGE_REL_AMD64_REL32_1     = $0005;  { 32-bit relative address from byte distance 1 from reloc }
       IMAGE_REL_AMD64_REL32_2     = $0006;  { 32-bit relative address from byte distance 2 from reloc }
       IMAGE_REL_AMD64_REL32_3     = $0007;  { 32-bit relative address from byte distance 3 from reloc }
       IMAGE_REL_AMD64_REL32_4     = $0008;  { 32-bit relative address from byte distance 4 from reloc }
       IMAGE_REL_AMD64_REL32_5     = $0009;  { 32-bit relative address from byte distance 5 from reloc }
       IMAGE_REL_AMD64_SECTION     = $000A;  { Section index }
       IMAGE_REL_AMD64_SECREL      = $000B;  { 32 bit offset from base of section containing target }
       IMAGE_REL_AMD64_SECREL7     = $000C;  { 7 bit unsigned offset from base of section containing target }
       IMAGE_REL_AMD64_TOKEN       = $000D;  { 32 bit metadata token }
       IMAGE_REL_AMD64_SREL32      = $000E;  { 32 bit signed span-dependent value emitted into object }
       IMAGE_REL_AMD64_PAIR        = $000F;
       IMAGE_REL_AMD64_SSPAN32     = $0010;  { 32 bit signed span-dependent value applied at link time }
{$endif x86_64}

       R_DIR32 = 6;
       R_IMAGEBASE = 7;
       R_PCRLONG = 20;

    type
       { Structures which are written directly to the output file }
       coffheader=packed record
         mach   : word;
         nsects : smallint;
         time   : longint;
         sympos : longint;
         syms   : longint;
         opthdr : word;
         flag   : word;
       end;
       coffdjoptheader=packed record
         magic  : word;
         vstamp : word;
         tsize  : longint;
         dsize  : longint;
         bsize  : longint;
         entry  : longint;
         text_start : longint;
         data_start : longint;
       end;
       coffpedatadir=packed record
         vaddr : longint;
         size  : longint;
       end;
       coffpeoptheader=packed record
         Magic : word;
         MajorLinkerVersion : byte;
         MinorLinkerVersion : byte;
         tsize : longint;
         dsize : longint;
         bsize : longint;
         entry : longint;
         text_start : longint;
{$ifndef x86_64}
         data_start : longint;
{$endif x86_64}
         ImageBase : aint;
         SectionAlignment : longint;
         FileAlignment : longint;
         MajorOperatingSystemVersion : word;
         MinorOperatingSystemVersion : word;
         MajorImageVersion : word;
         MinorImageVersion : word;
         MajorSubsystemVersion : word;
         MinorSubsystemVersion : word;
         Win32Version : longint;
         SizeOfImage : longint;
         SizeOfHeaders : longint;
         CheckSum : longint;
         Subsystem : word;
         DllCharacteristics : word;
         SizeOfStackReserve : aint;
         SizeOfStackCommit : aint;
         SizeOfHeapReserve : aint;
         SizeOfHeapCommit : aint;
         LoaderFlags : longint;
         NumberOfRvaAndSizes : longint;
         DataDirectory : array[0..PE_DATADIR_ENTRIES-1] of coffpedatadir;
       end;
       coffsechdr=packed record
         name     : array[0..7] of char;
         vsize    : longint;
         rvaofs   : longint;
         datasize : longint;
         datapos  : longint;
         relocpos : longint;
         lineno1  : longint;
         nrelocs  : word;
         lineno2  : word;
         flags    : longword;
       end;
       coffsectionrec=packed record
         len     : longint;
         nrelocs : word;
         empty   : array[0..11] of char;
       end;
       coffreloc=packed record
         address  : longint;
         sym      : longint;
         reloctype : word;
       end;
       coffsymbol=packed record
         name    : array[0..3] of char; { real is [0..7], which overlaps the strpos ! }
         strpos  : longint;
         value   : longint;
         section : smallint;
         empty   : word;
         typ     : byte;
         aux     : byte;
       end;

     const
       symbolresize = 200*sizeof(coffsymbol);
       strsresize   = 8192;

       coffsecnames : array[TAsmSectiontype] of string[17] = ('',
          '.text','.data','.data','.bss','.tls',
          '.text',
          '.stab','.stabstr',
          '.idata$2','.idata$4','.idata$5','.idata$6','.idata$7','.edata',
          '.eh_frame',
          '.debug_frame','.debug_info','.debug_line','.debug_abbrev',
          '.fpc',
          ''
        );

const go32v2stub : array[0..2047] of byte=(
  $4D,$5A,$00,$00,$04,$00,$00,$00,$20,$00,$27,$00,$FF,$FF,$00,
  $00,$60,$07,$00,$00,$54,$00,$00,$00,$00,$00,$00,$00,$0D,$0A,
  $73,$74,$75,$62,$2E,$68,$20,$67,$65,$6E,$65,$72,$61,$74,$65,
  $64,$20,$66,$72,$6F,$6D,$20,$73,$74,$75,$62,$2E,$61,$73,$6D,
  $20,$62,$79,$20,$64,$6A,$61,$73,$6D,$2C,$20,$6F,$6E,$20,$54,
  $68,$75,$20,$44,$65,$63,$20,$20,$39,$20,$31,$30,$3A,$35,$39,
  $3A,$33,$31,$20,$31,$39,$39,$39,$0D,$0A,$54,$68,$65,$20,$53,
  $54,$55,$42,$2E,$45,$58,$45,$20,$73,$74,$75,$62,$20,$6C,$6F,
  $61,$64,$65,$72,$20,$69,$73,$20,$43,$6F,$70,$79,$72,$69,$67,
  $68,$74,$20,$28,$43,$29,$20,$31,$39,$39,$33,$2D,$31,$39,$39,
  $35,$20,$44,$4A,$20,$44,$65,$6C,$6F,$72,$69,$65,$2E,$20,$0D,
  $0A,$50,$65,$72,$6D,$69,$73,$73,$69,$6F,$6E,$20,$67,$72,$61,
  $6E,$74,$65,$64,$20,$74,$6F,$20,$75,$73,$65,$20,$66,$6F,$72,
  $20,$61,$6E,$79,$20,$70,$75,$72,$70,$6F,$73,$65,$20,$70,$72,
  $6F,$76,$69,$64,$65,$64,$20,$74,$68,$69,$73,$20,$63,$6F,$70,
  $79,$72,$69,$67,$68,$74,$20,$0D,$0A,$72,$65,$6D,$61,$69,$6E,
  $73,$20,$70,$72,$65,$73,$65,$6E,$74,$20,$61,$6E,$64,$20,$75,
  $6E,$6D,$6F,$64,$69,$66,$69,$65,$64,$2E,$20,$0D,$0A,$54,$68,
  $69,$73,$20,$6F,$6E,$6C,$79,$20,$61,$70,$70,$6C,$69,$65,$73,
  $20,$74,$6F,$20,$74,$68,$65,$20,$73,$74,$75,$62,$2C,$20,$61,
  $6E,$64,$20,$6E,$6F,$74,$20,$6E,$65,$63,$65,$73,$73,$61,$72,
  $69,$6C,$79,$20,$74,$68,$65,$20,$77,$68,$6F,$6C,$65,$20,$70,
  $72,$6F,$67,$72,$61,$6D,$2E,$0A,$0D,$0A,$24,$49,$64,$3A,$20,
  $73,$74,$75,$62,$2E,$61,$73,$6D,$20,$62,$75,$69,$6C,$74,$20,
  $31,$32,$2F,$30,$39,$2F,$39,$39,$20,$31,$30,$3A,$35,$39,$3A,
  $33,$31,$20,$62,$79,$20,$64,$6A,$61,$73,$6D,$20,$24,$0A,$0D,
  $0A,$40,$28,$23,$29,$20,$73,$74,$75,$62,$2E,$61,$73,$6D,$20,
  $62,$75,$69,$6C,$74,$20,$31,$32,$2F,$30,$39,$2F,$39,$39,$20,
  $31,$30,$3A,$35,$39,$3A,$33,$31,$20,$62,$79,$20,$64,$6A,$61,
  $73,$6D,$0A,$0D,$0A,$1A,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$67,$6F,$33,$32,$73,$74,$75,$62,$2C,$20,$76,$20,$32,
  $2E,$30,$32,$54,$00,$00,$00,$00,$00,$08,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$40,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$43,$57,$53,$44,$50,
  $4D,$49,$2E,$45,$58,$45,$00,$00,$00,$00,$00,$0E,$1F,$8C,$1E,
  $24,$00,$8C,$06,$60,$07,$FC,$B4,$30,$CD,$21,$3C,$03,$73,$08,
  $B0,$6D,$BA,$A7,$05,$E9,$D4,$03,$A2,$69,$08,$BE,$20,$00,$8B,
  $04,$09,$C0,$75,$02,$B4,$FE,$BB,$70,$08,$39,$C3,$73,$02,$89,
  $C3,$89,$1C,$FE,$C7,$B9,$04,$FF,$D3,$EB,$B4,$4A,$CD,$21,$73,
  $08,$D3,$E3,$FE,$CF,$89,$1C,$EB,$D8,$26,$8E,$06,$2C,$00,$31,
  $FF,$30,$C0,$A9,$F2,$AE,$26,$81,$3D,$50,$41,$75,$15,$AF,$26,
  $81,$3D,$54,$48,$75,$0D,$AF,$26,$80,$3D,$3D,$75,$06,$47,$89,
  $3E,$8C,$04,$4F,$AE,$75,$DF,$AF,$B4,$3E,$BB,$13,$00,$CD,$21,
  $B4,$3E,$BB,$12,$00,$CD,$21,$06,$57,$31,$C9,$74,$12,$B0,$6E,
  $BA,$7E,$05,$E9,$5E,$03,$09,$C9,$75,$F4,$41,$E8,$A1,$03,$72,
  $EE,$B8,$87,$16,$CD,$2F,$09,$C0,$75,$ED,$80,$E3,$01,$74,$E8,
  $89,$3E,$00,$06,$8C,$06,$02,$06,$89,$36,$04,$06,$5F,$07,$E8,
  $D3,$02,$89,$3E,$2A,$00,$89,$36,$62,$07,$80,$3E,$2C,$00,$00,
  $74,$23,$B9,$08,$00,$BF,$2C,$00,$8A,$05,$47,$08,$C0,$74,$05,
  $88,$07,$43,$E2,$F4,$66,$C7,$07,$2E,$45,$58,$45,$83,$C3,$04,
  $C6,$07,$00,$89,$1E,$62,$07,$B8,$00,$3D,$BA,$64,$07,$CD,$21,
  $0F,$82,$B3,$02,$A3,$06,$06,$89,$C3,$B9,$06,$00,$BA,$B5,$07,
  $B4,$3F,$CD,$21,$31,$D2,$31,$C9,$A1,$B5,$07,$3D,$4C,$01,$74,
  $1B,$3D,$4D,$5A,$0F,$85,$98,$02,$8B,$16,$B9,$07,$C1,$E2,$09,
  $8B,$1E,$B7,$07,$09,$DB,$74,$05,$80,$EE,$02,$01,$DA,$89,$16,
  $BB,$07,$89,$0E,$BD,$07,$B8,$00,$42,$8B,$1E,$06,$06,$CD,$21,
  $B9,$A8,$00,$BA,$BF,$07,$B4,$3F,$CD,$21,$3D,$A8,$00,$75,$06,
  $81,$3E,$BF,$07,$4C,$01,$0F,$85,$61,$02,$66,$A1,$E3,$07,$66,
  $A3,$10,$06,$66,$8B,$0E,$BB,$07,$66,$A1,$03,$08,$66,$01,$C8,
  $66,$A3,$08,$06,$66,$A1,$2B,$08,$66,$01,$C8,$66,$A3,$0C,$06,
  $66,$8B,$1E,$4B,$08,$66,$A1,$4F,$08,$66,$01,$C3,$66,$B8,$01,
  $00,$01,$00,$66,$39,$C3,$73,$03,$66,$89,$C3,$66,$81,$C3,$FF,
  $FF,$00,$00,$31,$DB,$66,$89,$1E,$1C,$00,$E8,$F5,$02,$8B,$1E,
  $04,$06,$09,$DB,$74,$0A,$B4,$48,$CD,$21,$0F,$82,$15,$02,$8E,
  $C0,$E8,$08,$03,$B8,$01,$00,$FF,$1E,$00,$06,$0F,$82,$0F,$02,
  $8C,$06,$26,$00,$8C,$0E,$28,$00,$8C,$D8,$A3,$22,$00,$8E,$C0,
  $31,$C0,$B9,$01,$00,$CD,$31,$72,$07,$A3,$14,$06,$31,$C0,$CD,
  $31,$0F,$82,$F3,$01,$A3,$16,$06,$66,$8B,$0E,$1C,$00,$B8,$01,
  $05,$8B,$1E,$1E,$00,$CD,$31,$0F,$82,$E5,$01,$89,$1E,$1A,$06,
  $89,$0E,$18,$06,$89,$36,$1A,$00,$89,$3E,$18,$00,$B8,$07,$00,
  $8B,$1E,$14,$06,$8B,$0E,$1A,$06,$8B,$16,$18,$06,$CD,$31,$B8,
  $09,$00,$8C,$C9,$83,$E1,$03,$C1,$E1,$05,$51,$81,$C9,$9B,$C0,
  $CD,$31,$B8,$08,$00,$8B,$0E,$1E,$00,$49,$BA,$FF,$FF,$CD,$31,
  $B8,$07,$00,$8B,$1E,$16,$06,$8B,$0E,$1A,$06,$8B,$16,$18,$06,
  $CD,$31,$B8,$09,$00,$59,$81,$C9,$93,$C0,$CD,$31,$B8,$08,$00,
  $8B,$0E,$1E,$00,$49,$BA,$FF,$FF,$CD,$31,$B8,$00,$01,$BB,$00,
  $0F,$CD,$31,$73,$10,$3D,$08,$00,$0F,$85,$73,$01,$B8,$00,$01,
  $CD,$31,$0F,$82,$6A,$01,$A3,$1C,$06,$89,$16,$1E,$06,$C1,$E3,
  $04,$89,$1E,$20,$06,$66,$8B,$36,$08,$06,$66,$8B,$3E,$FB,$07,
  $66,$8B,$0E,$FF,$07,$E8,$49,$00,$66,$8B,$36,$0C,$06,$66,$8B,
  $3E,$23,$08,$66,$8B,$0E,$27,$08,$E8,$37,$00,$8E,$06,$16,$06,
  $66,$8B,$3E,$4B,$08,$66,$8B,$0E,$4F,$08,$66,$31,$C0,$66,$C1,
  $E9,$02,$67,$F3,$66,$AB,$B4,$3E,$8B,$1E,$06,$06,$CD,$21,$B8,
  $01,$01,$8B,$16,$1E,$06,$CD,$31,$1E,$0F,$A1,$8E,$1E,$16,$06,
  $66,$64,$FF,$2E,$10,$06,$66,$89,$F0,$66,$25,$FF,$01,$00,$00,
  $66,$01,$C1,$29,$C6,$66,$29,$C7,$66,$89,$0E,$26,$06,$66,$89,
  $3E,$22,$06,$E8,$0F,$01,$89,$36,$3E,$06,$66,$C1,$EE,$10,$89,
  $36,$42,$06,$8B,$1E,$06,$06,$89,$1E,$3A,$06,$C7,$06,$46,$06,
  $00,$42,$E8,$03,$01,$A1,$1C,$06,$A3,$4E,$06,$C7,$06,$3E,$06,
  $00,$00,$C6,$06,$47,$06,$3F,$A1,$28,$06,$09,$C0,$75,$09,$A1,
  $26,$06,$3B,$06,$20,$06,$76,$03,$A1,$20,$06,$A3,$42,$06,$E8,
  $D9,$00,$66,$31,$C9,$8B,$0E,$46,$06,$66,$8B,$3E,$22,$06,$66,
  $01,$0E,$22,$06,$66,$29,$0E,$26,$06,$66,$31,$F6,$C1,$E9,$02,
  $1E,$06,$8E,$06,$16,$06,$8E,$1E,$1E,$06,$67,$F3,$66,$A5,$07,
  $1F,$66,$03,$0E,$26,$06,$75,$AF,$C3,$3C,$3A,$74,$06,$3C,$2F,
  $74,$02,$3C,$5C,$C3,$BE,$64,$07,$89,$F3,$26,$8A,$05,$47,$88,
  $04,$38,$E0,$74,$0E,$08,$C0,$74,$0A,$46,$E8,$DE,$FF,$75,$EC,
  $89,$F3,$74,$E8,$C3,$B0,$66,$BA,$48,$05,$EB,$0C,$B0,$67,$BA,
  $55,$05,$EB,$05,$B0,$68,$BA,$5F,$05,$52,$8B,$1E,$62,$07,$C6,
  $07,$24,$BB,$64,$07,$EB,$28,$E8,$F5,$00,$B0,$69,$BA,$99,$05,
  $EB,$1A,$B0,$6A,$BA,$B2,$05,$EB,$13,$B0,$6B,$BA,$C4,$05,$EB,
  $0C,$B0,$6C,$BA,$D6,$05,$EB,$05,$B0,$69,$BA,$99,$05,$52,$BB,
  $3B,$05,$E8,$15,$00,$5B,$E8,$11,$00,$BB,$67,$04,$E8,$0B,$00,
  $B4,$4C,$CD,$21,$43,$50,$B4,$02,$CD,$21,$58,$8A,$17,$80,$FA,
  $24,$75,$F2,$C3,$0D,$0A,$24,$50,$51,$57,$31,$C0,$BF,$2A,$06,
  $B9,$19,$00,$F3,$AB,$5F,$59,$58,$C3,$B8,$00,$03,$BB,$21,$00,
  $31,$C9,$66,$BF,$2A,$06,$00,$00,$CD,$31,$C3,$00,$00,$30,$E4,
  $E8,$4E,$FF,$89,$DE,$8B,$3E,$8C,$04,$EB,$17,$B4,$3B,$E8,$41,
  $FF,$81,$FE,$64,$07,$74,$12,$8A,$44,$FF,$E8,$2A,$FF,$74,$04,
  $C6,$04,$5C,$46,$E8,$03,$00,$72,$E4,$C3,$E8,$34,$00,$BB,$44,
  $00,$8A,$07,$88,$04,$43,$46,$08,$C0,$75,$F6,$06,$57,$1E,$07,
  $E8,$9B,$FF,$BB,$2A,$06,$8C,$5F,$04,$89,$5F,$02,$BA,$64,$07,
  $B8,$00,$4B,$CD,$21,$5F,$07,$72,$09,$B4,$4D,$CD,$21,$2D,$00,
  $03,$F7,$D8,$EB,$28,$80,$3E,$69,$08,$05,$72,$20,$B8,$00,$58,
  $CD,$21,$A2,$67,$08,$B8,$02,$58,$CD,$21,$A2,$68,$08,$B8,$01,
  $58,$BB,$80,$00,$CD,$21,$B8,$03,$58,$BB,$01,$00,$CD,$21,$C3,
  $9C,$80,$3E,$69,$08,$05,$72,$1A,$50,$53,$B8,$03,$58,$8A,$1E,
  $68,$08,$30,$FF,$CD,$21,$B8,$01,$58,$8A,$1E,$67,$08,$30,$FF,
  $CD,$21,$5B,$58,$9D,$C3,$4C,$6F,$61,$64,$20,$65,$72,$72,$6F,
  $72,$3A,$20,$24,$3A,$20,$63,$61,$6E,$27,$74,$20,$6F,$70,$65,
  $6E,$24,$3A,$20,$6E,$6F,$74,$20,$45,$58,$45,$24,$3A,$20,$6E,
  $6F,$74,$20,$43,$4F,$46,$46,$20,$28,$43,$68,$65,$63,$6B,$20,
  $66,$6F,$72,$20,$76,$69,$72,$75,$73,$65,$73,$29,$24,$6E,$6F,
  $20,$44,$50,$4D,$49,$20,$2D,$20,$47,$65,$74,$20,$63,$73,$64,
  $70,$6D,$69,$2A,$62,$2E,$7A,$69,$70,$24,$6E,$6F,$20,$44,$4F,
  $53,$20,$6D,$65,$6D,$6F,$72,$79,$24,$6E,$65,$65,$64,$20,$44,
  $4F,$53,$20,$33,$24,$63,$61,$6E,$27,$74,$20,$73,$77,$69,$74,
  $63,$68,$20,$6D,$6F,$64,$65,$24,$6E,$6F,$20,$44,$50,$4D,$49,
  $20,$73,$65,$6C,$65,$63,$74,$6F,$72,$73,$24,$6E,$6F,$20,$44,
  $50,$4D,$49,$20,$6D,$65,$6D,$6F,$72,$79,$24,$90,$90,$90,$90,
  $90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,
  $90,$90,$90,$90,$90,$90,$90,$90);

const win32stub : array[0..131] of byte=(
  $4D,$5A,$90,$00,$03,$00,$00,$00,$04,$00,$00,$00,$FF,$FF,$00,$00,
  $B8,$00,$00,$00,$00,$00,$00,$00,$40,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$00,
  $0E,$1F,$BA,$0E,$00,$B4,$09,$CD,$21,$B8,$01,$4C,$CD,$21,$54,$68,
  $69,$73,$20,$70,$72,$6F,$67,$72,$61,$6D,$20,$63,$61,$6E,$6E,$6F,
  $74,$20,$62,$65,$20,$72,$75,$6E,$20,$69,$6E,$20,$44,$4F,$53,$20,
  $6D,$6F,$64,$65,$2E,$0D,$0D,$0A,$24,$00,$00,$00,$00,$00,$00,$00,
  $50,$45,$00,$00);

{****************************************************************************
                                 Helpers
****************************************************************************}

    function djencodesechdrflags(aoptions:TObjSectionOptions):longword;
      begin
        if (oso_load in aoptions) then
          begin
            if oso_executable in aoptions then
              result:=COFF_STYP_TEXT
            else if not(oso_data in aoptions) then
              result:=COFF_STYP_BSS
            else
              result:=COFF_STYP_DATA;
          end
        else
          result:=COFF_STYP_REG;
      end;


    function djdecodesechdrflags(const aname:string;flags:longword):TObjSectionOptions;
      begin
        result:=[];
        if flags and COFF_STYP_TEXT<>0 then
          result:=[oso_data,oso_load,oso_executable]
        else if flags and COFF_STYP_BSS<>0 then
          result:=[oso_load]
        else if flags and COFF_STYP_DATA<>0 then
          result:=[oso_data,oso_load]
        else
          result:=[oso_data]
      end;


    function peencodesechdrflags(aoptions:TObjSectionOptions;aalign:shortint):longword;
      begin
        result:=0;
        if (oso_load in aoptions) then
          begin
            if oso_executable in aoptions then
              result:=result or PE_SCN_CNT_CODE or PE_SCN_MEM_EXECUTE
            else
              begin
                if (oso_data in aoptions) then
                  result:=result or PE_SCN_CNT_INITIALIZED_DATA
                else
                  result:=result or PE_SCN_CNT_UNINITIALIZED_DATA;
              end;
            if oso_write in aoptions then
              result:=result or PE_SCN_MEM_WRITE or PE_SCN_MEM_READ
            else
              result:=result or PE_SCN_MEM_READ;
          end
        else
          result:=result or PE_SCN_MEM_DISCARDABLE;
        case aalign of
           1 : result:=result or PE_SCN_ALIGN_1BYTES;
           2 : result:=result or PE_SCN_ALIGN_2BYTES;
           4 : result:=result or PE_SCN_ALIGN_4BYTES;
           8 : result:=result or PE_SCN_ALIGN_8BYTES;
          16 : result:=result or PE_SCN_ALIGN_16BYTES;
          32 : result:=result or PE_SCN_ALIGN_32BYTES;
          64 : result:=result or PE_SCN_ALIGN_64BYTES;
          else result:=result or PE_SCN_ALIGN_16BYTES;
        end;
      end;


    procedure pedecodesechdrflags(const aname:string;flags:longword;out aoptions:TObjSectionOptions;out aalign:shortint);
      var
        alignflag : longword;
      begin
        aoptions:=[];
        aalign:=sizeof(aint);
        if flags and PE_SCN_CNT_CODE<>0 then
          include(aoptions,oso_executable);
        if flags and PE_SCN_MEM_DISCARDABLE<>0 then
          include(aoptions,oso_debug);
        if flags and PE_SCN_CNT_UNINITIALIZED_DATA=0 then
          include(aoptions,oso_data);
        if (flags and PE_SCN_LNK_REMOVE<>0) or
           (flags and PE_SCN_MEM_DISCARDABLE<>0) then
          include(aoptions,oso_noload)
        else
          include(aoptions,oso_load);
        { read/write }
        if flags and PE_SCN_MEM_WRITE<>0 then
          include(aoptions,oso_write)
        else
          include(aoptions,oso_readonly);
        { alignment }
        alignflag:=flags and PE_SCN_ALIGN_MASK;
        if alignflag=PE_SCN_ALIGN_64BYTES then
          aalign:=64
        else if alignflag=PE_SCN_ALIGN_32BYTES then
          aalign:=32
        else if alignflag=PE_SCN_ALIGN_16BYTES then
          aalign:=16
        else if alignflag=PE_SCN_ALIGN_8BYTES then
          aalign:=8
        else if alignflag=PE_SCN_ALIGN_4BYTES then
          aalign:=4
        else if alignflag=PE_SCN_ALIGN_2BYTES then
          aalign:=2
        else if alignflag=PE_SCN_ALIGN_1BYTES then
          aalign:=1;
      end;


{****************************************************************************
                               TCoffObjSection
****************************************************************************}

    constructor TCoffObjSection.create(const aname:string;aalign:shortint;aoptions:TObjSectionOptions);
      begin
        inherited create(aname,aalign,aoptions);
      end;


    procedure TCoffObjSection.addsymsizereloc(ofs:aint;p:TObjSymbol;symsize:aint;reloctype:TObjRelocationType);
      begin
        ObjRelocations.Add(TObjRelocation.createsymbolsize(ofs,p,symsize,reloctype));
      end;


    procedure TCoffObjSection.fixuprelocs;
      var
        i        : longint;
        objreloc : TObjRelocation;
        address,
        relocval : aint;
        relocsec : TObjSection;
      begin
        if (ObjRelocations.Count>0) and
           not assigned(data) then
          internalerror(200205183);
        for i:=0 to ObjRelocations.Count-1 do
          begin
            objreloc:=TObjRelocation(ObjRelocations[i]);
            if objreloc.typ=RELOC_ZERO then
              begin
                data.Seek(objreloc.dataoffset);
                data.Write(0,4);
                continue;
              end;
            data.Seek(objreloc.dataoffset);
            data.Read(address,4);
            if assigned(objreloc.symbol) then
              begin
                relocsec:=objreloc.symbol.objsection;
                relocval:=objreloc.symbol.address;
              end
            else
              if assigned(objreloc.objsection) then
                begin
                  relocsec:=objreloc.objsection;
                  relocval:=objreloc.objsection.mempos
                end
            else
              internalerror(200205183);
            { Only debug section are allowed to have }
            if not relocsec.used and
               not(oso_debug in secoptions) then
              internalerror(200603061);
            case objreloc.typ of
              RELOC_RELATIVE  :
                begin
                  address:=address-mempos+relocval;
                  if TCoffObjData(objdata).win32 then
                    dec(address,objreloc.dataoffset+4);
                end;
              RELOC_RVA :
                begin
                  { fixup address when the symbol was known in defined object }
                  if (relocsec.objdata=objdata) then
                    dec(address,TCoffObjSection(relocsec).orgmempos);
                  inc(address,relocval);
                end;
{$ifdef x86_64}
              RELOC_ABSOLUTE32,
{$endif x86_64}
              RELOC_ABSOLUTE :
                begin
                  if oso_common in relocsec.secoptions then
                    dec(address,objreloc.orgsize)
                  else
                    begin
                      { fixup address when the symbol was known in defined object }
                      if (relocsec.objdata=objdata) then
                        dec(address,TCoffObjSection(relocsec).orgmempos);
                    end;
                  inc(address,relocval);
                  inc(address,relocsec.objdata.imagebase);
                end;
              else
                internalerror(200604014);
            end;
            data.Seek(objreloc.dataoffset);
            data.Write(address,4);
          end;
      end;



{****************************************************************************
                               TDJCoffObjSection
****************************************************************************}

    constructor TDJCoffObjSection.create(const aname:string;aalign:shortint;aoptions:TObjSectionOptions);
      begin
        inherited create(aname,aalign,aoptions);
      end;


{****************************************************************************
                               TPECoffObjSection
****************************************************************************}

    constructor TPECoffObjSection.create(const aname:string;aalign:shortint;aoptions:TObjSectionOptions);
      begin
        inherited create(aname,aalign,aoptions);
      end;


{****************************************************************************
                                TCoffObjData
****************************************************************************}

    constructor TCoffObjData.createcoff(const n:string;awin32:boolean;acObjSection:TObjSectionClass);
      begin
        inherited create(n);
        CObjSection:=ACObjSection;
        win32:=awin32;
        { we need at least the following 3 ObjSections }
        createsection(sec_code,'');
        createsection(sec_data,'');
        createsection(sec_bss,'');
      end;


    destructor TCoffObjData.destroy;
      begin
        inherited destroy;
      end;


    function TCoffObjData.sectionname(atype:TAsmSectiontype;const aname:string):string;
      var
        secname : string;
      begin
        secname:=coffsecnames[atype];
        if use_smartlink_section and
           (aname<>'') then
          result:=secname+'$'+aname
        else
          result:=secname;
      end;


    procedure TCoffObjData.CreateDebugSections;
      begin
        if target_dbg.id=dbg_stabs then
          begin
            stabssec:=createsection(sec_stab,'');
            stabstrsec:=createsection(sec_stabstr,'');
          end;
      end;


    procedure TCoffObjData.writereloc(data,len:aint;p:TObjSymbol;reloctype:TObjRelocationType);
      var
        curraddr,
        symaddr : aint;
      begin
        if CurrObjSec=nil then
          internalerror(200403072);
        if assigned(p) then
          begin
            { current address }
            curraddr:=CurrObjSec.mempos+CurrObjSec.Size;
            { external/common symbols don't have a fixed memory position yet }
            if (p.bind=AB_COMMON) then
              begin
                { For go32v2 we need to use the size as address }
                if not win32 then
                  symaddr:=p.size
                else
                  symaddr:=0;
              end
            else
              symaddr:=p.address;
            { no symbol relocation need inside a section }
            if (p.objsection=CurrObjSec) and
               (p.bind<>AB_COMMON) then
              begin
                case reloctype of
                  RELOC_ABSOLUTE :
                    begin
                      CurrObjSec.addsectionreloc(curraddr,CurrObjSec,RELOC_ABSOLUTE);
                      inc(data,symaddr);
                    end;
                  RELOC_RELATIVE :
                    begin
                      inc(data,symaddr-len-CurrObjSec.Size);
                    end;
                  RELOC_RVA :
                    begin
                      CurrObjSec.addsectionreloc(curraddr,CurrObjSec,RELOC_RVA);
                      inc(data,symaddr);
                    end;
                  else
                    internalerror(200604013);
                end;
              end
            else
              begin
                if (p.objsection<>nil) and
                   (p.bind<>AB_COMMON) and
                   (reloctype<>RELOC_RELATIVE) then
                  CurrObjSec.addsectionreloc(curraddr,p.objsection,reloctype)
                else
                  CurrObjSec.addsymreloc(curraddr,p,reloctype);
                if (not win32) or
                   ((reloctype<>RELOC_RELATIVE) and (p.objsection<>nil)) then
                  inc(data,symaddr);
                if reloctype=RELOC_RELATIVE then
                  begin
                    if win32 then
                      dec(data,len-4)
                    else
                      dec(data,len+CurrObjSec.Size);
                  end;
              end;
          end
        else
          begin
            if reloctype=RELOC_RVA then
              internalerror(200603033);
          end;
        CurrObjSec.write(data,len);
      end;


    procedure TCoffObjData.writestab(offset:aint;ps:TObjSymbol;nidx,nother:byte;ndesc:word;p:pchar);
      const
        N_SourceFile = $64;
        N_IncludeFile = $84;
      var
        stab : TObjStabEntry;
        stabstrlen : longint;
        curraddr : aint;
{$ifdef optimizestabs}
        hs : string;
{$endif optimizestabs}
      begin
        if not assigned(StabsSec) then
          internalerror(200602256);
        { Win32 does not need an offset if a symbol relocation is used }
        if win32 and
           assigned(ps) and
           (ps.bind<>AB_LOCAL) then
          offset:=0;
        if assigned(p) and (p[0]<>#0) then
          begin
            stabstrlen:=strlen(p);
{$ifdef optimizestabs}
            StabStrEntry:=nil;
            if (nidx=N_SourceFile) or (nidx=N_IncludeFile) then
              begin
                hs:=strpas(p);
                StabstrEntry:=StabStrDict.Search(hs);
                if not assigned(StabstrEntry) then
                  begin
                    StabstrEntry:=TStabStrEntry.Create(hs);
                    StabstrEntry:=StabStrSec.Size;
                    StabStrDict.Insert(StabstrEntry);
                    { generate new stab }
                    StabstrEntry:=nil;
                  end;
              end;
            if assigned(StabstrEntry) then
              stab.strpos:=StabstrEntry.strpos
            else
{$endif optimizestabs}
              begin
                stab.strpos:=StabStrSec.Size;
                StabStrSec.write(p^,stabstrlen+1);
              end;
          end
        else
          stab.strpos:=0;
        stab.ntype:=nidx;
        stab.ndesc:=ndesc;
        stab.nother:=nother;
        stab.nvalue:=offset;
        StabsSec.write(stab,sizeof(stab));
        if assigned(ps) then
         begin
           { current address }
           curraddr:=StabsSec.mempos+StabsSec.Size;
           if DLLSource and RelocSection then
            { avoid relocation in the .stab section
              because it ends up in the .reloc section instead }
            StabsSec.addsymreloc(curraddr-4,ps,RELOC_RVA)
           else
            StabsSec.addsymreloc(curraddr-4,ps,RELOC_ABSOLUTE);
         end;
      end;


    procedure TCoffObjData.afteralloc;
      var
        mempos : aint;
        i      : longint;
      begin
        inherited afteralloc;
        { DJ Coff requires mempositions }
        if not win32 then
          begin
            mempos:=0;
            for i:=0 to ObjSectionList.Count-1 do
              TObjSection(ObjSectionList[i]).setmempos(mempos);
          end;
      end;


{****************************************************************************
                                TDJCoffObjData
****************************************************************************}

    constructor TDJCoffObjData.create(const n:string);
      begin
        inherited createcoff(n,false,TDJCoffObjSection);
      end;


{****************************************************************************
                                TPECoffObjData
****************************************************************************}

    constructor TPECoffObjData.create(const n:string);
      begin
        inherited createcoff(n,true,TPECoffObjSection);
      end;


{****************************************************************************
                                TCoffObjOutput
****************************************************************************}

    constructor TCoffObjOutput.createcoff(AWriter:TObjectWriter;awin32:boolean);
      begin
        inherited create(AWriter);
        win32:=awin32;
      end;


    destructor TCoffObjOutput.destroy;
      begin
        if assigned(FCoffSyms) then
          FCoffSyms.free;
        if assigned(FCoffStrs) then
          FCoffStrs.free;
        inherited destroy;
      end;


    procedure TCoffObjOutput.write_symbol(const name:string;value:aint;section:smallint;typ,aux:byte);
      var
        sym : coffsymbol;
      begin
        FillChar(sym,sizeof(sym),0);
        { symbolname }
        if length(name)>8 then
          begin
            sym.strpos:=FCoffStrs.size+4;
            FCoffStrs.writestr(name);
            FCoffStrs.writestr(#0);
          end
        else
          move(name[1],sym.name,length(name));
        sym.value:=value;
        sym.section:=section;
        sym.typ:=typ;
        sym.aux:=aux;
        inc(symidx);
        FCoffSyms.write(sym,sizeof(sym));
      end;


    procedure TCoffObjOutput.section_write_symbol(p:TObject;arg:pointer);
      var
        secrec : coffsectionrec;
      begin
        with TCoffObjSection(p) do
          begin
            secidx:=symidx div 2;
            secsymidx:=symidx;
            write_symbol(name,mempos,secidx,COFF_SYM_SECTION,1);
            { AUX }
            fillchar(secrec,sizeof(secrec),0);
            secrec.len:=Size;
            secrec.nrelocs:=ObjRelocations.count;
            inc(symidx);
            FCoffSyms.write(secrec,sizeof(secrec));
          end;
      end;


    procedure TCoffObjOutput.section_write_relocs(p:TObject;arg:pointer);
      var
        i    : longint;
        rel  : coffreloc;
        objreloc : TObjRelocation;
      begin
        for i:=0 to TObjSection(p).ObjRelocations.Count-1 do
          begin
            objreloc:=TObjRelocation(TObjSection(p).ObjRelocations[i]);
            rel.address:=objreloc.dataoffset;
            if assigned(objreloc.symbol) then
              begin
                if (objreloc.symbol.bind=AB_LOCAL) then
                  rel.sym:=objreloc.symbol.objsection.secsymidx
                else
                  begin
                    if objreloc.symbol.symidx=-1 then
                      internalerror(200602233);
                    rel.sym:=objreloc.symbol.symidx;
                  end;
              end
            else
              begin
                if objreloc.objsection<>nil then
                  rel.sym:=objreloc.objsection.secsymidx
                else
                  rel.sym:=0;
              end;
            case objreloc.typ of
{$ifdef arm}
              RELOC_ABSOLUTE :
                ;
{$endif arm}
{$ifdef i386}
              RELOC_RELATIVE :
                rel.reloctype:=R_PCRLONG;
              RELOC_ABSOLUTE :
                rel.reloctype:=R_DIR32;
              RELOC_RVA :
                rel.reloctype:=R_IMAGEBASE;
{$endif i386}
{$ifdef x86_64}
              RELOC_RELATIVE :
                rel.reloctype:=IMAGE_REL_AMD64_REL32;
              RELOC_ABSOLUTE32 :
                rel.reloctype:=IMAGE_REL_AMD64_ADDR32;
              RELOC_ABSOLUTE :
                rel.reloctype:=IMAGE_REL_AMD64_ADDR64;
              RELOC_RVA :
                rel.reloctype:=IMAGE_REL_AMD64_ADDR32NB;
{$endif x86_64}
              else
                internalerror(200603311);
            end;
            FWriter.write(rel,sizeof(rel));
          end;
      end;


    procedure TCoffObjOutput.create_symbols(data:TObjData);
      var
        filename   : string[18];
        sectionval : word;
        globalval  : byte;
        i          : longint;
        value      : aint;
        objsym     : TObjSymbol;
      begin
        with TCoffObjData(data) do
         begin
           symidx:=0;
           { The `.file' record, and the file name auxiliary record }
           write_symbol('.file', 0, -2, COFF_SYM_FILE, 1);
           fillchar(filename,sizeof(filename),0);
           filename:=SplitFileName(current_module.mainsource^);
           inc(symidx);
           FCoffSyms.write(filename[1],sizeof(filename)-1);
           { Sections }
           ObjSectionList.ForEachCall(@section_write_symbol,nil);
           { ObjSymbols }
           for i:=0 to ObjSymbolList.Count-1 do
             begin
               objsym:=TObjSymbol(ObjSymbolList[i]);
               case objsym.bind of
                 AB_GLOBAL :
                   begin
                     globalval:=2;
                     sectionval:=TCoffObjSection(objsym.objsection).secidx;
                     value:=objsym.address;
                   end;
                 AB_LOCAL :
                   begin
                     globalval:=3;
                     sectionval:=TCoffObjSection(objsym.objsection).secidx;
                     value:=objsym.address;
                   end;
                 else
                   begin
                     globalval:=2;
                     sectionval:=0;
                     value:=objsym.size;
                   end;
               end;
               { symbolname }
               objsym.symidx:=symidx;
               write_symbol(objsym.name,value,sectionval,globalval,0);
             end;
         end;
      end;


    procedure TCoffObjOutput.section_set_datapos(p:TObject;arg:pointer);
      begin
        TObjSection(p).setdatapos(paint(arg)^);
      end;


    procedure TCoffObjOutput.section_set_reloc_datapos(p:TObject;arg:pointer);
      begin
        TCoffObjSection(p).coffrelocpos:=paint(arg)^;
        inc(paint(arg)^,sizeof(coffreloc)*TObjSection(p).ObjRelocations.count);
      end;


    procedure TCoffObjOutput.section_write_header(p:TObject;arg:pointer);
      var
        sechdr   : coffsechdr;
        s        : string;
        strpos   : Aint;
      begin
        with TCoffObjSection(p) do
          begin
            fillchar(sechdr,sizeof(sechdr),0);
            s:=name;
            if length(s)>8 then
             begin
               strpos:=FCoffStrs.size+4;
               FCoffStrs.writestr(s);
               FCoffStrs.writestr(#0);
               s:='/'+ToStr(strpos);
             end;
            move(s[1],sechdr.name,length(s));
            if not win32 then
              begin
                sechdr.rvaofs:=mempos;
                sechdr.vsize:=mempos;
              end
            else
              begin
                if not(oso_data in secoptions) then
                  sechdr.vsize:=Size;
              end;
            sechdr.DataSize:=size;
            if (Size>0) and
               (oso_data in secoptions) then
              sechdr.datapos:=datapos;
            sechdr.nrelocs:=ObjRelocations.count;
            sechdr.relocpos:=coffrelocpos;
            if win32 then
              sechdr.flags:=peencodesechdrflags(secoptions,secalign)
            else
              sechdr.flags:=djencodesechdrflags(secoptions);
            FWriter.write(sechdr,sizeof(sechdr));
          end;
      end;


    procedure TCoffObjOutput.section_write_data(p:TObject;arg:pointer);
      begin
        with TObjSection(p) do
          begin
            if assigned(data) then
              begin
                FWriter.writezeros(dataalignbytes);
                if Datapos<>FWriter.ObjSize then
                  internalerror(200603052);
                FWriter.writearray(data);
              end;
          end;
      end;


    function TCoffObjOutput.writedata(data:TObjData):boolean;
      var
        orgdatapos,
        datapos,
        sympos   : aint;
        i        : longint;
        gotreloc : boolean;
        header   : coffheader;
      begin
        result:=false;
        FCoffSyms:=TDynamicArray.Create(symbolresize);
        FCoffStrs:=TDynamicArray.Create(strsresize);
        with TCoffObjData(data) do
         begin
           { Create Symbol Table }
           create_symbols(data);

           { Calculate the filepositions }
           datapos:=sizeof(coffheader)+sizeof(coffsechdr)*ObjSectionList.Count;
           { Sections first }
           ObjSectionList.ForEachCall(@section_set_datapos,@datapos);
           { relocs }
           orgdatapos:=datapos;
           ObjSectionList.ForEachCall(@section_set_reloc_datapos,@datapos);
           gotreloc:=(orgdatapos<>datapos);
           { Symbols }
           sympos:=datapos;

           { Generate COFF header }
           fillchar(header,sizeof(coffheader),0);
           header.mach:=COFF_MAGIC;
           header.nsects:=ObjSectionList.Count;
           header.sympos:=sympos;
           header.syms:=symidx;
           if win32 then
             begin
               header.flag:=PE_FILE_BYTES_REVERSED_LO or PE_FILE_32BIT_MACHINE or
                            PE_FILE_LINE_NUMS_STRIPPED or PE_FILE_LOCAL_SYMS_STRIPPED;
               if not gotreloc then
                 header.flag:=header.flag or PE_FILE_RELOCS_STRIPPED;
             end
           else
             begin
               header.flag:=COFF_FLAG_AR32WR or COFF_FLAG_NOLINES or COFF_FLAG_NOLSYMS;
               if not gotreloc then
                 header.flag:=header.flag or COFF_FLAG_NORELOCS;
             end;
           FWriter.write(header,sizeof(header));
           { Section headers }
           ObjSectionList.ForEachCall(@section_write_header,nil);
           { ObjSections }
           ObjSectionList.ForEachCall(@section_write_data,nil);
           { Relocs }
           ObjSectionList.ForEachCall(@section_write_relocs,nil);
           { ObjSymbols }
           if Sympos<>FWriter.ObjSize then
             internalerror(200603051);
           FWriter.writearray(FCoffSyms);
           { Strings }
           i:=FCoffStrs.size+4;
           FWriter.write(i,4);
           FWriter.writearray(FCoffStrs);
         end;
        FCoffStrs.Free;
        FCoffStrs:=nil;
        FCoffSyms.Free;
        FCoffSyms:=nil;
      end;


    constructor TDJCoffObjOutput.create(AWriter:TObjectWriter);
      begin
        inherited createcoff(AWriter,false);
        cobjdata:=TDJCoffObjData;
      end;


    constructor TPECoffObjOutput.create(AWriter:TObjectWriter);
      begin
        inherited createcoff(AWriter,true);
        cobjdata:=TPECoffObjData;
      end;


{****************************************************************************
                                TCoffObjInput
****************************************************************************}

    constructor TCoffObjInput.createcoff(awin32:boolean);
      begin
        inherited create;
        win32:=awin32;
        FSymTbl:=nil;
      end;


    destructor TCoffObjInput.destroy;
      begin
        if assigned(FCoffSyms) then
          FCoffSyms.free;
        if assigned(FCoffStrs) then
          FCoffStrs.free;
        if assigned(FSymTbl) then
          freemem(FSymTbl);
        if assigned(FSecTbl) then
          freemem(FSecTbl);
        inherited destroy;
      end;


    function TCoffObjInput.GetSection(secidx:longint):TObjSection;
      begin
        result:=nil;
        if (secidx<1) or (secidx>FSecCount) then
          begin
            InputError('Failed reading coff file, invalid section index');
            exit;
          end;
        result:=FSecTbl^[secidx];
      end;


    function TCoffObjInput.Read_str(strpos:longint):string;
      begin
        FCoffStrs.Seek(strpos-4);
        FCoffStrs.Read(result[1],255);
        result[255]:=#0;
        result[0]:=chr(strlen(@result[1]));
        if result='' then
          Internalerror(200205172);
      end;


    procedure TCoffObjInput.read_relocs(s:TCoffObjSection);
      var
        rel      : coffreloc;
        rel_type : TObjRelocationType;
        i        : longint;
        p        : TObjSymbol;
      begin
        for i:=1 to s.coffrelocs do
         begin
           FReader.read(rel,sizeof(rel));
           case rel.reloctype of
{$ifdef arm}
             R_IMAGEBASE :
               ;
{$endif arm}
{$ifdef i386}
             R_PCRLONG :
               rel_type:=RELOC_RELATIVE;
             R_DIR32 :
               rel_type:=RELOC_ABSOLUTE;
             R_IMAGEBASE :
               rel_type:=RELOC_RVA;
{$endif i386}
{$ifdef x86_64}
             IMAGE_REL_AMD64_REL32:
               rel_type:=RELOC_RELATIVE;
             IMAGE_REL_AMD64_ADDR32:
               rel_type:=RELOC_ABSOLUTE32;
             IMAGE_REL_AMD64_ADDR64:
               rel_type:=RELOC_ABSOLUTE;
             IMAGE_REL_AMD64_ADDR32NB:
               rel_type:=RELOC_RVA;
{$endif x86_64}
           else
             begin
               InputError('Failed reading coff file, illegal reloctype $'+system.hexstr(rel.reloctype,4));
               exit;
             end;
           end;

           p:=FSymTbl^[rel.sym].sym;
           if assigned(p) then
             s.addsymsizereloc(rel.address-s.mempos,p,FSymTbl^[rel.sym].orgsize,rel_type)
           else
            begin
              InputError('Failed reading coff file, can''t resolve symbol of relocation');
              exit;
            end;
         end;
      end;


    procedure TCoffObjInput.read_symbols(objdata:TObjData);
      var
        size,
        address,
        nsyms,
        symidx    : aint;
        i         : longint;
        sym       : coffsymbol;
        objsym    : TObjSymbol;
        bind      : Tasmsymbind;
        strname   : string;
        auxrec    : array[0..17] of byte;
        objsec    : TObjSection;
      begin
        with TCoffObjData(objdata) do
         begin
           nsyms:=FCoffSyms.Size div sizeof(CoffSymbol);
           { Allocate memory for symidx -> TObjSymbol table }
           GetMem(FSymTbl,nsyms*sizeof(TObjSymbolrec));
           FillChar(FSymTbl^,nsyms*sizeof(TObjSymbolrec),0);
           { Load the Symbols }
           FCoffSyms.Seek(0);
           symidx:=0;
           while (symidx<nsyms) do
            begin
              FCoffSyms.Read(sym,sizeof(sym));
              if plongint(@sym.name)^<>0 then
                begin
                  move(sym.name,strname[1],8);
                  strname[9]:=#0;
                  strname[0]:=chr(strlen(@strname[1]));
                  if strname='' then
                    Internalerror(200205171);
                end
              else
                strname:=Read_str(sym.strpos);
              bind:=AB_EXTERNAL;
              size:=0;
              address:=0;
              objsym:=nil;
              objsec:=nil;
              case sym.typ of
                COFF_SYM_GLOBAL :
                  begin
                    if sym.section=0 then
                     begin
                       if sym.value=0 then
                        bind:=AB_EXTERNAL
                       else
                        begin
                          bind:=AB_COMMON;
                          size:=sym.value;
                        end;
                     end
                    else
                     begin
                       bind:=AB_GLOBAL;
                       objsec:=GetSection(sym.section);
                       if sym.value>=objsec.mempos then
                         address:=sym.value-objsec.mempos;
                     end;
                    objsym:=CreateSymbol(strname);
                    objsym.bind:=bind;
                    objsym.typ:=AT_FUNCTION;
                    objsym.objsection:=objsec;
                    objsym.offset:=address;
                    objsym.size:=size;
                    { Register in ObjSection }
                    if assigned(objsec) then
                      objsec.AddSymbolDefine(objsym);
                  end;
                COFF_SYM_LABEL,
                COFF_SYM_LOCAL :
                  begin
                    { do not add constants (section=-1) }
                    if sym.section<>-1 then
                     begin
                       bind:=AB_LOCAL;
                       objsec:=GetSection(sym.section);
                       if sym.value>=objsec.mempos then
                         address:=sym.value-objsec.mempos;
                       objsym:=CreateSymbol(strname);
                       objsym.bind:=bind;
                       objsym.typ:=AT_FUNCTION;
                       objsym.objsection:=objsec;
                       objsym.offset:=address;
                       objsym.size:=size;
                     end;
                  end;
                COFF_SYM_SECTION :
                  begin
                    if sym.section=0 then
                      InputError('Failed reading coff file, illegal section');
                    objsec:=GetSection(sym.section);
                    if sym.value>=objsec.mempos then
                      address:=sym.value-objsec.mempos;
                    objsym:=CreateSymbol(strname);
                    objsym.bind:=AB_LOCAL;
                    objsym.typ:=AT_FUNCTION;
                    objsym.objsection:=objsec;
                    objsym.offset:=address;
                    objsym.size:=size;
                  end;
                COFF_SYM_FUNCTION,
                COFF_SYM_FILE :
                  ;
                else
                  internalerror(200602232);
              end;
              FSymTbl^[symidx].sym:=objsym;
              FSymTbl^[symidx].orgsize:=size;
              { read aux records }
              for i:=1 to sym.aux do
               begin
                 FCoffSyms.Read(auxrec,sizeof(auxrec));
                 inc(symidx);
               end;
              inc(symidx);
            end;
         end;
      end;


    procedure TCoffObjInput.ObjSections_read_data(p:TObject;arg:pointer);
      begin
        with TCoffObjSection(p) do
          begin
            { Skip debug sections }
            if (cs_link_strip in aktglobalswitches) and
               (oso_debug in secoptions) then
              exit;

            if assigned(data) then
              begin
                Reader.Seek(datapos);
                if not Reader.ReadArray(data,Size) then
                  begin
                    Comment(V_Error,'Error reading coff file, can''t read object data');
                    exit;
                  end;
              end;
          end;
      end;


    procedure TCoffObjInput.ObjSections_read_relocs(p:TObject;arg:pointer);
      begin
        with TCoffObjSection(p) do
          begin
            { Skip debug sections }
            if (cs_link_strip in aktglobalswitches) and
               (oso_debug in secoptions) then
              exit;

            if coffrelocs>0 then
              begin
                Reader.Seek(coffrelocpos);
                read_relocs(TCoffObjSection(p));
              end;
          end;
      end;


    function  TCoffObjInput.readObjData(objdata:TObjData):boolean;
      var
        secalign : shortint;
        strsize,
        strpos,
        i        : longint;
        code     : longint;
        objsec   : TCoffObjSection;
        secoptions : TObjSectionOptions;
        header   : coffheader;
        sechdr   : coffsechdr;
        secname  : string;
        secnamebuf : array[0..15] of char;
      begin
        result:=false;
        FCoffSyms:=TDynamicArray.Create(symbolresize);
        FCoffStrs:=TDynamicArray.Create(strsresize);
        with TCoffObjData(objdata) do
         begin
           { Read COFF header }
           if not reader.read(header,sizeof(coffheader)) then
             begin
               Comment(V_Error,'Error reading coff file, can''t read header: '+reader.filename);
               exit;
             end;
           if header.mach<>COFF_MAGIC then
             begin
               Comment(V_Error,'Not a coff file, illegal magic: '+reader.filename);
               exit;
             end;
           { Strings }
           Reader.Seek(header.sympos+header.syms*sizeof(CoffSymbol));
           if not Reader.Read(strsize,4) then
             begin
               Comment(V_Error,'Error reading coff file');
               exit;
             end;
           if strsize<4 then
             begin
               Comment(V_Error,'Error reading coff file');
               exit;
             end;
           if not Reader.ReadArray(FCoffStrs,Strsize-4) then
             begin
               Comment(V_Error,'Error reading coff file: '+reader.filename);
               exit;
             end;
           { Section headers }
           { Allocate SecIdx -> TObjSection table, secidx is 1-based }
           FSecCount:=header.nsects;
           GetMem(FSecTbl,(header.nsects+1)*sizeof(TObjSection));
           FillChar(FSecTbl^,(header.nsects+1)*sizeof(TObjSection),0);
           reader.Seek(sizeof(coffheader)+header.opthdr);
           for i:=1 to header.nsects do
             begin
               if not reader.read(sechdr,sizeof(sechdr)) then
                begin
                  Comment(V_Error,'Error reading coff file, can''t read section header: '+reader.filename);
                  exit;
                end;
               move(sechdr.name,secnamebuf,8);
               secnamebuf[8]:=#0;
               secname:=strpas(secnamebuf);
               if secname[1]='/' then
                 begin
                   Val(Copy(secname,2,8),strpos,code);
                   if code=0 then
                     secname:=Read_str(strpos)
                   else
                     begin
                       Comment(V_Error,'Error reading section headers coff file');
                       secname:='error';
                     end;
                 end;
               if win32 then
                 pedecodesechdrflags(secname,sechdr.flags,secoptions,secalign)
               else
                 begin
                   djdecodesechdrflags(secname,sechdr.flags);
                   secalign:=sizeof(aint);
                 end;
{$warning TODO idata keep can maybe replaced with grouping of text and idata}
               if (Copy(secname,1,6)='.idata') or
                  (Copy(secname,1,6)='.rsrc') then
                 include(secoptions,oso_keep);
               objsec:=TCoffObjSection(createsection(secname,secalign,secoptions));
               FSecTbl^[i]:=objsec;
               if not win32 then
                 objsec.mempos:=sechdr.rvaofs;
               objsec.orgmempos:=sechdr.rvaofs;
               objsec.coffrelocs:=sechdr.nrelocs;
               objsec.coffrelocpos:=sechdr.relocpos;
               objsec.datapos:=sechdr.datapos;
               objsec.Size:=sechdr.dataSize;
             end;
           { ObjSymbols }
           Reader.Seek(header.sympos);
           if not Reader.ReadArray(FCoffSyms,header.syms*sizeof(CoffSymbol)) then
             begin
               Comment(V_Error,'Error reading coff file');
               exit;
             end;
           { Insert all ObjSymbols }
           read_symbols(objdata);
           { Section Data }
           ObjSectionList.ForEachCall(@objsections_read_data,nil);
           { Relocs }
           ObjSectionList.ForEachCall(@objsections_read_relocs,nil);
         end;
        FCoffStrs.Free;
        FCoffStrs:=nil;
        FCoffSyms.Free;
        FCoffSyms:=nil;
        result:=true;
      end;


    constructor TDJCoffObjInput.create;
      begin
        inherited createcoff(false);
        cobjdata:=TDJCoffObjData;
      end;


    constructor TPECoffObjInput.create;
      begin
        inherited createcoff(true);
        cobjdata:=TPECoffObjData;
      end;


{****************************************************************************
                              TCoffexesection
****************************************************************************}


    constructor TCoffExeSection.createcoff(const n:string;awin32:boolean);
      begin
        inherited create(n);
        win32:=awin32;
      end;


    constructor TDJCoffExeSection.create(const n:string);
      begin
        inherited createcoff(n,false);
      end;


    constructor TPECoffExeSection.create(const n:string);
      begin
        inherited createcoff(n,false);
      end;


{****************************************************************************
                              TCoffexeoutput
****************************************************************************}

    constructor TCoffexeoutput.createcoff(awin32:boolean);
      begin
        inherited create;
        win32:=awin32;
        if win32 then
          imagebase:=$400000;
      end;


    procedure TCoffexeoutput.write_symbol(const name:string;value:aint;section:smallint;typ,aux:byte);
      var
        sym : coffsymbol;
      begin
        FillChar(sym,sizeof(sym),0);
        if length(name)>8 then
          begin
             sym.strpos:=FCoffStrs.size+4;
             FCoffStrs.writestr(name);
             FCoffStrs.writestr(#0);
          end
        else
          move(name[1],sym.name,length(name));
        sym.value:=value;
        sym.section:=section;
        sym.typ:=typ;
        sym.aux:=aux;
        FWriter.write(sym,sizeof(sym));
      end;


    procedure TCoffexeoutput.globalsyms_write_symbol(p:TObject;arg:pointer);
      var
        value  : aint;
        globalval : byte;
        exesec : TExeSection;
      begin
        if not assigned(texesymbol(p).objsymbol) then
          internalerror(200603053);
        with texesymbol(p).objsymbol do
          begin
            exesec:=TExeSection(objsection.exesection);
            if not assigned(exesec) then
              internalerror(200602255);
            if bind=AB_LOCAL then
              globalval:=3
            else
              globalval:=2;
            { reloctype address to the section in the executable }
            value:=address-exesec.mempos;
            write_symbol(name,value,exesec.secsymidx,globalval,0);
          end;
      end;


    procedure TCoffexeoutput.ExeSections_write_header(p:TObject;arg:pointer);
      var
        sechdr    : coffsechdr;
      begin
        with tExeSection(p) do
          begin
            fillchar(sechdr,sizeof(sechdr),0);
            move(name[1],sechdr.name,length(name));
            sechdr.rvaofs:=mempos;
            sechdr.vsize:=mempos;
            if win32 then
              begin
                sechdr.rvaofs:=mempos;
                sechdr.vsize:=align(Size,$100);
              end
            else
              begin
                sechdr.rvaofs:=mempos;
                sechdr.vsize:=mempos;
              end;
            if oso_data in SecOptions then
              begin
                sechdr.dataSize:=Size;
                sechdr.datapos:=datapos;
              end
            else
              sechdr.dataSize:=Size;
            sechdr.nrelocs:=0;
            sechdr.relocpos:=0;
            if win32 then
              sechdr.flags:=peencodesechdrflags(SecOptions,SecAlign)
            else
              sechdr.flags:=djencodesechdrflags(SecOptions);
            FWriter.write(sechdr,sizeof(sechdr));
          end;
      end;


    procedure TCoffexeoutput.ExeSections_pass2_header(p:TObject;arg:pointer);
      begin
        with TExeSection(p) do
          begin
            inc(plongint(arg)^);
            secsymidx:=plongint(arg)^;
          end;
      end;


    procedure Tcoffexeoutput.ExeSections_write_Data(p:TObject;arg:pointer);
      var
        objsec : TObjSection;
        i      : longint;
      begin
        with texesection(p) do
          begin
            if oso_data in secoptions then
              begin
                FWriter.Writezeros(Align(FWriter.Size,SectionDataAlign)-FWriter.Size);
                for i:=0 to ObjSectionList.Count-1 do
                  begin
                    objsec:=TObjSection(ObjSectionList[i]);
                    if not assigned(objsec.data) then
                      internalerror(200603042);
                    FWriter.writezeros(objsec.dataalignbytes);
                    if objsec.DataPos<>FWriter.Size then
                      internalerror(200602251);
                    FWriter.writearray(objsec.data);
                  end;
              end;
          end;
      end;


    procedure tcoffexeoutput.CalcPos_Header;
      var
        stubsize,
        optheadersize : longint;
      begin
        if win32 then
          begin
            stubsize:=sizeof(win32stub);
            optheadersize:=sizeof(coffpeoptheader);
          end
        else
          begin
            stubsize:=sizeof(go32v2stub);
            optheadersize:=sizeof(coffdjoptheader);
          end;
        { retrieve amount of ObjSections }
        nsects:=0;
        ExeSections.ForEachCall(@ExeSections_pass2_header,@nsects);
        { calculate start positions after the headers }
        currdatapos:=stubsize+optheadersize+sizeof(coffsechdr)*nsects;
        currmempos:=stubsize+optheadersize+sizeof(coffsechdr)*nsects;
      end;


    procedure tcoffexeoutput.CalcPos_Symbols;
      begin
        nsyms:=0;
        sympos:=0;
        if not(cs_link_strip in aktglobalswitches) then
         begin
           nsyms:=ExeSymbolList.Count;
           sympos:=CurrDataPos;
           inc(CurrDataPos,sizeof(coffsymbol)*nsyms);
         end;
      end;


    function TCoffexeoutput.writedata:boolean;
      var
        i           : longint;
        header      : coffheader;
        djoptheader : coffdjoptheader;
        peoptheader : coffpeoptheader;
        rsrcexesec,
        idataexesec,
        textExeSec,
        dataExeSec,
        bssExeSec   : TExeSection;
      begin
        result:=false;
        FCoffSyms:=TDynamicArray.Create(symbolresize);
        FCoffStrs:=TDynamicArray.Create(strsresize);
        textExeSec:=FindExeSection('.text');
        dataExeSec:=FindExeSection('.data');
        bssExeSec:=FindExeSection('.bss');
        if not assigned(TextExeSec) or
           not assigned(DataExeSec) or
           not assigned(BSSExeSec) then
          internalerror(200602231);
        { Stub }
        if win32 then
          FWriter.write(win32stub,sizeof(win32stub))
        else
          FWriter.write(go32v2stub,sizeof(go32v2stub));
        { COFF header }
        fillchar(header,sizeof(header),0);
        header.mach:=COFF_MAGIC;
        header.nsects:=nsects;
        header.sympos:=sympos;
        header.syms:=nsyms;
        if win32 then
          header.opthdr:=sizeof(coffpeoptheader)
        else
          header.opthdr:=sizeof(coffdjoptheader);
        if win32 then
          begin
            header.flag:=PE_FILE_EXECUTABLE_IMAGE or PE_FILE_RELOCS_STRIPPED or
                         {PE_FILE_BYTES_REVERSED_LO or }
                         PE_FILE_LINE_NUMS_STRIPPED;
            if FindExeSection('.stab')=nil then
              header.flag:=header.flag or PE_FILE_DEBUG_STRIPPED;
            if (cs_link_strip in aktglobalswitches) then
              header.flag:=header.flag or PE_FILE_LOCAL_SYMS_STRIPPED;
          end
        else
          header.flag:=COFF_FLAG_AR32WR or COFF_FLAG_EXE or COFF_FLAG_NORELOCS or COFF_FLAG_NOLINES;

        if target_info.system in [system_i386_win32,system_arm_wince,system_i386_wince] then
          header.flag:=header.flag or PE_FILE_32BIT_MACHINE;

        FWriter.write(header,sizeof(header));
        { Optional COFF Header }
        if win32 then
          begin
            fillchar(peoptheader,sizeof(peoptheader),0);
            peoptheader.magic:=COFF_OPT_MAGIC;
            peoptheader.tsize:=TextExeSec.Size;
            peoptheader.dsize:=DataExeSec.Size;
            peoptheader.bsize:=BSSExeSec.Size;
            peoptheader.text_start:=TextExeSec.mempos;
{$ifndef x86_64}
            peoptheader.data_start:=DataExeSec.mempos;
{$endif x86_64}
            peoptheader.entry:=EntrySym.Address;
            peoptheader.ImageBase:=ImageBase;
            peoptheader.SectionAlignment:=SectionMemAlign;
            peoptheader.FileAlignment:=SectionDataAlign;
            peoptheader.MajorOperatingSystemVersion:=4;
            peoptheader.MinorOperatingSystemVersion:=0;
            peoptheader.MajorImageVersion:=dllmajor;
            peoptheader.MinorImageVersion:=dllminor;
            peoptheader.MajorSubsystemVersion:=4;
            peoptheader.MinorSubsystemVersion:=0;
            peoptheader.Win32Version:=0;
            peoptheader.SizeOfImage:=Align(CurrMemPos,SectionMemAlign);
            peoptheader.SizeOfHeaders:=textExeSec.DataPos;
            peoptheader.CheckSum:=0;
            if target_info.system in [system_arm_wince,system_i386_wince] then
              peoptheader.Subsystem:=PE_SUBSYSTEM_WINDOWS_CE_GUI
            else
              if apptype=app_gui then
                peoptheader.Subsystem:=PE_SUBSYSTEM_WINDOWS_GUI
            else
              peoptheader.Subsystem:=PE_SUBSYSTEM_WINDOWS_CUI;
            peoptheader.DllCharacteristics:=0;
            peoptheader.SizeOfStackReserve:=stacksize;
            peoptheader.SizeOfStackCommit:=$1000;
            peoptheader.SizeOfHeapReserve:=$100000;
            peoptheader.SizeOfHeapCommit:=$1000;
            peoptheader.LoaderFlags:=0;
            peoptheader.NumberOfRvaAndSizes:=PE_DATADIR_ENTRIES;
            idataexesec:=FindExeSection('.idata');
            if assigned(idataexesec) then
              begin
                peoptheader.DataDirectory[PE_DATADIR_IDATA].vaddr:=idataexesec.mempos;
                peoptheader.DataDirectory[PE_DATADIR_IDATA].size:=idataexesec.Size;
              end;
            rsrcexesec:=FindExeSection('.rsrc');
            if assigned(rsrcexesec) then
              begin
                peoptheader.DataDirectory[PE_DATADIR_RSRC].vaddr:=rsrcexesec.mempos;
                peoptheader.DataDirectory[PE_DATADIR_RSRC].size:=rsrcexesec.Size;
              end;
            FWriter.write(peoptheader,sizeof(peoptheader));
          end
        else
          begin
            fillchar(djoptheader,sizeof(djoptheader),0);
            djoptheader.magic:=COFF_OPT_MAGIC;
            djoptheader.tsize:=TextExeSec.Size;
            djoptheader.dsize:=DataExeSec.Size;
            djoptheader.bsize:=BSSExeSec.Size;
            djoptheader.text_start:=TextExeSec.mempos;
            djoptheader.data_start:=DataExeSec.mempos;
            djoptheader.entry:=EntrySym.offset;
            FWriter.write(djoptheader,sizeof(djoptheader));
          end;
        { Section headers }
        ExeSections.ForEachCall(@ExeSections_write_header,nil);
        { Section data }
        ExeSections.ForEachCall(@ExeSections_write_data,nil);
        { Optional ObjSymbols }
        if not(cs_link_strip in aktglobalswitches) then
         begin
           if SymPos<>FWriter.Size then
             internalerror(200602252);
           { ObjSymbols }
           ExeSymbolList.ForEachCall(@globalsyms_write_symbol,nil);
           { Strings }
           i:=FCoffStrs.size+4;
           FWriter.write(i,4);
           FWriter.writearray(FCoffStrs);
         end;
        { Release }
        FCoffStrs.Free;
        FCoffSyms.Free;
        result:=true;
      end;


    constructor TDJCoffexeoutput.create;
      begin
        inherited createcoff(false);
        CExeSection:=TDJCoffExeSection;
        CObjData:=TPECoffObjData;
      end;


    constructor TPECoffexeoutput.create;
      begin
        inherited createcoff(true);
        CExeSection:=TPECoffExeSection;
        CObjData:=TPECoffObjData;
      end;


    function TPECoffexeoutput.LoadDLL(const dllname:string):boolean;
      type
       TPECoffExpDir=packed record
         flag,
         stamp      : cardinal;
         Major,
         Minor      : word;
         Name,
         Base,
         NumFuncs,
         NumNames,
         AddrFuncs,
         AddrNames,
         AddrOrds   : cardinal;
       end;
      var
        basedllname : string;
        DLLReader : TObjectReader;
        DosHeader : array[0..$7f] of byte;
        PEMagic   : array[0..3] of byte;
        Header    : CoffHeader;
        peheader  : coffpeoptheader;
        NameOfs,
        newheaderofs : longint;
        expdir    : TPECoffExpDir;
        i,j       : longint;
        found     : boolean;
        sechdr    : CoffSecHdr;
        FuncName  : string;
        exesym    : TExeSymbol;
        textobjsection,
        idata2objsection,
        idata4objsection,
        idata5objsection,
        idata6objsection,
        idata7objsection : TObjSection;

        procedure StartImport;
        var
          idata4label,
          idata5label,
          idata7label : TObjSymbol;
          emptyint : longint;
        begin
          if assigned(exemap) then
            begin
              exemap.Add('');
              exemap.Add('Importing from DLL '+dllname);
            end;
          emptyint:=0;
          textobjsection:=internalobjdata.createsection(sec_code,'');
          idata2objsection:=internalobjdata.createsection(sec_idata2,'');
          idata4objsection:=internalobjdata.createsection(sec_idata4,'');
          idata4label:=internalobjdata.SymbolDefine('__imp_names_'+basedllname,AB_LOCAL,AT_DATA);
          idata5objsection:=internalobjdata.createsection(sec_idata5,'');
          idata5label:=internalobjdata.SymbolDefine('__imp_fixup_'+basedllname,AB_LOCAL,AT_DATA);
          idata6objsection:=internalobjdata.createsection(sec_idata6,'');
          idata7objsection:=internalobjdata.createsection(sec_idata7,'');
          idata7label:=internalobjdata.SymbolDefine('__imp_dll_'+basedllname,AB_LOCAL,AT_DATA);
          { idata2 }
          internalobjdata.SetSection(idata2objsection);
          internalobjdata.writereloc(0,sizeof(longint),idata4label,RELOC_RVA);
          internalobjdata.writebytes(emptyint,sizeof(emptyint));
          internalobjdata.writebytes(emptyint,sizeof(emptyint));
          internalobjdata.writereloc(0,sizeof(longint),idata7label,RELOC_RVA);
          internalobjdata.writereloc(0,sizeof(longint),idata5label,RELOC_RVA);
          { idata7 }
          internalobjdata.SetSection(idata7objsection);
          internalobjdata.writebytes(basedllname[1],length(basedllname));
          internalobjdata.writebytes(emptyint,1);
        end;

        procedure EndImport;
        var
          emptyint : longint;
        begin
          emptyint:=0;
          { idata4 }
          internalobjdata.SetSection(idata4objsection);
          internalobjdata.writebytes(emptyint,sizeof(emptyint));
          if target_info.system=system_x86_64_win64 then
            internalobjdata.writebytes(emptyint,sizeof(emptyint));
          { idata5 }
          internalobjdata.SetSection(idata5objsection);
          internalobjdata.writebytes(emptyint,sizeof(emptyint));
          if target_info.system=system_x86_64_win64 then
            internalobjdata.writebytes(emptyint,sizeof(emptyint));
        end;

        function AddProcImport(const afuncname:string):TObjSymbol;
        const
          jmpopcode : array[0..1] of byte = (
            $ff,$25
          );
          nopopcodes : array[0..1] of byte = (
            $90,$90
          );
        var
          idata5label,
          idata6label : TObjSymbol;
          emptyint : longint;
        begin
          result:=nil;
          emptyint:=0;
          if not assigned(idata2objsection) then
            StartImport;
          if assigned(exemap) then
            exemap.Add(' Importing Function '+afuncname);
          { idata6, import data (ordnr+name) }
          internalobjdata.SetSection(idata6objsection);
          inc(idatalabnr);
          idata6label:=internalobjdata.SymbolDefine('__imp_'+tostr(idatalabnr),AB_LOCAL,AT_DATA);
          internalobjdata.writebytes(emptyint,2);
          internalobjdata.writebytes(afuncname[1],length(afuncname));
          internalobjdata.writebytes(emptyint,1);
          internalobjdata.writebytes(emptyint,align(internalobjdata.CurrObjSec.size,2)-internalobjdata.CurrObjSec.size);
          { idata4, import lookup table }
          internalobjdata.SetSection(idata4objsection);
          internalobjdata.writereloc(0,sizeof(longint),idata6label,RELOC_RVA);
          internalobjdata.writebytes(emptyint,sizeof(emptyint));
          if target_info.system=system_x86_64_win64 then
            internalobjdata.writebytes(emptyint,sizeof(emptyint));
          { idata5, import address table }
          internalobjdata.SetSection(idata5objsection);
          idata5label:=internalobjdata.SymbolDefine('__imp_'+afuncname,AB_LOCAL,AT_DATA);
          internalobjdata.writereloc(0,sizeof(longint),idata6label,RELOC_RVA);
          if target_info.system=system_x86_64_win64 then
            internalobjdata.writebytes(emptyint,sizeof(emptyint));
          { text, jmp }
          internalobjdata.SetSection(textobjsection);
          result:=internalobjdata.SymbolDefine('_'+afuncname,AB_GLOBAL,AT_FUNCTION);
          internalobjdata.writebytes(jmpopcode,sizeof(jmpopcode));
          internalobjdata.writereloc(0,sizeof(aint),idata5label,RELOC_ABSOLUTE);
          internalobjdata.writebytes(nopopcodes,align(internalobjdata.CurrObjSec.size,sizeof(nopopcodes))-internalobjdata.CurrObjSec.size);
        end;

      begin
        result:=false;
        basedllname:=splitfilename(dllname);
        DLLReader:=TObjectReader.Create;
        DLLReader.OpenFile(dllname);
        if not DLLReader.Read(DosHeader,sizeof(DosHeader)) or
           (DosHeader[0]<>$4d) or (DosHeader[1]<>$5a) then
          begin
            Comment(V_Error,'Invalid DLL '+dllname+', Dos Header invalid');
            exit;
          end;
        newheaderofs:=longint(DosHeader[$3c]) or (DosHeader[$3d] shl 8) or (DosHeader[$3e] shl 16) or (DosHeader[$3f] shl 24);
        DLLReader.Seek(newheaderofs);
        if not DLLReader.Read(PEMagic,sizeof(PEMagic)) or
           (PEMagic[0]<>$50) or (PEMagic[1]<>$45) or (PEMagic[2]<>$00) or (PEMagic[3]<>$00) then
          begin
            Comment(V_Error,'Invalid DLL '+dllname+', Not a PE file');
            exit;
          end;
        if not DLLReader.Read(Header,sizeof(CoffHeader)) or
           (Header.mach<>COFF_MAGIC) or
           (Header.opthdr<>sizeof(coffpeoptheader)) then
          begin
            Comment(V_Error,'Invalid DLL '+dllname+', Not a PE file');
            exit;
          end;
        { Read optheader }
        DLLreader.Read(peheader,sizeof(coffpeoptheader));
        { Section headers }
        found:=false;
        for i:=1 to header.nsects do
          begin
            if not DLLreader.read(sechdr,sizeof(sechdr)) then
              begin
                Comment(V_Error,'Error reading coff file '+DLLName);
                exit;
              end;
            if (sechdr.rvaofs<=peheader.DataDirectory[PE_DATADIR_EDATA].vaddr) and
               (peheader.DataDirectory[PE_DATADIR_EDATA].vaddr<sechdr.rvaofs+sechdr.vsize) then
              begin
                found:=true;
                break;
              end;
          end;
        if not found then
          begin
            Comment(V_Warning,'DLL '+DLLName+' does not contain any exports');
            exit;
          end;
        { Process edata }
        idata2objsection:=nil;
        idata4objsection:=nil;
        idata5objsection:=nil;
        idata6objsection:=nil;
        idata7objsection:=nil;
        DLLReader.Seek(sechdr.datapos+peheader.DataDirectory[PE_DATADIR_EDATA].vaddr-sechdr.rvaofs);
        DLLReader.Read(expdir,sizeof(expdir));
        for i:=0 to expdir.NumNames-1 do
          begin
            DLLReader.Seek(sechdr.datapos+expdir.AddrNames-sechdr.rvaofs+i*4);
            DLLReader.Read(NameOfs,4);
            Dec(NameOfs,sechdr.rvaofs);
            if (NameOfs<0) or
               (NameOfs>sechdr.vsize) then
              begin
                Comment(V_Error,'DLL does contains invalid exports');
                break;
              end;
            { Read Function name from DLL, prepend _ and terminate with #0 }
            DLLReader.Seek(sechdr.datapos+NameOfs);
            DLLReader.Read(FuncName[2],sizeof(FuncName)-3);
            { Add underscore to be compatible with ld.exe importing }
            FuncName[1]:='_';
            FuncName[sizeof(FuncName)-1]:=#0;
            FuncName[0]:=chr(Strlen(@FuncName[1]));

            for j:=0 to UnresolvedExeSymbols.Count-1 do
              begin
                exesym:=TExeSymbol(UnresolvedExeSymbols[j]);
                if assigned(exesym) and
                   not assigned(exesym.objsymbol) and
                   (exesym.name=FuncName) then
                  begin
                    { Remove underscore }
                    Delete(FuncName,1,1);
                    exesym.objsymbol:=AddProcImport(FuncName);
                    UnresolvedExeSymbols[j]:=nil;
                    break;
                  end;
              end;
          end;
        UnresolvedExeSymbols.Pack;
        if assigned(idata2objsection) then
          EndImport;
        DLLReader.Free;
      end;


    procedure TPECoffexeoutput.ResolveExternals(const libname:string);
      begin
        LoadDLL(libname);
      end;


{****************************************************************************
                                 TDJCoffAssembler
****************************************************************************}

    constructor TDJCoffAssembler.Create(smart:boolean);
      begin
        inherited Create(smart);
        CObjOutput:=TDJCoffObjOutput;
      end;


{****************************************************************************
                               TPECoffAssembler
****************************************************************************}

    constructor TPECoffAssembler.Create(smart:boolean);
      begin
        inherited Create(smart);
        CObjOutput:=TPECoffObjOutput;
      end;


{****************************************************************************
                                  TCoffLinker
****************************************************************************}

    constructor TDJCoffLinker.Create;
      begin
        inherited Create;
        CExeoutput:=TDJCoffexeoutput;
        CObjInput:=TDJCoffObjInput;
      end;


    procedure TDJCoffLinker.DefaultLinkScript;
      begin
      end;


    constructor TPECoffLinker.Create;
      begin
        inherited Create;
        CExeoutput:=TPECoffexeoutput;
        CObjInput:=TPECoffObjInput;
      end;


    procedure TPECoffLinker.DefaultLinkScript;
      begin
        with LinkScript do
          begin
            Concat('READUNITOBJECTS');
            if apptype=app_gui then
              Concat('ENTRYNAME _WinMainCRTStartup')
            else
              Concat('ENTRYNAME _mainCRTStartup');
            Concat('HEADER');
            Concat('EXESECTION .text');
            Concat('  OBJSECTION .text*');
            Concat('  SYMBOL etext');
            Concat('ENDEXESECTION');
            Concat('EXESECTION .data');
            Concat('  SYMBOL __data_start__');
            Concat('  OBJSECTION .data*');
            Concat('  SYMBOL edata');
            Concat('  SYMBOL __data_end__');
            Concat('ENDEXESECTION');
            Concat('EXESECTION .idata');
            Concat('  OBJSECTION .idata$2');
            Concat('  OBJSECTION .idata$3');
            Concat('  ZEROS 20');
            Concat('  OBJSECTION .idata$4');
            Concat('  OBJSECTION .idata$5');
            Concat('  OBJSECTION .idata$6');
            Concat('  OBJSECTION .idata$7');
            Concat('ENDEXESECTION');
            Concat('EXESECTION .bss');
            Concat('  SYMBOL __bss_start__');
            Concat('  OBJSECTION .bss*');
            Concat('  SYMBOL __bss_end__');
            Concat('ENDEXESECTION');
            Concat('EXESECTION .rsrc');
            Concat('  OBJSECTION .rsrc*');
            Concat('ENDEXESECTION');
            Concat('EXESECTION .stab');
            Concat('  OBJSECTION .stab');
            Concat('ENDEXESECTION');
            Concat('EXESECTION .stabstr');
            Concat('  OBJSECTION .stabstr');
            Concat('ENDEXESECTION');
            Concat('STABS');
            Concat('SYMBOLS');
          end;
      end;


{*****************************************************************************
                                  Initialize
*****************************************************************************}

{$ifdef i386}
    const
       as_i386_coff_info : tasminfo =
          (
            id     : as_i386_coff;
            idtxt  : 'COFF';
            asmbin : '';
            asmcmd : '';
            supported_target : system_i386_go32v2;
            flags : [af_outputbinary];
            labelprefix : '.L';
            comment : '';
          );

       as_i386_pecoff_info : tasminfo =
          (
            id     : as_i386_pecoff;
            idtxt  : 'PECOFF';
            asmbin : '';
            asmcmd : '';
            supported_target : system_i386_win32;
            flags : [af_outputbinary,af_smartlink_sections];
            labelprefix : '.L';
            comment : '';
          );

       as_i386_pecoffwdosx_info : tasminfo =
          (
            id     : as_i386_pecoffwdosx;
            idtxt  : 'PEWDOSX';
            asmbin : '';
            asmcmd : '';
            supported_target : system_i386_wdosx;
            flags : [af_outputbinary];
            labelprefix : '.L';
            comment : '';
          );

       as_i386_pecoffwince_info : tasminfo =
          (
            id     : as_i386_pecoffwince;
            idtxt  : 'PECOFFWINCE';
            asmbin : '';
            asmcmd : '';
            supported_target : system_i386_wince;
            flags : [af_outputbinary];
            labelprefix : '.L';
            comment : '';
          );
{$endif i386}
{$ifdef x86_64}
    const
       as_x86_64_pecoff_info : tasminfo =
          (
            id     : as_x86_64_pecoff;
            idtxt  : 'PECOFF';
            asmbin : '';
            asmcmd : '';
            supported_target : system_x86_64_win64;
            flags : [af_outputbinary,af_smartlink_sections];
            labelprefix : '.L';
            comment : '';
          );
{$endif x86_64}
{$ifdef arm}
    const
       as_arm_pecoffwince_info : tasminfo =
          (
            id     : as_arm_pecoffwince;
            idtxt  : 'PECOFFWINCE';
            asmbin : '';
            asmcmd : '';
            supported_target : system_arm_wince;
            flags : [af_outputbinary];
            labelprefix : '.L';
            comment : '';
          );
{$endif arm}


initialization
{$ifdef i386}
  RegisterAssembler(as_i386_coff_info,TDJCoffAssembler);
  RegisterAssembler(as_i386_pecoff_info,TPECoffAssembler);
  RegisterAssembler(as_i386_pecoffwdosx_info,TPECoffAssembler);
  RegisterAssembler(as_i386_pecoffwince_info,TPECoffAssembler);
{$endif i386}
{$ifdef x86_64}
  RegisterAssembler(as_x86_64_pecoff_info,TPECoffAssembler);
{$endif x86_64}
{$ifdef arm}
  RegisterAssembler(as_arm_pecoffwince_info,TPECoffAssembler);
{$endif arm}
end.
