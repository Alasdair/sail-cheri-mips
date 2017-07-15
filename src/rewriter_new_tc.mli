(**************************************************************************)
(*     Sail                                                               *)
(*                                                                        *)
(*  Copyright (c) 2013-2017                                               *)
(*    Kathyrn Gray                                                        *)
(*    Shaked Flur                                                         *)
(*    Stephen Kell                                                        *)
(*    Gabriel Kerneis                                                     *)
(*    Robert Norton-Wright                                                *)
(*    Christopher Pulte                                                   *)
(*    Peter Sewell                                                        *)
(*                                                                        *)
(*  All rights reserved.                                                  *)
(*                                                                        *)
(*  This software was developed by the University of Cambridge Computer   *)
(*  Laboratory as part of the Rigorous Engineering of Mainstream Systems  *)
(*  (REMS) project, funded by EPSRC grant EP/K008528/1.                   *)
(*                                                                        *)
(*  Redistribution and use in source and binary forms, with or without    *)
(*  modification, are permitted provided that the following conditions    *)
(*  are met:                                                              *)
(*  1. Redistributions of source code must retain the above copyright     *)
(*     notice, this list of conditions and the following disclaimer.      *)
(*  2. Redistributions in binary form must reproduce the above copyright  *)
(*     notice, this list of conditions and the following disclaimer in    *)
(*     the documentation and/or other materials provided with the         *)
(*     distribution.                                                      *)
(*                                                                        *)
(*  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''    *)
(*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     *)
(*  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A       *)
(*  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR   *)
(*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,          *)
(*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT      *)
(*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF      *)
(*  USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND   *)
(*  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,    *)
(*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT    *)
(*  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF    *)
(*  SUCH DAMAGE.                                                          *)
(**************************************************************************)

open Big_int
open Ast
open Type_check_new

type 'a rewriters = { rewrite_exp  : 'a rewriters -> 'a exp -> 'a exp;
                      rewrite_lexp : 'a rewriters -> 'a lexp -> 'a lexp;
                      rewrite_pat  : 'a rewriters -> 'a pat -> 'a pat;
                      rewrite_let  : 'a rewriters -> 'a letbind -> 'a letbind;
                      rewrite_fun  : 'a rewriters -> 'a fundef -> 'a fundef;
                      rewrite_def  : 'a rewriters -> 'a def -> 'a def;
                      rewrite_defs : 'a rewriters -> 'a defs -> 'a defs;
                    }
                    
val rewrite_exp : tannot rewriters -> tannot exp -> tannot exp
val rewrite_defs : tannot defs -> tannot defs
val rewrite_defs_ocaml : tannot defs -> tannot defs (*Perform rewrites to exclude AST nodes not supported for ocaml out*)
val rewrite_defs_lem : tannot defs -> tannot defs (*Perform rewrites to exclude AST nodes not supported for lem out*)

