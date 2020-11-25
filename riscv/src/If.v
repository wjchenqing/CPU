`include "defines.v"

module If(
    input   wire        rst_in,

    input   wire[`InstAddrBus]        pc,

    output  reg                if_req_out,
    output  reg[`InstAddrBus]  inst_addr_out,

    input   wire[`InstBus]      inst_in,
    input   wire[1:0]           busy_in,
    input   wire                inst_done_in,

    input   wire                branch_flag_in,
    input   wire[`InstAddrBus]                branch_target_addr_in,

    output  reg                stall_req_from_if,

    output  reg[`InstAddrBus ] if_pc_out,
    output  reg[`InstBus ]     if_inst_out
);
    always @ (*) begin
        if (rst_in == `RstEnable) begin
            if_req_out <= 1'b0;
            inst_addr_out <= `ZeroWord ;
            stall_req_from_if <= `NotStop ;
            if_pc_out <= `ZeroWord ;
            if_inst_out <= `ZeroWord ;
        end else if (branch_flag_in == `Branch ) begin
            if_req_out <= 1'b0;
            inst_addr_out <= `ZeroWord ;
            stall_req_from_if <= `NotStop ;
            if_pc_out <= `ZeroWord ;
            if_inst_out <= `ZeroWord ;
        end else if (inst_done_in == 1'b1) begin
            if_req_out <= 1'b0;
            inst_addr_out <= `ZeroWord ;
            stall_req_from_if <= `NotStop ;
            if_pc_out <= pc;
            if_inst_out <= inst_in;
        end else if (busy_in[0] == `True_v ) begin
            if_req_out <= 1'b0;
            inst_addr_out <= pc ;
            stall_req_from_if <= `Stop ;
            if_pc_out <= `ZeroWord ;
            if_inst_out <= `ZeroWord ;
        end else if ((busy_in == 2'b10) || (busy_in == 2'b0)) begin
            if_req_out <= `True_v ;
            inst_addr_out <= pc;
            stall_req_from_if <= `Stop ;
            if_pc_out <= `ZeroWord ;
            if_inst_out <= `ZeroWord ;
        end
    end
endmodule : If