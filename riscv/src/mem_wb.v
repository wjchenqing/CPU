`include "defines.v"

module mem_wb(
    input   wire            clk_in,
    input   wire            rst_in,
    input   wire            rdy_in,
    input   wire[5:0]       stall,

    input   wire                rd_mem_in,
    input   wire[`RegBus]       rd_val_mem_in,
    input   wire[`RegAddrBus]   rd_addr_mem_in,

    output  reg                 rd_wb_out,
    output  reg[`RegBus]        rd_val_wb_out,
    output  reg[`RegAddrBus]    rd_addr_wb_out
);

    always @ (posedge clk_in) begin
        if (rst_in == `RstEnable) begin
            rd_wb_out <= `WriteDisable;
            rd_val_wb_out <= `ZeroWord;
            rd_addr_wb_out <= `NOPRegAdder;
        end else if (rdy_in == 1'b1) begin
            if (stall[4] == `Stop && stall[5] == `NotStop ) begin
                rd_wb_out <= `WriteDisable ;
                rd_val_wb_out <= `ZeroWord ;
                rd_addr_wb_out <= `NOPRegAdder ;
            end else if (stall[4] == `NotStop ) begin
                rd_wb_out <= rd_mem_in;
                rd_val_wb_out <= rd_val_mem_in;
                rd_addr_wb_out <= rd_addr_mem_in;
            end
        end
    end

endmodule : mem_wb