(* the type of interpretations of pattern-matching expressions *)
type ('a,'pat,'pat_aux,'fpat,'fpat_aux) pat_alg =
  { p_lit            : lit -> 'pat_aux
  ; p_wild           : 'pat_aux
  ; p_as             : 'pat * id -> 'pat_aux
  ; p_typ            : Ast.typ * 'pat -> 'pat_aux
  ; p_id             : id -> 'pat_aux
  ; p_app            : id * 'pat list -> 'pat_aux
  ; p_record         : 'fpat list * bool -> 'pat_aux
  ; p_vector         : 'pat list -> 'pat_aux
  ; p_vector_indexed : (int * 'pat) list -> 'pat_aux
  ; p_vector_concat  : 'pat list -> 'pat_aux
  ; p_tup            : 'pat list -> 'pat_aux
  ; p_list           : 'pat list -> 'pat_aux
  ; p_aux            : 'pat_aux * 'a annot -> 'pat
  ; fP_aux           : 'fpat_aux * 'a annot -> 'fpat
  ; fP_Fpat          : id * 'pat -> 'fpat_aux
  }

(* fold over pat_aux expressions *)


(* the type of interpretations of expressions *)
type ('a,'exp,'exp_aux,'lexp,'lexp_aux,'fexp,'fexp_aux,'fexps,'fexps_aux,
      'opt_default_aux,'opt_default,'pexp,'pexp_aux,'letbind_aux,'letbind,
      'pat,'pat_aux,'fpat,'fpat_aux) exp_alg = 
 { e_block                  : 'exp list -> 'exp_aux
 ; e_nondet                 : 'exp list -> 'exp_aux
 ; e_id                     : id -> 'exp_aux
 ; e_lit                    : lit -> 'exp_aux
 ; e_cast                   : Ast.typ * 'exp -> 'exp_aux
 ; e_app                    : id * 'exp list -> 'exp_aux
 ; e_app_infix              : 'exp * id * 'exp -> 'exp_aux
 ; e_tuple                  : 'exp list -> 'exp_aux
 ; e_if                     : 'exp * 'exp * 'exp -> 'exp_aux
 ; e_for                    : id * 'exp * 'exp * 'exp * Ast.order * 'exp -> 'exp_aux
 ; e_vector                 : 'exp list -> 'exp_aux
 ; e_vector_indexed         : (int * 'exp) list * 'opt_default -> 'exp_aux
 ; e_vector_access          : 'exp * 'exp -> 'exp_aux
 ; e_vector_subrange        : 'exp * 'exp * 'exp -> 'exp_aux
 ; e_vector_update          : 'exp * 'exp * 'exp -> 'exp_aux
 ; e_vector_update_subrange : 'exp * 'exp * 'exp * 'exp -> 'exp_aux
 ; e_vector_append          : 'exp * 'exp -> 'exp_aux
 ; e_list                   : 'exp list -> 'exp_aux
 ; e_cons                   : 'exp * 'exp -> 'exp_aux
 ; e_record                 : 'fexps -> 'exp_aux
 ; e_record_update          : 'exp * 'fexps -> 'exp_aux
 ; e_field                  : 'exp * id -> 'exp_aux
 ; e_case                   : 'exp * 'pexp list -> 'exp_aux
 ; e_let                    : 'letbind * 'exp -> 'exp_aux
 ; e_assign                 : 'lexp * 'exp -> 'exp_aux
 ; e_exit                   : 'exp -> 'exp_aux
 ; e_return                 : 'exp -> 'exp_aux
 ; e_assert                 : 'exp * 'exp -> 'exp_aux
 ; e_internal_cast          : 'a annot * 'exp -> 'exp_aux
 ; e_internal_exp           : 'a annot -> 'exp_aux
 ; e_internal_exp_user      : 'a annot * 'a annot -> 'exp_aux
 ; e_internal_let           : 'lexp * 'exp * 'exp -> 'exp_aux
 ; e_internal_plet          : 'pat * 'exp * 'exp -> 'exp_aux
 ; e_internal_return        : 'exp -> 'exp_aux
 ; e_aux                    : 'exp_aux * 'a annot -> 'exp
 ; lEXP_id                  : id -> 'lexp_aux
 ; lEXP_memory              : id * 'exp list -> 'lexp_aux
 ; lEXP_cast                : Ast.typ * id -> 'lexp_aux
 ; lEXP_tup                 : 'lexp list -> 'lexp_aux
 ; lEXP_vector              : 'lexp * 'exp -> 'lexp_aux
 ; lEXP_vector_range        : 'lexp * 'exp * 'exp -> 'lexp_aux
 ; lEXP_field               : 'lexp * id -> 'lexp_aux
 ; lEXP_aux                 : 'lexp_aux * 'a annot -> 'lexp
 ; fE_Fexp                  : id * 'exp -> 'fexp_aux
 ; fE_aux                   : 'fexp_aux * 'a annot -> 'fexp
 ; fES_Fexps                : 'fexp list * bool -> 'fexps_aux
 ; fES_aux                  : 'fexps_aux * 'a annot -> 'fexps
 ; def_val_empty            : 'opt_default_aux
 ; def_val_dec              : 'exp -> 'opt_default_aux
 ; def_val_aux              : 'opt_default_aux * 'a annot -> 'opt_default
 ; pat_exp                  : 'pat * 'exp -> 'pexp_aux
 ; pat_aux                  : 'pexp_aux * 'a annot -> 'pexp
 ; lB_val_explicit          : typschm * 'pat * 'exp -> 'letbind_aux
 ; lB_val_implicit          : 'pat * 'exp -> 'letbind_aux
 ; lB_aux                   : 'letbind_aux * 'a annot -> 'letbind
 ; pat_alg                  : ('a,'pat,'pat_aux,'fpat,'fpat_aux) pat_alg
 }

(* fold over expressions *)
val fold_exp : ('a,'exp,'exp_aux,'lexp,'lexp_aux,'fexp,'fexp_aux,'fexps,'fexps_aux,
      'opt_default_aux,'opt_default,'pexp,'pexp_aux,'letbind_aux,'letbind,
      'pat,'pat_aux,'fpat,'fpat_aux) exp_alg -> 'a exp -> 'exp

val id_pat_alg : ('a,'a pat, 'a pat_aux, 'a fpat, 'a fpat_aux) pat_alg