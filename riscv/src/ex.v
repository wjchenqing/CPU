`include "defines.v"

module ex(
    input   wire                rst_in,

    input   wire[`RegBus]       rs1_val_in,
    input   wire[`RegBus]       rs2_val_in,
    input   wire                rd_in,
    input   wire[`RegAddrBus]   rd_addr_in,
    input   wire[`InstTypeBus]  inst_type_in,
    input   wire[`RegBus]       imm_in,
    input   wire[`InstAddrBus]  pc_in,
    input   wire                is_loading_in,

    input   wire                pre_to_take,

    input   wire[`RegBus ]      rd_val_from_mem,

    output  reg                 rd_out,
    output  reg[`RegBus]        rd_val_out,
    output  reg[`RegAddrBus]    rd_addr_out,
    output  reg[`InstTypeBus]   inst_type_out,

    output  reg                 load_out,
    output  reg                 store_out,
    output  reg[`InstAddrBus]   mem_addr_out,
    output  reg[`RegBus]        mem_val_out,

    output  reg                 branch_taken,
    output  reg                 branch_flag_out,
    output  reg[`InstAddrBus  ]   branch_target_addr_out,
    output  reg[`InstAddrBus ]  branch_pc_out,
    output  reg                 is_jalr,

    output  reg                stallreq_from_ex,

    output  reg                ex_is_loading_out
);

    always @ (*) begin
        if (rst_in == `RstEnable) begin
            rd_out <= `WriteDisable;
            rd_val_out <= `ZeroWord;
            rd_addr_out <= `NOPRegAdder;
            inst_type_out <= `NOPInstType;
            load_out <= `ReadDisable ;
            store_out <= `WriteDisable ;
            mem_addr_out <= `ZeroWord;
            mem_val_out <= `ZeroWord;
            branch_flag_out <= `NotBranch ;
            branch_target_addr_out <= `ZeroWord ;
            ex_is_loading_out <= 1'b0;
            stallreq_from_ex <= `NotStop ;
            branch_pc_out <= `ZeroWord ;
            branch_taken <= `False_v;
        end else begin
            ex_is_loading_out <= is_loading_in;
            rd_out <= rd_in;
            rd_val_out <= `ZeroWord;
            rd_addr_out <= rd_addr_in;
            inst_type_out <= inst_type_in;
            load_out <= `ReadDisable ;
            store_out <= `WriteDisable ;
            mem_addr_out <= `ZeroWord ;
            mem_val_out <= `ZeroWord ;
            branch_flag_out <= `NotBranch ;
            branch_target_addr_out <= `ZeroWord ;
            stallreq_from_ex <= `NotStop ;
            branch_pc_out <= pc_in ;
            branch_taken <= `False_v;
            is_jalr <= `False_v;
            case (inst_type_in)
                `ADDI: rd_val_out <= imm_in + rs1_val_in;
                `SLTI: begin
                    if ($signed(rs1_val_in) < $signed(imm_in)) begin
                        rd_val_out <= 1'b1;
                    end else begin
                        rd_val_out <= 1'b0;
                    end
                end
                `SLTIU: begin
                    if (rs1_val_in < imm_in) begin
                        rd_val_out <= 1'b1;
                    end else begin
                        rd_val_out <= 1'b0;
                    end
                end
                `XORI: rd_val_out <= rs1_val_in ^ imm_in;
                `ORI: rd_val_out <= rs1_val_in | imm_in;
                `ANDI: rd_val_out <= rs1_val_in & imm_in;
                `SLLI: rd_val_out <= rs1_val_in << imm_in[4:0];
                `SRLI: rd_val_out <= rs1_val_in >> imm_in[4:0];
                `SRAI: rd_val_out <= rs1_val_in >>> imm_in[4:0];
                `ADD: rd_val_out <= rs1_val_in + rs2_val_in;
                `SUB: rd_val_out <= rs1_val_in - rs2_val_in;
                `SLT: begin
                    if ($signed(rs1_val_in) < $signed(rs2_val_in)) begin
                        rd_val_out <= 1'b1;
                    end else begin
                        rd_val_out <= 1'b0;
                    end
                end
                `SLTU: begin
                    if (rs1_val_in < rs2_val_in) begin
                        rd_val_out <= 1'b1;
                    end else begin
                        rd_val_out <= 1'b0;
                    end
                end
                `XOR: rd_val_out <= rs1_val_in ^ rs2_val_in;
                `OR: rd_val_out <= rs1_val_in | rs2_val_in;
                `AND: rd_val_out <= rs1_val_in & rs2_val_in;
                `SLL: rd_val_out <= rs1_val_in << rs2_val_in[4:0];
                `SRL: rd_val_out <= rs1_val_in >> rs2_val_in[4:0];
                `SRA: rd_val_out <= rs1_val_in >>> rs2_val_in[4:0];
                `LUI: rd_val_out <= imm_in;
                `AUIPC: rd_val_out <= imm_in + pc_in;
                `JAL: begin
                    branch_taken <= `True_v;
                    if (pre_to_take) begin
                        branch_flag_out <= `NotBranch;
                        branch_target_addr_out <= `ZeroWord;
                        rd_val_out <= pc_in + `PCstep;
                        branch_pc_out <= pc_in;
                    end else begin
                        branch_flag_out <= `Branch ;
                        branch_target_addr_out <= pc_in + imm_in;
                        rd_val_out <= pc_in + `PCstep ;
                        branch_pc_out <= pc_in;
                    end
                end
                `JALR: begin
                    branch_taken <= `True_v;
                    is_jalr <= `True_v;
                    if (pre_to_take) begin
                        branch_flag_out <= `Branch;
                        branch_target_addr_out <= (rs1_val_in + imm_in) & 32'hFFFFFFFE;
                        rd_val_out <= pc_in + `PCstep;
                        branch_pc_out <= pc_in;
                    end else begin
                        branch_flag_out <= `Branch ;
                        branch_target_addr_out <= (rs1_val_in + imm_in) & 32'hFFFFFFFE;
                        rd_val_out <= pc_in + `PCstep ;
                        branch_pc_out <= pc_in;
                    end
                end
                `BEQ: begin
                    rd_val_out <= `ZeroWord ;
                    if (rs1_val_in == rs2_val_in) begin
                        branch_taken <= `True_v;
                        if (pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + imm_in;
                            branch_pc_out <= pc_in;
                        end
                    end else begin
                        branch_taken <= `False_v;
                        if (!pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + 4'h4 ;
                            branch_pc_out <= pc_in;
                        end
                    end
                end
                `BNE: begin
                    rd_val_out <= `ZeroWord ;
                    if (rs1_val_in != rs2_val_in) begin
                        branch_taken <= `True_v;
                        if (pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + imm_in;
                            branch_pc_out <= pc_in;
                        end
                    end else begin
                        branch_taken <= `False_v;
                        if (!pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + 4'h4 ;
                            branch_pc_out <= pc_in;
                        end
                    end
                end
                `BLT: begin
                    rd_val_out <= `ZeroWord ;
                    if ($signed(rs1_val_in) < $signed(rs2_val_in)) begin
                        branch_taken <= `True_v;
                        if (pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + imm_in;
                            branch_pc_out <= pc_in;
                        end
                    end else begin
                        branch_taken <= `False_v;
                        if (!pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + 4'h4 ;
                            branch_pc_out <= pc_in;
                        end
                    end
                end
                `BGE: begin
                    rd_val_out <= `ZeroWord ;
                    if ($signed(rs1_val_in) >= $signed(rs2_val_in)) begin
                        branch_taken <= `True_v;
                        if (pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + imm_in;
                            branch_pc_out <= pc_in;
                        end
                    end else begin
                        branch_taken <= `False_v;
                        if (!pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + 4'h4 ;
                            branch_pc_out <= pc_in;
                        end
                    end
                end
                `BLTU: begin
                    rd_val_out <= `ZeroWord ;
                    if (rs1_val_in < rs2_val_in) begin
                        branch_taken <= `True_v;
                        if (pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + imm_in;
                            branch_pc_out <= pc_in;
                        end
                    end else begin
                        branch_taken <= `False_v;
                        if (!pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + 4'h4 ;
                            branch_pc_out <= pc_in;
                        end
                    end
                end
                `BGEU: begin
                    rd_val_out <= `ZeroWord ;
                    if (rs1_val_in >= rs2_val_in) begin
                        branch_taken <= `True_v;
                        if (pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + imm_in;
                            branch_pc_out <= pc_in;
                        end
                    end else begin
                        branch_taken <= `False_v;
                        if (!pre_to_take) begin
                            branch_flag_out <= `NotBranch;
                            branch_target_addr_out <= `ZeroWord;
                            branch_pc_out <= pc_in;
                        end else begin
                            branch_flag_out <= `Branch ;
                            branch_target_addr_out <= pc_in + 4'h4 ;
                            branch_pc_out <= pc_in;
                        end
                    end
                end
                `LB: begin
                    rd_val_out <= rd_val_from_mem;
                    load_out <= `ReadEnable ;
                    mem_addr_out <= rs1_val_in + imm_in;
                end
                `LH: begin
                    rd_val_out <= rd_val_from_mem;
                    load_out <= `ReadEnable ;
                    mem_addr_out <= rs1_val_in + imm_in;
                end
                `LW: begin
                    rd_val_out <= rd_val_from_mem;
                    load_out <= `ReadEnable ;
                    mem_addr_out <= rs1_val_in + imm_in;
                end
                `LBU: begin
                    rd_val_out <= rd_val_from_mem;
                    load_out <= `ReadEnable ;
                    mem_addr_out <= rs1_val_in + imm_in;
                end
                `LHU: begin
                    rd_val_out <= rd_val_from_mem;
                    load_out <= `ReadEnable ;
                    mem_addr_out <= rs1_val_in + imm_in;
                end
                `SB : begin
                    store_out <= `WriteEnable ;
                    mem_addr_out <= rs1_val_in + imm_in;
                    mem_val_out <= rs2_val_in;
                end
                `SH : begin
                    store_out <= `WriteEnable ;
                    mem_addr_out <= rs1_val_in + imm_in;
                    mem_val_out <= rs2_val_in;
                end
                `SW : begin
                    store_out <= `WriteEnable ;
                    mem_addr_out <= rs1_val_in + imm_in;
                    mem_val_out <= rs2_val_in;
                end
                default : begin
                    rd_out <= `WriteDisable;
                    rd_val_out <= `ZeroWord;
                    rd_addr_out <= `NOPRegAdder;
                    inst_type_out <= `NOPInstType;
                    load_out <= `ReadDisable ;
                    store_out <= `WriteDisable ;
                    mem_addr_out <= `ZeroWord;
                    mem_val_out <= `ZeroWord;
                    branch_flag_out <= `NotBranch ;
                    branch_target_addr_out <= `ZeroWord ;
                    ex_is_loading_out <= 1'b0;
                    stallreq_from_ex <= `NotStop ;
                end
            endcase
        end

    end

endmodule : ex