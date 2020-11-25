`include "defines.v"

module mem_ctrl(
    input   wire        clk_in,
    input   wire        rst_in,
    input   wire        rdy_in,

    // from if
    input   wire                if_req_in,
    input   wire[`InstAddrBus]  inst_addr_in,

    // to if
    output  reg                 inst_done,
    output  reg [`RegBus]       inst_out,

    // from mem
    input   wire                read_req_in,
    input   wire                write_req_in,
    input   wire[`InstAddrBus]  mem_addr_in,
    input   wire[`RegBus ]      mem_val_in,
    input   wire[2:0]           store_len,

    // to mem
    output  reg                 mem_done,
    output  reg[`RegBus]        mem_val_read_out,

    // to ram
    output  reg                 rw_req_out,
    output  reg [`InstAddrBus]  mem_addr_out,
    output  reg [`RamBus]       mem_val_out,

    //from ram
    input   wire[`RamBus]       mem_val_read_in,

    //
    output  reg[1:0]                 busy //busy[1] stands for if, busy[0] stands for mem.
);

    reg[2:0]        cnt;
    reg[31:0]       val_out;

    always @ (negedge clk_in) begin
        if (rst_in == `RstEnable ) begin
            rw_req_out <= 1'b0;
            mem_addr_out <= `ZeroWord ;
            mem_val_out <= 8'b0;
            mem_val_read_out <= `ZeroWord ;
            inst_out <= `ZeroWord ;
            inst_done <= `False_v ;
            mem_done <= `False_v ;
            busy <= 2'b0;
            cnt <= 1'b0;
            val_out <= `ZeroWord ;
        end else if (if_req_in == `True_v) begin
            rw_req_out <= 1'b0;
            mem_addr_out <= inst_addr_in + cnt;
            mem_val_out <= 8'b0;
            mem_val_read_out <= `ZeroWord ;
            busy <= 2'b10;
            inst_done <= 1'b0;
            mem_done <= 1'b0;
            case (cnt)
                3'b001: val_out[7:0] <= mem_val_read_in;
                3'b010: val_out[15:8] <= mem_val_read_in;
                3'b011: val_out[23:16] <= mem_val_read_in;
                3'b100: val_out[31:24] <= mem_val_read_in;
            endcase
            if (cnt == 3'b100) begin
                val_out[31:24] = mem_val_read_in;
                inst_out <= val_out;
                cnt <= 3'b000;
                busy <= 2'b00;
                inst_done <= 1'b1;
            end else begin
                cnt <= cnt + 3'b001;
            end
        end else if (read_req_in == `True_v ) begin
            rw_req_out <= 1'b0;
            mem_addr_out <= mem_addr_in + cnt;
            inst_out <= `ZeroWord ;
            mem_val_out <= 8'b0;
            busy <= 2'b01;
            inst_done <= 1'b0;
            mem_done <= 1'b0;
            case (cnt)
                3'b001: val_out[7:0] <= mem_val_read_in;
                3'b010: val_out[15:8] <= mem_val_read_in;
                3'b011: val_out[23:16] <= mem_val_read_in;
                3'b100: val_out[31:24] <= mem_val_read_in;
            endcase
            if (cnt == 3'b100) begin
                val_out[31:24] = mem_val_read_in;
                mem_val_read_out <= val_out;
                cnt <= 2'b00;
                busy <= 2'b00;
                mem_done <= 1'b1;
            end else begin
                cnt <= cnt + 2'b01;
            end
        end else if (write_req_in == `True_v ) begin
            rw_req_out <= 1'b1;
            mem_addr_out <= mem_addr_in + cnt;
            inst_out <= `ZeroWord ;
            mem_val_read_out <= `ZeroWord ;
            busy <= 2'b01;
            inst_done <= 1'b0;
            mem_done <= 1'b0;
            case (cnt)
                3'b000: mem_val_out <= mem_val_in[7:0];
                3'b001: mem_val_out <= mem_val_in[15:8];
                3'b010: mem_val_out <= mem_val_in[23:16];
                3'b011: mem_val_out <= mem_val_in[32:24];
            endcase
            if (cnt == store_len) begin
                cnt <= 2'b00;
                busy <= 2'b00;
                mem_done <= 1'b1;
            end else begin
                cnt <= cnt + 2'b01;
            end
        end else begin
            inst_done <= `False_v ;
            mem_done <= `False_v ;
        end
    end


endmodule : mem_ctrl