`include "defines.v"

module id_ex(
    input   wire            clk_in,
    input   wire            rst_in,
    input   wire[5:0]       stall,

    //form id
    input   wire[`RegBus]       rs1_val_id_in,
    input   wire[`RegBus]       rs2_val_id_in,
    input   wire                rd_id_in,
    input   wire[`RegAddrBus]   rd_addr_id_in,
    input   wire[`InstTypeBus]  inst_type_id_in,
    input   wire[`RegBus]       imm_id_in,
    input   wire[`InstAddrBus]  pc_id_in,

    output  reg[`RegBus]        rs1_val_ex_out,
    output  reg[`RegBus]        rs2_val_ex_out,
    output  reg                 rd_ex_out,
    output  reg[`RegAddrBus]    rd_addr_ex_out,
    output  reg[`InstTypeBus]   inst_type_ex_out,
    output  reg[`RegBus]        imm_ex_out,
    output  reg[`InstAddrBus]   pc_ex_out
);

    always @ (posedge clk_in) begin
        if (rst_in == `RstEnable) begin
            rs1_val_ex_out <= `ZeroWord;
            rs2_val_ex_out <= `ZeroWord;
            rd_ex_out <= `WriteDisable;
            rd_addr_ex_out <= `NOPRegAdder;
            inst_type_ex_out <= `NOPInstType;
            imm_ex_out <= `ZeroWord;
            pc_ex_out <= `ZeroWord;
        end else if (stall[2] == `Stop && stall[3] == `NotStop ) begin
            rs1_val_ex_out <= `ZeroWord ;
            rs2_val_ex_out <= `ZeroWord ;
            rd_ex_out <= `WriteDisable ;
            rd_addr_ex_out <= `NOPRegAdder ;
            inst_type_ex_out <= `NOPInstType ;
            imm_ex_out <= `ZeroWord ;
            pc_ex_out <= `ZeroWord ;
        end else if (stall[2] == `NotStop ) begin
            rs1_val_ex_out <= rs1_val_id_in;
            rs2_val_ex_out <= rs2_val_id_in;
            rd_ex_out <= rd_id_in;
            rd_addr_ex_out <= rd_addr_id_in;
            inst_type_ex_out <= inst_type_id_in;
            imm_ex_out <= imm_id_in;
            pc_ex_out <= pc_id_in;
        end
    end

endmodule : id_ex