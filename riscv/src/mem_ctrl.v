`include "defines.v"

module mem_ctrl(
    input   wire        clk_in,
    input   wire        rst_in,
    input   wire        rdy_in,

    // from if
    input   wire                if_req_in,
    input   wire[`InstAddrBus]  inst_addr_in,

    // to if
    output  wire                inst_done,
    output  wire[`RegBus]       inst_out,

    // from mem
    input   wire                read_req_in,
    input   wire                write_req_in,
    input   wire[`InstAddrBus]  mem_addr_in,
    input   wire[`RegBus ]      mem_val_in,

    // to mem
    output  wire                mem_done,
    output  wire[`RegBus]       mem_val_read_out,

    // to ram
    output  wire                rw_req_out,
    output  wire[`InstAddrBus]  mem_addr_out,
    output  wire[`RamBus]       mem_val_out,

    //from ram
    input   wire[`RamBus]       mem_val_read_in,

    //
    output  reg[1:0]                 busy, //busy[1] stands for if, busy[0] stands for mem.
);

    reg[1:0]        cnt;
    reg[31:0]       val_out;

    always @ (negedge clk_in) begin
        if (rst_in == `RstEnable ) begin
            rw_req_out <= 1'b0;
            mem_addr_out <= `ZeroWord ;
            mem_val_out <= 8'b0;
            mem_val_read_out <= 8'b0;
            inst_out <= `ZeroWord ;
        end else if (if_req_in == `True_v) begin
            rw_req_out <= 1'b1;
            mem_addr_out <= mem_addr_in;
            mem_val_out <= 8'b0;
            mem_val_read_out <= `ZeroWord ;
            busy <= 2'b10;
            inst_done <= 1'b0;
            mem_done <= 1'b0;
            case (cnt)
                2'b00: val_out[7:0] <= mem_val_read_in;
                2'b01: val_out[15:8] <= mem_val_read_in;
                2'b10: val_out[23:16] <= mem_val_read_in;
                2'b11: val_out[31:24] <= mem_val_read_in;
            endcase
            if (cnt == 2'b11) begin
                inst_out <= val_out;
                cnt <= 2'b00;
                busy <= 2'b00;
                inst_done <= 1'b1;
            end else begin
                cnt <= cnt + 2'b01;
            end
        end else if (read_req_in == `True_v ) begin
            rw_req_out <= 1'b1;
            mem_addr_out <= mem_addr_in;
            inst_out <= `ZeroWord ;
            mem_val_out <= 8'b0;
            busy <= 2'b01;
            inst_done <= 1'b0;
            mem_done <= 1'b0;
            case (cnt)
                2'b00: val_out[7:0] <= mem_val_read_in;
                2'b01: val_out[15:8] <= mem_val_read_in;
                2'b10: val_out[23:16] <= mem_val_read_in;
                2'b11: val_out[31:24] <= mem_val_read_in;
            endcase
            if (cnt == 2'b11) begin
                mem_val_read_out <= val_out;
                cnt <= 2'b00;
                busy <= 2'b00;
                mem_done <= 1'b1;
            end else begin
                cnt <= cnt + 2'b01;
            end
        end else if (write_req_in == `True_v ) begin
            rw_req_out <= 1'b0;
            mem_addr_out <= mem_addr_in;
            inst_out <= `ZeroWord ;
            mem_val_read_out <= `ZeroWord ;
            busy <= 2'b01;
            inst_done <= 1'b0;
            mem_done <= 1'b0;
            case (cnt)
                2'b00: mem_val_out <= mem_val_in[7:0];
                2'b01: mem_val_out <= mem_val_in[15:8];
                2'b10: mem_val_out <= mem_val_in[23:16];
                2'b11: mem_val_out <= mem_val_in[32:24];
            endcase
            if (cnt == 2'b11) begin
                cnt <= 2'b00;
                busy <= 2'b00;
                mem_done <= 1'b1;
            end else begin
                cnt <= cnt + 2'b01;
            end
        end
    end


endmodule : mem_ctrl