`include "defines.v"

module pc_reg(
    input   wire        clk_in,
    input   wire        rst_in,
    input   wire        rdy_in,
    input   wire[5:0]   stall,

    input   wire                branch_flag_in,
    input   wire[`InstAddrBus ]   branch_target_addr_in,
    input   wire[`InstAddrBus ] branch_pc_in,

    output  reg[`InstAddrBus]   pc_out,
    output  wire                 incorrect
);

    reg[`InstBus]       btb_target[`BTBNum - 1 : 0];
    reg[`BTBTagBus ]    btb_tag[`BTBNum - 1 : 0];
    reg[1:0]            btb_predictor[`BTBNum - 1 : 0];

    assign incorrect = (branch_flag_in == `Branch)
        & !((((btb_predictor[branch_pc_in[`BTBAddrRange]][1]==`False_v) | btb_tag[branch_pc_in[`BTBAddrRange]] != branch_pc_in[`BTBTagRange])
        & (branch_target_addr_in == (branch_pc_in + `PCstep)))
        |((btb_tag[branch_pc_in[`BTBAddrRange]] == branch_pc_in[`BTBTagRange])
        & (btb_target[branch_pc_in[`BTBAddrRange]] == branch_pc_in)
        & (btb_predictor[branch_pc_in[`BTBAddrRange]][1]==`True_v )));

    reg [5:0] i;
    initial begin
        for (i = 0; i < `BTBNum ; i=i+1) begin
            btb_target[i] <= `ZeroWord ;
            btb_tag[i] <= -1;
            btb_predictor[i] <= 0;
        end
    end

    always @ (posedge clk_in) begin
        if (rst_in == `RstEnable) begin
            pc_out <= `ZeroWord;
        end else if (branch_flag_in == `Branch ) begin
            if (incorrect == `False_v ) begin
                btb_tag[branch_pc_in[`BTBAddrRange]] <= branch_pc_in[`BTBTagRange];
                btb_target[branch_pc_in[`BTBAddrRange]] <= branch_target_addr_in;
                btb_predictor[branch_pc_in[`BTBAddrRange]]
                    <= (btb_predictor[branch_pc_in[`BTBAddrRange]] == 2'b11
                        ? 2'b11
                        : btb_predictor[branch_pc_in[`BTBAddrRange]] + 2'b01);
                if (stall[0] == `NotStop) begin
                    pc_out <= pc_out + 4'h4;
                end
            end else begin
                btb_tag[branch_pc_in[`BTBAddrRange]] <= branch_pc_in[`BTBTagRange];
                btb_target[branch_pc_in[`BTBAddrRange]] <= branch_target_addr_in;
                btb_predictor[branch_pc_in[`BTBAddrRange]]
                    <= (btb_predictor[branch_pc_in[`BTBAddrRange]] == 2'b00
                    ? 2'b00
                    : btb_predictor[branch_pc_in[`BTBAddrRange]] - 2'b01);
                pc_out <= branch_target_addr_in;
            end
        end else if ((stall[0] == `NotStop)
            && (btb_tag[pc_out[`BTBAddrRange]] == pc_out[`BTBTagRange])
            && (btb_predictor[pc_out[`BTBAddrRange]][1]==`True_v )) begin
            pc_out <= btb_target[pc_out[`BTBAddrRange]];
        end else if (stall[0] == `NotStop) begin
            pc_out <= pc_out + 4'h4;
        end
    end

endmodule : pc_reg