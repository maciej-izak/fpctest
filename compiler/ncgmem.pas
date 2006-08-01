{
    Copyright (c) 1998-2002 by Florian Klaempfl

    Generate assembler for memory related nodes which are
    the same for all (most?) processors

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
unit ncgmem;

{$i fpcdefs.inc}

interface

    uses
      globtype,cgbase,cpuinfo,cpubase,
      node,nmem;

    type
       tcgloadvmtaddrnode = class(tloadvmtaddrnode)
          procedure pass_2;override;
       end;

       tcgloadparentfpnode = class(tloadparentfpnode)
          procedure pass_2;override;
       end;

       tcgaddrnode = class(taddrnode)
          procedure pass_2;override;
       end;

       tcgderefnode = class(tderefnode)
          procedure pass_2;override;
       end;

       tcgsubscriptnode = class(tsubscriptnode)
          procedure pass_2;override;
       end;

       tcgwithnode = class(twithnode)
          procedure pass_2;override;
       end;

       tcgvecnode = class(tvecnode)
       private
         procedure rangecheck_array;
       protected
         function get_mul_size : aint;
         {# This routine is used to calculate the address of the reference.
            On entry reg contains the index in the array,
           and l contains the size of each element in the array.
           This routine should update location.reference correctly,
           so it points to the correct address.
         }
         procedure update_reference_reg_mul(reg:tregister;l:aint);virtual;
         procedure second_wideansistring;virtual;
         procedure second_dynamicarray;virtual;
       public
         procedure pass_2;override;
       end;


implementation

    uses
      systems,
      cutils,verbose,globals,
      symconst,symdef,symsym,symtable,defutil,paramgr,
      aasmbase,aasmtai,aasmdata,
      procinfo,pass_2,parabase,
      pass_1,nld,ncon,nadd,nutils,
      cgutils,cgobj,
      tgobj,ncgutil
      ;


{*****************************************************************************
                              TCGLOADVMTADDRNODE
*****************************************************************************}

    procedure tcgloadvmtaddrnode.pass_2;
      var
       href : treference;

      begin
         location_reset(location,LOC_REGISTER,OS_ADDR);
         if (left.nodetype=typen) then
           begin
             reference_reset_symbol(href,
               current_asmdata.RefAsmSymbol(tobjectdef(tclassrefdef(resulttype.def).pointertype.def).vmt_mangledname),0);
             location.register:=cg.getaddressregister(current_asmdata.CurrAsmList);
             cg.a_loadaddr_ref_reg(current_asmdata.CurrAsmList,href,location.register);
           end
         else
           begin
             { left contains self, load vmt from self }
             secondpass(left);
             gen_load_vmt_register(current_asmdata.CurrAsmList,tobjectdef(left.resulttype.def),left.location,location.register);
           end;
      end;


{*****************************************************************************
                        TCGLOADPARENTFPNODE
*****************************************************************************}

    procedure tcgloadparentfpnode.pass_2;
      var
        currpi : tprocinfo;
        hsym   : tparavarsym;
        href   : treference;
      begin
        if (current_procinfo.procdef.parast.symtablelevel=parentpd.parast.symtablelevel) then
          begin
            location_reset(location,LOC_REGISTER,OS_ADDR);
            location.register:=current_procinfo.framepointer;
          end
        else
          begin
            currpi:=current_procinfo;
            location_reset(location,LOC_REGISTER,OS_ADDR);
            location.register:=cg.getaddressregister(current_asmdata.CurrAsmList);
            { load framepointer of current proc }
            hsym:=tparavarsym(currpi.procdef.parast.search('parentfp'));
            if not assigned(hsym) then
              internalerror(200309281);
            cg.a_load_loc_reg(current_asmdata.CurrAsmList,OS_ADDR,hsym.localloc,location.register);
            { walk parents }
            while (currpi.procdef.owner.symtablelevel>parentpd.parast.symtablelevel) do
              begin
                currpi:=currpi.parent;
                if not assigned(currpi) then
                  internalerror(200311201);
                hsym:=tparavarsym(currpi.procdef.parast.search('parentfp'));
                if not assigned(hsym) then
                  internalerror(200309282);

                if hsym.localloc.loc<>LOC_REFERENCE then
                  internalerror(200309283);

                reference_reset_base(href,location.register,hsym.localloc.reference.offset);
                cg.a_load_ref_reg(current_asmdata.CurrAsmList,OS_ADDR,OS_ADDR,href,location.register);
              end;
          end;
      end;


{*****************************************************************************
                             TCGADDRNODE
*****************************************************************************}

    procedure tcgaddrnode.pass_2;
      begin
         secondpass(left);

         location_reset(location,LOC_REGISTER,OS_ADDR);
         location.register:=cg.getaddressregister(current_asmdata.CurrAsmList);
         cg.a_loadaddr_ref_reg(current_asmdata.CurrAsmList,left.location.reference,location.register);
      end;


{*****************************************************************************
                           TCGDEREFNODE
*****************************************************************************}

    procedure tcgderefnode.pass_2;
      var
        paraloc1 : tcgpara;
      begin
         secondpass(left);
         location_reset(location,LOC_REFERENCE,def_cgsize(resulttype.def));
         case left.location.loc of
            LOC_CREGISTER,
            LOC_REGISTER:
              begin
              {$ifdef cpu_uses_separate_address_registers}
                if getregtype(left.location.register)<>R_ADDRESSREGISTER then
                  begin
                    location.reference.base := cg.getaddressregister(current_asmdata.CurrAsmList);
                    cg.a_load_reg_reg(current_asmdata.CurrAsmList,OS_ADDR,OS_ADDR,left.location.register,
                      location.reference.base);
                  end
                else
              {$endif}
                  location.reference.base := left.location.register;
              end;
            LOC_CREFERENCE,
            LOC_REFERENCE:
              begin
                 location.reference.base:=cg.getaddressregister(current_asmdata.CurrAsmList);
                 cg.a_load_loc_reg(current_asmdata.CurrAsmList,OS_ADDR,left.location,location.reference.base);
              end;
            LOC_CONSTANT:
              begin
                location.reference.offset:=left.location.value;
              end;
            else
              internalerror(200507031);
         end;
         if (cs_use_heaptrc in aktglobalswitches) and
            (cs_checkpointer in aktlocalswitches) and
            not(cs_compilesystem in aktmoduleswitches) and
            not(tpointerdef(left.resulttype.def).is_far) and
            not(nf_no_checkpointer in flags) then
          begin
            paraloc1.init;
            paramanager.getintparaloc(pocall_default,1,paraloc1);
            paramanager.allocparaloc(current_asmdata.CurrAsmList,paraloc1);
            cg.a_param_reg(current_asmdata.CurrAsmList, OS_ADDR,location.reference.base,paraloc1);
            paramanager.freeparaloc(current_asmdata.CurrAsmList,paraloc1);
            paraloc1.done;
            cg.allocallcpuregisters(current_asmdata.CurrAsmList);
            cg.a_call_name(current_asmdata.CurrAsmList,'FPC_CHECKPOINTER');
            cg.deallocallcpuregisters(current_asmdata.CurrAsmList);
          end;
      end;


{*****************************************************************************
                          TCGSUBSCRIPTNODE
*****************************************************************************}

    procedure tcgsubscriptnode.pass_2;
      var
        paraloc1 : tcgpara;
      begin
         secondpass(left);
         if codegenerror then
           exit;
         paraloc1.init;
         { classes and interfaces must be dereferenced implicit }
         if is_class_or_interface(left.resulttype.def) then
           begin
             location_reset(location,LOC_REFERENCE,def_cgsize(resulttype.def));
             case left.location.loc of
                LOC_CREGISTER,
                LOC_REGISTER:
                  begin
                  {$ifdef cpu_uses_separate_address_registers}
                    if getregtype(left.location.register)<>R_ADDRESSREGISTER then
                      begin
                        location.reference.base:=rg.getaddressregister(current_asmdata.CurrAsmList);
                        cg.a_load_reg_reg(current_asmdata.CurrAsmList,OS_ADDR,OS_ADDR,
                          left.location.register,location.reference.base);
                      end
                    else
                  {$endif}
                      location.reference.base := left.location.register;
                  end;
                LOC_CREFERENCE,
                LOC_REFERENCE:
                  begin
                     location.reference.base:=cg.getaddressregister(current_asmdata.CurrAsmList);
                     cg.a_load_loc_reg(current_asmdata.CurrAsmList,OS_ADDR,left.location,location.reference.base);
                  end;
             end;
             { implicit deferencing }
             if (cs_use_heaptrc in aktglobalswitches) and
                (cs_checkpointer in aktlocalswitches) and
                not(cs_compilesystem in aktmoduleswitches) then
              begin
                paramanager.getintparaloc(pocall_default,1,paraloc1);
                paramanager.allocparaloc(current_asmdata.CurrAsmList,paraloc1);
                cg.a_param_reg(current_asmdata.CurrAsmList, OS_ADDR,location.reference.base,paraloc1);
                paramanager.freeparaloc(current_asmdata.CurrAsmList,paraloc1);
                cg.allocallcpuregisters(current_asmdata.CurrAsmList);
                cg.a_call_name(current_asmdata.CurrAsmList,'FPC_CHECKPOINTER');
                cg.deallocallcpuregisters(current_asmdata.CurrAsmList);
              end;
           end
         else if is_interfacecom(left.resulttype.def) then
           begin
             location_reset(location,LOC_REFERENCE,def_cgsize(resulttype.def));
             tg.GetTempTyped(current_asmdata.CurrAsmList,left.resulttype.def,tt_normal,location.reference);
             cg.a_load_loc_ref(current_asmdata.CurrAsmList,OS_ADDR,left.location,location.reference);
             { implicit deferencing also for interfaces }
             if (cs_use_heaptrc in aktglobalswitches) and
                (cs_checkpointer in aktlocalswitches) and
                not(cs_compilesystem in aktmoduleswitches) then
              begin
                paramanager.getintparaloc(pocall_default,1,paraloc1);
                paramanager.allocparaloc(current_asmdata.CurrAsmList,paraloc1);
                cg.a_param_reg(current_asmdata.CurrAsmList, OS_ADDR,location.reference.base,paraloc1);
                paramanager.freeparaloc(current_asmdata.CurrAsmList,paraloc1);
                cg.allocallcpuregisters(current_asmdata.CurrAsmList);
                cg.a_call_name(current_asmdata.CurrAsmList,'FPC_CHECKPOINTER');
                cg.deallocallcpuregisters(current_asmdata.CurrAsmList);
              end;
           end
         else
           begin
             location_copy(location,left.location);
             { some abi's require that functions return (some) records in }
             { registers                                                  }
             case location.loc of
               LOC_REFERENCE,
               LOC_CREFERENCE:
                 ;
               LOC_REGISTER,
               LOC_CREGISTER:
                 begin
                   if (left.resulttype.def.size > sizeof(aint)) then
                     location_force_mem(current_asmdata.CurrAsmList,location)
                   else
                     begin
                       if (left.location.loc = LOC_REGISTER) then
                         location.loc := LOC_SUBSETREG
                       else
                         location.loc := LOC_CSUBSETREG;
                       location.size:=def_cgsize(resulttype.def);
                       location.sreg.subsetreg := left.location.register;
                       location.sreg.subsetregsize := left.location.size;
                       if (target_info.endian = ENDIAN_BIG) then
                         location.sreg.startbit := (tcgsize2size[location.sreg.subsetregsize] - tcgsize2size[location.size] - vs.fieldoffset) * 8
                       else
                         location.sreg.startbit := (vs.fieldoffset * 8);
                       location.sreg.bitlen := tcgsize2size[location.size] * 8;
                     end;
                 end;
               LOC_SUBSETREG,
               LOC_CSUBSETREG:
                 begin
                   location.size:=def_cgsize(resulttype.def);
                   if (target_info.endian = ENDIAN_BIG) then
                     inc(location.sreg.startbit, (left.resulttype.def.size - tcgsize2size[location.size] - vs.fieldoffset) * 8)
                   else
                     inc(location.sreg.startbit, vs.fieldoffset * 8);
                   location.sreg.bitlen := tcgsize2size[location.size] * 8;
                 end;
               else
                 internalerror(2006031901);
             end;
           end;

         if (location.loc in [LOC_REFERENCE,LOC_CREFERENCE]) then
           begin
             inc(location.reference.offset,vs.fieldoffset);
    {$ifdef SUPPORT_UNALIGNED}
             { packed? }
             if (vs.owner.defowner.deftype in [recorddef,objectdef]) and
               (tabstractrecordsymtable(vs.owner).usefieldalignment=1) then
               location.reference.alignment:=1;
    {$endif SUPPORT_UNALIGNED}
    
             { also update the size of the location }
             location.size:=def_cgsize(resulttype.def);
           end;
         paraloc1.done;
      end;


{*****************************************************************************
                            TCGWITHNODE
*****************************************************************************}

    procedure tcgwithnode.pass_2;
      begin
        location_reset(location,LOC_VOID,OS_NO);

        if assigned(left) then
          secondpass(left);
       end;


{*****************************************************************************
                            TCGVECNODE
*****************************************************************************}

     function tcgvecnode.get_mul_size : aint;
       begin
         if nf_memindex in flags then
          get_mul_size:=1
         else
          begin
            if (left.resulttype.def.deftype=arraydef) then
             get_mul_size:=tarraydef(left.resulttype.def).elesize
            else
             get_mul_size:=resulttype.def.size;
          end
       end;


     procedure tcgvecnode.update_reference_reg_mul(reg:tregister;l:aint);
       var
         hreg: tregister;
       begin
         if location.reference.base=NR_NO then
          begin
            if l<>1 then
              cg.a_op_const_reg(current_asmdata.CurrAsmList,OP_IMUL,OS_ADDR,l,reg);
            location.reference.base:=reg;
          end
         else if location.reference.index=NR_NO then
          begin
            if l<>1 then
              cg.a_op_const_reg(current_asmdata.CurrAsmList,OP_IMUL,OS_ADDR,l,reg);
            location.reference.index:=reg;
          end
         else
          begin
            hreg := cg.getaddressregister(current_asmdata.CurrAsmList);
            cg.a_loadaddr_ref_reg(current_asmdata.CurrAsmList,location.reference,hreg);
            reference_reset_base(location.reference,hreg,0);
            { insert new index register }
            if l<>1 then
              cg.a_op_const_reg(current_asmdata.CurrAsmList,OP_IMUL,OS_ADDR,l,reg);
            location.reference.index:=reg;
          end;
       end;


     procedure tcgvecnode.second_wideansistring;
       begin
       end;

     procedure tcgvecnode.second_dynamicarray;
       begin
       end;


     procedure tcgvecnode.rangecheck_array;
       var
         hightree : tnode;
         poslabel,
         neglabel : tasmlabel;
         hreg : tregister;
         paraloc1,paraloc2 : tcgpara;
       begin
         paraloc1.init;
         paraloc2.init;
         if is_open_array(left.resulttype.def) or
            is_array_of_const(left.resulttype.def) then
          begin
            { cdecl functions don't have high() so we can not check the range }
            if not(current_procinfo.procdef.proccalloption in [pocall_cdecl,pocall_cppdecl]) then
             begin
               { Get high value }
               hightree:=load_high_value_node(tparavarsym(tloadnode(left).symtableentry));
               { it must be available }
               if not assigned(hightree) then
                 internalerror(200212201);
               firstpass(hightree);
               secondpass(hightree);
               { generate compares }
               if (right.location.loc in [LOC_REGISTER,LOC_CREGISTER]) then
                 hreg:=cg.makeregsize(current_asmdata.CurrAsmList,right.location.register,OS_INT)
               else
                 begin
                   hreg:=cg.getintregister(current_asmdata.CurrAsmList,OS_INT);
                   cg.a_load_loc_reg(current_asmdata.CurrAsmList,OS_INT,right.location,hreg);
                 end;
               current_asmdata.getjumplabel(neglabel);
               current_asmdata.getjumplabel(poslabel);
               cg.a_cmp_const_reg_label(current_asmdata.CurrAsmList,OS_INT,OC_LT,0,hreg,poslabel);
               cg.a_cmp_loc_reg_label(current_asmdata.CurrAsmList,OS_INT,OC_BE,hightree.location,hreg,neglabel);
               cg.a_label(current_asmdata.CurrAsmList,poslabel);
               cg.a_call_name(current_asmdata.CurrAsmList,'FPC_RANGEERROR');
               cg.a_label(current_asmdata.CurrAsmList,neglabel);
               { release hightree }
               hightree.free;
             end;
          end
         else
          if is_dynamic_array(left.resulttype.def) then
            begin
               paramanager.getintparaloc(pocall_default,1,paraloc1);
               paramanager.getintparaloc(pocall_default,2,paraloc2);
               paramanager.allocparaloc(current_asmdata.CurrAsmList,paraloc2);
               cg.a_param_loc(current_asmdata.CurrAsmList,right.location,paraloc2);
               paramanager.allocparaloc(current_asmdata.CurrAsmList,paraloc1);
               cg.a_param_loc(current_asmdata.CurrAsmList,left.location,paraloc1);
               paramanager.freeparaloc(current_asmdata.CurrAsmList,paraloc1);
               paramanager.freeparaloc(current_asmdata.CurrAsmList,paraloc2);
               cg.allocallcpuregisters(current_asmdata.CurrAsmList);
               cg.a_call_name(current_asmdata.CurrAsmList,'FPC_DYNARRAY_RANGECHECK');
               cg.deallocallcpuregisters(current_asmdata.CurrAsmList);
            end
         else
           cg.g_rangecheck(current_asmdata.CurrAsmList,right.location,right.resulttype.def,left.resulttype.def);
         paraloc1.done;
         paraloc2.done;
       end;


    procedure tcgvecnode.pass_2;

      var
         offsetdec,
         extraoffset : aint;
         t        : tnode;
         href     : treference;
         otl,ofl  : tasmlabel;
         newsize  : tcgsize;
         mulsize  : aint;
         isjump   : boolean;
         paraloc1,
         paraloc2 : tcgpara;
      begin
         paraloc1.init;
         paraloc2.init;
         mulsize := get_mul_size;

         newsize:=def_cgsize(resulttype.def);
         secondpass(left);
         if left.location.loc=LOC_CREFERENCE then
           location_reset(location,LOC_CREFERENCE,newsize)
         else
           location_reset(location,LOC_REFERENCE,newsize);

         { an ansistring needs to be dereferenced }
         if is_ansistring(left.resulttype.def) or
            is_widestring(left.resulttype.def) then
           begin
              if nf_callunique in flags then
                internalerror(200304236);

              {DM!!!!!}
              case left.location.loc of
                LOC_REGISTER,
                LOC_CREGISTER :
                  location.reference.base:=left.location.register;
                LOC_CREFERENCE,
                LOC_REFERENCE :
                  begin
                    location.reference.base:=cg.getaddressregister(current_asmdata.CurrAsmList);
                    cg.a_load_ref_reg(current_asmdata.CurrAsmList,OS_ADDR,OS_ADDR,left.location.reference,location.reference.base);
                  end;
                else
                  internalerror(2002032218);
              end;

              { check for a zero length string,
                we can use the ansistring routine here }
              if (cs_check_range in aktlocalswitches) then
                begin
                   paramanager.getintparaloc(pocall_default,1,paraloc1);
                   paramanager.allocparaloc(current_asmdata.CurrAsmList,paraloc1);
                   cg.a_param_reg(current_asmdata.CurrAsmList,OS_ADDR,location.reference.base,paraloc1);
                   paramanager.freeparaloc(current_asmdata.CurrAsmList,paraloc1);
                   cg.allocallcpuregisters(current_asmdata.CurrAsmList);
                   cg.a_call_name(current_asmdata.CurrAsmList,'FPC_'+upper(tstringdef(left.resulttype.def).stringtypname)+'_CHECKZERO');
                   cg.deallocallcpuregisters(current_asmdata.CurrAsmList);
                end;

              { in ansistrings/widestrings S[1] is p<w>char(S)[0] !! }
              if is_ansistring(left.resulttype.def) then
                offsetdec:=1
              else
                offsetdec:=2;
              dec(location.reference.offset,offsetdec);
           end
         else if is_dynamic_array(left.resulttype.def) then
           begin
              case left.location.loc of
                LOC_REGISTER,
                LOC_CREGISTER :
                  location.reference.base:=left.location.register;
                LOC_REFERENCE,
                LOC_CREFERENCE :
                  begin
                     location.reference.base:=cg.getaddressregister(current_asmdata.CurrAsmList);
                     cg.a_load_ref_reg(current_asmdata.CurrAsmList,OS_ADDR,OS_ADDR,
                      left.location.reference,location.reference.base);
                  end;
                else
                  internalerror(2002032219);
              end;
           end
         else
           location_copy(location,left.location);

         { location must be memory }
         if not(location.loc in [LOC_REFERENCE,LOC_CREFERENCE]) then
           internalerror(200411013);

         { offset can only differ from 0 if arraydef }
         if (left.resulttype.def.deftype=arraydef) and
            not(is_dynamic_array(left.resulttype.def)) then
           dec(location.reference.offset,mulsize*tarraydef(left.resulttype.def).lowrange);

         if right.nodetype=ordconstn then
           begin
              { offset can only differ from 0 if arraydef }
              case left.resulttype.def.deftype of
                arraydef :
                  begin
                     if not(is_open_array(left.resulttype.def)) and
                        not(is_array_of_const(left.resulttype.def)) and
                        not(is_dynamic_array(left.resulttype.def)) then
                       begin
                          if (tordconstnode(right).value>tarraydef(left.resulttype.def).highrange) or
                             (tordconstnode(right).value<tarraydef(left.resulttype.def).lowrange) then
                            begin
                              { this should be caught in the resulttypepass! (JM) }
                              if (cs_check_range in aktlocalswitches) then
                                CGMessage(parser_e_range_check_error)
                              else
                                CGMessage(parser_w_range_check_error);
                            end;
                       end
                     else
                       begin
                          { range checking for open and dynamic arrays needs
                            runtime code }
                          secondpass(right);
                          if (cs_check_range in aktlocalswitches) then
                            rangecheck_array;
                       end;
                  end;
                stringdef :
                  begin
                    if (cs_check_range in aktlocalswitches) then
                     begin
                       case tstringdef(left.resulttype.def).string_typ of
                         { it's the same for ansi- and wide strings }
                         st_widestring,
                         st_ansistring:
                           begin
                              paramanager.getintparaloc(pocall_default,1,paraloc1);
                              paramanager.getintparaloc(pocall_default,2,paraloc2);
                              paramanager.allocparaloc(current_asmdata.CurrAsmList,paraloc2);
                              cg.a_param_const(current_asmdata.CurrAsmList,OS_INT,tordconstnode(right).value,paraloc2);
                              href:=location.reference;
                              dec(href.offset,sizeof(aint)-offsetdec);
                              paramanager.allocparaloc(current_asmdata.CurrAsmList,paraloc1);
                              cg.a_param_ref(current_asmdata.CurrAsmList,OS_INT,href,paraloc1);
                              paramanager.freeparaloc(current_asmdata.CurrAsmList,paraloc1);
                              paramanager.freeparaloc(current_asmdata.CurrAsmList,paraloc2);
                              cg.allocallcpuregisters(current_asmdata.CurrAsmList);
                              cg.a_call_name(current_asmdata.CurrAsmList,'FPC_'+upper(tstringdef(left.resulttype.def).stringtypname)+'_RANGECHECK');
                              cg.deallocallcpuregisters(current_asmdata.CurrAsmList);
                           end;

                         st_shortstring:
                           begin
                              {!!!!!!!!!!!!!!!!!}
                              { if this one is implemented making use of the high parameter for openshortstrings, update ncgutils.do_get_used_regvars() too (JM) }
                           end;

                         st_longstring:
                           begin
                              {!!!!!!!!!!!!!!!!!}
                           end;
                       end;
                     end;
                   end;
              end;
              inc(location.reference.offset,
                  mulsize*tordconstnode(right).value);
           end
         else
         { not nodetype=ordconstn }
           begin
              if (cs_opt_regvar in aktoptimizerswitches) and
                 { if we do range checking, we don't }
                 { need that fancy code (it would be }
                 { buggy)                            }
                 not(cs_check_range in aktlocalswitches) and
                 (left.resulttype.def.deftype=arraydef) then
                begin
                   extraoffset:=0;
                   if (right.nodetype=addn) then
                     begin
                        if taddnode(right).right.nodetype=ordconstn then
                          begin
                             extraoffset:=tordconstnode(taddnode(right).right).value;
                             t:=taddnode(right).left;
                             { First pass processed this with the assumption   }
                             { that there was an add node which may require an }
                             { extra register. Fake it or die with IE10 (JM)   }
                             t.registersint := taddnode(right).registersint;
                             taddnode(right).left:=nil;
                             right.free;
                             right:=t;
                          end
                        else if taddnode(right).left.nodetype=ordconstn then
                          begin
                             extraoffset:=tordconstnode(taddnode(right).left).value;
                             t:=taddnode(right).right;
                             t.registersint :=  right.registersint;
                             taddnode(right).right:=nil;
                             right.free;
                             right:=t;
                          end;
                     end
                   else if (right.nodetype=subn) then
                     begin
                        if taddnode(right).right.nodetype=ordconstn then
                          begin
                             extraoffset:=-tordconstnode(taddnode(right).right).value;
                             t:=taddnode(right).left;
                             t.registersint :=  right.registersint;
                             taddnode(right).left:=nil;
                             right.free;
                             right:=t;
                          end
{ You also have to negate right.right in this case! I can't add an
  unaryminusn without causing a crash, so I've disabled it (JM)
                        else if right.left.nodetype=ordconstn then
                          begin
                             extraoffset:=right.left.value;
                             t:=right.right;
                             t^.registersint :=  right.registersint;
                             putnode(right);
                             putnode(right.left);
                             right:=t;
                         end;}
                     end;
                   inc(location.reference.offset,
                       mulsize*extraoffset);
                end;
              { calculate from left to right }
              if not(location.loc in [LOC_CREFERENCE,LOC_REFERENCE]) then
                internalerror(200304237);
              isjump:=(right.expectloc=LOC_JUMP);
              if isjump then
               begin
                 otl:=current_procinfo.CurrTrueLabel;
                 current_asmdata.getjumplabel(current_procinfo.CurrTrueLabel);
                 ofl:=current_procinfo.CurrFalseLabel;
                 current_asmdata.getjumplabel(current_procinfo.CurrFalseLabel);
               end;
              secondpass(right);

              { if mulsize = 1, we won't have to modify the index }
              location_force_reg(current_asmdata.CurrAsmList,right.location,OS_ADDR,(mulsize = 1));

              if isjump then
               begin
                 current_procinfo.CurrTrueLabel:=otl;
                 current_procinfo.CurrFalseLabel:=ofl;
               end
              else if (right.location.loc = LOC_JUMP) then
                internalerror(2006010801);

              { only range check now, we can't range check loc_flags/loc_jump }
              if cs_check_range in aktlocalswitches then
               begin
                 if left.resulttype.def.deftype=arraydef then
                   rangecheck_array;
               end;

            { produce possible range check code: }
              if cs_check_range in aktlocalswitches then
               begin
                 if left.resulttype.def.deftype=arraydef then
                   begin
                     { done defore (PM) }
                   end
                 else if (left.resulttype.def.deftype=stringdef) then
                   begin
                      case tstringdef(left.resulttype.def).string_typ of
                         { it's the same for ansi- and wide strings }
                         st_widestring,
                         st_ansistring:
                           begin
                              paramanager.getintparaloc(pocall_default,1,paraloc1);
                              paramanager.getintparaloc(pocall_default,2,paraloc2);
                              paramanager.allocparaloc(current_asmdata.CurrAsmList,paraloc2);
                              cg.a_param_reg(current_asmdata.CurrAsmList,OS_INT,right.location.register,paraloc2);
                              href:=location.reference;
                              dec(href.offset,sizeof(aint)-offsetdec);
                              //dec(href.offset,7);
                              paramanager.allocparaloc(current_asmdata.CurrAsmList,paraloc1);
                              cg.a_param_ref(current_asmdata.CurrAsmList,OS_INT,href,paraloc1);
                              paramanager.freeparaloc(current_asmdata.CurrAsmList,paraloc1);
                              paramanager.freeparaloc(current_asmdata.CurrAsmList,paraloc2);
                              cg.allocallcpuregisters(current_asmdata.CurrAsmList);
                              cg.a_call_name(current_asmdata.CurrAsmList,'FPC_'+upper(tstringdef(left.resulttype.def).stringtypname)+'_RANGECHECK');
                              cg.deallocallcpuregisters(current_asmdata.CurrAsmList);
                           end;
                         st_shortstring:
                           begin
                              {!!!!!!!!!!!!!!!!!}
                           end;
                         st_longstring:
                           begin
                              {!!!!!!!!!!!!!!!!!}
                           end;
                      end;
                   end;
               end;

              { insert the register and the multiplication factor in the
                reference }
              update_reference_reg_mul(right.location.register,mulsize);
           end;

        location.size:=newsize;
        paraloc1.done;
        paraloc2.done;
      end;


begin
   cloadvmtaddrnode:=tcgloadvmtaddrnode;
   cloadparentfpnode:=tcgloadparentfpnode;
   caddrnode:=tcgaddrnode;
   cderefnode:=tcgderefnode;
   csubscriptnode:=tcgsubscriptnode;
   cwithnode:=tcgwithnode;
   cvecnode:=tcgvecnode;
end.
