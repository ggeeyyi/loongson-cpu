module MEM_stage (
    /*
    MEM_stage模块

    clk: 时钟
    resetn: 复位信号
    MEM_allowin: 允许MEM_stage接收数据
    EX_rf_bus: EX_rf总线
    EX_MEM_valid: EX_MEM是否有效
    EX_pc: EX_pc
    EX_mem_ld_inst: EX_mem_ld指令
    WB_allowin: 允许WB_stage接收数据
    MEM_rf_bus: MEM_rf总线
    MEM_WB_valid: MEM_WB是否有效
    MEM_pc: MEM_pc
    data_sram_rdata: 数据存储器读数据
    */

    input  wire        clk,
    input  wire        resetn,
    output wire        MEM_allowin,
    input  wire [38:0] EX_rf_bus,       // {EX_res_from_mem, EX_rf_we, EX_rf_waddr, EX_alu_result}
    input  wire        EX_MEM_valid,
    input  wire [31:0] EX_pc,
    input  wire [ 4:0] EX_mem_ld_inst,  //{inst_ld_w, inst_ld_b, inst_ld_h, inst_ld_bu, inst_ld_hu}
    input  wire        WB_allowin,
    output wire [37:0] MEM_rf_bus,      // {MEM_rf_we, MEM_rf_waddr, MEM_rf_wdata}
    output wire        MEM_WB_valid,
    output reg  [31:0] MEM_pc,
    input  wire [31:0] data_sram_rdata
);
  wire        MEM_ready_go;
    reg         MEM_valid;
    reg  [31:0] MEM_alu_result ; 
    reg         MEM_res_from_mem;
    reg         MEM_rf_we      ;
    reg  [4 :0] MEM_rf_waddr   ;
    wire [31:0] MEM_rf_wdata   ;
    wire [31:0] MEM_mem_result ;
    reg  [7 :0] MEM_mem_ld_inst;
    wire inst_ld_w;
    wire inst_ld_b;
    wire inst_ld_h;
    wire inst_ld_bu;
    wire inst_ld_hu;
//------------------------------state control signal---------------------------------------

    assign MEM_ready_go      = 1'b1;
    assign MEM_allowin       = ~MEM_valid | MEM_ready_go & WB_allowin;     
    assign MEM_WB_valid      = MEM_valid & MEM_ready_go;
    always @(posedge clk) begin
        if(~resetn)
            MEM_valid <= 1'b0;
        else
            MEM_valid <= EX_MEM_valid & MEM_allowin; 
    end

//------------------------------EX TO MEM state interface---------------------------------------
    always @(posedge clk) begin
        if(~resetn) begin
            MEM_pc <= 32'b0;
            {MEM_res_from_mem, MEM_rf_we, MEM_rf_waddr, MEM_alu_result} <= 38'b0;
            MEM_mem_ld_inst <= 8'b0;
        end
        if(EX_MEM_valid & MEM_allowin) begin
            MEM_pc <= EX_pc;
            {MEM_res_from_mem, MEM_rf_we, MEM_rf_waddr, MEM_alu_result} <= EX_rf_bus;
            MEM_mem_ld_inst <= EX_mem_ld_inst;
        end
    end

    assign {inst_ld_w, inst_ld_b, inst_ld_h, inst_ld_bu, inst_ld_hu} = MEM_mem_ld_inst;

    wire [31:0] shift_rdata;
    assign shift_rdata   = {24'b0, data_sram_rdata} >> {MEM_alu_result[1:0], 3'b0};
    assign MEM_mem_result[7: 0]   =  shift_rdata[7: 0];

    assign MEM_mem_result[15: 8]  =  inst_ld_b ? {8{shift_rdata[7]}} :
                                    inst_ld_bu ? 8'b0 :
                                    shift_rdata[15: 8];

    assign  MEM_mem_result[31:16] = inst_ld_b ? {16{shift_rdata[7]}} :
                                    inst_ld_h ? {16{shift_rdata[15]}} :
                                    inst_ld_bu | inst_ld_hu ? 16'b0 :
                                    shift_rdata[31:16];
    
    assign MEM_rf_wdata = MEM_res_from_mem ?  MEM_mem_result : MEM_alu_result;
    assign MEM_rf_bus  = {MEM_rf_we & MEM_valid, MEM_rf_waddr, MEM_rf_wdata};

endmodule