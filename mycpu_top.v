`include "mycpu.h"
module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_req,
    output wire        inst_sram_wr,
    output wire [ 1:0] inst_sram_size,
    output wire [ 3:0] inst_sram_wstrb,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire        inst_sram_addr_ok,
    input  wire        inst_sram_data_ok,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_req,
    output wire        data_sram_wr,
    output wire [ 1:0] data_sram_size,
    output wire [ 3:0] data_sram_wstrb,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire        data_sram_addr_ok,
    input  wire        data_sram_data_ok,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

    wire        ID_allowin;
    wire        EX_allowin;
    wire        MEM_allowin;
    wire        WB_allowin;

    wire        IF_ID_valid;
    wire        ID_EX_valid;
    wire        EX_MEM_valid;
    wire        MEM_WB_valid;

    wire [31:0] EX_pc;
    wire [31:0] MEM_pc;

    wire [39:0] EX_rf_bus;
    wire [38:0] MEM_rf_bus;
    wire [37:0] WB_rf_bus;

    wire [33:0] br_bus;

    wire [`IF_ID_LEN -1:0] IF_ID_bus;
    wire [`ID_EX_LEN -1:0] ID_EX_bus;

    wire [4:0] EX_mem_ld_inst;

    //csr wire
    wire [13:0] csr_num;
    wire [31:0] rdata;
    wire we;
    wire [31:0] wdata;
    wire [31:0] wmask;
    wire EXC_signal;
    wire ERTN_signal;

    wire MEM_EXC_signal;
    wire WB_EXC_signal;


    wire [5:0] EXC_ecode;
    wire [8:0] EXC_esubcode;
    wire [31:0] EXC_pc;

    wire [31:0] CSR_2_IF_pc;
    wire INT_signal;

    wire [84:0] ID_except_bus;
    wire [85:0] EX_except_bus;
    wire [85:0] MEM_except_bus;

    wire [31:0] WB_vaddr;
    wire [31:0] MEM_alu_result;

    //added in exp14
    wire EX_req;

    IF_stage IF(
        .clk(clk),
        .resetn(resetn),

        .ID_allowin(ID_allowin),
        .br_bus(br_bus),
        .IF_ID_valid(IF_ID_valid),
        .IF_ID_bus(IF_ID_bus),

        .inst_sram_req(inst_sram_req),
        .inst_sram_wr(inst_sram_wr),
        .inst_sram_size(inst_sram_size),
        .inst_sram_wstrb(inst_sram_wstrb),
        .inst_sram_addr(inst_sram_addr),
        .inst_sram_wdata(inst_sram_wdata),
        .inst_sram_addr_ok(inst_sram_addr_ok),
        .inst_sram_data_ok(inst_sram_data_ok),
        .inst_sram_rdata(inst_sram_rdata),

        .WB_EXC_signal(WB_EXC_signal),
        .WB_ERTN_signal(ERTN_signal),
        .CSR_2_IF_pc(CSR_2_IF_pc)
    );

    ID_stage ID(
        .clk(clk),
        .resetn(resetn),

        .IF_ID_valid(IF_ID_valid),
        .ID_allowin(ID_allowin),
        .br_bus(br_bus),
        .IF_ID_bus(IF_ID_bus),

        .EX_allowin(EX_allowin),
        .ID_EX_valid(ID_EX_valid),
        .ID_EX_bus(ID_EX_bus),

        .WB_rf_bus(WB_rf_bus),
        .MEM_rf_bus(MEM_rf_bus),
        .EX_rf_bus(EX_rf_bus),
        .ID_except_bus(ID_except_bus),

        .WB_EXC_signal(WB_EXC_signal|ERTN_signal),
        .INT_signal(INT_signal)
    );

    EX_stage EX(
        .clk(clk),
        .resetn(resetn),
        
        .EX_allowin(EX_allowin),
        .ID_EX_valid(ID_EX_valid),
        .ID_EX_bus(ID_EX_bus),

        .MEM_allowin(MEM_allowin),
        .EX_rf_bus(EX_rf_bus),
        .EX_MEM_valid(EX_MEM_valid),
        .EX_pc(EX_pc),
        .EX_mem_ld_inst(EX_mem_ld_inst),
        .EX_req(EX_req),

        .data_sram_req(data_sram_req),
        .data_sram_wr(data_sram_wr),
        .data_sram_size(data_sram_size),
        .data_sram_wstrb(data_sram_wstrb),
        .data_sram_addr(data_sram_addr),
        .data_sram_wdata(data_sram_wdata),
        .data_sram_addr_ok(data_sram_addr_ok),

        .ID_except_bus(ID_except_bus),
        .EX_except_bus(EX_except_bus),

        .MEM_EXC_signal(MEM_EXC_signal),
        .WB_EXC_signal(WB_EXC_signal|ERTN_signal)
    );

    MEM_stage MEM(
        .clk(clk),
        .resetn(resetn),

        .MEM_allowin(MEM_allowin),
        .EX_rf_bus(EX_rf_bus),
        .EX_MEM_valid(EX_MEM_valid),
        .EX_pc(EX_pc),
        .EX_mem_ld_inst(EX_mem_ld_inst),
        .EX_req(EX_req),

        .WB_allowin(WB_allowin),
        .MEM_rf_bus(MEM_rf_bus),
        .MEM_WB_valid(MEM_WB_valid),
        .MEM_pc(MEM_pc),

        .WB_EXC_signal(WB_EXC_signal|ERTN_signal),
        .MEM_EXC_signal(MEM_EXC_signal),

        .MEM_except_bus(MEM_except_bus),
        .EX_except_bus(EX_except_bus),
        .MEM_alu_result(MEM_alu_result),

        .data_sram_rdata(data_sram_rdata),
        .data_sram_data_ok(data_sram_data_ok)
    ) ;

    WB_stage WB(
        .clk(clk),
        .resetn(resetn),

        .WB_allowin(WB_allowin),
        .MEM_rf_bus(MEM_rf_bus),
        .MEM_WB_valid(MEM_WB_valid),
        .MEM_pc(MEM_pc),

        .WB_rf_bus(WB_rf_bus),

        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_we(debug_wb_rf_we),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata),

        .csr_num(csr_num),
        .csr_rvalue(rdata),
        .csr_we(we),
        .csr_wvalue(wdata),
        .csr_wmask(wmask),
        .EXC_signal(WB_EXC_signal),
        .ERTN_signal(ERTN_signal),
        .WB_vaddr(WB_vaddr),
        .WB_pc(EXC_pc),
        .WB_ecode(EXC_ecode),
        .WB_esubcode(EXC_esubcode),

        .MEM_alu_result(MEM_alu_result),
       
        .MEM_except_bus(MEM_except_bus)
    );

    csr CSR(
        .clk(clk),
        .resetn(resetn),

        .csr_num(csr_num),
        .rdata(rdata),

        .we(we),
        .wdata(wdata),
        .wmask(wmask),

        .EXC_signal(WB_EXC_signal),
        .ERTN_signal(ERTN_signal),
        .EXC_ecode(EXC_ecode),
        .EXC_esubcode(EXC_esubcode),
        .EXC_pc(EXC_pc),
        .EXC_vaddr(WB_vaddr),

        .CSR_2_IF_pc(CSR_2_IF_pc),
        .INT_signal(INT_signal)
    );
endmodule
