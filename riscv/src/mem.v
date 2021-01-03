`include "defines.v"

module mem(
    input   wire        rst_in,
    input   wire        clk_in,
    input   wire        rdy,

    //from mem_ctrl.
    input   wire                mem_done_in,
    input   wire[`RegBus ]      mem_val_read_in,
    input   wire[1:0]           memctrl_busy_in,

    //to mem_ctrl
    output  reg                 read_req_out,
    output  reg                 write_req_out,
    output  reg[`InstAddrBus]   mem_addr_out,
    output  reg[`RegBus ]       mem_val_out,
    output  reg[2:0]            store_len,

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
    output  reg                 stall_req_from_mem
);

    reg [`RegBus]   cache_data[`DCacheNum - 1 : 0];
    reg [`DTagBus]  cache_tag [`DCacheNum - 1 : 0];
    reg[`DCacheNum - 1 : 0] cache_valid;

    reg [`RegBus]       cache_val;
    reg [`InstAddrBus]  cache_addr;
    reg                 cache_done;
    reg                 cache_changed;

    wire [7:0]          cache_index;
    assign cache_index = mem_addr_in[`DCacheAddrRange];
    wire [`DTagBus]     addr_tag;
    assign addr_tag = mem_addr_in[`DTagRange];
    wire [`DTagBus]     cache_tag_indexed;
    assign cache_tag_indexed = cache_tag[cache_index];
    wire                valid;
    assign valid = cache_valid[cache_index];
    wire [`RegBus]      val;
    assign val = cache_data[cache_index];

    always @ (*) begin
        if (rst_in == `RstEnable) begin
            read_req_out <= `False_v;
            write_req_out <= `False_v ;
            mem_addr_out <= `ZeroWord ;
            mem_val_out <= `ZeroWord ;
            stall_req_from_mem <= `False_v ;
            store_len <= 2'b0;
            cache_done <= `False_v;
            cache_changed <= `False_v;
            cache_addr <= `ZeroWord;
            cache_val <= `ZeroWord;
        end else if (load_in == `True_v) begin
            if (valid && cache_tag_indexed == addr_tag) begin
                cache_done <= `True_v;
                cache_changed <= `False_v;
                cache_addr <= mem_addr_in;
                cache_val <= `ZeroWord;
                case (inst_type_in)
                    `LW : cache_val <= val;
                    `LH : begin
                        case (mem_addr_in[1:0])
                            2'b00:   cache_val <= {16'b0,val[15:0]};
                            2'b10:   cache_val <= {16'b0,val[31:16]};
                        endcase
                    end
                    `LHU: begin
                        case (mem_addr_in[1:0])
                            2'b00:   cache_val <= {16'b0,val[15:0]};
                            2'b10:   cache_val <= {16'b0,val[31:16]};
                        endcase
                    end
                    `LB : begin
                        case (mem_addr_in[1:0])
                            2'b00:   cache_val <= {24'b0,val[7:0]};
                            2'b01:   cache_val <= {24'b0,val[15:8]};
                            2'b10:   cache_val <= {24'b0,val[23:16]};
                            2'b11:   cache_val <= {24'b0,val[31:24]};
                        endcase
                    end
                    `LBU: begin
                        case (mem_addr_in[1:0])
                            2'b00:   cache_val <= {24'b0,val[7:0]};
                            2'b01:   cache_val <= {24'b0,val[15:8]};
                            2'b10:   cache_val <= {24'b0,val[23:16]};
                            2'b11:   cache_val <= {24'b0,val[31:24]};
                        endcase
                    end
                endcase
                read_req_out <= `False_v;
                write_req_out <= `False_v ;
                mem_addr_out <= `ZeroWord ;
                mem_val_out <= `ZeroWord ;
                stall_req_from_mem <= `False_v ;
                store_len <= 2'b0;
            end else if (mem_done_in == `True_v) begin
                read_req_out <= `False_v;
                write_req_out <= `False_v ;
                mem_addr_out <= `ZeroWord ;
                mem_val_out <= `ZeroWord ;
                stall_req_from_mem <= `False_v ;
                store_len <= 2'b0;
                cache_done <= `True_v;
                if(inst_type_in == `LW) begin
                    cache_changed <= `True_v;
                end else begin
                    cache_changed <= `False_v;
                end
                cache_addr <= mem_addr_in;
                cache_val <= mem_val_read_in;
            end else begin
                read_req_out <= `False_v;
                write_req_out <= `False_v ;
                mem_addr_out <= `ZeroWord ;
                mem_val_out <= `ZeroWord ;
                stall_req_from_mem <= `True_v ;
                store_len <= 3'b100;
                cache_done <= `False_v;
                cache_changed <= `False_v;
                cache_addr <= `ZeroWord;
                cache_val <= `ZeroWord;
                case (inst_type_in)
                    `LW : store_len <= 3'b100;
                    `LH : store_len <= 3'b010;
                    `LHU :store_len <= 3'b010;
                    `LB : store_len <= 3'b001;
                    `LBU :store_len <= 3'b001;
                endcase
                if (memctrl_busy_in == 2'b01 || memctrl_busy_in == 2'b0) begin
                    read_req_out <= `True_v ;
                    write_req_out <= `False_v ;
                    mem_addr_out <= mem_addr_in;
                    mem_val_out <= `ZeroWord ;
                end else if (memctrl_busy_in[1] == `True_v ) begin
                    read_req_out <= `False_v;
                    write_req_out <= `False_v ;
                    mem_addr_out <= `ZeroWord ;
                    mem_val_out <= `ZeroWord ;
                end
            end
        end else if (store_in == `True_v) begin
            if (mem_done_in == `True_v) begin
                read_req_out <= `False_v;
                write_req_out <= `False_v ;
                mem_addr_out <= `ZeroWord ;
                mem_val_out <= `ZeroWord ;
                stall_req_from_mem <= `False_v ;
                store_len <= 2'b0;
                cache_done <= `True_v;
                if(inst_type_in == `SW) begin
                    cache_changed <= `True_v;
                end else begin
                    cache_changed <= `False_v;
                end
                cache_addr <= mem_addr_in;
                cache_val <= mem_val_in;
            end else begin
                read_req_out <= `False_v;
                write_req_out <= `False_v ;
                mem_addr_out <= `ZeroWord ;
                mem_val_out <= `ZeroWord ;
                stall_req_from_mem <= `True_v ;
                store_len <= 2'b0;
                cache_done <= `False_v;
                cache_changed <= `False_v;
                cache_addr <= `ZeroWord;
                cache_val <= `ZeroWord;
                if (memctrl_busy_in == 2'b01 || memctrl_busy_in == 2'b0) begin
                    read_req_out <= `False_v ;
                    write_req_out <= `True_v ;
                    mem_addr_out <= mem_addr_in;
                    mem_val_out <= mem_val_in;
                    case (inst_type_in)
                        `SW : store_len <= 3'b011;
                        `SH : store_len <= 3'b001;
                        `SB : store_len <= 3'b000;
                    endcase
                end else if (memctrl_busy_in[1] == `True_v ) begin
                    read_req_out <= `False_v;
                    write_req_out <= `False_v ;
                    mem_addr_out <= `ZeroWord ;
                    mem_val_out <= `ZeroWord ;
                    case (inst_type_in)
                        `SW : store_len <= 3'b011;
                        `SH : store_len <= 3'b001;
                        `SB : store_len <= 3'b000;
                    endcase
                end
            end
        end else begin
            read_req_out <= `False_v;
            write_req_out <= `False_v ;
            mem_addr_out <= `ZeroWord ;
            mem_val_out <= `ZeroWord ;
            stall_req_from_mem <= `False_v ;
            store_len <= 2'b0;
            cache_done <= `False_v;
            cache_changed <= `False_v;
            cache_addr <= `ZeroWord;
            cache_val <= `ZeroWord;
        end
    end

    always @ (*) begin
        if (rst_in == `RstEnable) begin
            rd_out <= `WriteDisable;
            rd_val_out <= `ZeroWord;
            rd_addr_out <= `NOPRegAdder;
        end else if (cache_done == `True_v) begin
            rd_out <= rd_in ;
            rd_addr_out <= rd_addr_in;
            rd_val_out <= `ZeroWord;
            case (inst_type_in)
                `LW : rd_val_out <= cache_val;
                `LH : rd_val_out <= {{16{cache_val[15]}},cache_val[15:0]};
                `LHU :rd_val_out <= {16'b0,cache_val[15:0]};
                `LB : rd_val_out <= {{24{cache_val[7]}},cache_val[7:0]};
                `LBU :rd_val_out <= {24'b0,cache_val[7:0]};
            endcase
        end else if (load_in == `True_v || store_in == `True_v) begin
            rd_out <= `WriteDisable;
            rd_val_out <= `ZeroWord;
            rd_addr_out <= `NOPRegAdder;
        end else begin
            rd_out <= rd_in;
            rd_addr_out <= rd_addr_in;
            rd_val_out <= rd_val_in;
        end
    end

    always @ (posedge clk_in) begin
        if (rst_in == `RstEnable) begin
            cache_valid <= 0;
        end else if (cache_changed == `True_v) begin
            cache_tag[cache_addr[`CacheAddrRange]] <= cache_addr[`TagRange];
            cache_data[cache_addr[`CacheAddrRange]] <= cache_val;
            cache_valid[cache_addr[`CacheAddrRange]] <= 1;
        end
    end

endmodule : mem
