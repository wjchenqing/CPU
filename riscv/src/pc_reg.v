`include "defines.v"

module pc_reg(
    input   wire        clk_in,
    input   wire        rst_in,
    input   wire        rdy_in,
    input   wire[5:0]   stall,

    output reg[`InstAddrBus]    pc_out,
    output reg                  ce
);

    always @ (posedge clk_in) begin
        if (rst_in == `RstEnable) begin
            ce <= `ChipDisable;
        end else begin
            ce <= `ChipEnable;
        end
    end

    always @ (posedge clk_in) begin
        if (ce == `ChipDisable) begin
            pc <= `ZeroWord;
        end else if (stall[0] == `NotStop) begin
            pc <= pc + 4'h4;
        end
    end

endmodule : pc_reg