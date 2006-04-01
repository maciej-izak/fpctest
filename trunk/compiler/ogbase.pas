{
    Copyright (c) 1998-2006 by Peter Vreman

    Contains the base stuff for binary object file writers

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
unit ogbase;

{$i fpcdefs.inc}

interface

    uses
      { common }
      cclasses,
      { targets }
      systems,globtype,
      { outputwriters }
      owbase,
      { assembler }
      aasmbase;

    type
      TObjSection = class;
      TObjData = class;

      TExeSection = class;
      TExeSymbol  = class;

      TObjRelocationType = (Reloc_ABSOLUTE,Reloc_RELATIVE,Reloc_RVA
{$ifdef x86_64}
        ,Reloc_ABSOLUTE32
{$endif x86_64}
      );

      TObjSectionOption = (
       { Has Data available in the file }
       oso_Data,
       { Is loaded into memory }
       oso_load,
       { Not loaded into memory }
       oso_noload,
       { Read only }
       oso_readonly,
       { Read/Write }
       oso_write,
       { Contains executable instructions }
       oso_executable,
       { Never discard section }
       oso_keep,
       { Special common symbols }
       oso_common,
       { Contains debug info and can be stripped }
       oso_debug,
       { Contains only strings }
       oso_strings
     );

     TObjSectionOptions = set of TObjSectionOption;

     TObjSymbol = class(TNamedIndexItem)
     public
       bind       : TAsmsymbind;
       typ        : TAsmsymtype;
       { Current assemble pass, used to detect duplicate labels }
       pass       : byte;
       objsection : TObjSection;
       symidx     : longint;
       offset,
       size       : aint;
       { Used for external and common solving during linking }
       exesymbol  : TExeSymbol;
       constructor create(const s:string);
       function  address:aint;
       procedure SetAddress(apass:byte;aobjsec:TObjSection;abind:TAsmsymbind;atyp:Tasmsymtype);
     end;

     { Stabs is common for all targets }
     TObjStabEntry=packed record
        strpos  : longint;
        ntype   : byte;
        nother  : byte;
        ndesc   : word;
        nvalue  : longint;
     end;
     PObjStabEntry=^TObjStabEntry;

     TObjRelocation = class(TLinkedListItem)
        DataOffset,
        orgsize    : aint;  { original size of the symbol to Relocate, required for COFF }
        symbol     : TObjSymbol;
        objsection : TObjSection; { only used if symbol=nil }
        typ        : TObjRelocationType;
        constructor CreateSymbol(ADataOffset:aint;s:TObjSymbol;Atyp:TObjRelocationType);
        constructor CreateSymbolSize(ADataOffset:aint;s:TObjSymbol;Aorgsize:aint;Atyp:TObjRelocationType);
        constructor CreateSection(ADataOffset:aint;aobjsec:TObjSection;Atyp:TObjRelocationType);
     end;

     TObjSection = class(TNamedIndexItem)
     private
       FData       : TDynamicArray;
       FSecOptions : TObjSectionOptions;
       procedure SetSecOptions(Aoptions:TObjSectionOptions);
     public
       ObjData    : TObjData;
       SecSymIdx  : longint;   { index for the section in symtab }
       SecAlign   : shortint;   { alignment of the section }
       { section Data }
       Size,
       DataPos,
       MemPos     : aint;
       DataAlignBytes : shortint;
       { Relocation }
       Relocations : TLinkedList;
       { Symbols this section references and defines }
       ObjSymbolRefs     : TFPObjectList;
       ObjSymbolDefines  : TFPObjectList;
       { executable linking }
       ExeSection  : TExeSection;
       Used       : boolean;
       constructor create(const Aname:string;Aalign:shortint;Aoptions:TObjSectionOptions);virtual;
       destructor  destroy;override;
       function  write(const d;l:aint):aint;
       function  writestr(const s:string):aint;
       function  WriteZeros(l:longint):aint;
       procedure setmempos(var mpos:aint);
       procedure setDatapos(var dpos:aint);
       procedure alloc(l:aint);
       procedure addsymReloc(ofs:aint;p:TObjSymbol;Reloctype:TObjRelocationType);
       procedure addsectionReloc(ofs:aint;aobjsec:TObjSection;Reloctype:TObjRelocationType);
       procedure AddSymbolDefine(p:TObjSymbol);
       procedure AddSymbolRef(p:TObjSymbol);
       procedure FixupRelocs;virtual;
       procedure ReleaseData;
       function  FullName:string;
       property  Data:TDynamicArray read FData;
       property  SecOptions:TObjSectionOptions read FSecOptions write SetSecOptions;
     end;
     TObjSectionClass = class of TObjSection;

     TObjData = class(TLinkedListItem)
     private
       FName       : string[80];
       FCurrObjSec : TObjSection;
       { ObjSections will be stored in order in SectsIndex, this is at least
         required for stabs debuginfo. The SectsDict is only used for lookups (PFV) }
       FObjSectionDict  : TDictionary;
       FObjSectionList  : TFPObjectList;
       FCObjSection     : TObjSectionClass;
       { Symbols that will be defined in this object file }
       FObjSymbolList    : TFPObjectList;
       FObjSymbolDict    : TDictionary;
       FCachedAsmSymbolList : TFPObjectList;
       { Special info sections that are written to during object generation }
       FStabsObjSec,
       FStabStrObjSec : TObjSection;
       procedure section_reset(p:TObject;arg:pointer);
       procedure section_afteralloc(p:TObject;arg:pointer);
       procedure section_afterwrite(p:TObject;arg:pointer);
     protected
       property StabsSec:TObjSection read FStabsObjSec write FStabsObjSec;
       property StabStrSec:TObjSection read FStabStrObjSec write FStabStrObjSec;
       property CObjSection:TObjSectionClass read FCObjSection write FCObjSection;
     public
       CurrPass  : byte;
       ImageBase : aint;
       constructor create(const n:string);virtual;
       destructor  destroy;override;
       { Sections }
       function  sectionname(atype:TAsmSectiontype;const aname:string):string;virtual;
       function  sectiontype2options(atype:TAsmSectiontype):TObjSectionOptions;virtual;
       function  sectiontype2align(atype:TAsmSectiontype):shortint;virtual;
       function  createsection(atype:TAsmSectionType;const aname:string):TObjSection;
       function  createsection(const aname:string;aalign:shortint;aoptions:TObjSectionOptions):TObjSection;virtual;
       procedure CreateDebugSections;virtual;
       function  findsection(const aname:string):TObjSection;
       procedure setsection(asec:TObjSection);
       { Symbols }
       function  createsymbol(const aname:string):TObjSymbol;
       function  symboldefine(asmsym:TAsmSymbol):TObjSymbol;
       function  symboldefine(const aname:string;abind:TAsmsymbind;atyp:Tasmsymtype):TObjSymbol;
       function  symbolref(asmsym:TAsmSymbol):TObjSymbol;
       function  symbolref(const aname:string):TObjSymbol;
       procedure ResetCachedAsmSymbols;
       { Allocation }
       procedure alloc(len:aint);
       procedure allocalign(len:shortint);
       procedure allocstab(p:pchar);
       procedure writebytes(const Data;len:aint);
       procedure writeReloc(Data,len:aint;p:TObjSymbol;Reloctype:TObjRelocationType);virtual;abstract;
       procedure writestab(offset:aint;ps:TObjSymbol;nidx,nother:byte;ndesc:word;p:pchar);virtual;abstract;
       procedure beforealloc;virtual;
       procedure beforewrite;virtual;
       procedure afteralloc;virtual;
       procedure afterwrite;virtual;
       procedure resetsections;
       property Name:string[80] read FName;
       property CurrObjSec:TObjSection read FCurrObjSec;
       property ObjSymbolList:TFPObjectList read FObjSymbolList;
       property ObjSectionList:TFPObjectList read FObjSectionList;
     end;
     TObjDataClass = class of TObjData;

     TObjOutput = class
      private
        FCObjData : TObjDataClass;
      protected
        { writer }
        FWriter    : TObjectwriter;
        function  writeData(Data:TObjData):boolean;virtual;abstract;
        property CObjData : TObjDataClass read FCObjData write FCObjData;
      public
        constructor create(AWriter:TObjectWriter);virtual;
        destructor  destroy;override;
        function  newObjData(const n:string):TObjData;
        function  startObjectfile(const fn:string):boolean;
        function  writeobjectfile(Data:TObjData):boolean;
        procedure exportsymbol(p:TObjSymbol);
        property Writer:TObjectWriter read FWriter;
      end;
      TObjOutputClass=class of TObjOutput;

      TObjInput = class
      private
        FCObjData : TObjDataClass;
      protected
        { reader }
        FReader    : TObjectreader;
        function  readObjData(Data:TObjData):boolean;virtual;abstract;
        property CObjData : TObjDataClass read FCObjData write FCObjData;
      public
        constructor create;virtual;
        destructor  destroy;override;
        function  newObjData(const n:string):TObjData;
        function  readobjectfile(const fn:string;Data:TObjData):boolean;virtual;
        property Reader:TObjectReader read FReader;
        procedure inputerror(const s : string);
      end;
      TObjInputClass=class of TObjInput;

      TExeSymbol = class(TNamedIndexItem)
        ObjSymbol  : TObjSymbol;
        ExeSection : TExeSection;
        constructor create(sym:TObjSymbol);
      end;

      TExeSection = class(tnamedindexitem)
      private
        FSecSymIdx : longint;
        FObjSectionList : TFPObjectList;
      public
        Size,
        DataPos,
        MemPos     : aint;
        SecAlign   : shortint;
        SecOptions : TObjSectionOptions;
        constructor create(const n:string);virtual;
        destructor  destroy;override;
        procedure AddObjSection(objsec:TObjSection);
        property ObjSectionList:TFPObjectList read FObjSectionList;
        property SecSymIdx:longint read FSecSymIdx write FSecSymIdx;
      end;
      TExeSectionClass=class of TExeSection;

      TExeOutput = class
      private
        { ExeSections }
        FCObjData         : TObjDataClass;
        FCExeSection      : TExeSectionClass;
        FCurrExeSec       : TExeSection;
        FExeSectionList   : TFPObjectList;
        FExeSectionDict   : TDictionary;
        Fzeronr           : longint;
        { Symbols }
        FExeSymbolDict    : TDictionary;
        FExeSymbolList,
        FUnresolvedExeSymbols : TFPObjectList;
        FExternalObjSymbols,
        FCommonObjSymbols   : TFPObjectList;
        FEntryName          : string;
        { Objects }
        FObjDataList  : TFPObjectList;
        { Position calculation }
        FImageBase    : aint;
        FCurrDataPos,
        FCurrMemPos   : aint;
      protected
        { writer }
        FWriter : TObjectwriter;
        commonObjSection : TObjSection;
        internalObjData : TObjData;
        EntrySym  : TObjSymbol;
        SectionDataAlign,
        SectionMemAlign : aint;
        function  writeData:boolean;virtual;abstract;
        property CExeSection:TExeSectionClass read FCExeSection write FCExeSection;
        property CObjData:TObjDataClass read FCObjData write FCObjData;
      public
        constructor create;virtual;
        destructor  destroy;override;
        procedure AddObjData(ObjData:TObjData);
        function  FindExeSection(const aname:string):TExeSection;
        procedure Load_Start;virtual;
        procedure Load_EntryName(const aname:string);virtual;
        procedure Load_Symbol(const aname:string);virtual;
        procedure Order_Start;virtual;
        procedure Order_End;virtual;
        procedure Order_ExeSection(const aname:string);virtual;
        procedure Order_Align(const aname:string);virtual;
        procedure Order_Zeros(const aname:string);virtual;
        procedure Order_Symbol(const aname:string);virtual;
        procedure Order_EndExeSection;virtual;
        procedure Order_ObjSection(const aname:string);virtual;
        procedure CalcPos_ExeSection(const aname:string);virtual;
        procedure CalcPos_EndExeSection;virtual;
        procedure CalcPos_Header;virtual;
        procedure CalcPos_Start;virtual;
        procedure CalcPos_Symbols;virtual;
        procedure ResolveSymbols;
        procedure PrintMemoryMap;
        procedure FixupSymbols;
        procedure FixupRelocations;
        procedure MergeStabs;
        procedure RemoveUnreferencedSections;
        procedure RemoveEmptySections;
        procedure ResolveExternals(const libname:string);virtual;
        function  writeexefile(const fn:string):boolean;
        property Writer:TObjectWriter read FWriter;
        property ExeSections:TFPObjectList read FExeSectionList;
        property ObjDataList:TFPObjectList read FObjDataList;
        property ExeSymbolDict:TDictionary read FExeSymbolDict;
        property ExeSymbolList:TFPObjectList read FExeSymbolList;
        property UnresolvedExeSymbols:TFPObjectList read FUnresolvedExeSymbols;
        property ExternalObjSymbols:TFPObjectList read FExternalObjSymbols;
        property CommonObjSymbols:TFPObjectList read FCommonObjSymbols;
        property EntryName:string read FEntryName write FEntryName;
        property ImageBase:aint read FImageBase write FImageBase;
        property CurrExeSec:TExeSection read FCurrExeSec;
        property CurrDataPos:aint read FCurrDataPos write FCurrDataPos;
        property CurrMemPos:aint read FCurrMemPos write FCurrMemPos;
      end;
      TExeOutputClass=class of TExeOutput;

{$ifdef i386}
    const
      Reloc_ABSOLUTE32 = Reloc_ABSOLUTE;
{$endif i386}

    var
      exeoutput : TExeOutput;


implementation

    uses
      cutils,globals,verbose,fmodule,ogmap;

    const
      sectionDatagrowsize = 1024;


{*****************************************************************************
                                 TObjSymbol
*****************************************************************************}

    constructor TObjSymbol.create(const s:string);
      begin;
        inherited createname(s);
        bind:=AB_EXTERNAL;
        typ:=AT_NONE;
        symidx:=-1;
        size:=0;
        offset:=0;
        objsection:=nil;
      end;


    function TObjSymbol.address:aint;
      begin
        if assigned(objsection) then
          result:=offset+objsection.mempos
        else
          result:=0;
      end;


    procedure TObjSymbol.SetAddress(apass:byte;aobjsec:TObjSection;abind:TAsmsymbind;atyp:Tasmsymtype);
      begin
        if not(abind in [AB_GLOBAL,AB_LOCAL,AB_COMMON]) then
          internalerror(200603016);
        if not assigned(aobjsec) then
          internalerror(200603017);
        if (bind=AB_EXTERNAL) then
          begin
            bind:=abind;
            typ:=atyp;
          end
        else
          begin
            if pass=apass then
              Message1(asmw_e_duplicate_label,name);
          end;
        pass:=apass;
        { Code can never grow after a pass }
        if assigned(objsection) and
           (aobjsec.size>offset) then
          internalerror(200603014);
        objsection:=aobjsec;
        offset:=aobjsec.size;
      end;

{****************************************************************************
                              TObjRelocation
****************************************************************************}

    constructor TObjRelocation.CreateSymbol(ADataOffset:aint;s:TObjSymbol;Atyp:TObjRelocationType);
      begin
        if not assigned(s) then
          internalerror(200603034);
        DataOffset:=ADataOffset;
        Symbol:=s;
        OrgSize:=0;
        ObjSection:=nil;
        Typ:=Atyp;
      end;


    constructor TObjRelocation.CreateSymbolSize(ADataOffset:aint;s:TObjSymbol;Aorgsize:aint;Atyp:TObjRelocationType);
      begin
        if not assigned(s) then
          internalerror(200603035);
        DataOffset:=ADataOffset;
        Symbol:=s;
        OrgSize:=Aorgsize;
        ObjSection:=nil;
        Typ:=Atyp;
      end;


    constructor TObjRelocation.CreateSection(ADataOffset:aint;aobjsec:TObjSection;Atyp:TObjRelocationType);
      begin
        if not assigned(aobjsec) then
          internalerror(200603036);
        DataOffset:=ADataOffset;
        Symbol:=nil;
        OrgSize:=0;
        ObjSection:=aobjsec;
        Typ:=Atyp;
      end;


{****************************************************************************
                              TObjSection
****************************************************************************}

    constructor TObjSection.create(const Aname:string;Aalign:shortint;Aoptions:TObjSectionOptions);
      begin
        inherited createname(Aname);
        name:=Aname;
        { Data }
        Size:=0;
        Datapos:=0;
        mempos:=0;
        FData:=Nil;
        { Setting the secoptions allocates Data if needed }
        secoptions:=Aoptions;
        secalign:=Aalign;
        secsymidx:=0;
        { Relocation }
        Relocations:=TLinkedList.Create;
        ObjSymbolRefs:=TFPObjectList.Create(false);
        ObjSymbolDefines:=TFPObjectList.Create(false);
      end;


    destructor TObjSection.destroy;
      begin
        if assigned(Data) then
          Data.Free;
        Relocations.free;
        ObjSymbolRefs.Free;
        ObjSymbolDefines.Free;
        inherited destroy;
      end;


    procedure TObjSection.SetSecOptions(Aoptions:TObjSectionOptions);
      begin
        FSecOptions:=FSecOptions+AOptions;
        if (oso_Data in secoptions) and
           not assigned(FData) then
          FData:=TDynamicArray.Create(sectionDatagrowsize);
      end;


    function TObjSection.write(const d;l:aint):aint;
      begin
        result:=size;
        if assigned(Data) then
          begin
            if Size<>Data.size then
              internalerror(200602281);
            Data.write(d,l);
            inc(Size,l);
          end
        else
          internalerror(200602289);
      end;


    function TObjSection.writestr(const s:string):aint;
      begin
        result:=Write(s[1],length(s));
      end;


    function TObjSection.WriteZeros(l:longint):aint;
      var
        empty : array[0..1023] of byte;
      begin
        if l>sizeof(empty) then
          internalerror(200404082);
        if l>0 then
          begin
            fillchar(empty,l,0);
            result:=Write(empty,l);
          end
        else
          result:=Size;
      end;


    procedure TObjSection.setDatapos(var dpos:aint);
      begin
        if oso_Data in secoptions then
          begin
            { get aligned Datapos }
            Datapos:=align(dpos,secalign);
            Dataalignbytes:=Datapos-dpos;
            { return updated Datapos }
            dpos:=Datapos+size;
          end
        else
          Datapos:=dpos;
      end;


    procedure TObjSection.setmempos(var mpos:aint);
      begin
        mempos:=align(mpos,secalign);
        { return updated mempos }
        mpos:=mempos+size;
      end;


    procedure TObjSection.alloc(l:aint);
      begin
        inc(size,l);
      end;


    procedure TObjSection.addsymReloc(ofs:aint;p:TObjSymbol;Reloctype:TObjRelocationType);
      begin
        Relocations.concat(TObjRelocation.CreateSymbol(ofs,p,Reloctype));
      end;


    procedure TObjSection.addsectionReloc(ofs:aint;aobjsec:TObjSection;Reloctype:TObjRelocationType);
      begin
        Relocations.concat(TObjRelocation.CreateSection(ofs,aobjsec,Reloctype));
      end;


    procedure TObjSection.AddSymbolDefine(p:TObjSymbol);
      begin
        if p.bind<>AB_GLOBAL then
          exit;
        ObjSymbolDefines.Add(p);
      end;


    procedure TObjSection.AddSymbolRef(p:TObjSymbol);
      begin
        { Register all references, also the local references between the
          ObjSections in an ObjData }
        ObjSymbolRefs.Add(p);
      end;


    procedure TObjSection.FixupRelocs;
      begin
      end;


    procedure TObjSection.ReleaseData;
      begin
        if assigned(FData) then
          begin
            FData.free;
            FData:=nil;
          end;
        Relocations.free;
        Relocations:=nil;
        ObjSymbolRefs.Free;
        ObjSymbolRefs:=nil;
        ObjSymbolDefines.Free;
        ObjSymbolDefines:=nil;
      end;


    function  TObjSection.FullName:string;
      begin
        if assigned(ObjData) then
          result:=ObjData.Name+'('+Name+')'
        else
          result:=Name;
      end;


{****************************************************************************
                                TObjData
****************************************************************************}

    constructor TObjData.create(const n:string);
      begin
        inherited create;
        FName:=SplitFileName(n);
        { sections, the SectsIndex owns the items, the FObjSectionDict
          is only used for lookups }
        FObjSectionDict:=tdictionary.create;
        FObjSectionDict.noclear:=true;
        FObjSectionList:=TFPObjectList.Create(true);
        FStabsObjSec:=nil;
        FStabStrObjSec:=nil;
        { symbols }
        FObjSymbolDict:=tdictionary.create;
        FObjSymbolDict.noclear:=true;
        FObjSymbolList:=TFPObjectList.Create(true);
        FCachedAsmSymbolList:=TFPObjectList.Create(false);
        { section class type for creating of new sections }
        FCObjSection:=TObjSection;
      end;


    destructor TObjData.destroy;
{$ifdef MEMDEBUG}
       var
         d : tmemdebug;
{$endif}
      begin
{$ifdef MEMDEBUG}
        d:=tmemdebug.create(name+' - ObjData symbols');
{$endif}
        ResetCachedAsmSymbols;
        FCachedAsmSymbolList.free;
        FObjSymbolDict.free;
        FObjSymbolList.free;
{$ifdef MEMDEBUG}
        d.free;
{$endif}
{$ifdef MEMDEBUG}
        d:=tmemdebug.create(name+' - ObjData sections');
{$endif}
        FObjSectionDict.free;
        FObjSectionList.free;
{$ifdef MEMDEBUG}
        d.free;
{$endif}
        inherited destroy;
      end;


    function TObjData.sectionname(atype:TAsmSectiontype;const aname:string):string;
      const
        secnames : array[TAsmSectiontype] of string[16] = ('',
          'code',
          'Data',
          'roData',
          'bss',
          'threadvar',
          'stub',
          'stab','stabstr',
          'iData2','iData4','iData5','iData6','iData7','eData',
          'eh_frame',
          'debug_frame','debug_info','debug_line','debug_abbrev',
          'fpc',
          'toc'
        );
      begin
        if aname<>'' then
          result:=secnames[atype]+'.'+aname
        else
          result:=secnames[atype];
      end;


    function TObjData.sectiontype2options(atype:TAsmSectiontype):TObjSectionOptions;
      const
        secoptions : array[TAsmSectiontype] of TObjSectionOptions = ([],
          {code} [oso_Data,oso_load,oso_readonly,oso_executable,oso_keep],
          {Data} [oso_Data,oso_load,oso_write,oso_keep],
{$warning TODO Fix roData be read-only}
          {roData} [oso_Data,oso_load,oso_write,oso_keep],
          {bss} [oso_load,oso_write,oso_keep],
          {threadvar} [oso_load,oso_write],
          {stub} [oso_Data,oso_load,oso_readonly,oso_executable],
          {stab} [oso_Data,oso_noload,oso_debug],
          {stabstr} [oso_Data,oso_noload,oso_strings,oso_debug],
{$warning TODO iData keep can maybe replaced with grouping of text and iData}
          {iData2} [oso_Data,oso_load,oso_write,oso_keep],
          {iData4} [oso_Data,oso_load,oso_write,oso_keep],
          {iData5} [oso_Data,oso_load,oso_write,oso_keep],
          {iData6} [oso_Data,oso_load,oso_write,oso_keep],
          {iData7} [oso_Data,oso_load,oso_write,oso_keep],
          {eData} [oso_Data,oso_load,oso_readonly],
          {eh_frame} [oso_Data,oso_load,oso_readonly],
          {debug_frame} [oso_Data,oso_noload,oso_debug],
          {debug_info} [oso_Data,oso_noload,oso_debug],
          {debug_line} [oso_Data,oso_noload,oso_debug],
          {debug_abbrev} [oso_Data,oso_noload,oso_debug],
          {fpc} [oso_Data,oso_load,oso_write,oso_keep],
          {toc} [oso_Data,oso_load,oso_readonly]
        );
      begin
        result:=secoptions[atype];
      end;


    function TObjData.sectiontype2align(atype:TAsmSectiontype):shortint;
      begin
        if atype in [sec_stabstr,sec_debug_info,sec_debug_line,sec_debug_abbrev] then
          result:=1
        else
          result:=sizeof(aint);
      end;


    function TObjData.createsection(atype:TAsmSectionType;const aname:string):TObjSection;
      begin
        result:=createsection(sectionname(atype,aname),sectiontype2align(atype),sectiontype2options(atype));
      end;


    function TObjData.createsection(const aname:string;aalign:shortint;aoptions:TObjSectionOptions):TObjSection;
      begin
        result:=TObjSection(FObjSectionDict.search(aname));
        if not assigned(result) then
          begin
            result:=CObjSection.create(aname,aalign,aoptions);
            FObjSectionDict.Insert(result);
            FObjSectionList.Add(result);
            result.ObjData:=self;
          end;
        FCurrObjSec:=result;
      end;


    procedure TObjData.CreateDebugSections;
      begin
      end;


    function TObjData.FindSection(const aname:string):TObjSection;
      begin
        result:=TObjSection(FObjSectionDict.Search(aname));
      end;


    procedure TObjData.setsection(asec:TObjSection);
      begin
        if asec.ObjData<>self then
          internalerror(200403041);
        FCurrObjSec:=asec;
      end;


    function TObjData.createsymbol(const aname:string):TObjSymbol;
      begin
        result:=TObjSymbol(FObjSymbolDict.search(aname));
        if not assigned(result) then
          begin
            result:=TObjSymbol.Create(aname);
            FObjSymbolDict.Insert(result);
            FObjSymbolList.Add(result);
          end;
      end;


    function TObjData.symboldefine(asmsym:TAsmSymbol):TObjSymbol;
      begin
        if assigned(asmsym) then
          begin
            if not assigned(asmsym.cachedObjSymbol) then
              begin
                result:=symboldefine(asmsym.name,asmsym.bind,asmsym.typ);
                asmsym.cachedObjSymbol:=result;
                FCachedAsmSymbolList.add(asmsym);
              end
            else
              begin
                result:=TObjSymbol(asmsym.cachedObjSymbol);
                result.SetAddress(CurrPass,CurrObjSec,asmsym.bind,asmsym.typ);
                { Register also in TObjSection }
                CurrObjSec.AddSymbolDefine(result);
              end;
          end
        else
          result:=nil;
      end;


    function TObjData.symboldefine(const aname:string;abind:TAsmsymbind;atyp:Tasmsymtype):TObjSymbol;
      begin
        if not assigned(CurrObjSec) then
          internalerror(200603051);
        result:=CreateSymbol(aname);
        { Register also in TObjSection }
        CurrObjSec.AddSymbolDefine(result);
        result.SetAddress(CurrPass,CurrObjSec,abind,atyp);
      end;


    function TObjData.symbolref(asmsym:TAsmSymbol):TObjSymbol;
      begin
        if assigned(asmsym) then
          begin
            if not assigned(asmsym.cachedObjSymbol) then
              begin
                result:=symbolref(asmsym.name);
                asmsym.cachedObjSymbol:=result;
                FCachedAsmSymbolList.add(asmsym);
              end
            else
              begin
                result:=TObjSymbol(asmsym.cachedObjSymbol);
                { Register also in TObjSection }
                CurrObjSec.AddSymbolRef(result);
              end;
          end
        else
          result:=nil;
      end;


    function TObjData.symbolref(const aname:string):TObjSymbol;
      begin
        if not assigned(CurrObjSec) then
          internalerror(200603052);
        result:=CreateSymbol(aname);
        { Register also in TObjSection }
        CurrObjSec.AddSymbolRef(result);
      end;


    procedure TObjData.ResetCachedAsmSymbols;
      var
        i  : longint;
      begin
        for i:=0 to FCachedAsmSymbolList.Count-1 do
          tasmsymbol(FCachedAsmSymbolList[i]).cachedObjSymbol:=nil;
        FCachedAsmSymbolList.Clear;
      end;


    procedure TObjData.writebytes(const Data;len:aint);
      begin
        if not assigned(CurrObjSec) then
          internalerror(200402251);
        CurrObjSec.write(Data,len);
      end;


    procedure TObjData.alloc(len:aint);
      begin
        if not assigned(CurrObjSec) then
          internalerror(200402252);
        CurrObjSec.alloc(len);
      end;


    procedure TObjData.allocalign(len:shortint);
      begin
        if not assigned(CurrObjSec) then
          internalerror(200402253);
        CurrObjSec.alloc(align(CurrObjSec.size,len)-CurrObjSec.size);
      end;


    procedure TObjData.allocstab(p:pchar);
      begin
        if not(assigned(FStabsObjSec) and assigned(FStabStrObjSec)) then
          internalerror(200402254);
        FStabsObjSec.alloc(sizeof(TObjStabEntry));
        if assigned(p) and (p[0]<>#0) then
          FStabStrObjSec.alloc(strlen(p)+1);
      end;


    procedure TObjData.section_afteralloc(p:TObject;arg:pointer);
      begin
        with TObjSection(p) do
          alloc(align(size,secalign)-size);
      end;


    procedure TObjData.section_afterwrite(p:TObject;arg:pointer);
      begin
        with TObjSection(p) do
          begin
            if assigned(Data) then
              writezeros(align(size,secalign)-size);
          end;
      end;


    procedure TObjData.section_reset(p:TObject;arg:pointer);
      begin
        with TObjSection(p) do
          begin
            Size:=0;
            Datapos:=0;
            mempos:=0;
          end;
      end;


    procedure TObjData.beforealloc;
      begin
        { create stabs sections if debugging }
        if assigned(StabsSec) then
          begin
            StabsSec.Alloc(sizeof(TObjStabEntry));
            StabStrSec.Alloc(1);
          end;
      end;


    procedure TObjData.beforewrite;
      var
        s : string[1];
      begin
        { create stabs sections if debugging }
        if assigned(StabsSec) then
         begin
           writestab(0,nil,0,0,0,nil);
           s:=#0;
           stabstrsec.write(s[1],length(s));
         end;
      end;


    procedure TObjData.afteralloc;
      begin
        FObjSectionList.ForEachCall(@section_afteralloc,nil);
      end;


    procedure TObjData.afterwrite;
      var
        s : string[1];
        hstab : TObjStabEntry;
      begin
        FObjSectionList.ForEachCall(@section_afterwrite,nil);
        { For the stab section we need an HdrSym which can now be
          calculated more easily }
        if assigned(StabsSec) then
          begin
            { header stab }
            s:=#0;
            stabstrsec.write(s[1],length(s));
            hstab.strpos:=1;
            hstab.ntype:=0;
            hstab.nother:=0;
            hstab.ndesc:=(StabsSec.Size div sizeof(TObjStabEntry))-1;
            hstab.nvalue:=StabStrSec.Size;
            StabsSec.Data.seek(0);
            StabsSec.Data.write(hstab,sizeof(hstab));
          end;
      end;


    procedure TObjData.resetsections;
      begin
        FObjSectionList.ForEachCall(@section_reset,nil);
      end;


{****************************************************************************
                                TObjOutput
****************************************************************************}

    constructor TObjOutput.create(AWriter:TObjectWriter);
      begin
        FWriter:=AWriter;
        CObjData:=TObjData;
      end;


    destructor TObjOutput.destroy;
      begin
        inherited destroy;
      end;


    function TObjOutput.newObjData(const n:string):TObjData;
      begin
        result:=CObjData.create(n);
        if (cs_use_lineinfo in aktglobalswitches) or
           (cs_debuginfo in aktmoduleswitches) then
          result.CreateDebugSections;
      end;


    function TObjOutput.startObjectfile(const fn:string):boolean;
      begin
        result:=false;
        { start the writer already, so the .a generation can initialize
          the position of the current objectfile }
        if not FWriter.createfile(fn) then
         Comment(V_Fatal,'Can''t create object '+fn);
        result:=true;
      end;


    function TObjOutput.writeobjectfile(Data:TObjData):boolean;
      begin
        if errorcount=0 then
         result:=writeData(Data)
        else
         result:=true;
        { close the writer }
        FWriter.closefile;
      end;


    procedure TObjOutput.exportsymbol(p:TObjSymbol);
      begin
        { export globals and common symbols, this is needed
          for .a files }
        if p.bind in [AB_GLOBAL,AB_COMMON] then
         FWriter.writesym(p.name);
      end;


{****************************************************************************
                                 TExeSymbol
****************************************************************************}

    constructor TExeSymbol.create(sym:TObjSymbol);
      begin
        inherited createname(sym.name);
        ObjSymbol:=sym;
      end;


{****************************************************************************
                                tExeSection
****************************************************************************}

    constructor tExeSection.create(const n:string);
      begin
        inherited createname(n);
        Size:=0;
        MemPos:=0;
        DataPos:=0;
        FSecSymIdx:=0;
        FObjSectionList:=TFPObjectList.Create(false);
      end;


    destructor tExeSection.destroy;
      begin
        ObjSectionList.Free;
        inherited destroy;
      end;


    procedure tExeSection.AddObjSection(objsec:TObjSection);
      begin
        ObjSectionList.Add(objsec);
        if (SecOptions<>[]) then
          begin
            if (oso_Data in SecOptions)<>(oso_Data in objsec.SecOptions) then
              Comment(V_Error,'Incompatible section options');
          end
        else
          begin
            { inherit section options }
            SecAlign:=objsec.SecAlign;
            SecOptions:=SecOptions+objsec.SecOptions;
          end;
        { relate ObjSection to ExeSection, and mark it Used by default }
        objsec.ExeSection:=self;
        objsec.Used:=true;
      end;


{****************************************************************************
                                TExeOutput
****************************************************************************}

    constructor TExeOutput.create;
      begin
        { init writer }
        FWriter:=TObjectwriter.create;
        { object files }
        FObjDataList:=TFPObjectList.Create(true);
        { symbols }
        FExeSymbolDict:=tdictionary.create;
        FExeSymbolDict.noclear:=true;
        FExeSymbolDict.usehash;
        FExeSymbolList:=TFPObjectList.Create(true);
        FUnresolvedExeSymbols:=TFPObjectList.Create(false);
        FExternalObjSymbols:=TFPObjectList.Create(false);
        FCommonObjSymbols:=TFPObjectList.Create(false);
        FEntryName:='start';
        { sections }
        FExeSectionDict:=TDictionary.create;
        FExeSectionDict.noclear:=true;
        FExeSectionList:=TFPObjectList.Create(true);
        FImageBase:=0;
        SectionMemAlign:=$1000;
        SectionDataAlign:=$200;
        FCExeSection:=TExeSection;
        FCObjData:=TObjData;
      end;


    destructor TExeOutput.destroy;
      begin
        FExeSymbolDict.free;
        FExeSymbolList.free;
        UnresolvedExeSymbols.free;
        ExternalObjSymbols.free;
        CommonObjSymbols.free;
        FExeSectionDict.free;
        FExeSectionList.free;
        ObjDatalist.free;
        FWriter.free;
        inherited destroy;
      end;


    function TExeOutput.writeexefile(const fn:string):boolean;
      begin
        result:=false;
        if FWriter.createfile(fn) then
         begin
           { Only write the .o if there are no errors }
           if errorcount=0 then
             result:=writeData
           else
             result:=true;
           { close the writer }
           FWriter.closefile;
         end
        else
         Comment(V_Fatal,'Can''t create executable '+fn);
      end;


    procedure TExeOutput.AddObjData(ObjData:TObjData);
      begin
        if ObjData.classtype<>FCObjData then
          Comment(V_Error,'Invalid input object format for '+ObjData.name+' got '+ObjData.classname+' expected '+FCObjData.classname);
        ObjDataList.Add(ObjData);
      end;


    function  TExeOutput.FindExeSection(const aname:string):TExeSection;
      begin
        result:=TExeSection(FExeSectionDict.Search(aname));
      end;


    procedure TExeOutput.Load_Start;
      begin
        ObjDataList.Clear;
        { Globals defined in the linker script }
        if not assigned(internalObjData) then
          internalObjData:=CObjData.create('*Internal*');
        AddObjData(internalObjData);
        { Common Data section }
        commonObjSection:=internalObjData.createsection(sec_bss,'');
      end;


    procedure TExeOutput.Load_EntryName(const aname:string);
      begin
        EntryName:=aname;
      end;


    procedure TExeOutput.Load_Symbol(const aname:string);
      begin
        internalObjData.createsection('*'+aname,0,[]);
        internalObjData.SymbolDefine(aname,AB_GLOBAL,AT_FUNCTION);
      end;


    procedure TExeOutput.Order_Start;
      begin
      end;


    procedure TExeOutput.Order_End;
      begin
        internalObjData.afterwrite;
      end;


    procedure TExeOutput.Order_ExeSection(const aname:string);
      var
        sec : TExeSection;
      begin
        sec:=FindExeSection(aname);
        if not assigned(sec) then
          begin
            sec:=CExeSection.create(aname);
            FExeSectionDict.Insert(sec);
            FExeSectionList.Add(sec);
          end;
        { Clear ExeSection contents }
        FCurrExeSec:=sec;
      end;


    procedure TExeOutput.Order_EndExeSection;
      begin
        if not assigned(CurrExeSec) then
          internalerror(200602184);
        FCurrExeSec:=nil;
      end;


    procedure TExeOutput.Order_ObjSection(const aname:string);
      var
        i,j     : longint;
        ObjData : TObjData;
        objsec  : TObjSection;
      begin
        if not assigned(CurrExeSec) then
          internalerror(200602181);
        for i:=0 to ObjDataList.Count-1 do
          begin
            ObjData:=TObjData(ObjDataList[i]);
            for j:=0 to ObjData.ObjSectionList.Count-1 do
              begin
                objsec:=TObjSection(ObjData.ObjSectionList[j]);
                if MatchPattern(aname,objsec.name) then
                  CurrExeSec.AddObjSection(objsec);
              end;
          end;
      end;


    procedure TExeOutput.Order_Symbol(const aname:string);
      var
        ObjSection : TObjSection;
      begin
        ObjSection:=internalObjData.findsection('*'+aname);
        if not assigned(ObjSection) then
          internalerror(200603041);
        ObjSection.SecOptions:=CurrExeSec.SecOptions;
        CurrExeSec.AddObjSection(ObjSection);
      end;


    procedure TExeOutput.Order_Align(const aname:string);
      var
        code     : integer;
        alignval : longint;
        objsec   : TObjSection;
      begin
        val(aname,alignval,code);
        if alignval<=0 then
          exit;
        { Create an empty section with the required aligning }
        inc(Fzeronr);
        objsec:=internalObjData.createsection('*align'+tostr(Fzeronr),alignval,CurrExeSec.SecOptions+[oso_Data,oso_keep]);
        CurrExeSec.AddObjSection(objsec);
      end;


    procedure TExeOutput.Order_Zeros(const aname:string);
      var
        zeros : array[0..1023] of byte;
        code  : integer;
        len   : longint;
        objsec : TObjSection;
      begin
        val(aname,len,code);
        if len<=0 then
          exit;
        if len>sizeof(zeros) then
          internalerror(200602254);
        fillchar(zeros,len,0);
        inc(Fzeronr);
        objsec:=internalObjData.createsection('*zeros'+tostr(Fzeronr),0,CurrExeSec.SecOptions+[oso_Data,oso_keep]);
        internalObjData.writebytes(zeros,len);
        CurrExeSec.AddObjSection(objsec);
      end;


    procedure TExeOutput.CalcPos_ExeSection(const aname:string);
      var
        i      : longint;
        objsec : TObjSection;
      begin
        { Section can be removed }
        FCurrExeSec:=FindExeSection(aname);
        if not assigned(CurrExeSec) then
          exit;

        { Alignment of ExeSection }
        CurrMemPos:=align(CurrMemPos,SectionMemAlign);
        CurrExeSec.MemPos:=CurrMemPos;
        if (oso_Data in currexesec.SecOptions) then
          begin
            CurrDataPos:=align(CurrDataPos,SectionDataAlign);
            CurrExeSec.DataPos:=CurrDataPos;
          end;

        { set position of object ObjSections }
        for i:=0 to CurrExeSec.ObjSectionList.Count-1 do
          begin
            objsec:=TObjSection(CurrExeSec.ObjSectionList[i]);
            { Position in memory }
            objsec.setmempos(CurrMemPos);
            { Position in File }
            if (oso_Data in objsec.SecOptions) then
              begin
                if not (oso_Data in currexesec.SecOptions) then
                  internalerror(200603043);
                if not assigned(objsec.Data) then
                  internalerror(200603044);
                objsec.setDatapos(CurrDataPos);
              end;
          end;

        { calculate size of the section }
        CurrExeSec.Size:=CurrMemPos-CurrExeSec.MemPos;
      end;


    procedure TExeOutput.CalcPos_EndExeSection;
      begin
        if not assigned(CurrExeSec) then
          exit;
        FCurrExeSec:=nil;
      end;


    procedure TExeOutput.CalcPos_Start;
      begin
        CurrMemPos:=0;
        CurrDataPos:=0;
      end;


    procedure TExeOutput.CalcPos_Header;
      begin
      end;


    procedure TExeOutput.CalcPos_Symbols;
      begin
      end;


    procedure TExeOutput.ResolveSymbols;
      var
        ObjData   : TObjData;
        exesym    : TExeSymbol;
        objsym,
        commonsym : TObjSymbol;
        firstcommon : boolean;
        i,j       : longint;
      begin
        {
          The symbol calculation is done in 3 steps:
           1. register globals
              register externals
              register commons
           2. try to find commons, if not found then
              add to the globals (so externals can be resolved)
           3. try to find externals
        }

        { Step 1, Register symbols }
        for i:=0 to ObjDataList.Count-1 do
          begin
            ObjData:=TObjData(ObjDataList[i]);
            for j:=0 to ObjData.ObjSymbolList.Count-1 do
              begin
                objsym:=TObjSymbol(ObjData.ObjSymbolList[j]);
                { Skip local symbols }
                if objsym.bind=AB_LOCAL then
                  continue;
                exesym:=texesymbol(FExeSymbolDict.search(objsym.name));
                if not assigned(exesym) then
                  begin
                    exesym:=texesymbol.createname(objsym.name);
                    FExeSymbolDict.insert(exesym);
                    FExeSymbolList.Add(exesym);
                  end;
                { Defining the symbol? }
                if objsym.bind=AB_GLOBAL then
                  begin
                    if not assigned(exesym.ObjSymbol) then
                      exesym.ObjSymbol:=objsym
                    else
                      Comment(V_Error,'Multiple defined symbol '+objsym.name);
                  end;
                objsym.exesymbol:=exesym;
                case objsym.bind of
                  AB_EXTERNAL :
                    ExternalObjSymbols.add(objsym);
                  AB_COMMON :
                    CommonObjSymbols.add(objsym);
                end;
              end;
          end;

        { Step 2, Match common symbols or add to the globals }
        firstcommon:=true;
        for i:=0 to CommonObjSymbols.count-1 do
          begin
            objsym:=TObjSymbol(CommonObjSymbols[i]);
            if assigned(objsym.exesymbol.objsymbol) then
              begin
                if objsym.exesymbol.ObjSymbol.size<>objsym.size then
                  internalerror(200206301)
                else
                  begin
                    { allocate new objsymbol in .bss of *COMMON* and assign
                      it to the exesymbol }
                    if firstcommon then
                      begin
                        if assigned(exemap) then
                          exemap.AddCommonSymbolsHeader;
                        firstcommon:=false;
                      end;
                    internalObjData.setsection(commonObjSection);
                    commonsym:=internalObjData.symboldefine(objsym.name,AB_GLOBAL,AT_FUNCTION);
                    commonsym.size:=objsym.size;
                    internalObjData.alloc(objsym.size);
                    if assigned(exemap) then
                      exemap.AddCommonSymbol(commonsym);
                    { Assign to the exesymbol }
                    objsym.exesymbol.objsymbol:=commonsym
                  end;
              end;
          end;

        { Generate a list of Unresolved External symbols }
        for i:=0 to ExeSymbolList.count-1 do
          begin
            exesym:=TExeSymbol(ExeSymbolList[i]);
            if exesym.objsymbol=nil then
              UnresolvedExeSymbols.Add(exesym);
          end;
        Comment(V_Debug,'Number of unresolved externals in objects '+tostr(UnresolvedExeSymbols.Count));

        { Find entry symbol and print in map }
        exesym:=texesymbol(ExeSymbolDict.search(EntryName));
        if assigned(exesym) then
          begin
            EntrySym:=exesym.ObjSymbol;
            if assigned(exemap) then
              begin
                exemap.Add('');
                exemap.Add('Entry symbol '+EntryName);
              end;
          end
        else
          Comment(V_Error,'Entrypoint '+EntryName+' not defined');
      end;


    procedure TExeOutput.ResolveExternals(const libname:string);
      begin
      end;


    procedure TExeOutput.PrintMemoryMap;
      var
        exesec : TExeSection;
        objsec : TObjSection;
        objsym : TObjSymbol;
        i,j,k  : longint;
      begin
        if not assigned(exemap) then
          exit;
        exemap.AddMemoryMapHeader(ImageBase);
        for i:=0 to ExeSections.Count-1 do
          begin
            exesec:=TExeSection(ExeSections[i]);
            exemap.AddMemoryMapExeSection(exesec);
            for j:=0 to exesec.ObjSectionList.count-1 do
              begin
                objsec:=TObjSection(exesec.ObjSectionList[j]);
                exemap.AddMemoryMapObjectSection(objsec);
                for k:=0 to objsec.ObjSymbolDefines.Count-1 do
                  begin
                    objsym:=TObjSymbol(objsec.ObjSymbolDefines[k]);
                    exemap.AddMemoryMapSymbol(objsym);
                  end;
              end;
          end;
      end;


    procedure TExeOutput.FixupSymbols;
      var
        i   : longint;
        sym : TObjSymbol;
      begin
        { Update ImageBase to ObjData so it can access from ObjSymbols }
        for i:=0 to ObjDataList.Count-1 do
          TObjData(ObjDataList[i]).imagebase:=imagebase;

        {
          Fixing up symbols is done in the following steps:
           1. Update common references
           2. Update external references
        }

        { Step 1, Update commons }
        for i:=0 to CommonObjSymbols.count-1 do
          begin
            sym:=TObjSymbol(CommonObjSymbols[i]);
            if sym.bind=AB_COMMON then
              begin
                { update this symbol }
                sym.bind:=sym.exesymbol.ObjSymbol.bind;
                sym.offset:=sym.exesymbol.ObjSymbol.offset;
                sym.size:=sym.exesymbol.ObjSymbol.size;
                sym.typ:=sym.exesymbol.ObjSymbol.typ;
                sym.ObjSection:=sym.exesymbol.ObjSymbol.ObjSection;
              end;
          end;

        { Step 2, Update externals }
        for i:=0 to ExternalObjSymbols.count-1 do
          begin
            sym:=TObjSymbol(ExternalObjSymbols[i]);
            if sym.bind=AB_EXTERNAL then
              begin
                if assigned(sym.exesymbol.ObjSymbol) then
                  begin
                    { update this symbol }
                    sym.bind:=sym.exesymbol.ObjSymbol.bind;
                    sym.offset:=sym.exesymbol.ObjSymbol.offset;
                    sym.size:=sym.exesymbol.ObjSymbol.size;
                    sym.typ:=sym.exesymbol.ObjSymbol.typ;
                    sym.ObjSection:=sym.exesymbol.ObjSymbol.ObjSection;
                  end
                else
                  Comment(V_Error,'Undefined symbol: '+sym.name);
              end;
          end;
      end;


    procedure TExeOutput.MergeStabs;
      var
        stabexesec,
        stabstrexesec : TExeSection;
        relocsec,
        currstabsec,
        currstabstrsec,
        mergedstabsec,
        mergedstabstrsec : TObjSection;
        hstabreloc,
        currstabReloc : TObjRelocation;
        i,j,
        mergestabcnt,
        stabcnt : longint;
        skipstab : boolean;
        hstab   : TObjStabEntry;
        stabRelocofs : longint;
        buf     : array[0..1023] of byte;
        bufend,
        bufsize  : longint;
      begin
        stabexesec:=FindExeSection('.stab');
        stabstrexesec:=FindExeSection('.stabstr');
        if (stabexesec=nil) or
           (stabstrexesec=nil) or
           (stabexesec.ObjSectionlist.count=0) then
          exit;
        { Create new stabsection }
        stabRelocofs:=@hstab.nvalue-@hstab;
        mergedstabsec:=internalObjData.CreateSection(sec_stab,'');
        mergedstabstrsec:=internalObjData.CreateSection(sec_stabstr,'');

        { write stab for hdrsym }
        fillchar(hstab,sizeof(TObjStabEntry),0);
        mergedstabsec.write(hstab,sizeof(TObjStabEntry));
        mergestabcnt:=1;

        { .stabstr starts with a #0 }
        buf[0]:=0;
        mergedstabstrsec.write(buf[0],1);

        { Copy stabs and corresponding Relocations }
        for i:=0 to stabexesec.ObjSectionList.Count-1 do
          begin
            currstabsec:=TObjSection(stabexesec.ObjSectionList[i]);
            currstabstrsec:=currstabsec.ObjData.findsection('.stabstr');
            if assigned(currstabstrsec) then
              begin
                stabcnt:=currstabsec.Data.size div sizeof(TObjStabEntry);
                currstabsec.Data.seek(0);
                currstabReloc:=TObjRelocation(currstabsec.Relocations.first);
                for j:=0 to stabcnt-1 do
                  begin
                    hstabreloc:=nil;
                    skipstab:=false;
                    currstabsec.Data.read(hstab,sizeof(TObjStabEntry));
                    { Only include first hdrsym stab }
                    if hstab.ntype=0 then
                      skipstab:=true;
                    if not skipstab then
                      begin
                        { Find corresponding Relocation }
                        while assigned(currstabReloc) and
                              (currstabReloc.Dataoffset<j*sizeof(TObjStabEntry)+stabRelocofs) do
                          currstabReloc:=TObjRelocation(currstabReloc.next);
                        if assigned(currstabReloc) and
                           (currstabReloc.Dataoffset=j*sizeof(TObjStabEntry)+stabRelocofs) then
                          begin
                            hstabReloc:=currstabReloc;
                            currstabReloc:=TObjRelocation(currstabReloc.next);
                          end;
                        { Check if the stab is refering to a removed section }
                        if assigned(hstabreloc) then
                          begin
                            if assigned(hstabreloc.Symbol) then
                              relocsec:=hstabreloc.Symbol.ObjSection
                            else
                              relocsec:=hstabreloc.ObjSection;
                            if not assigned(relocsec) then
                              internalerror(200603302);
                            if not relocsec.Used then
                              skipstab:=true;
                          end;
                      end;
                    if not skipstab then
                      begin
                        { Copy string in stabstr }
                        if hstab.strpos<>0 then
                          begin
                            currstabstrsec.Data.seek(hstab.strpos);
                            hstab.strpos:=mergedstabstrsec.Size;
                            repeat
                              bufsize:=currstabstrsec.Data.read(buf,sizeof(buf));
                              bufend:=indexbyte(buf,bufsize,0);
                              if bufend=-1 then
                                bufend:=bufsize
                              else
                                begin
                                  { include the #0 }
                                  inc(bufend);
                                end;
                              mergedstabstrsec.write(buf,bufend);
                            until (bufend<>-1) or (bufsize<sizeof(buf));
                          end;
                        { Copy and Update the relocation }
                        if assigned(hstabreloc) then
                          begin
                            hstabreloc.Dataoffset:=mergestabcnt*sizeof(TObjStabEntry)+stabRelocofs;
                            currstabsec.Relocations.remove(hstabreloc);
                            mergedstabsec.Relocations.concat(hstabreloc);
                          end;
                        { Write updated stab }
                        mergedstabsec.write(hstab,sizeof(hstab));
                        inc(mergestabcnt);
                      end;
                  end;
              end;

            { Unload stabs }
            if assigned(currstabstrsec) then
              begin
                currstabstrsec.Used:=False;
                currstabstrsec.ReleaseData;
              end;
            currstabsec.Used:=false;
            currstabsec.ReleaseData;
          end;

        { Generate new HdrSym }
        if mergedstabsec.Size>0 then
          begin
            hstab.strpos:=1;
            hstab.ntype:=0;
            hstab.nother:=0;
            hstab.ndesc:=word(mergestabcnt-1);
            hstab.nvalue:=mergedstabstrsec.Size;
            mergedstabsec.Data.seek(0);
            mergedstabsec.Data.write(hstab,sizeof(hstab));
          end;

        { Replace all sections with our combined stabsec }
        stabexesec.ObjSectionList.Clear;
        stabstrexesec.ObjSectionList.Clear;
        stabexesec.AddObjSection(mergedstabsec);
        stabstrexesec.AddObjSection(mergedstabstrsec);
      end;


    procedure TExeOutput.RemoveEmptySections;
      var
        i      : longint;
        exesec : TExeSection;
      begin
        for i:=0 to ExeSections.Count-1 do
          begin
            exesec:=TExeSection(ExeSections[i]);
            if not(oso_keep in exesec.SecOptions) and
               (
                (exesec.ObjSectionlist.count=0) or
                (
                 (cs_link_strip in aktglobalswitches) and
                 (oso_debug in exesec.SecOptions)
                )
               ) then
              begin
                Comment(V_Debug,'Deleting empty section '+exesec.name);
                FExeSectionDict.Delete(exesec.name);
                FExeSectionList[i]:=nil;
              end;
          end;
        ExeSections.Pack;
      end;


    procedure TExeOutput.RemoveUnreferencedSections;
      var
        ObjSectionWorkList : TFPObjectList;

        procedure AddToObjSectionWorkList(aobjsec:TObjSection);
        begin
          if not aobjsec.Used then
            begin
              aobjsec.Used:=true;
              ObjSectionWorkList.Add(aobjsec);
            end;
        end;

      var
        i,j     : longint;
        exesec  : TExeSection;
        ObjData : TObjData;
        refobjsec,
        objsec  : TObjSection;
        objsym  : TObjSymbol;
      begin
        ObjSectionWorkList:=TFPObjectList.Create(false);

        if assigned(exemap) then
          exemap.AddHeader('Removing unreferenced sections');

        { Initialize by marking all sections unused and
          adding the sections with oso_keep flags to the ObjSectionWorkList }
        for i:=0 to ObjDataList.Count-1 do
          begin
            ObjData:=TObjData(ObjDataList[i]);
            for j:=0 to ObjData.ObjSectionList.Count-1 do
              begin
                objsec:=TObjSection(ObjData.ObjSectionList[j]);
                objsec.Used:=false;
{$warning TODO remove debug section always keep}
                if oso_debug in objsec.secoptions then
                  objsec.Used:=true;
                if (oso_keep in objsec.secoptions) then
                  AddToObjSectionWorkList(objsec);
              end;
          end;
        AddToObjSectionWorkList(entrysym.exesymbol.objsymbol.objsection);

        { Process all sections, add new sections to process based
          on the symbol references  }
        while ObjSectionWorkList.Count>0 do
          begin
            objsec:=TObjSection(ObjSectionWorkList.Last);
            if assigned(exemap) then
              exemap.Add('Keeping '+objsec.FullName+' '+ToStr(objsec.ObjSymbolRefs.Count)+' references');
            ObjSectionWorkList.Delete(ObjSectionWorkList.Count-1);
            for i:=0 to objsec.ObjSymbolRefs.count-1 do
              begin
                objsym:=TObjSymbol(objsec.ObjSymbolRefs[i]);
                if objsym.bind=AB_LOCAL then
                  begin
                    if not assigned(objsym.objsection) then
                      internalerror(200603062);
                    refobjsec:=objsym.objsection
                  end
                else
                  begin
                    if not(assigned(objsym.exesymbol) and
                           assigned(objsym.exesymbol.objsymbol)) then
                      internalerror(200603063);
                    refobjsec:=objsym.exesymbol.objsymbol.objsection;
                  end;
                if assigned(exemap) then
                  exemap.Add('  References '+refobjsec.fullname);
                AddToObjSectionWorkList(refobjsec);
              end;
          end;
        ObjSectionWorkList.Free;
        ObjSectionWorkList:=nil;

        { Remove unused objsections from exesections }
        for i:=0 to ExeSections.Count-1 do
          begin
            exesec:=TExeSection(ExeSections[i]);
            for j:=0 to exesec.ObjSectionlist.count-1 do
              begin
                objsec:=TObjSection(exesec.ObjSectionlist[j]);
                if not objsec.used then
                  begin
                    if assigned(exemap) then
                      exemap.Add('Removing '+objsec.FullName);
                    exesec.ObjSectionlist[j]:=nil;
                    objsec.ReleaseData;
                  end;
              end;
            exesec.ObjSectionlist.Pack;
          end;
      end;


    procedure TExeOutput.FixupRelocations;
      var
        i,j     : longint;
        exesec  : TExeSection;
        objsec  : TObjSection;
      begin
        for i:=0 to ExeSections.Count-1 do
          begin
            exesec:=TExeSection(ExeSections[i]);
            for j:=0 to exesec.ObjSectionlist.count-1 do
              begin
                objsec:=TObjSection(exesec.ObjSectionlist[j]);
                if not objsec.Used then
                  internalerror(200603301);
                objsec.FixupRelocs;
              end;
          end;
      end;


{****************************************************************************
                                TObjInput
****************************************************************************}

    constructor TObjInput.create;
      begin
        { init reader }
        FReader:=TObjectreader.create;
      end;


    destructor TObjInput.destroy;
      begin
        FReader.free;
        inherited destroy;
      end;


    function TObjInput.newObjData(const n:string):TObjData;
      begin
        result:=CObjData.create(n);
      end;


    function TObjInput.readobjectfile(const fn:string;Data:TObjData):boolean;
      begin
        result:=false;
        { start the reader }
        if FReader.openfile(fn) then
         begin
           result:=readObjData(Data);
           FReader.closefile;
         end;
      end;

    procedure TObjInput.inputerror(const s : string);
      begin
        Comment(V_Error,s+' while reading '+reader.filename);
      end;

end.
