`include "defines.v"

module mem(
    input   wire        rst_in,

    //from mem_ctrl.
    input   wire                mem_done_in,
    input   wire[`RegBus ]      mem_val_read_in,
    input   wire[1:0]           memctrl_busy_in,

    //to mem_ctrl
    output  reg                 read_req_out,
    output  reg                 write_req_out,
    output  reg[`InstAddrBus]   mem_addr_out,
    output  reg[`RegBus ]       mem_val_out,

    //from ex_mem.
    input   wire                rd_in,
    input   wire[`RegBus]       rd_val_in,
    input   wire[`RegAddrBus]   rd_addr_in,
    input   wire[`InstTypeBus]  inst_type_in,
    input   wire                load_in,
    input   wire                store_in,
    input   wire[`InstAddrBus]  mem_addr_in,
    input   wire[`RegBus]       mem_val_in,

    //to mem_wb.
    output  reg                 rd_out,
    output  reg[`RegBus]        rd_val_out,
    output  reg[`RegAddrBus]    rd_addr_out,

    //to ctrl
    output  reg                 stall_req_from_mem,
);

    always @ (*) begin
        if (rst_in == `RstEnable) begin
            read_req_out <= `False_v;
            write_req_out <= `False_v ;
            mem_addr_out <= `ZeroWord ;
            mem_val_out <= `ZeroWord ;
            rd_out <= `WriteDisable;
            rd_val_out <= `ZeroWord;
            rd_addr_out <= `NOPRegAdder;
            stall_req_from_mem <= `False_v ;
        end else if (mem_done_in == `True_v ) begin
            read_req_out <= `False_v;
            write_req_out <= `False_v ;
            mem_addr_out <= `ZeroWord ;
            mem_val_out <= `ZeroWord ;
            rd_out <= rd_in;
            rd_addr_out <= rd_addr_in;
            rd_val_out <= mem_val_out;
            stall_req_from_mem <= `False_v ;
        end else if (load_in == `True_v ) begin
            stall_req_from_mem <= `True_v ;
            if (memctrl_busy_in == 2'b01 || memctrl_busy_in == 2'b0) begin
                read_req_out <= `True_v ;
                write_req_out <= `False_v ;
                mem_addr_out <= mem_addr_in;
                mem_val_out <= `ZeroWord ;
                rd_out <= `False_v ;
                rd_addr_out <= `ZeroWord ;
                rd_val_out <= `ZeroWord ;
            end else if (memctrl_busy_in[1] == `True_v ) begin
                read_req_out <= `False_v;
                write_req_out <= `False_v ;
                mem_addr_out <= `ZeroWord ;
                mem_val_out <= `ZeroWord ;
                rd_out <= `False_v ;
                rd_addr_out <= `ZeroWord;
                rd_val_out <= `ZeroWord ;
            end
        end else if (store_in == `True_v ) begin
            stall_req_from_mem <= `True_v ;
            if (memctrl_busy_in == 2'b01 || memctrl_busy_in == 2'b0) begin
                read_req_out <= `False_v ;
                write_req_out <= `True_v ;
                mem_addr_out <= mem_addr_in;
                mem_val_out <= mem_val_in;
                rd_out <= `False_v ;
                rd_addr_out <= `ZeroWord ;
                rd_val_out <= `ZeroWord ;
            end else if (memctrl_busy_in[1] == `True_v ) begin
                read_req_out <= `False_v;
                write_req_out <= `False_v ;
                mem_addr_out <= `ZeroWord ;
                mem_val_out <= `ZeroWord ;
                rd_out <= `False_v ;
                rd_addr_out <= `ZeroWord;
                rd_val_out <= `ZeroWord ;
            end
        end else begin
            read_req_out <= `False_v;
            write_req_out <= `False_v ;
            mem_addr_out <= `ZeroWord ;
            mem_val_out <= `ZeroWord ;
            rd_out <= rd_in;
            rd_addr_out <= rd_addr_in;
            rd_val_out <= rd_val_in;
            stall_req_from_mem <= `False_v ;
        end
    end

endmodule : mem