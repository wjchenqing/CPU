`include "defines.v"

module regfile(
    input   wire        clk_in,
    input   wire        rst_in,
    input   wire        rdy_in,

    //write
    input   wire                we,
    input   wire[`RegAddrBus]   waddr,
    input   wire[`RegBus]       wdata,

    //read1
    input   wire                re1,
    input   wire[`RegAddrBus]   raddr1,
    output  reg[`RegBus]        rdata1,

    //read2
    input   wire                re2,
    input   wire[`RegAddrBus]   raddr2,
    output  reg[`RegBus]        rdata2
);

    //def
    integer i;
    reg[`RegBus]    regs[0:`RegNum - 1];

    //write
    always @ (posedge clk_in) begin
        if (rst_in==`ReadEnable ) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 0;
        end else if (rdy_in == 1'b1 && rst_in == `RstDisable) begin
            if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
                regs[waddr] <= wdata;
            end
        end
    end

    //read1
    always @ (*) begin
        if (rst_in == `RstEnable) begin
            rdata1 <= `ZeroWord;
        end else if (raddr1 == `RegNumLog2'h0) begin
            rdata1 <= `ZeroWord;
        end else if ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable)) begin
            rdata1 <= wdata;
        end else if (re1 == `ReadEnable) begin
            rdata1 <= regs[raddr1];
        end else begin
            rdata1 <= `ZeroWord;
        end
    end

    //
    always @ (*) begin
        if (rst_in == `RstEnable) begin
            rdata2 <= `ZeroWord;
        end else if (raddr2 == `RegNumLog2'h0) begin
            rdata2 <= `ZeroWord;
        end else if ((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable)) begin
            rdata2 <= wdata;
        end else if (re2 == `ReadEnable) begin
            rdata2 <= regs[raddr2];
        end else begin
            rdata2 <= `ZeroWord;
        end
    end

endmodule : regfile