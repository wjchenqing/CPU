`include "defines.v"

module ex_mem(
    input   wire        clk_in,
    input   wire        rst_in,
    input   wire        rdy_in,
    input   wire[5:0]   stall,

    input   wire                rd_ex_in,
    input   wire[`RegBus]       rd_val_ex_in,
    input   wire[`RegAddrBus]   rd_addr_ex_in,
    input   wire[`InstTypeBus]  inst_type_ex_in,

    input   wire                load_ex_in,
    input   wire                store_ex_in,
    input   wire[`InstAddrBus]  mem_addr_ex_in,
    input   wire[`RegBus]       mem_val_ex_in,

    output  reg                 rd_mem_out,
    output  reg[`RegBus]        rd_val_mem_out,
    output  reg[`RegAddrBus]    rd_addr_mem_out,
    output  reg[`InstTypeBus]   inst_type_mem_out,

    output  reg                 load_mem_out,
    output  reg                 store_mem_out,
    output  reg[`InstAddrBus]   mem_addr_mem_out,
    output  reg[`RegBus]        mem_val_mem_out,
);

    always @ (posedge clk_in) begin
        if (rst_in == `RstEnable) begin
            rd_mem_out <= `WriteDisable;
            rd_val_mem_out <= `ZeroWord;
            rd_addr_mem_out <= `NOPRegAdder;
            inst_type_mem_out <= `NOPInstType;
            load_mem_out <= `ReadDisable ;
            store_mem_out <= `WriteDisable ;
            mem_addr_mem_out <= `ZeroWord ;
            mem_val_mem_out <= `ZeroWord ;
        end else if (stall[3] == `Stop && stall[4] == `NotStop ) begin
            rd_mem_out <= `WriteDisable ;
            rd_val_mem_out <= `ZeroWord ;
            rd_addr_mem_out <= `NOPRegAdder ;
            inst_type_mem_out <= `NOPInstType ;
            load_mem_out <= `ReadDisable ;
            store_mem_out <= `WriteDisable ;
            mem_addr_mem_out <= `ZeroWord ;
            mem_val_mem_out <= `ZeroWord ;
        end else if (stall[3] == `NotStop ) begin
            rd_mem_out <= rd_ex_in;
            rd_val_mem_out <= rd_val_ex_in;
            rd_addr_mem_out <= rd_addr_ex_in;
            inst_type_mem_out <= inst_type_ex_in;
            load_mem_out <= load_ex_in ;
            store_mem_out <= store_ex_in ;
            mem_addr_mem_out <= mem_addr_ex_in;
            mem_val_mem_out <= mem_val_ex_in;
        end
    end

endmodule : ex_mem