`include "defines.v"

module If(
    input   wire        clk_in,
    input   wire        rst_in,
    input   wire        rdy,

    input   wire[`InstAddrBus]        pc,

    input   wire                pre_to_take_in,

    output  reg                 pre_to_take_out,

    output  reg                if_req_out,
    output  reg[`InstAddrBus]  inst_addr_out,

    input   wire[`InstBus]      inst_in,
    input   wire[1:0]           busy_in,
    input   wire                inst_done_in,

    input   wire                branch_flag_in,
    input   wire[`InstAddrBus]                branch_target_addr_in,

    output  reg                stall_req_from_if,

    output  reg[`InstAddrBus ] if_pc_out,
    output  reg[`InstBus ]     if_inst_out
);

    reg[`InstBus ]          cache_data[`ICacheNum - 1 : 0];
    reg[`TagBus ]           cache_tag [`ICacheNum - 1 : 0];
    reg[`ICacheNum - 1 : 0] cache_valid;

    reg                 cache_done;
    reg[`InstBus]       cache_inst;

    always @ (*) begin
        if (rst_in == `RstEnable ) begin
            if_req_out <= `False_v ;
            inst_addr_out <= `ZeroWord ;
            stall_req_from_if <= `NotStop ;
            cache_done <= `False_v ;
            cache_inst <= `ZeroWord ;
        end else if (cache_valid[pc[`CacheAddrRange]] && cache_tag[pc[`CacheAddrRange]] == pc[`TagRange]) begin
            if_req_out <= `False_v ;
            inst_addr_out <= `ZeroWord ;
            stall_req_from_if <= `NotStop ;
            cache_done <= `True_v  ;
            cache_inst <= cache_data[pc[`CacheAddrRange]];
        end else if (inst_done_in == 1'b1) begin
            if_req_out <= 1'b0;
            inst_addr_out <= `ZeroWord ;
            stall_req_from_if <= `NotStop ;
            cache_done <= `True_v  ;
            cache_inst <= inst_in;
        end else if (busy_in[0] == `True_v ) begin
            if_req_out <= 1'b0;
            inst_addr_out <= pc ;
            stall_req_from_if <= `Stop ;
            cache_done <= `False_v ;
            cache_inst <= `ZeroWord ;
        end else if ((busy_in == 2'b10) || (busy_in == 2'b0)) begin
            if_req_out <= `True_v ;
            inst_addr_out <= pc;
            stall_req_from_if <= `Stop ;
            cache_done <= `False_v ;
            cache_inst <= `ZeroWord ;
        end else begin
            if_req_out <= `False_v ;
            inst_addr_out <= `ZeroWord ;
            stall_req_from_if <= `NotStop ;
            cache_done <= `False_v ;
            cache_inst <= `ZeroWord ;
        end
    end

    always @ (*) begin
        if (rst_in == `RstEnable) begin
            if_pc_out <= `ZeroWord ;
            if_inst_out <= `ZeroWord ;
            pre_to_take_out <= `False_v;
        end else if (branch_flag_in == `True_v  || cache_done == `False_v ) begin
            if_pc_out <= `ZeroWord ;
            if_inst_out <= `ZeroWord ;
            pre_to_take_out <= `False_v;
        end else if (cache_done == `True_v) begin
            if_pc_out <= pc;
            if_inst_out <= cache_inst;
            pre_to_take_out <= pre_to_take_in;
        end else begin
            if_pc_out <= `ZeroWord ;
            if_inst_out <= `ZeroWord ;
            pre_to_take_out <= `False_v;
        end
    end

    always @ (posedge clk_in) begin
        // if (rdy && (rst_in == `RstDisable) && (cache_done == `True_v )) begin
        /*
        if ((rst_in == `RstDisable) && (cache_done == `True_v )) begin
            cache_tag[pc[`CacheAddrRange]] <= pc[`TagRange];
            cache_data[pc[`CacheAddrRange]] <= cache_inst;
        end
         */
        if (rst_in == `RstEnable) begin
            cache_valid <= 0;
        end else if (cache_done == `True_v) begin
            cache_tag[pc[`CacheAddrRange]] <= pc[`TagRange];
            cache_data[pc[`CacheAddrRange]] <= cache_inst;
            cache_valid[pc[`CacheAddrRange]] <= 1;
        end
    end
endmodule : If
