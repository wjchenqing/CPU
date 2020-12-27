`include "defines.v"

module if_id(
    input   wire        clk_in,
    input   wire        rst_in,
    input   wire        rdy_in,
    input   wire[5:0]   stall,

    input   wire        branch_flag_in,

    input   wire[`InstAddrBus]  if_pc,
    input   wire[`InstBus]      if_inst,
    input   wire                pre_to_take_in,

    output  reg[`InstAddrBus]   id_pc,
    output  reg[`InstBus]       id_inst,
    output  reg                 pre_to_take_out
);

    always @ (posedge clk_in) begin
        if (rst_in == `RstEnable) begin
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
            pre_to_take_out <= `False_v;
        end else if (rdy_in == 1'b1) begin
            if (stall[1] == `Stop && stall[2] == `NotStop ) begin
                id_pc <= `ZeroWord ;
                id_inst <= `ZeroWord ;
                pre_to_take_out <= `False_v;
            end else if (stall[1] == `Stop) begin

            end else if (branch_flag_in == `Branch ) begin
                id_pc <= `ZeroWord ;
                id_inst <= `ZeroWord ;
                pre_to_take_out <= `False_v;
            end else if (stall[1] == `NotStop ) begin
                id_pc <= if_pc;
                id_inst <= if_inst;
                pre_to_take_out <= pre_to_take_in;
            end
        end
    end

endmodule : if_id