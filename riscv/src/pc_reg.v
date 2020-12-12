`include "defines.v"

module pc_reg(
    input   wire        clk_in,
    input   wire        rst_in,
    input   wire        rdy_in,
    input   wire[5:0]   stall,

    input   wire                branch_flag_in,
    input   wire[`InstAddrBus ]   branch_target_addr_in,

    output  reg[`InstAddrBus]   pc_out
);

    always @ (posedge clk_in) begin
        if (rst_in == `RstEnable) begin
            pc_out <= `ZeroWord;
        end else if (branch_flag_in == `Branch ) begin
            pc_out <= branch_target_addr_in;
        end else if (stall[0] == `NotStop) begin
            pc_out <= pc_out + 4'h4;
        end
    end

endmodule : pc_reg