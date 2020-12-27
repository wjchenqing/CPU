`include "defines.v"

module pc_reg(
    input   wire        clk_in,
    input   wire        rst_in,
    input   wire        rdy_in,
    input   wire[5:0]   stall,

    input   wire                branch_flag_in,
    input   wire[`InstAddrBus ]   branch_target_addr_in,
    input   wire[`InstAddrBus ] branch_pc_in,
    input   wire                branch_taken,
    input   wire                is_jalr,

    output  reg[`InstAddrBus]   pc_out,
    output  wire                incorrect,
    output  reg                 pre_to_take
);

    reg[`InstBus]       btb_target[`BTBNum - 1 : 0];
    reg[`BTBTagBus ]    btb_tag[`BTBNum - 1 : 0];
    reg[`InstAddrBus]   next_pc;

    assign incorrect = (branch_flag_in == `Branch) | ((is_jalr == `True_v) & (btb_target[branch_pc_in[`BTBAddrRange]] != branch_target_addr_in));

    reg [5:0] i;
    initial begin
        for (i = 0; i < `BTBNum ; i=i+1) begin
            btb_target[i] <= `ZeroWord ;
            btb_tag[i] <= -1;
        end
    end

    always @ (posedge clk_in) begin
        if (rst_in == `RstEnable) begin
            pc_out <= `ZeroWord;
            pre_to_take <= `False_v;
            next_pc <= 4'h4;
        end else if (branch_flag_in == `Branch ) begin
            pc_out <= branch_target_addr_in;
            if (btb_tag[branch_target_addr_in[`BTBAddrRange]] == branch_target_addr_in[`BTBTagRange]) begin
                next_pc = btb_target[branch_target_addr_in[`BTBAddrRange]];
                pre_to_take = `True_v;
            end else begin
                next_pc = branch_target_addr_in + 4'h4;
                pre_to_take = `False_v; 
            end
            if (branch_taken == `True_v || is_jalr == `True_v) begin
                btb_tag[branch_pc_in[`BTBAddrRange]] = branch_pc_in[`BTBTagRange];
                btb_target[branch_pc_in[`BTBAddrRange]] = branch_target_addr_in;
            end else begin
                btb_tag[branch_pc_in[`BTBAddrRange]] = -1;
                btb_target[branch_pc_in[`BTBAddrRange]] = `ZeroWord;
            end
        end else if ((stall[0] == `NotStop)
            && (btb_tag[next_pc[`BTBAddrRange]] == next_pc[`BTBTagRange])) begin
            next_pc <= btb_target[next_pc[`BTBAddrRange]];
            pc_out <= next_pc;
            pre_to_take <= `True_v;
        end else if (stall[0] == `NotStop) begin
            pc_out <= next_pc;
            next_pc <= next_pc+4'h4;
            pre_to_take <= `False_v;
        end
    end

endmodule : pc_reg