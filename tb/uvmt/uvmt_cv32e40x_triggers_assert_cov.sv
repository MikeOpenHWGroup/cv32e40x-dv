// Copyright 2023 Silicon Labs, Inc.
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://solderpad.org/licenses/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

//The assertions written in this file are denoted with a number.
//You will find this number in the file vplan_coverage.txt,
//and they describe what vplan tasks the assertions aim to cover.

module uvmt_cv32e40x_triggers_assert_cov
  import uvm_pkg::*;
  import cv32e40x_pkg::*;
  import uvmt_cv32e40x_base_test_pkg::*;
  import cv32e40x_rvfi_pkg::*;
  import uvmt_cv32e40x_pkg::*;
  (
    input logic wb_valid,
    input logic [10:0] wb_exception_code,
    input logic [31:0] wb_tdata1,
    input logic [31:0] wb_tdata2,
    input logic [31:0] wb_tselect,
    input privlvl_t priv_lvl,
    input logic wb_dbg_mode,
    input logic wb_last_op,
    input logic wb_exception,

    uvma_rvfi_instr_if_t rvfi_if,
    uvma_clknrst_if_t clknrst_if,
    uvmt_cv32e40x_support_logic_module_o_if_t.slave_mp  support_if,

    uvma_rvfi_csr_if_t tdata1,
    uvma_rvfi_csr_if_t tdata2,
    uvma_rvfi_csr_if_t tdata3,
    uvma_rvfi_csr_if_t tinfo,
    uvma_rvfi_csr_if_t tselect,
    uvma_rvfi_csr_if_t tcontrol,
    uvma_rvfi_csr_if_t dcsr,
    uvma_rvfi_csr_if_t dpc
  );

  default clocking @(posedge clknrst_if.clk); endclocking
  default disable iff !(clknrst_if.reset_n);

  string info_tag = "TRIGGER ASSERT: ";
  localparam MAX_MEM_ACCESS = 13; //Push and pop can do 13 memory access. XIF can potentially do more (TODO: check this when merging to cv32e40x)

  //Reads and writes of CSR values
  logic [31:0] tdata1_pre_state;
  logic [31:0] tdata2_pre_state;
  logic [31:0] tdata3_pre_state;
  logic [31:0] tinfo_pre_state;
  logic [31:0] tselect_pre_state;
  logic [31:0] tcontrol_pre_state;

  logic [31:0] tdata1_post_state;
  logic [31:0] tdata2_post_state;
  logic [31:0] tdata3_post_state;
  logic [31:0] tinfo_post_state;
  logic [31:0] tselect_post_state;
  logic [31:0] tcontrol_post_state;

  logic [MAX_MEM_ACCESS-1:0][31:0] rvfi_mem_addrs;


  always_comb begin
    tdata1_pre_state = tdata1.pre_state();
    tdata2_pre_state = tdata2.pre_state();
    tdata3_pre_state = tdata3.pre_state();
    tinfo_pre_state = tinfo.pre_state();
    tselect_pre_state = tselect.pre_state();
    tcontrol_pre_state = tcontrol.pre_state();
  end

  always_comb begin
    tdata1_post_state = tdata1.post_state();
    tdata2_post_state = tdata2.post_state();
    tdata3_post_state = tdata3.post_state();
    tinfo_post_state = tinfo.post_state();
    tselect_post_state = tselect.post_state();
    tcontrol_post_state = tcontrol.post_state();
  end

  generate
    for (genvar i = 0; i < MAX_MEM_ACCESS; i++) begin
      assign rvfi_mem_addrs[i] = rvfi_if.get_mem_addr(i);
    end
  endgenerate

  /////////// Local Parameters ///////////

  //common tdata1 mcontrol and mcontrol6 values:
  localparam DMODE = 27;
  localparam LOAD = 0;
  localparam STORE = 1;
  localparam EXECUTE = 2;
  localparam U_MODE = 3;
  localparam S_MODE = 4;
  localparam M_MODE = 6;
  localparam LSB_MATCH = 7;
  localparam MSB_MATCH = 10;
  localparam CHAIN = 11;
  localparam LSB_ACTION = 12;
  localparam MSB_ACTION = 15;
  localparam LSB_TYPE = 28;
  localparam MSB_TYPE = 31;

  //tdata1 mcontrol:
  localparam MSB_MASKMAX = 26;
  localparam LSB_MASKMAX = 21;
  localparam M2_HIT = 20;
  localparam M2_SELECT = 19;
  localparam M2_TIMING = 18;
  localparam M2_MSB_SIZELO = 17;
  localparam M2_LSB_SIZELO = 16;

  //tdata1 mcontrol6:
  localparam M6_VS = 24;
  localparam M6_VU = 23;
  localparam M6_HIT = 22;
  localparam M6_SELECT = 21;
  localparam M6_TIMING = 20;
  localparam M6_MSB_SIZE = 19;
  localparam M6_LSB_SIZE = 16;

  //tdata1 etriggers:
  localparam ET_HIT = 26;
  localparam ET_VS = 12;
  localparam ET_VU = 11;
  localparam ET_M_MODE = 9;
  localparam ET_S = 7;
  localparam ET_U_MODE = 6;
  localparam ET_MSB_ACTION = 5;
  localparam ET_LSB_ACTION = 0;

  //tdata1 disabled:
  localparam DIS_MSB_DATA = 26;
  localparam DIS_LSB_DATA = 0;

  //tdata2:
  localparam ET2_DATA_31 = 31;
  localparam ET2_DATA_26 = 26;
  localparam ET2_DATA_23 = 23;
  localparam ET2_DATA_12 = 12;
  localparam ET2_DATA_10 = 10;
  localparam ET2_DATA_9 = 9;
  localparam ET2_DATA_6 = 6;
  localparam ET2_DATA_4 = 4;
  localparam ET2_DATA_0 = 0;

  //tcontrol:
  localparam MPTE = 7;
  localparam MTE = 3;

  //Actions:
  localparam ENTER_DBG_ON_MATCH = 1;

  //Trigger match specifications:
  localparam MATCH_WHEN_EQUAL = 0;
  localparam MATCH_WHEN_GREATER_OR_EQUAL = 2;
  localparam MATCH_WHEN_LESSER = 3;

  //Cause of entering debug:
  localparam TRIGGER_MATCH = 2;

  //CSR addresses:
  localparam ADDR_TSELECT = 12'h7A0;
  localparam ADDR_TDATA1 = 12'h7A1;
  localparam ADDR_TDATA2 = 12'h7A2;
  localparam ADDR_TDATA3 = 12'h7A3;
  localparam ADDR_TINFO = 12'h7A4;
  localparam ADDR_TCONTROL = 12'h7A5;
  localparam ADDR_MCONTEXT = 12'h7A8;
  localparam ADDR_MSCONTEXT = 12'h7AA;
  localparam ADDR_HCONTEXT = 12'h6A8;
  localparam ADDR_SCONTEXT = 12'h5A8;
  localparam ADDR_DCSR = 12'h7b0;
  localparam ADDR_DPC = 12'h7b1;

  //DCSR:
  localparam MSB_CAUSE = 8;
  localparam LSB_CAUSE = 6;

  //Hardwired to zero:
  localparam HW_ZERO_31 = 31;
  localparam HW_ZERO_26 = 26;
  localparam HW_ZERO_25 = 25;
  localparam HW_ZERO_16 = 16;
  localparam HW_ZERO_14 = 14;
  localparam HW_ZERO_13 = 13;
  localparam HW_ZERO_10 = 10;
  localparam HW_ZERO_8 = 8;
  localparam HW_ZERO_7 = 7;
  localparam HW_ZERO_6 = 6;
  localparam HW_ZERO_5 = 5;
  localparam HW_ZERO_4 = 4;
  localparam HW_ZERO_3 = 3;
  localparam HW_ZERO_2 = 2;
  localparam HW_ZERO_1 = 1;
  localparam HW_ZERO_0 = 0;

  localparam TDATA1_DISABLED = 32'hF800_0000;
  localparam MAX_NUM_TRIGGERS = 5;


  /////////// Signals ///////////

  logic valid_instr_in_mmode;
  assign valid_instr_in_mmode = rvfi_if.rvfi_valid
      && !rvfi_if.rvfi_trap
      && !rvfi_if.rvfi_dbg_mode
      && rvfi_if.is_mmode;

  logic valid_instr_in_umode;
  assign valid_instr_in_umode = rvfi_if.rvfi_valid
      && !rvfi_if.rvfi_dbg_mode
      && rvfi_if.is_umode;

  logic valid_instr_in_dmode;
  assign valid_instr_in_dmode = rvfi_if.rvfi_valid
      && !rvfi_if.rvfi_trap
      && rvfi_if.rvfi_dbg_mode;

  logic is_csrrw;
  logic is_csrrs;
  logic is_csrrc;
  logic is_csrrwi;
  logic is_csrrsi;
  logic is_csrrci;
  logic [4:0] csri_uimm;

  assign is_csrrw = rvfi_if.match_instr_isb(rvfi_if.INSTR_OPCODE_CSRRW);
  assign is_csrrs = rvfi_if.match_instr_isb(rvfi_if.INSTR_OPCODE_CSRRS);
  assign is_csrrc = rvfi_if.match_instr_isb(rvfi_if.INSTR_OPCODE_CSRRC);
  assign is_csrrwi = rvfi_if.match_instr_isb(rvfi_if.INSTR_OPCODE_CSRRWI);
  assign is_csrrsi = rvfi_if.match_instr_isb(rvfi_if.INSTR_OPCODE_CSRRSI);
  assign is_csrrci = rvfi_if.match_instr_isb(rvfi_if.INSTR_OPCODE_CSRRCI);
  assign csri_uimm = rvfi_if.rvfi_insn[19:15];


  /////////// Sequences ///////////

  sequence seq_general_conditions_for_trigger_hit(t, priv_lvl, match_type);
    rvfi_if.rvfi_valid
    && !rvfi_if.rvfi_dbg_mode
    && priv_lvl
    && rvfi_if.rvfi_trap.exception_cause != 6'h18
    && rvfi_if.rvfi_trap.exception_cause != 6'h19
    && rvfi_if.rvfi_trap.exception_cause != 6'h1
    && (support_if.tdata1_array[t][MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL
    || support_if.tdata1_array[t][MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL6)
    && support_if.tdata1_array[t][MSB_MATCH:LSB_MATCH] == match_type;
  endsequence

  sequence seq_csr_read_mmode(csr_addr);
    valid_instr_in_mmode
    && rvfi_if.is_csr_read(csr_addr)
    && rvfi_if.rvfi_rd1_addr != 0;
  endsequence

  sequence seq_csr_write_mmode(csr_addr);
    valid_instr_in_mmode
    && rvfi_if.is_csr_write(csr_addr);
  endsequence

  sequence seq_csr_read_dmode(csr_addr);
    valid_instr_in_dmode
    && rvfi_if.is_csr_read(csr_addr)
    && rvfi_if.rvfi_rd1_addr != 0;
  endsequence

  sequence seq_csr_write_dmode(csr_addr);
    valid_instr_in_dmode
    && rvfi_if.is_csr_write(csr_addr);
  endsequence

  sequence seq_tdata2_m2_m6_disabled(t);
    valid_instr_in_dmode
    && tselect_pre_state == t
    && (tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL
    || tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL6
    || tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_DISABLED);
  endsequence

  sequence seq_execute_hit(t, priv_lvl, match_type);
    support_if.is_trigger_match_execute
    && rvfi_if.rvfi_valid
    && !rvfi_if.rvfi_dbg_mode
    && priv_lvl
    && support_if.tdata1_array[t][MSB_MATCH:LSB_MATCH] == match_type
    && rvfi_if.rvfi_trap.exception_cause != 6'h18
    && rvfi_if.rvfi_trap.exception_cause != 6'h19
    && rvfi_if.rvfi_trap.exception_cause != 6'h1;
  endsequence

  sequence seq_load_hit(t, priv_lvl, match_type);
    support_if.is_trigger_match_load
    && rvfi_if.rvfi_valid
    && !rvfi_if.rvfi_dbg_mode
    && priv_lvl
    && support_if.tdata1_array[t][MSB_MATCH:LSB_MATCH] == match_type
    && !rvfi_if.rvfi_trap.exception;
  endsequence

  sequence seq_store_hit(t, priv_lvl, match_type);
    support_if.is_trigger_match_store
    && rvfi_if.rvfi_valid
    && !rvfi_if.rvfi_dbg_mode
    && priv_lvl
    && support_if.tdata1_array[t][MSB_MATCH:LSB_MATCH] == match_type
    && !rvfi_if.rvfi_trap.exception;
  endsequence


  /////////// Properties ///////////

  property p_etrigger_hit(priv_lvl, exception);
    support_if.is_trigger_match_exception
    && rvfi_if.rvfi_valid
    && !rvfi_if.rvfi_dbg_mode
    && priv_lvl
    && rvfi_if.rvfi_trap.exception_cause == exception
    |->
    rvfi_if.rvfi_trap.debug;
  endproperty

  property p_all_trigger(tselect_trigger_i, tdata1_type);
    tselect_pre_state == tselect_trigger_i
    && tdata1_pre_state[MSB_TYPE:LSB_TYPE] == tdata1_type;
  endproperty

  property p_csrrw_in_dmode(addr, csr_post_state);
    seq_csr_write_dmode(addr)
    ##0 is_csrrw
    |->
    csr_post_state == rvfi_if.rvfi_rs1_rdata;
  endproperty

  property p_csrrs_in_dmode(addr, csr_post_state);
    seq_csr_write_dmode(addr)
    ##0 is_csrrs
    |->
    csr_post_state == (tdata2_pre_state | rvfi_if.rvfi_rs1_rdata);
  endproperty

  property p_csrrc_in_dmode(addr, csr_post_state);
    seq_csr_write_dmode(addr)
    ##0 is_csrrc
    |->
    csr_post_state == (tdata2_pre_state & (~rvfi_if.rvfi_rs1_rdata));
  endproperty

  property p_csrrwi_in_dmode(addr, csr_post_state);
    seq_csr_write_dmode(addr)
    ##0 is_csrrwi
    |->
    csr_post_state == csri_uimm;
  endproperty

  property p_csrrsi_in_dmode(addr, csr_post_state);
    seq_csr_write_dmode(addr)
    ##0 is_csrrsi
    |->
    csr_post_state == (tdata2_pre_state | csri_uimm);
  endproperty

  property p_csrrci_in_dmode(addr, csr_post_state);
    seq_csr_write_dmode(addr)
    ##0 is_csrrci
    |->
    csr_post_state == (tdata2_pre_state & (~csri_uimm));
  endproperty


  /////////// Assertions and Coverages ///////////

  //- Vplan:
  //Verify that core enters debug mode when the trigger matches on instruction address. NB! According to spec, the tdataN registers can only be written from debug mode, as m-mode writes are ignored.

  //Enter debug mode by any of the above methods.
  //Write (randomized) breakpoint addr to tdata2 and enable breakpoint in tdata1[2]
  //Exit debug mode (dret instruction)
  //Verify that core enters debug mode on breakpoint addr
  //Current PC is saved to DPC
  //Cause of debug must be saved to DCSR (cause=2)
  //PC is updated to value on dm_haltaddr_i input
  //Core starts executing debug code

  //- Assertion verification:
  //1) Verify that core enters debug mode on breakpoint addr
  //2) Current PC is saved to DPC
  //3) Cause of debug must be saved to DCSR (cause=2)
  //4) PC is updated to value on dm_haltaddr_i input
  //5) Core starts executing debug code


  //1) see a_dt_instr_trigger_hit_*
  //2) - 5): Debug assertions uvmt_cv32e40x_debug_assert.sv


  //- Vplan:
  //Have 0 triggers, access any trigger register and check that illegal instruction exception occurs.
  //Check that no triggers ever fire. Check that "tselect" is 0.

  //- Assertion verification:
  //1) Have 0 triggers, access any trigger register and check that illegal instruction exception occurs
  //2) Have 0 triggers, No trigger ever fires


  // Assertions and coverages for when there are no debug triggers:
  if (CORE_PARAM_DBG_NUM_TRIGGERS == 0) begin
    //1)
    a_dt_0_triggers_tdata1_access: assert property (
        (rvfi_if.is_csr_instr(ADDR_TSELECT)
      || rvfi_if.is_csr_instr(ADDR_TDATA1)
      || rvfi_if.is_csr_instr(ADDR_TDATA2)
      || rvfi_if.is_csr_instr(ADDR_TDATA3)
      || rvfi_if.is_csr_instr(ADDR_TINFO)
      || rvfi_if.is_csr_instr(ADDR_TCONTROL))

      |->
      rvfi_if.rvfi_trap.trap
      && rvfi_if.rvfi_trap.exception
      && (rvfi_if.rvfi_trap.exception_cause == EXC_CAUSE_ILLEGAL_INSN)

    ) else `uvm_error(info_tag, "There are no triggers, but accessing trigger SCRs does not cause exceptions.\n");

    //2)
    a_dt_0_triggers_no_triggering: assert property (
      rvfi_if.rvfi_valid
      |->
      rvfi_if.rvfi_dbg != TRIGGER_MATCH

    ) else `uvm_error(info_tag, "There are no triggers, but debug cause indicate a trigger match.\n");

  end // if CORE_PARAM_DBG_NUM_TRIGGERS == 0


    //- Vplan:
  //For all number of triggers, use tselect to exercise each trigger with each supported type.
  //(Also try writing to higher "tselect" than supported and check that a supported number is read back.)
  //Make the triggers fire and check that debug mode is entered. Check also that the four context registers trap when accessed.

  //- Assertion verification:
  //1) Check also that the four context registers trap when accessed.
  //2) For all number of triggers, use tselect to exercise each trigger with each supported type
  //3) Make the triggers fire and check that debug mode is entered.
  //4) Writing to higher "tselect" than supported, check that a supported number is read back


  //1)
  a_dt_access_context: assert property (
    (rvfi_if.is_csr_instr(ADDR_MCONTEXT)
    || rvfi_if.is_csr_instr(ADDR_MSCONTEXT)
    || rvfi_if.is_csr_instr(ADDR_HCONTEXT)
    || rvfi_if.is_csr_instr(ADDR_SCONTEXT))

    |->
    rvfi_if.rvfi_trap.trap
  ) else `uvm_error(info_tag, "Accessing context registers does not trap.\n");


  // Assertions and coverages for when debug triggers are enabled:

  if (CORE_PARAM_DBG_NUM_TRIGGERS > 0) begin

    //2)
    for (genvar tselect_trigger_i = 0; tselect_trigger_i < CORE_PARAM_DBG_NUM_TRIGGERS; tselect_trigger_i++) begin

      c_dt_trigger_i_has_type_mcontrol: cover property(
        p_all_trigger(tselect_trigger_i, TTYPE_MCONTROL)
      );

      c_dt_trigger_i_has_type_etrigger: cover property(
        p_all_trigger(tselect_trigger_i, TTYPE_ETRIGGER)
      );

      c_dt_trigger_i_has_type_mcontrol6: cover property(
        p_all_trigger(tselect_trigger_i, TTYPE_MCONTROL6)
      );

      c_dt_trigger_i_has_type_disable: cover property(
        p_all_trigger(tselect_trigger_i, TTYPE_DISABLED)
      );

    end

    //3) see a_dt_instr_trigger_hit_*, a_dt_load_trigger_hit_*, a_dt_store_trigger_hit_*, a_dt_exception_trigger_hit_*, a_dt_enter_dbg_reason

    //4)
    a_dt_tselect_higher_than_dbg_num_triggers: assert property(
      rvfi_if.is_csr_instr(ADDR_TSELECT)
      |->
      rvfi_if.rvfi_rd1_wdata < CORE_PARAM_DBG_NUM_TRIGGERS
    ) else `uvm_error(info_tag, "The CSR tselect is set to equal or higher than the number of trigger.\n");




    //- Vplan:
    //Configure triggers for load/store/execute and combinations of them, configure tdata2,
    //cause triggers to fire and check that debug mode is entered correctly.
    //Also check that the tied fields are tied. All of these configurations must be crossed, also against match conditions.

    //- Assertion verification:
    //1) trigger on loads if the load setting in tdata1 is set high
    //2) trigger on stores if the store setting in tdata1 is set high
    //3) trigger on instructions if the execute setting in tdata1 is set high
    //4) check that the tied fields are tied

    //1) - 3) see a_dt_instr_trigger_hit_*, a_dt_load_trigger_hit_*, a_dt_store_trigger_hit_*

    //4)
    a_dt_tie_offs_tselect: assert property (
      rvfi_if.rvfi_valid

      |->
      !tselect_pre_state[31:CORE_PARAM_DBG_NUM_TRIGGERS-1]
    ) else `uvm_error(info_tag, "There is a problem with tselect's tied off fields.\n");


    //mcontrol
    a_dt_tie_offs_tdata1_mcontrol: assert property (
      rvfi_if.rvfi_valid
      && tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL

      |->
      tdata1_pre_state[DMODE]
      && !tdata1_pre_state[MSB_MASKMAX:LSB_MASKMAX]
      && !tdata1_pre_state[M2_HIT]
      && !tdata1_pre_state[M2_SELECT]
      && !tdata1_pre_state[M2_TIMING]
      && !tdata1_pre_state[M2_MSB_SIZELO:M2_LSB_SIZELO]
      && tdata1_pre_state[MSB_ACTION:LSB_ACTION] == ENTER_DBG_ON_MATCH
      && !tdata1_pre_state[CHAIN]
      && !tdata1_pre_state[HW_ZERO_5]
      && !tdata1_pre_state[S_MODE]
    ) else `uvm_error(info_tag, "There is a problem with tdata1-mcontrol's tied off fields.\n");

    //etrigger
    a_dt_tie_offs_tdata1_etrigger: assert property (
      rvfi_if.rvfi_valid
      && tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_ETRIGGER

      |->
      tdata1_pre_state[DMODE]
      && !tdata1_pre_state[ET_HIT]
      && !tdata1_pre_state[HW_ZERO_25:HW_ZERO_13]
      && !tdata1_pre_state[ET_VS]
      && !tdata1_pre_state[ET_VU]
      && !tdata1_pre_state[HW_ZERO_10]
      && !tdata1_pre_state[HW_ZERO_8]
      && !tdata1_pre_state[ET_S]
      && tdata1_pre_state[ET_MSB_ACTION:ET_LSB_ACTION] == ENTER_DBG_ON_MATCH
    ) else `uvm_error(info_tag, "There is a problem with tdata1-etrigger's tied off fields.\n");

    //mcontrol6
    a_dt_tie_offs_tdata1_mcontrol6: assert property (
      rvfi_if.rvfi_valid
      && tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL6

      |->
      tdata1_pre_state[DMODE]
      && !tdata1_pre_state[HW_ZERO_26:HW_ZERO_25]
      && !tdata1_pre_state[M6_VS]
      && !tdata1_pre_state[M6_VU]
      && !tdata1_pre_state[M6_HIT]
      && !tdata1_pre_state[M6_SELECT]
      && !tdata1_pre_state[M6_TIMING]
      && !tdata1_pre_state[M6_MSB_SIZE:M6_LSB_SIZE]
      && tdata1_pre_state[MSB_ACTION:LSB_ACTION] == ENTER_DBG_ON_MATCH
      && !tdata1_pre_state[CHAIN]
      && !tdata1_pre_state[HW_ZERO_5]
      && !tdata1_pre_state[S_MODE]
    ) else `uvm_error(info_tag, "There is a problem with tdata1-mcontrol6's tied off fields.\n");

    //disabled
    a_dt_tie_offs_tdata1_disabled: assert property (
      rvfi_if.rvfi_valid
      && tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_DISABLED

      |->
      tdata1_pre_state[DMODE]
      && !tdata1_pre_state[DIS_MSB_DATA:DIS_LSB_DATA]
    ) else `uvm_error(info_tag, "There is a problem with tdata1-disabled's tied off fields.\n");


    a_dt_tie_offs_tdata2_etrigger: assert property (
      rvfi_if.rvfi_valid
      && tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_ETRIGGER

      |->
      !tdata2_pre_state[ET2_DATA_31:ET2_DATA_26]
      && !tdata2_pre_state[ET2_DATA_23:ET2_DATA_12]
      && !tdata2_pre_state[ET2_DATA_10:ET2_DATA_9]
      && !tdata2_pre_state[ET2_DATA_6]
      && !tdata2_pre_state[ET2_DATA_4]
      && !tdata2_pre_state[ET2_DATA_0]
    ) else `uvm_error(info_tag, "There is a problem with tdata2-etrigger's tied off fields.\n");


    a_dt_tie_offs_tdata3: assert property (
      rvfi_if.rvfi_valid
      |->
      !tdata3_pre_state
    ) else `uvm_error(info_tag, "There is a problem with tdata3's tied off fields.\n");


    a_dt_tie_offs_tinfo: assert property (
      rvfi_if.rvfi_valid
      |->
      !tinfo_pre_state[HW_ZERO_31:HW_ZERO_16]
    ) else `uvm_error(info_tag, "There is a problem with tinfo's tied off fields.\n");


    a_dt_tie_offs_tcontrol: assert property (
      rvfi_if.rvfi_valid
      |->
      !tcontrol_pre_state[HW_ZERO_31:HW_ZERO_8]
      && !tcontrol_pre_state[HW_ZERO_6:HW_ZERO_4]
      && !tcontrol_pre_state[HW_ZERO_2:HW_ZERO_0]
    ) else `uvm_error(info_tag, "There is a problem with tcontrol's tied off fields.\n");


    //- Vplan:
    //Have triggers configured to be able to match, but enable/disable their corresponding mode bit, check that the trigger is either able to fire or is blocked from firing accordingly. Also check the tied values.

    //- Assertion verification:
    //1) but enable/disable their corresponding mode bit, check that the trigger is either able to fire or is blocked from firing accordingly, using different match configurations.
    //2) Also check the tied values. (P20-P21: 4))


    //1) see a_dt_instr_trigger_hit_*, a_dt_load_trigger_hit_*, a_dt_store_trigger_hit_*, a_dt_exception_trigger_hit_*, a_dt_enter_dbg_reason
    //2) see a_dt_tie_offs_*


    //- Vplan:
    //Check that these types can be selected, and check that no other types can be selected. (Functionality of these types should be handled by other items in this plan.) Check also that the default is "15".

    //- Assertion verification:
    //1) Sjekk at tdata1 type kun kan være 2, 6, 5 eller 15


    //1)
    a_dt_tdata1_types: assert property (
      rvfi_if.rvfi_valid
      |->
      tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL
      || tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_ETRIGGER
      || tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL6
      || tdata1_pre_state[MSB_TYPE:LSB_TYPE] == TTYPE_DISABLED
    ) else `uvm_error(info_tag, "tdata1 type is neither mcontrol, etrigger, mcontrol6 or disabled.\n");


    //- Vplan:
    //Try to write tdata registers outside of debug mode, check that they are not writable. Try changing "tdata1.dmode" and check that it is WARL (0x1). Cross the above checks with all supported types.

    //- Assertion verification:
    //1) write tdata registers outside of debug mode, check that they are not writable
    //2) Try changing "tdata1.dmode" and check that it is WARL (0x1)


    //1)
    a_dt_access_csr_not_dbg_mode: assert property (
      !rvfi_if.rvfi_dbg_mode
      && (rvfi_if.is_csr_instr(ADDR_TDATA1)
      || rvfi_if.is_csr_instr(ADDR_TDATA2)
      || rvfi_if.is_csr_instr(ADDR_TDATA3))

      |->
      !tdata1.rvfi_csr_wmask
      && !tdata2.rvfi_csr_wmask
      && !tdata3.rvfi_csr_wmask
    ) else `uvm_error(info_tag, "Writing tdata1, tdata2 or tdata3 in non-debug mode succeeds.\n");

    //2)
    a_dt_dmode: assert property (
      seq_csr_write_dmode(ADDR_TDATA1)
      ##0 !rvfi_if.rvfi_trap.trap
      |->
      tdata1_post_state[DMODE]
    ) else `uvm_error(info_tag, "Setting tdata1's dmode bit to 0 succeeds.\n");


    //- Vplan:
    //When num triggers is more than 0, check that "tinfo.info" is "1" for the three supported types, and that the remaining bits are 0.

    //- Assertion verification:
    //1) When num triggers is more than 0, check that "tinfo.info" is "1" for the three supported types, and that the remaining bits are 0.

    //1)
    a_dt_triggers_tinfo: assert property (
      CORE_PARAM_DBG_NUM_TRIGGERS != '0
      && rvfi_if.rvfi_valid
      |->
      !tinfo_pre_state[HW_ZERO_1:HW_ZERO_0]
      && tinfo_pre_state[TTYPE_MCONTROL]
      && !tinfo_pre_state[HW_ZERO_4:HW_ZERO_3]
      && tinfo_pre_state[TTYPE_ETRIGGER]
      && tinfo_pre_state[TTYPE_MCONTROL6]
      && !tinfo_pre_state[HW_ZERO_14:HW_ZERO_7]
      && tinfo_pre_state[TTYPE_DISABLED]
      && !tinfo_pre_state[HW_ZERO_31:HW_ZERO_16]
    ) else `uvm_error(info_tag, "tinfo does not indicated that only tdata type mcontrol, etrigger, mcontrol6 and disabled are allowed.\n");


  //- Vplan:
  //Configure an exception trigger, use the privmode bits to disable/enable the trigger, exercise the trigger conditions, check that it fires/not accordingly. Also check the WARL fields.

  //- Assertion verification:
  //1) Configure an exception trigger, use the privmode bits to disable/enable the trigger, exercise the trigger conditions, check that it fires/not accordingly.
  //2) Check the WARL fields


  //1) see a_dt_exception_trigger_hit_*, a_dt_enter_dbg_reason

  //2)
    a_dt_warl_tselect: assert property (
      rvfi_if.rvfi_valid
      && |tselect.rvfi_csr_wmask != 0
      |->
      tselect_post_state < CORE_PARAM_DBG_NUM_TRIGGERS
    ) else `uvm_error(info_tag, "There is a problem with tselect's WARL fields.\n");

    a_dt_warl_tdata1_general: assert property (
      rvfi_if.rvfi_valid
      && |tdata1.rvfi_csr_wmask != 0
      |->
      (tdata1_post_state[MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL
      || tdata1_post_state[MSB_TYPE:LSB_TYPE] == TTYPE_ETRIGGER
      || tdata1_post_state[MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL6
      || tdata1_post_state[MSB_TYPE:LSB_TYPE] == TTYPE_DISABLED)
      && tdata1_post_state[DMODE]
    ) else `uvm_error(info_tag, "There is a problem with tdata1's general WARL fields.\n");

    a_dt_warl_tdata1_m2: assert property (
      rvfi_if.rvfi_valid
      && |tdata1.rvfi_csr_wmask != 0
      && tdata1_post_state[MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL
      |->
      !tdata1_post_state[MSB_MASKMAX:LSB_MASKMAX]
      && !tdata1_post_state[M2_HIT]
      && !tdata1_post_state[M2_SELECT]
      && !tdata1_post_state[M2_TIMING]
      && !tdata1_post_state[M2_MSB_SIZELO:M2_LSB_SIZELO]
      && tdata1_post_state[MSB_ACTION:LSB_ACTION] == ENTER_DBG_ON_MATCH
      && !tdata1_post_state[CHAIN]
      && (tdata1_post_state[MSB_MATCH:LSB_MATCH] == MATCH_WHEN_EQUAL
      || tdata1_post_state[MSB_MATCH:LSB_MATCH] == MATCH_WHEN_GREATER_OR_EQUAL
      || tdata1_post_state[MSB_MATCH:LSB_MATCH] == MATCH_WHEN_LESSER)
      && !tdata1_post_state[HW_ZERO_5]
      && !tdata1_post_state[S_MODE]
    ) else `uvm_error(info_tag, "There is a problem with tdata1-mcontrol's WARL fields.\n");

    a_dt_warl_tdata1_etrigger: assert property (
      rvfi_if.rvfi_valid
      && |tdata1.rvfi_csr_wmask != 0
      && tdata1_post_state[MSB_TYPE:LSB_TYPE] == TTYPE_ETRIGGER
      |->
      !tdata1_post_state[ET_HIT]
      && !tdata1_post_state[HW_ZERO_25:HW_ZERO_13]
      && !tdata1_post_state[ET_VS]
      && !tdata1_post_state[ET_VU]
      && !tdata1_post_state[HW_ZERO_10]
      && !tdata1_post_state[HW_ZERO_8]
      && !tdata1_post_state[ET_S]
      && tdata1_post_state[ET_MSB_ACTION:ET_LSB_ACTION] == ENTER_DBG_ON_MATCH
    ) else `uvm_error(info_tag, "There is a problem with tdata1-etrigger's WARL fields.\n");

    a_dt_warl_tdata1_m6: assert property (
      rvfi_if.rvfi_valid
      && |tdata1.rvfi_csr_wmask != 0
      && tdata1_post_state[MSB_TYPE:LSB_TYPE] == TTYPE_MCONTROL6
      |->
      !tdata1_post_state[HW_ZERO_26:HW_ZERO_25]
      && !tdata1_post_state[M6_VS]
      && !tdata1_post_state[M6_VU]
      && !tdata1_post_state[M6_HIT]
      && !tdata1_post_state[M6_SELECT]
      && !tdata1_post_state[M6_TIMING]
      && !tdata1_post_state[M6_MSB_SIZE:M6_LSB_SIZE]
      && tdata1_post_state[MSB_ACTION:LSB_ACTION] == ENTER_DBG_ON_MATCH
      && !tdata1_post_state[CHAIN]
      && (tdata1_post_state[MSB_MATCH:LSB_MATCH] == MATCH_WHEN_EQUAL
      || tdata1_post_state[MSB_MATCH:LSB_MATCH] ==  MATCH_WHEN_GREATER_OR_EQUAL
      || tdata1_post_state[MSB_MATCH:LSB_MATCH] ==  MATCH_WHEN_LESSER)
      && !tdata1_post_state[HW_ZERO_5]
      && !tdata1_post_state[S_MODE]
    ) else `uvm_error(info_tag, "There is a problem with tdata1-mcontrol6's WARL fields.\n");

    a_dt_warl_tdata1_disabled: assert property (
      rvfi_if.rvfi_valid
      && |tdata1.rvfi_csr_wmask != 0
      && tdata1_post_state[MSB_TYPE:LSB_TYPE] == TTYPE_DISABLED
      |->
      !tdata1_post_state[DIS_MSB_DATA:DIS_LSB_DATA]
    ) else `uvm_error(info_tag, "There is a problem with tdata1-disabled's WARL fields.\n");

    a_dt_warl_tdata2_etrigger: assert property (
      rvfi_if.rvfi_valid
      && |tdata2.rvfi_csr_wmask != 0
      && tdata1_post_state[MSB_TYPE:LSB_TYPE] == TTYPE_ETRIGGER
      |->
      !tdata2_post_state[ET2_DATA_31:ET2_DATA_26]
      && !tdata2_post_state[ET2_DATA_23:ET2_DATA_12]
      && !tdata2_post_state[ET2_DATA_10:ET2_DATA_9]
      && !tdata2_post_state[ET2_DATA_6]
      && !tdata2_post_state[ET2_DATA_4]
      && !tdata2_post_state[ET2_DATA_0]
    ) else `uvm_error(info_tag, "There is a problem with tdata1-etrigger's WARL fields.\n");

    a_dt_warl_tdata3: assert property (
      rvfi_if.rvfi_valid
      && |tdata3.rvfi_csr_wmask != 0
      |->
      !tdata3_post_state
    ) else `uvm_error(info_tag, "There is a problem with tdata3's WARL fields.\n");

    a_dt_warl_tinfo: assert property (
      rvfi_if.rvfi_valid
      && |tinfo.rvfi_csr_wmask != 0
      |->
      !tinfo_post_state[31:16]
    ) else `uvm_error(info_tag, "There is a problem with tinfo's WARL fields.\n");

    a_dt_warl_tcontrol: assert property (
      rvfi_if.rvfi_valid
      && |tcontrol.rvfi_csr_wmask != 0
      |->
      !tcontrol_post_state[HW_ZERO_31:HW_ZERO_8]
      && !tcontrol_post_state[MPTE]
      && !tcontrol_post_state[HW_ZERO_6:HW_ZERO_4]
      && !tcontrol_post_state[MTE]
      && !tcontrol_post_state[HW_ZERO_2:HW_ZERO_0]
    ) else `uvm_error(info_tag, "There is a problem with tcontrol's WARL fields.\n");


    //- Vplan:
    //Access all tdata registers in M-mode and observe writes have no effects and reads should reflect register content.
    //Access registers from D-mode and observe full R/W access.
    //Access from U-mode and observe no access at all.

    // - Assertion verification:
    //1) Verify that all tdata registers can be read in machine mode, but that writes do not have any effect
    //2) Verify that all tdata registers can be read in debug mode, and that writes have an effect
    //3) Verify that the tdata registers are unaccessible in user mode

    //1)
    a_dt_no_write_access_to_tcsrs_in_mmode: assert property (

      valid_instr_in_mmode
      && rvfi_if.csr_addr != ADDR_TSELECT

      |->
      tdata1_post_state == tdata1_pre_state
      && tdata2_post_state == tdata2_pre_state
      && tdata3_post_state == tdata3_pre_state

    ) else `uvm_error(info_tag, "The t-CSRs are written in machine mode (not debug mode), and the write changes the CSRs values.\n");


    c_dt_write_tdata1_in_mmode: cover property (
      seq_csr_write_mmode(ADDR_TDATA1)
    );

    c_dt_write_tdata2_in_mmode: cover property (
      seq_csr_write_mmode(ADDR_TDATA2)
    );

    c_dt_write_tdata3_in_mmode: cover property (
      seq_csr_write_mmode(ADDR_TDATA3)
    );


    a_dt_read_access_to_tdata1_in_mmode: assert property (
      seq_csr_read_mmode(ADDR_TDATA1)
      |->
      rvfi_if.rvfi_rd1_wdata == tdata1_pre_state
    ) else `uvm_error(info_tag, "No read access to tdata1 in machine mode.\n");

    a_dt_read_access_to_tdata2_in_mmode: assert property (
      seq_csr_read_mmode(ADDR_TDATA2)
      |->
      rvfi_if.rvfi_rd1_wdata == tdata2_pre_state
    ) else `uvm_error(info_tag, "No read access to tdata2 in machine mode.\n");

    a_dt_read_access_to_tdata3_in_mmode: assert property (
      seq_csr_read_mmode(ADDR_TDATA3)
      |->
      rvfi_if.rvfi_rd1_wdata == tdata3_pre_state
    ) else `uvm_error(info_tag, "No read access to tdata3 in machine mode.\n");


    //2)
    a_dt_write_access_to_tdata1_in_dmode: assert property (
      p_csrrw_in_dmode(ADDR_TDATA1, tdata1_post_state)
      or p_csrrs_in_dmode(ADDR_TDATA1, tdata1_post_state)
      or p_csrrc_in_dmode(ADDR_TDATA1, tdata1_post_state)
      or p_csrrwi_in_dmode(ADDR_TDATA1, tdata1_post_state)
      or p_csrrsi_in_dmode(ADDR_TDATA1, tdata1_post_state)
      or p_csrrci_in_dmode(ADDR_TDATA1, tdata1_post_state)
    ) else `uvm_error(info_tag, "No write access to tdata1 in debug mode.\n");

    a_dt_write_access_to_tdata2_in_dmode: assert property (
      p_csrrw_in_dmode(ADDR_TDATA2, tdata2_post_state)
      or p_csrrs_in_dmode(ADDR_TDATA2, tdata2_post_state)
      or p_csrrc_in_dmode(ADDR_TDATA2, tdata2_post_state)
      or p_csrrwi_in_dmode(ADDR_TDATA2, tdata2_post_state)
      or p_csrrsi_in_dmode(ADDR_TDATA2, tdata2_post_state)
      or p_csrrci_in_dmode(ADDR_TDATA2, tdata2_post_state)
    ) else `uvm_error(info_tag, "No write access to tdata2 in debug mode.\n");

    a_dt_write_access_to_tdata3_in_dmode: assert property (
      p_csrrw_in_dmode(ADDR_TDATA3, tdata3_post_state)
      or p_csrrs_in_dmode(ADDR_TDATA3, tdata3_post_state)
      or p_csrrc_in_dmode(ADDR_TDATA3, tdata3_post_state)
      or p_csrrwi_in_dmode(ADDR_TDATA3, tdata3_post_state)
      or p_csrrsi_in_dmode(ADDR_TDATA3, tdata3_post_state)
      or p_csrrci_in_dmode(ADDR_TDATA3, tdata3_post_state)
    ) else `uvm_error(info_tag, "No write access to tdata3 in debug mode.\n");


    a_dt_read_access_to_tdata1_in_dmode: assert property (
      seq_csr_read_dmode(ADDR_TDATA1)
      |->
      rvfi_if.rvfi_rd1_wdata == tdata1_pre_state
    ) else `uvm_error(info_tag, "No read access to tdata1 in debug mode.\n");

    a_dt_read_access_to_tdata2_in_dmode: assert property (
      seq_csr_read_dmode(ADDR_TDATA2)
      |->
      rvfi_if.rvfi_rd1_wdata == tdata2_pre_state
    ) else `uvm_error(info_tag, "No read access to tdata2 in debug mode.\n");

    a_dt_read_access_to_tdata3_in_dmode: assert property (
      seq_csr_read_dmode(ADDR_TDATA3)
      |->
      rvfi_if.rvfi_rd1_wdata == tdata3_pre_state
    ) else `uvm_error(info_tag, "No read access to tdata3 in debug mode.\n");


    //3)
    a_dt_no_access_to_tdata_in_umode: assert property (

      valid_instr_in_umode

      && (rvfi_if.is_csr_instr(ADDR_TDATA1)
      || rvfi_if.is_csr_instr(ADDR_TDATA2)
      || rvfi_if.is_csr_instr(ADDR_TDATA3))

      |->
      rvfi_if.rvfi_trap.trap
    ) else `uvm_error(info_tag, "Access to the t-CSRs in user mode.\n");


    //- Vplan:
    //Write 0 to "tdata1", ensure that its state becomes disabled (type 15). Write values to "tdata2" (addresses and/or exception causes)
    //and exercise would-have-been triggers and check that the trigger does not fire.

    //- Assertion verification:
    //1) Write 0 to "tdata1", ensure that its state becomes disabled (type 15).
    //2) Write values to "tdata2" (addresses and/or exception causes) and exercise would-have-been triggers and check that the trigger does not fire (because tdata1 is in disabled state).


    //1)
    a_dt_write_0_to_tdata1: assert property (
      seq_csr_write_dmode(ADDR_TDATA1)

      ##0 rvfi_if.is_csr_write(ADDR_TDATA1)

      && ((rvfi_if.rvfi_insn[14:12] == 3'b001 //write
      && rvfi_if.rvfi_rs1_rdata == '0)

      || (rvfi_if.rvfi_insn[14:12] == 3'b011 //clear
      && rvfi_if.rvfi_rs1_rdata == 32'hFFFF_FFFF)

      || (rvfi_if.rvfi_insn[14:12] == 3'b101 //write immediate
      && rvfi_if.csri_uimm == '0)

      || (rvfi_if.rvfi_insn[14:12] == 3'b111 //clear immediate
      && rvfi_if.csri_uimm == 5'h1F
      && tdata1_pre_state[31:6] == '0))

      |->
      tdata1_post_state == TDATA1_DISABLED
    ) else `uvm_error(info_tag, "Writing 0 to tdata1 does not set tdata1 into disabled state.\n");


    //2) see a_dt_enter_dbg_reason

    //A not fully covering extra check:
    a_dt_tdata1s_disabled_no_dbg: assert property (
      rvfi_if.rvfi_valid
      && rvfi_if.rvfi_trap.debug

      && support_if.tdata1_array[0] == TDATA1_DISABLED
      && support_if.tdata1_array[1] == TDATA1_DISABLED
      && support_if.tdata1_array[2] == TDATA1_DISABLED
      && support_if.tdata1_array[3] == TDATA1_DISABLED

      |->
      rvfi_if.rvfi_trap.debug_cause != TRIGGER_MATCH
    ) else `uvm_error(info_tag, "Entering debug due to trigger match even though no triggers are enabled.\n");


    //- Vplan:
    //Read the state of all triggers, write to tdata1/2/3 (using all types in tdata1), read back the state of all triggers and
    //check that nothing got changes except the one "tdata*" register that was written.

    //- Assertion verification:
    //1) write to tdata1/2/3 and check that nothing got changes except the one "tdata*" register that was written

    //1)
    a_dt_write_only_tdata1: assert property (
      seq_csr_write_dmode(ADDR_TDATA1)
      |->
      !tdata2.rvfi_csr_wmask
      && !tdata3.rvfi_csr_wmask
    ) else `uvm_error(info_tag, "A write to tdata1 writes tdata2 or tdata3 as well.\n");

    a_dt_write_only_tdata2: assert property (
      seq_csr_write_dmode(ADDR_TDATA2)
      |->
      !tdata1.rvfi_csr_wmask
      && !tdata3.rvfi_csr_wmask
    ) else `uvm_error(info_tag, "A write to tdata2 writes tdata1 or tdata3 as well.\n");

    a_dt_write_only_tdata3: assert property (
      seq_csr_write_dmode(ADDR_TDATA3)
      |->
      !tdata1.rvfi_csr_wmask
      && !tdata2.rvfi_csr_wmask
    ) else `uvm_error(info_tag, "A write to tdata3 writes tdata1 or tdata2 as well.\n");


    //- Vplan:
    //Bring core into debug and enable a trigger on the PC (pointing to the debug program buffer).
    //Continue execution in debug, and observe that no action is taken when the trigger matches.

    //- Assertion verification:
    //1) Bring core into debug and observe that no action is taken when there are trigger matches


    //1)
    a_dt_no_actions_on_trigger_matches_in_debug: assert property (
      rvfi_if.rvfi_valid
      && rvfi_if.rvfi_dbg_mode

      //Random trigger match
      && ((support_if.is_trigger_match_exception
      && !rvfi_if.is_csr_write(ADDR_DCSR)
      && !rvfi_if.is_csr_write(ADDR_DPC))

      || (support_if.is_trigger_match_execute
      && !rvfi_if.is_csr_write(ADDR_DCSR)
      && !rvfi_if.is_csr_write(ADDR_DPC))

      || support_if.is_trigger_match_load
      || support_if.is_trigger_match_store)

      //Instruction dont write to dcsr og dpc

      |->
      !dcsr.rvfi_csr_wmask
      && !dpc.rvfi_csr_wmask
    ) else `uvm_error(info_tag, "Action is taken when there is a trigger match while in debug mode.\n");


    //- Vplan:
    //Configure "tdata1" and "tdata2" to fire on exceptions, try both individual and multiple exceptions in addition to supported and unsupported. Exercise scenarios that would trigger or not trigger according to the configuration and check that debug mode is either entered or not entered accordingly, and that the entry goes correctly (pc, dpc, cause, etc).

    //- Assertion verification:
    //1) Verify that we enter debug when triggering the enabled exceptions
    //2) Verify that we do not enter debug when triggering unenabled exceptions

    //1)
    a_dt_exception_trigger_hit_m_instr_access_fault: assert property(
      p_etrigger_hit(
        rvfi_if.is_mmode,
        EXC_CAUSE_INSTR_FAULT)
    ) else `uvm_error(info_tag, "The trigger match (exception match, machine mode, instruction fault) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_u_instr_access_fault: assert property(
      p_etrigger_hit(
        rvfi_if.is_umode,
        EXC_CAUSE_INSTR_FAULT)
    ) else `uvm_error(info_tag, "The trigger match (exception match, user mode, instruction fault) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_m_illegal_instr: assert property(
      p_etrigger_hit(
        rvfi_if.is_mmode,
        EXC_CAUSE_ILLEGAL_INSN)
    ) else `uvm_error(info_tag, "The trigger match (exception match, machine mode, illegal instruction) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_u_illegal_instr: assert property(
      p_etrigger_hit(
        rvfi_if.is_umode,
        EXC_CAUSE_ILLEGAL_INSN)
    ) else `uvm_error(info_tag, "The trigger match (exception match, user mode, illegal instruction) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_m_breakpoint: assert property(
      p_etrigger_hit(
        rvfi_if.is_mmode,
        EXC_CAUSE_BREAKPOINT)
    ) else `uvm_error(info_tag, "The trigger match (exception match, machine mode, breakpoint in machine mode) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_u_breakpoint: assert property(
      p_etrigger_hit(
        rvfi_if.is_umode,
        EXC_CAUSE_BREAKPOINT)
    ) else `uvm_error(info_tag, "The trigger match (exception match, user mode, breakpoint in user mode) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_m_load_access_fault: assert property(
      p_etrigger_hit(
        rvfi_if.is_mmode,
        EXC_CAUSE_LOAD_FAULT)
    ) else `uvm_error(info_tag, "The trigger match (exception match, machine mode, load access fault) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_u_load_access_fault: assert property(
      p_etrigger_hit(
        rvfi_if.is_umode,
        EXC_CAUSE_LOAD_FAULT)
    ) else `uvm_error(info_tag, "The trigger match (exception match, user mode, load access fault) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_m_store_AMO_access_fault: assert property(
      p_etrigger_hit(
        rvfi_if.is_mmode,
        EXC_CAUSE_STORE_FAULT)
    ) else `uvm_error(info_tag, "The trigger match (exception match, machine mode, stor/AMO access fault) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_u_store_AMO_access_fault: assert property(
      p_etrigger_hit(
        rvfi_if.is_umode,
        EXC_CAUSE_STORE_FAULT)
    ) else `uvm_error(info_tag, "The trigger match (exception match, user mode, stor/AMO access fault) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_m_mecall: assert property(
      p_etrigger_hit(
        rvfi_if.is_mmode,
        EXC_CAUSE_ECALL_MMODE)
    ) else `uvm_error(info_tag, "The trigger match (exception match, machine mode, ecall in machine mode) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_m_instr_bus_fault: assert property(
      p_etrigger_hit(
        rvfi_if.is_mmode,
        EXC_CAUSE_INSTR_BUS_FAULT)
    ) else `uvm_error(info_tag, "The trigger match (exception match, machine mode, instruction bus fault) does not send the core into debug mode.\n");

    a_dt_exception_trigger_hit_u_instr_bus_fault: assert property(
      p_etrigger_hit(
        rvfi_if.is_umode,
        EXC_CAUSE_INSTR_BUS_FAULT)
    ) else `uvm_error(info_tag, "The trigger match (exception match, user mode, instruction bus fault) does not send the core into debug mode.\n");


    //- Assertion verification:
    //1) Verify that we enter debug when triggering the enabled instruction, memory address or exception
    //2) Verify that we do not enter debug when triggering unenabled instruction, memory address or exception

    //It is possible to formulate an assertions for general verification of instruction triggering,
    //However, to reduce convergense time we verify this trigger feature with several more constricted assertions:
    //for (genvar t = 0; t < MAX_NUM_TRIGGERS; t++) begin

    for (genvar t = 0; t < CORE_PARAM_DBG_NUM_TRIGGERS; t++) begin
      //machine mode:
      a_dt_instr_trigger_hit_mmode_match_when_equal: assert property (
        seq_execute_hit(
          t,
          rvfi_if.is_mmode,
          MATCH_WHEN_EQUAL)

        ##0 rvfi_if.rvfi_pc_rdata == support_if.tdata2_array[t]
        |->
        rvfi_if.rvfi_trap.debug
      ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

      a_dt_instr_trigger_hit_umode_match_when_equal: assert property (
        seq_execute_hit(
          t,
          rvfi_if.is_umode,
          MATCH_WHEN_EQUAL)

        ##0 rvfi_if.rvfi_pc_rdata == support_if.tdata2_array[t]
        |->
        rvfi_if.rvfi_trap.debug
      ) else `uvm_error(info_tag, "The trigger match (instruction match, user mode, match when equal) does not send the core into debug mode.\n");

      a_dt_instr_trigger_hit_mmode_match_when_equal_or_greater: assert property (
        seq_execute_hit(
          t,
          rvfi_if.is_mmode,
          MATCH_WHEN_GREATER_OR_EQUAL)

        ##0 rvfi_if.rvfi_pc_rdata >= support_if.tdata2_array[t]
        |->
        rvfi_if.rvfi_trap.debug
      ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when greater or equal) does not send the core into debug mode.\n");

      a_dt_instr_trigger_hit_umode_match_when_equal_or_greater: assert property (
        seq_execute_hit(
          t,
          rvfi_if.is_umode,
          MATCH_WHEN_GREATER_OR_EQUAL)

        ##0 rvfi_if.rvfi_pc_rdata >= support_if.tdata2_array[t]
        |->
        rvfi_if.rvfi_trap.debug
      ) else `uvm_error(info_tag, "The trigger match (instruction match, user mode, match when greater or equal) does not send the core into debug mode.\n");

      a_dt_instr_trigger_hit_mmode_match_when_lesser: assert property (
        seq_execute_hit(
          t,
          rvfi_if.is_mmode,
          MATCH_WHEN_LESSER)

        ##0 rvfi_if.rvfi_pc_rdata < support_if.tdata2_array[t]
        |->
        rvfi_if.rvfi_trap.debug
      ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when lesser) does not send the core into debug mode.\n");

      a_dt_instr_trigger_hit_umode_match_when_lesser: assert property (
        seq_execute_hit(
          t,
          rvfi_if.is_umode,
          MATCH_WHEN_LESSER)

        ##0 rvfi_if.rvfi_pc_rdata < support_if.tdata2_array[t]
        |->
        rvfi_if.rvfi_trap.debug
      ) else `uvm_error(info_tag, "The trigger match (instruction match, user mode, match when lesser) does not send the core into debug mode.\n");


      for (genvar n = 0; n < MAX_MEM_ACCESS; n++) begin

        a_dt_load_trigger_hit_mmode_match_when_equal: assert property (
          seq_load_hit(
            t,
            rvfi_if.is_mmode,
            MATCH_WHEN_EQUAL)
          ##0 rvfi_mem_addrs[n][31:2] == support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

        a_dt_load_trigger_hit_umode_match_when_equal: assert property (
          seq_load_hit(
            t,
            rvfi_if.is_umode,
            MATCH_WHEN_EQUAL)
          ##0 rvfi_mem_addrs[n][31:2] == support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

        a_dt_load_trigger_hit_mmode_match_when_equal_or_greater: assert property (
          seq_load_hit(
            t,
            rvfi_if.is_mmode,
            MATCH_WHEN_GREATER_OR_EQUAL)
          ##0 rvfi_mem_addrs[n][31:2] >= support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

        a_dt_load_trigger_hit_umode_match_when_equal_or_greater: assert property (
          seq_load_hit(
            t,
            rvfi_if.is_umode,
            MATCH_WHEN_GREATER_OR_EQUAL)
          ##0 rvfi_mem_addrs[n][31:2] >= support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

        a_dt_load_trigger_hit_mmode_match_when_lesser: assert property (
          seq_load_hit(
            t,
            rvfi_if.is_mmode,
            MATCH_WHEN_LESSER)
          ##0 rvfi_mem_addrs[n][31:2] < support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

        a_dt_load_trigger_hit_umode_match_when_lesser: assert property (
          seq_load_hit(
            t,
            rvfi_if.is_umode,
            MATCH_WHEN_LESSER)
          ##0 rvfi_mem_addrs[n][31:2] < support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

        //Store:
        a_dt_store_trigger_hit_mmode_match_when_equal: assert property (
          seq_store_hit(
            t,
            rvfi_if.is_mmode,
            MATCH_WHEN_EQUAL)
          ##0 rvfi_mem_addrs[n][31:2] == support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

        a_dt_store_trigger_hit_umode_match_when_equal: assert property (
          seq_store_hit(
            t,
            rvfi_if.is_umode,
            MATCH_WHEN_EQUAL)
          ##0 rvfi_mem_addrs[n][31:2] == support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

        a_dt_store_trigger_hit_mmode_match_when_equal_or_greater: assert property (
          seq_store_hit(
            t,
            rvfi_if.is_mmode,
            MATCH_WHEN_GREATER_OR_EQUAL)
          ##0 rvfi_mem_addrs[n][31:2] >= support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

        a_dt_store_trigger_hit_umode_match_when_equal_or_greater: assert property (
          seq_store_hit(
            t,
            rvfi_if.is_umode,
            MATCH_WHEN_GREATER_OR_EQUAL)
          ##0 rvfi_mem_addrs[n][31:2] >= support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

        a_dt_store_trigger_hit_mmode_match_when_lesser: assert property (
          seq_store_hit(
            t,
            rvfi_if.is_mmode,
            MATCH_WHEN_LESSER)
          ##0 rvfi_mem_addrs[n][31:2] < support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

        a_dt_store_trigger_hit_umode_match_when_lesser: assert property (
          seq_store_hit(
            t,
            rvfi_if.is_umode,
            MATCH_WHEN_LESSER)
          ##0 rvfi_mem_addrs[n][31:2] < support_if.tdata2_array[t][31:2]
          |->
          rvfi_if.rvfi_trap.debug
        ) else `uvm_error(info_tag, "The trigger match (instruction match, machine mode, match when equal) does not send the core into debug mode.\n");

      end
    end


    //2)
    a_dt_enter_dbg_reason: assert property (
      rvfi_if.rvfi_valid
      && rvfi_if.rvfi_trap.debug
      && rvfi_if.rvfi_trap.debug_cause == TRIGGER_MATCH

      |->
      support_if.is_trigger_match_exception
      || support_if.is_trigger_match_execute
      || support_if.is_trigger_match_load
      || support_if.is_trigger_match_store

    ) else `uvm_error(info_tag, "We have entered debug mode due to triggers but not due to any of the listed reasons.\n");


    //- Vplan:
    //Change the type to 2/6/15 and write any data to "tdata2", read it back and check that it always gets set. Do the same for "tdata3" and check that it always reads back 0.

    //- Assertion verification:
    //1) Change the type to 2/6/15 and write any data to "tdata2", read it back and check that it always gets set.
    //2) Do the same for "tdata3" and check that it always reads back 0.


    //1)
    a_dt_write_tdata2_random_in_dmode_type_2_6_15: assert property (

      (seq_csr_write_dmode(ADDR_TDATA2)
      ##0 rvfi_if.rvfi_rs1_rdata == $random()
      && (tdata1_pre_state[MSB_TYPE:LSB_TYPE] == 2
      || tdata1_pre_state[MSB_TYPE:LSB_TYPE] == 6
      || tdata1_pre_state[MSB_TYPE:LSB_TYPE] == 15))

      |->
      (is_csrrw && (tdata2_post_state == rvfi_if.rvfi_rs1_rdata))
      || (is_csrrs && (tdata2_post_state == (tdata2_pre_state | rvfi_if.rvfi_rs1_rdata)))
      || (is_csrrc && (tdata2_post_state == (tdata2_pre_state & (~rvfi_if.rvfi_rs1_rdata))))
      || (is_csrrwi && (tdata2_post_state == csri_uimm))
      || (is_csrrsi && (tdata2_post_state == (tdata2_pre_state | csri_uimm)))
      || (is_csrrci && (tdata2_post_state == (tdata2_pre_state & (~csri_uimm))))

    ) else `uvm_error(info_tag, "Random values for tdata2 type 2/6/15 in debug mode, is not accepted.\n");


    for (genvar t = 0; t < CORE_PARAM_DBG_NUM_TRIGGERS; t++) begin

      c_dt_w_csrrw_tdata2_m2_m6_disabled: cover property (
        seq_tdata2_m2_m6_disabled(t)
        ##0 is_csrrw
        && rvfi_if.rvfi_insn[31:20] == ADDR_TDATA2
      );

      c_dt_w_csrrs_tdata2_m2_m6_disabled: cover property (
        seq_tdata2_m2_m6_disabled(t)
        ##0 is_csrrs
        && rvfi_if.rvfi_insn[31:20] == ADDR_TDATA2
      );

      c_dt_w_csrrc_tdata2_m2_m6_disabled: cover property (
        seq_tdata2_m2_m6_disabled(t)
        ##0 is_csrrc
        && rvfi_if.rvfi_insn[31:20] == ADDR_TDATA2
      );

      c_dt_w_csrrwi_tdata2_m2_m6_disabled: cover property (
        seq_tdata2_m2_m6_disabled(t)
        ##0 is_csrrwi
        && rvfi_if.rvfi_insn[31:20] == ADDR_TDATA2
      );

      c_dt_w_csrrsi_tdata2_m2_m6_disabled: cover property (
        seq_tdata2_m2_m6_disabled(t)
        ##0 is_csrrsi
        && rvfi_if.rvfi_insn[31:20] == ADDR_TDATA2
      );

      c_dt_w_csrrci_tdata2_m2_m6_disabled: cover property (
        seq_tdata2_m2_m6_disabled(t)
        ##0 is_csrrci
        && rvfi_if.rvfi_insn[31:20] == ADDR_TDATA2
      );

    end

    //2) see a_dt_warl_tdata3

  end // if CORE_PARAM_DBG_NUM_TRIGGERS > 0


endmodule : uvmt_cv32e40x_triggers_assert_cov