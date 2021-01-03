`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/06 22:37:20
// Design Name: 
// Module Name: timer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module timer
#(
  parameter ADDR_WIDTH = 17,
  parameter TIMER_CMP_W = 15'b100000000000000,
  parameter TIMER_CMP = 2'b01, 
  parameter MTIMER_CMP = 8'h32
)
(
    input clk,
    input rst,
    input en_in,
    input r_nw_in,
    input  wire  [ADDR_WIDTH-1:0] a_in,     // memory address
    input  wire  [ 7:0]           d_in,     // data input
    output wire timer_interrupt,
    output wire [7:0] timer_cmp_dout
);

wire write_en_w;
wire [1:0] write_pos;

assign write_en_w = (a_in[3:2] == TIMER_CMP) ? 1 : 0;
assign write_pos = a_in[1:0];
reg [7:0]  timer_cmp[3:0];
reg [31:0] ttimer;
wire[31:0] timer_cmp_wire = {timer_cmp[3], timer_cmp[2], timer_cmp[1], timer_cmp[0]};

wire [7:0] ttimer_slice[3:0];
assign ttimer_slice[0] = ttimer[7:0];
assign ttimer_slice[1] = ttimer[15:8];
assign ttimer_slice[2] = ttimer[23:16];
assign ttimer_slice[3] = ttimer[31:24];

always @(posedge clk or posedge rst)
    if (rst)
        ttimer <= 0;
    else 
        if (~en_in)
            ttimer <= ttimer + 32'b1;

reg[1:0] q_write_pos;

always @ (posedge clk) begin
    if (rst) begin
        q_write_pos <= 0;
        timer_cmp[0] <= 0;
        timer_cmp[1] <= 0;
        timer_cmp[2] <= 0;
        timer_cmp[3] <= 0;
    end else if (en_in & write_en_w) begin
        timer_cmp[write_pos] <= d_in;
    end else if (en_in)
        q_write_pos <= write_pos;
end
       
//always @(clk) begin
assign    timer_cmp_dout = ttimer_slice[q_write_pos];
//end        


assign timer_interrupt = (~write_en_w && (timer_cmp_wire <= ttimer));

endmodule
