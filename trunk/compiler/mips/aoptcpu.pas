{
    Copyright (c) 1998-2004 by Jonas Maebe

    This unit calls the optimization procedures to optimize the assembler
    code for sparc

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

unit aoptcpu;

{$i fpcdefs.inc}

  Interface

    uses
      cgbase, cpubase, aoptobj, aoptcpub, aopt, aasmtai, aasmcpu;

    Type
      TAsmOpSet = set of TAsmOp;

      TCpuAsmOptimizer = class(TAsmOptimizer)
        function RegModifiedByInstruction(Reg: TRegister; p1: tai): boolean; override;
        function GetNextInstructionUsingReg(Current: tai;
          var Next: tai; reg: TRegister): Boolean;
        function RegUsedAfterInstruction(reg: Tregister; p: tai;
          var AllUsedRegs: TAllUsedRegs): Boolean;
        function TryRemoveMov(var p: tai; opcode: TAsmOp): boolean;
        function TryRemoveMovToRefIndex(var p: tai; next: taicpu): boolean;
        function TryRemoveMovBeforeStore(var p: tai; next: taicpu; const storeops: TAsmOpSet): boolean;
        function PeepHoleOptPass1Cpu(var p: tai): boolean; override;
        procedure PeepHoleOptPass2; override;
      End;

  Implementation

     uses
       globals,aasmbase,cpuinfo,verbose;


  function MatchInstruction(const instr: tai; const op: TAsmOp): boolean;
    begin
      result :=
        (instr.typ = ait_instruction) and
        (taicpu(instr).opcode = op);
    end;


  function MatchOperand(const oper: TOper; reg: TRegister): boolean;
    begin
      result:=(oper.typ=top_reg) and (oper.reg=reg);
    end;


  function IsSameReg(this,next: taicpu): boolean;
    begin
      result:=(next.oper[0]^.typ=top_reg) and
        (next.oper[1]^.typ=top_reg) and
        (next.oper[0]^.reg=next.oper[1]^.reg) and
        (next.oper[0]^.reg=this.oper[0]^.reg);
    end;


  function regLoadedWithNewValue(reg: tregister; hp: tai): boolean;
    var
      p: taicpu;
    begin
      p:=taicpu(hp);
      result:=false;
      if not ((assigned(hp)) and (hp.typ=ait_instruction)) then
        exit;

      case p.opcode of
        { These instructions do not write into a register at all }
        A_NOP,
        A_C_EQ_D,A_C_EQ_S,A_C_LE_D,A_C_LE_S,A_C_LT_D,A_C_LT_S,
        A_BA,A_BC,
        A_SB,A_SH,A_SW,A_SWL,A_SWR,A_SWC1,A_SDC1:
          exit;
      end;

      result:=(p.ops>0) and (p.oper[0]^.typ=top_reg) and
        (p.oper[0]^.reg=reg);
    end;


  function CanBeCMOV(p: tai; condreg: tregister): boolean;
    begin
      result:=assigned(p) and (p.typ=ait_instruction) and
        ((taicpu(p).opcode in [A_MOV_D,A_MOV_S]) or
        (
          { register with condition must not be overwritten }
          (taicpu(p).opcode=A_MOVE) and
          (taicpu(p).oper[0]^.reg<>condreg)
        ));
    end;


  procedure ChangeToCMOV(p: taicpu; cond: tasmcond; reg: tregister);
    begin
      case cond of
        C_COP1TRUE:
          case p.opcode of
            A_MOV_D: p.opcode:=A_MOVT_D;
            A_MOV_S: p.opcode:=A_MOVT_S;
            A_MOVE:  p.opcode:=A_MOVT;
          else
            InternalError(2014061701);
          end;
        C_COP1FALSE:
          case p.opcode of
            A_MOV_D: p.opcode:=A_MOVF_D;
            A_MOV_S: p.opcode:=A_MOVF_S;
            A_MOVE:  p.opcode:=A_MOVF;
          else
            InternalError(2014061702);
          end;
        C_EQ:
          case p.opcode of
            A_MOV_D: p.opcode:=A_MOVZ_D;
            A_MOV_S: p.opcode:=A_MOVZ_S;
            A_MOVE:  p.opcode:=A_MOVZ;
          else
            InternalError(2014061703);
          end;
        C_NE:
          case p.opcode of
            A_MOV_D: p.opcode:=A_MOVN_D;
            A_MOV_S: p.opcode:=A_MOVN_S;
            A_MOVE:  p.opcode:=A_MOVN;
          else
            InternalError(2014061704);
          end;
      else
        InternalError(2014061705);
      end;
      p.ops:=3;
      p.loadreg(2,reg);
    end;


  function instructionLoadsFromReg(const reg: TRegister; const hp: tai): boolean;
    var
      p: taicpu;
      i: longint;
    begin
      result:=false;
      if not (assigned(hp) and (hp.typ=ait_instruction)) then
        exit;
      p:=taicpu(hp);

      i:=1;
      while(i<p.ops) do
        begin
          case p.oper[I]^.typ of
            top_reg:
              result:=(p.oper[I]^.reg=reg) and (I<2);
            top_ref:
              result:=
                (p.oper[I]^.ref^.base=reg) or
                (p.oper[I]^.ref^.index=reg);
          end;
          if result then exit; {Bailout if we found something}
          Inc(I);
        end;
    end;


  function TCpuAsmOptimizer.RegModifiedByInstruction(Reg: TRegister; p1: tai): boolean;
    var
      i : Longint;
    begin
      result:=false;
      for i:=0 to taicpu(p1).ops-1 do
        if (taicpu(p1).oper[i]^.typ=top_reg) and (taicpu(p1).oper[i]^.reg=Reg) and (taicpu(p1).spilling_get_operation_type(i) in [operand_write,operand_readwrite]) then
          begin
            result:=true;
            exit;
          end;
    end;


  function TCpuAsmOptimizer.GetNextInstructionUsingReg(Current: tai;
    var Next: tai; reg: TRegister): Boolean;
    begin
      Next:=Current;
      repeat
        Result:=GetNextInstruction(Next,Next);
      until {not(cs_opt_level3 in current_settings.optimizerswitches) or} not(Result) or (Next.typ<>ait_instruction) or (RegInInstruction(reg,Next)) or
        (is_calljmp(taicpu(Next).opcode));
      if Result and (next.typ=ait_instruction) and is_calljmp(taicpu(next).opcode) then
        begin
          result:=false;
          next:=nil;
        end;
    end;


  function TCpuAsmOptimizer.RegUsedAfterInstruction(reg: Tregister; p: tai;
    var AllUsedRegs: TAllUsedRegs): Boolean;
    begin
      AllUsedRegs[getregtype(reg)].Update(tai(p.Next),true);
      RegUsedAfterInstruction :=
        AllUsedRegs[getregtype(reg)].IsUsed(reg) and
        not(regLoadedWithNewValue(reg,p)) and
        (
          not(GetNextInstruction(p,p)) or
          instructionLoadsFromReg(reg,p) or
          not(regLoadedWithNewValue(reg,p))
        );
    end;


  function TCpuAsmOptimizer.TryRemoveMov(var p: tai; opcode: TAsmOp): boolean;
    var
      next,hp1: tai;
      alloc,dealloc: tai_regalloc;
    begin
      { Fold
          op      $reg1,...
          opcode  $reg2,$reg1
          dealloc $reg1
        into
          op   $reg2,...
        opcode may be A_MOVE, A_MOV_s, A_MOV_d, etc.
      }
      result:=false;
      if (taicpu(p).ops>0) and
         GetNextInstructionUsingReg(p,next,taicpu(p).oper[0]^.reg) and
         MatchInstruction(next,opcode) and
         MatchOperand(taicpu(next).oper[1]^,taicpu(p).oper[0]^.reg) and
         { the destination register of mov cannot be used between p and next }
         (not RegUsedBetween(taicpu(next).oper[0]^.reg,p,next)) then

        begin
          dealloc:=FindRegDealloc(taicpu(p).oper[0]^.reg,tai(next.Next));
          if assigned(dealloc) then
            begin
              { taicpu(p).oper[0]^.reg is not used anymore, try to find its allocation
                and remove it if possible }
              GetLastInstruction(p,hp1);

              asml.Remove(dealloc);
              alloc:=FindRegAlloc(taicpu(p).oper[0]^.reg,tai(hp1.Next));
              if assigned(alloc) then
                begin
                  asml.Remove(alloc);
                  alloc.free;
                  dealloc.free;
                end
              else
                asml.InsertAfter(dealloc,p);

              { try to move the allocation of the target register }
              GetLastInstruction(next,hp1);
              alloc:=FindRegAlloc(taicpu(next).oper[0]^.reg,tai(hp1.Next));
              if assigned(alloc) then
                begin
                  asml.Remove(alloc);
                  asml.InsertBefore(alloc,p);
                  { adjust used regs }
                  IncludeRegInUsedRegs(taicpu(next).oper[0]^.reg,UsedRegs);
                end;

              { finally get rid of the mov }
              taicpu(p).loadreg(0,taicpu(next).oper[0]^.reg);
              asml.remove(next);
              next.free;
              result:=true;
            end;
        end;
    end;


  function TCpuAsmOptimizer.TryRemoveMovBeforeStore(var p: tai; next: taicpu; const storeops: TAsmOpSet): boolean;
    begin
      result:=(next.opcode in storeops) and
        MatchOperand(next.oper[0]^,taicpu(p).oper[0]^.reg) and
        { Ry cannot be modified between move and store }
        (not RegModifiedBetween(taicpu(p).oper[1]^.reg,p,next)) and
        Assigned(FindRegDealloc(taicpu(p).oper[0]^.reg,tai(next.next)));
      if result then
        begin
          next.loadreg(0,taicpu(p).oper[1]^.reg);
          asml.remove(p);
          p.free;
          p:=next;
        end;
    end;


  function TCpuAsmOptimizer.TryRemoveMovToRefIndex(var p: tai; next: taicpu): boolean;
    begin
      result:=(next.oper[1]^.typ=top_ref) and
        (next.oper[1]^.ref^.base=taicpu(p).oper[0]^.reg) and
        (not RegModifiedBetween(taicpu(p).oper[1]^.reg,p,next)) and
        Assigned(FindRegDealloc(taicpu(p).oper[0]^.reg,tai(next.next)));
      if result then
        begin
          next.oper[1]^.ref^.base:=taicpu(p).oper[1]^.reg;
          asml.remove(p);
          p.free;
          p:=next;
        end;
    end;


  function TCpuAsmOptimizer.PeepHoleOptPass1Cpu(var p: tai): boolean;
    var
      next,next2: tai;
      TmpUsedRegs: TAllUsedRegs;
    begin
      result:=false;
      case p.typ of
        ait_instruction:
          begin
            case taicpu(p).opcode of
              A_SEH:
                begin
                  if GetNextInstructionUsingReg(p,next,taicpu(p).oper[0]^.reg) and
                    MatchInstruction(next,A_SH) and
                    MatchOperand(taicpu(next).oper[0]^,taicpu(p).oper[0]^.reg) and
                    (not RegUsedBetween(taicpu(p).oper[1]^.reg,p,next)) and
                    Assigned(FindRegDealloc(taicpu(p).oper[0]^.reg,tai(next.next))) then
                    begin
                      taicpu(next).loadreg(0,taicpu(p).oper[1]^.reg);
                      asml.remove(p);
                      p.free;
                      p:=next;
                    end
                  else
                    TryRemoveMov(p,A_MOVE);
                end;
              A_SEB:
                { TODO: can be handled similar to A_SEH, but it's almost never encountered }
                TryRemoveMov(p,A_MOVE);

              A_SLL:
                begin
                  { if this is a sign extension... }
                  if (taicpu(p).oper[2]^.typ=top_const) and
                    GetNextInstruction(p,next) and
                    MatchInstruction(next,A_SRA) and
                    IsSameReg(taicpu(p),taicpu(next)) and
                    (taicpu(next).oper[2]^.typ=top_const) and
                    (taicpu(next).oper[2]^.val=taicpu(p).oper[2]^.val) and
                    (taicpu(next).oper[2]^.val=16) and
                    { ...followed by 16-bit store (possibly with PIC simplification, etc. in between) }
                    GetNextInstructionUsingReg(next,next2,taicpu(p).oper[0]^.reg) and
                    MatchInstruction(next2,A_SH) and
                    (taicpu(next2).oper[0]^.typ=top_reg) and
                    (taicpu(next2).oper[0]^.reg=taicpu(p).oper[0]^.reg) and
                    { the initial register may not be reused }
                    (not RegUsedBetween(taicpu(p).oper[1]^.reg,next,next2)) then
                    begin
                      if Assigned(FindRegDealloc(taicpu(p).oper[0]^.reg,tai(next2.next))) then
                        begin
                          taicpu(next2).loadreg(0,taicpu(p).oper[1]^.reg);
                          asml.remove(p);
                          asml.remove(next);
                          p.free;
                          next.free;
                          p:=next2;
                        end;
                    end
                  else
                    TryRemoveMov(p,A_MOVE);
                end;

              A_SRL:
                begin
                  { TODO: also kill sign-extensions that follow, both SLL+SRA and SEB/SEH versions }
                  { Remove 'andi' in sequences
                      srl   Rx,Ry,16
                      andi  Rx,Rx,65535

                      srl   Rx,Ry,24
                      andi  Rx,Rx,255
                    since 'srl' clears all relevant upper bits }
                  if (taicpu(p).oper[2]^.typ=top_const) and
                    GetNextInstruction(p,next) and
                    MatchInstruction(next,A_ANDI) and
                    IsSameReg(taicpu(p),taicpu(next)) and
                    (taicpu(next).oper[2]^.typ=top_const) and
                    ((
                      (taicpu(p).oper[2]^.val>=16) and
                      (taicpu(next).oper[2]^.val=65535)
                    ) or (
                      (taicpu(p).oper[2]^.val>=24) and
                      (taicpu(next).oper[2]^.val=255)
                    )) then
                    begin
                      asml.remove(next);
                      next.free;
                    end
                  else
                    TryRemoveMov(p,A_MOVE);
                end;

              A_ANDI:
                begin
                  { Remove sign extension after 'andi' if bit 7/15 of const operand is clear }
                  if (taicpu(p).oper[2]^.typ=top_const) and
                    GetNextInstruction(p,next) and
                    MatchInstruction(next,A_SLL) and
                    GetNextInstruction(next,next2) and
                    MatchInstruction(next2,A_SRA) and
                    IsSameReg(taicpu(p),taicpu(next)) and
                    IsSameReg(taicpu(p),taicpu(next2)) and
                    (taicpu(next).oper[2]^.typ=top_const) and
                    (taicpu(next2).oper[2]^.typ=top_const) and
                    (taicpu(next).oper[2]^.val=taicpu(next2).oper[2]^.val) and
                    ((
                      (taicpu(p).oper[2]^.val<=$7fff) and
                      (taicpu(next).oper[2]^.val=16)
                    ) or (
                      (taicpu(p).oper[2]^.val<=$7f) and
                      (taicpu(next).oper[2]^.val=24)
                    )) then
                    begin
                      asml.remove(next);
                      asml.remove(next2);
                      next.free;
                      next2.free;
                    end
                  { Remove zero extension if register is used only for byte/word memory store }
                  else if (taicpu(p).oper[2]^.typ=top_const) and
                    GetNextInstruction(p,next) and
                    ((taicpu(p).oper[2]^.val=255) and MatchInstruction(next,A_SB)) or
                    ((taicpu(p).oper[2]^.val=65535) and MatchInstruction(next,A_SH)) and
                    (taicpu(next).oper[0]^.typ=top_reg) and
                    (taicpu(next).oper[0]^.reg=taicpu(p).oper[0]^.reg) then
                    begin
                      CopyUsedRegs(TmpUsedRegs);
                      UpdateUsedRegs(TmpUsedRegs, tai(p.next));
                      if not RegUsedAfterInstruction(taicpu(p).oper[0]^.reg,next,TmpUsedRegs) then
                        begin
                          taicpu(next).loadreg(0,taicpu(p).oper[1]^.reg);
                          asml.remove(p);
                          p.free;
                          p:=next;
                        end;
                      ReleaseUsedRegs(TmpUsedRegs);
                    end
                  else
                    TryRemoveMov(p,A_MOVE);
                end;

              A_MOV_S:
                begin
                  if GetNextInstructionUsingReg(p,next,taicpu(p).oper[0]^.reg) and
                     (next.typ=ait_instruction) then
                    begin
                      if TryRemoveMovBeforeStore(p,taicpu(next),[A_SWC1]) then
                        { optimization successful };
                    end;
                end;

              A_MOV_D:
                begin
                  if GetNextInstructionUsingReg(p,next,taicpu(p).oper[0]^.reg) and
                     (next.typ=ait_instruction) then
                    begin
                      if TryRemoveMovBeforeStore(p,taicpu(next),[A_SDC1]) then
                        { optimization successful };
                    end;
                end;

              A_MOVE:
                begin
                  if GetNextInstructionUsingReg(p,next,taicpu(p).oper[0]^.reg) and
                    (next.typ=ait_instruction) and
                    (not RegModifiedBetween(taicpu(p).oper[1]^.reg,p,next)) then
                    begin
                      { MOVE  Rx,Ry; store Rx,(ref); dealloc Rx   ==> store Ry,(ref) }
                      if TryRemoveMovBeforeStore(p,taicpu(next),[A_SB,A_SH,A_SW]) then
                        { optimization successful }
                      else if TryRemoveMovToRefIndex(p,taicpu(next)) then
                        { successful as well }
                      { MOVE  Rx,Ry; opcode  Rx,Rx,any              ==> opcode Rx,Ry,any
                        MOVE  Rx,Ry; opcode  Rx,Rz,Rx               ==> opcode Rx,Rz,Ry   }
                      else if (taicpu(next).opcode in [A_ADD,A_ADDU,A_ADDI,A_ADDIU,A_SUB,A_SUBU]) and
                         MatchOperand(taicpu(next).oper[0]^,taicpu(p).oper[0]^.reg) then
                        begin
                          if MatchOperand(taicpu(next).oper[1]^,taicpu(p).oper[0]^.reg) then
                            begin
                              taicpu(next).loadreg(1,taicpu(p).oper[1]^.reg);
                              asml.remove(p);
                              p.free;
                              p:=next;
                            end
                          { TODO: if Ry=NR_R0, this effectively changes instruction into MOVE,
                            providing further optimization possibilities }
                          else if MatchOperand(taicpu(next).oper[2]^,taicpu(p).oper[0]^.reg) then
                            begin
                              taicpu(next).loadreg(2,taicpu(p).oper[1]^.reg);
                              asml.remove(p);
                              p.free;
                              p:=next;
                            end;
                        end
                      { MOVE  Rx,Ry; opcode Rz,Rx,any; dealloc Rx  ==> opcode Rz,Ry,any }
                      else if (taicpu(next).opcode in [A_ADD,A_ADDU,A_ADDI,A_ADDIU,A_SUB,A_SUBU,A_SLT,A_SLTU,A_DIV,A_DIVU]) and
                         Assigned(FindRegDealloc(taicpu(p).oper[0]^.reg,tai(next.next))) then
                        begin
                          if MatchOperand(taicpu(next).oper[1]^,taicpu(p).oper[0]^.reg) then
                            begin
                              taicpu(next).loadreg(1,taicpu(p).oper[1]^.reg);
                              asml.remove(p);
                              p.free;
                              p:=next;
                            end
                          else if MatchOperand(taicpu(next).oper[2]^,taicpu(p).oper[0]^.reg) then
                            begin
                              taicpu(next).loadreg(2,taicpu(p).oper[1]^.reg);
                              asml.remove(p);
                              p.free;
                              p:=next;
                            end;
                        end
                      { MULT[U] must be handled separately due to different operand numbers }
                      else if (taicpu(next).opcode in [A_MULT,A_MULTU]) and
                         Assigned(FindRegDealloc(taicpu(p).oper[0]^.reg,tai(next.next))) then
                        begin
                          if MatchOperand(taicpu(next).oper[0]^,taicpu(p).oper[0]^.reg) then
                            begin
                              taicpu(next).loadreg(0,taicpu(p).oper[1]^.reg);
                              asml.remove(p);
                              p.free;
                              p:=next;
                            end
                          else if MatchOperand(taicpu(next).oper[1]^,taicpu(p).oper[0]^.reg) then
                            begin
                              taicpu(next).loadreg(1,taicpu(p).oper[1]^.reg);
                              asml.remove(p);
                              p.free;
                              p:=next;
                            end;
                        end
                      else if TryRemoveMov(p,A_MOVE) then
                        begin
                          { Ended up with move between same register? Suicide then. }
                          if (taicpu(p).oper[0]^.reg=taicpu(p).oper[1]^.reg) then
                            begin
                              GetNextInstruction(p,next);
                              asml.remove(p);
                              p.free;
                              p:=next;
                            end;
                        end;
                      { TODO: MOVE  Rx,Ry; Bcc Rx,Rz,label; dealloc Rx   ==> Bcc Ry,Rz,label  }
                    end;
                end;

              A_LB,A_LBU,A_LH,A_LHU,A_LW,
              A_ADD,A_ADDU,
              A_ADDI,A_ADDIU,
              A_SUB,A_SUBU,
              A_SRA,A_SRAV,
              A_SRLV,
              A_SLLV,
              A_MFLO,A_MFHI,
              A_AND,A_OR,A_XOR,A_ORI,A_XORI:
                TryRemoveMov(p,A_MOVE);

              A_LWC1,
              A_ADD_s, A_SUB_s, A_MUL_s, A_DIV_s,
              A_ABS_s, A_NEG_s, A_SQRT_s,
              A_CVT_s_w, A_CVT_s_l, A_CVT_s_d:
                TryRemoveMov(p,A_MOV_s);

              A_LDC1,
              A_ADD_d, A_SUB_d, A_MUL_d, A_DIV_d,
              A_ABS_d, A_NEG_d, A_SQRT_d,
              A_CVT_d_w, A_CVT_d_l, A_CVT_d_s:
                TryRemoveMov(p,A_MOV_d);
            end;
          end;
      end;
    end;


  procedure TCpuAsmOptimizer.PeepHoleOptPass2;
    var
      p: tai;
      l: longint;
      hp1,hp2,hp3: tai;
      condition: tasmcond;
      condreg: tregister;
    begin
      { Currently, everything below is mips4+ }
      if (current_settings.cputype<cpu_mips4) then
        exit;
      p:=BlockStart;
      ClearUsedRegs;
      while (p<>BlockEnd) Do
        begin
          UpdateUsedRegs(tai(p.next));
          case p.typ of
            ait_instruction:
              begin
                case taicpu(p).opcode of
                  A_BC:
                    begin
                      condreg:=NR_NO;
                      if (taicpu(p).condition in [C_COP1TRUE,C_COP1FALSE]) then
                        { TODO: must be taken from "p" if/when codegen makes use of multiple %fcc }
                        condreg:=NR_FCC0
                      else if (taicpu(p).condition in [C_EQ,C_NE]) then
                        begin
                          if (taicpu(p).oper[0]^.reg=NR_R0) then
                            condreg:=taicpu(p).oper[1]^.reg
                          else if (taicpu(p).oper[1]^.reg=NR_R0) then
                            condreg:=taicpu(p).oper[0]^.reg
                        end;

                      if (condreg<>NR_NO) then
                        begin
                          { check for
                              bCC   xxx
                              <several movs>
                          xxx:
                          }
                          l:=0;
                          GetNextInstruction(p, hp1);
                          while CanBeCMOV(hp1,condreg) do       // CanBeCMOV returns False for nil or labels
                            begin
                              inc(l);
                              GetNextInstruction(hp1,hp1);
                            end;
                          if assigned(hp1) then
                            begin
                              if FindLabel(tasmlabel(taicpu(p).oper[taicpu(p).ops-1]^.ref^.symbol),hp1) then
                                begin
                                  if (l<=4) and (l>0) then
                                    begin
                                      condition:=inverse_cond(taicpu(p).condition);
                                      hp2:=p;
                                      GetNextInstruction(p,hp1);
                                      p:=hp1;
                                      repeat
                                        ChangeToCMOV(taicpu(hp1),condition,condreg);
                                        GetNextInstruction(hp1,hp1);
                                      until not CanBeCMOV(hp1,condreg);
                                      { wait with removing else GetNextInstruction could
                                        ignore the label if it was the only usage in the
                                        jump moved away }
                                      tasmlabel(taicpu(hp2).oper[taicpu(hp2).ops-1]^.ref^.symbol).decrefs;
                                      RemoveDelaySlot(hp2);
                                      asml.remove(hp2);
                                      hp2.free;
                                      continue;
                                    end;
                                end
                              else
                                begin
                                  { check further for
                                        bCC   xxx
                                        <several movs 1>
                                        b     yyy
                                    xxx:
                                        <several movs 2>
                                    yyy:
                                  }
                                  { hp2 points to jmp yyy }
                                  hp2:=hp1;
                                  { skip hp1 to xxx }
                                  GetNextInstruction(hp1, hp1);
                                  if assigned(hp2) and
                                    assigned(hp1) and
                                    (l<=3) and
                                    (hp2.typ=ait_instruction) and
                                    (taicpu(hp2).opcode=A_BA) and
                                    { real label and jump, no further references to the
                                      label are allowed }
                                    (tasmlabel(taicpu(p).oper[taicpu(p).ops-1]^.ref^.symbol).getrefs<=2) and
                                    FindLabel(tasmlabel(taicpu(p).oper[taicpu(p).ops-1]^.ref^.symbol),hp1) then
                                    begin
                                      l:=0;
                                      { skip hp1 to <several moves 2> }
                                      GetNextInstruction(hp1, hp1);
                                      while CanBeCMOV(hp1,condreg) do
                                        begin
                                          inc(l);
                                          GetNextInstruction(hp1, hp1);
                                        end;
                                      { hp1 points to yyy: }
                                      if assigned(hp1) and
                                        FindLabel(tasmlabel(taicpu(hp2).oper[taicpu(hp2).ops-1]^.ref^.symbol),hp1) then
                                        begin
                                          condition:=inverse_cond(taicpu(p).condition);
                                          GetNextInstruction(p,hp1);
                                          hp3:=p;
                                          p:=hp1;
                                          repeat
                                            ChangeToCMOV(taicpu(hp1),condition,condreg);
                                            GetNextInstruction(hp1,hp1);
                                          until not CanBeCMOV(hp1,condreg);
                                          { hp2 is still at b yyy }
                                          GetNextInstruction(hp2,hp1);
                                          { hp2 is now at xxx: }
                                          condition:=inverse_cond(condition);
                                          GetNextInstruction(hp1,hp1);
                                          { hp1 is now at <several movs 2> }
                                          repeat
                                            ChangeToCMOV(taicpu(hp1),condition,condreg);
                                            GetNextInstruction(hp1,hp1);
                                          until not CanBeCMOV(hp1,condreg);
                                          { remove bCC }
                                          tasmlabel(taicpu(hp3).oper[taicpu(hp3).ops-1]^.ref^.symbol).decrefs;
                                          RemoveDelaySlot(hp3);
                                          asml.remove(hp3);
                                          hp3.free;
                                          { remove jmp }
                                          tasmlabel(taicpu(hp2).oper[taicpu(hp2).ops-1]^.ref^.symbol).decrefs;
                                          RemoveDelaySlot(hp2);
                                          asml.remove(hp2);
                                          hp2.free;
                                          continue;
                                        end;
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
              end;
          end;
          UpdateUsedRegs(p);
          p:=tai(p.next);
        end;
    end;

begin
  casmoptimizer:=TCpuAsmOptimizer;
end.
