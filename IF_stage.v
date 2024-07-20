`include "mycpu.h"
module IF_stage (
    input  wire                   clk,
    input  wire                   resetn,
    // ID to ID interface
    input  wire                   ID_allowin,
    input  wire [           32:0] br_bus,
    // IF to ID interface
    output wire                   IF_ID_valid,
    output wire [`IF_ID_LEN -1:0] IF_ID_bus,
    // inst sram interface
    output wire                   inst_sram_en,
    output wire [            3:0] inst_sram_we,
    output wire [           31:0] inst_sram_addr,
    output wire [           31:0] inst_sram_wdata,
    input  wire [           31:0] inst_sram_rdata
);

  reg         IF_valid;
  wire        IF_ready_go;
  wire        IF_allowin;
  wire        to_IF_valid;

  wire [31:0] seq_pc;
  wire [31:0] nextpc;

  wire        br_taken;
  wire [31:0] br_target;

  assign {br_taken, br_target} = br_bus;

  wire [31:0] IF_inst;
  reg  [31:0] IF_pc;
  assign IF_ID_bus   = {IF_inst, IF_pc};


  assign seq_pc      = IF_pc + 3'h4;
  assign nextpc      = br_taken ? br_target : seq_pc;

  //------------------------------state control signal---------------------------------------
  assign to_IF_valid = resetn;
  assign IF_ready_go = 1'b1;
  assign IF_allowin  = ~IF_valid | IF_ready_go & ID_allowin;
  assign IF_ID_valid = IF_valid & IF_ready_go;
  
  always @(posedge clk) begin
    if (~resetn) IF_valid <= 1'b0;
    else if (IF_allowin)
      IF_valid <= to_IF_valid;  // 在reset撤销的下一个时钟上升沿才开始取指
  end
  //------------------------------inst sram interface---------------------------------------

  assign inst_sram_en    = IF_allowin & resetn;
  assign inst_sram_we    = 4'b0;
  assign inst_sram_addr  = nextpc;
  assign inst_sram_wdata = 32'b0;

  //------------------------------pc relavant signals---------------------------------------

  assign seq_pc          = IF_pc + 3'h4;
  assign nextpc          = br_taken ? br_target : seq_pc;

  //------------------------------IF TO ID state interface---------------------------------------
  //IF_pc存前一条指令的pc值
  always @(posedge clk) begin
    if (~resetn) IF_pc <= 32'h1BFF_FFFC;
    else if (IF_allowin) IF_pc <= nextpc;
  end

  assign IF_inst   = inst_sram_rdata;
  assign IF_ID_bus = {IF_inst, IF_pc};  // 32+32
endmodule