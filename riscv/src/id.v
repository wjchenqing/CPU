`include "defines.v"

module id(
    input   wire                rst_in,
    input   wire[`InstAddrBus]  pc_in,
    input   wire[`InstBus]      inst_in,

    //read from regfile.
    input   wire[`RegBus]       rs1_data_in,
    input   wire[`RegBus]       rs2_data_in,

    //write to regfile.
    output  reg                 rs1_read_out,   //whether to read or not
    output  reg                 rs2_read_out,   //whether to read or not
    output  reg[`RegAddrBus]    rs1_addr_out,
    output  reg[`RegAddrBus]    rs2_addr_out,

    //to ex
    output  reg[`RegBus]        rs1_val_out,
    output  reg[`RegBus]        rs2_val_out,
    output  reg                 rd_out,
    output  reg[`RegAddrBus]    rd_addr_out,
    output  reg[`InstTypeBus]   inst_type_out,
    output  reg[`RegBus]        imm_out,
    output  reg[`InstAddrBus]   pc_out
);

    wire [6:0] opcode = inst_in[6 :0 ];
    wire [2:0] func3  = inst_in[14:12];
    wire [6:0] func7  = inst_in[31:25];

    reg[`RegBus]    imm;

    //decode
    always @ (*) begin
        if (rst_in == `RstEnable) begin
            rs1_read_out <= `ReadDisable;
            rs2_read_out <= `ReadDisable;
            rs1_addr_out <= `NOPRegAdder;
            rs2_addr_out <= `NOPRegAdder;
            rs1_val_out <= `ZeroWord;
            rs2_val_out <= `ZeroWord;
            rd_addr_out <= `NOPRegAdder;
            inst_type_out <= `NOPInstType;
            imm_out <= `ZeroWord;
            pc_out <= `ZeroWord;
        end else begin
            case (opcode)
                `opRI: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= `NOPRegAdder;
                    //todo rs1_out <=
                    //todo rs2_out <=
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;

                    case (func3)
                        `f3ADDI: begin
                            inst_type_out <= `ADDI;
                            imm_out <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3SLTI: begin
                            inst_type_out <= `SLTI;
                            imm_out <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3SLTIU: begin
                            inst_type_out <= `SLTIU;
                            imm_out <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3XORI: begin
                            inst_type_out <= `XORI;
                            imm_out <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3ORI: begin
                            inst_type_out <= `ORI;
                            imm_out <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3ANDI: begin
                            inst_type_out <= `ANDI;
                            imm_out <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3SLLI: begin
                            inst_type_out <= `SLLI;
                            imm_out <= {{27'b0},inst_in[24:20]};
                        end
                        `f3SRLI_SRAI: begin
                            if (func7 == `f7SRLI) begin
                                inst_type_out <= `SRLI;
                                imm_out <= {{27'b0},inst_in[24:20]};
                            end else begin
                                inst_type_out <= `SRAI;
                                imm_out <= {{27'b0},inst_in[24:20]};
                            end
                        end
                    endcase
                end
                `opRR: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadEnable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= inst_in[`rs2Range];
                    //todo rs1_out <=
                    //todo rs2_out <=
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm_out <= `ZeroWord;

                    case (func3)
                        `f3ADD_SUB: begin
                            if (func7 == `f7ADD) begin
                                inst_type_out <= `ADD;
                            end else begin
                                inst_type_out <= `SUB;
                            end
                        end
                        `f3SLL: begin
                            inst_type_out <= `SLL;
                        end
                        `f3SLT: begin
                            inst_type_out <= `SLT;
                        end
                        `f3SLTU: begin
                            inst_type_out <= `SLTU;
                        end
                        `f3XOR: begin
                            inst_type_out <= `XOR;
                        end
                        `f3SRL_SRA: begin
                            if (func7 == `f7SRL) begin
                                inst_type_out <= `SRL;
                            end else begin
                                inst_type_out <= `SRA;
                            end
                        end
                        `f3OR: begin
                            inst_type_out <= `OR;
                        end
                        `f3AND: begin
                            inst_type_out <= `AND;
                        end
                    endcase
                end
                `opBranch: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadEnable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= inst_in[`rs2Range];
                    //todo rs1_out <=
                    //todo rs2_out <=
                    rd_out <= `WriteDisable;
                    rd_addr_out <= `NOPRegAdder;
                    pc_out <= pc_in;
                    imm_out <= {{20{inst_in[31]}},inst_in[7],inst_in[30:25],inst_in[11:8],1'b0};

                    case (func3)
                        `f3BEQ: begin
                            inst_type_out <= `BEQ;
                        end
                        `f3BNE: begin
                            inst_type_out <= `BNE;
                        end
                        `f3BLT: begin
                            inst_type_out <= `BNE;
                        end
                        `f3BGE: begin
                            inst_type_out <= `BGE;
                        end
                        `f3BLTU: begin
                            inst_type_out <= `BLTU;
                        end
                        `f3BGEU: begin
                            inst_type_out <= `BGEU;
                        end
                    endcase
                end
                `opLoad: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= `NOPRegAdder;
                    //todo rs1_out <=
                    //todo rs2_out <=
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm_out <= {{20{inst_in[31]}},inst_in[31:20]};

                    case (func3)
                        `f3LB: inst_type_out <= `LB;
                        `f3LH: inst_type_out <= `LH;
                        `f3LW: inst_type_out <= `LW;
                        `f3LBU: inst_type_out <= `LBU;
                        `f3LHU: inst_type_out <= `LHU;
                    endcase
                end
                `opStore: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadEnable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= inst_in[`rs2Range];
                    //todo rs1_out <=
                    //todo rs2_out <=
                    rd_out <= `WriteDisable;
                    rd_addr_out <= `NOPRegAdder;
                    pc_out <= pc_in;
                    imm_out <= {{20{inst_in[31]}},inst_in[31:25],inst_in[11:7]};

                    case (func3)
                        `f3SB: inst_type_out <= `SB;
                        `f3SH: inst_type_out <= `SH;
                        `f3SW: inst_type_out <= `SW;
                    endcase
                end
                `opLUI: begin
                    rs1_read_out <= `ReadDisable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= `NOPRegAdder;
                    rs2_addr_out <= `NOPRegAdder;
                    //todo rs1_out <=
                    //todo rs2_out <=
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm_out <= {inst_in[31:12],12'b0};
                    inst_type_out <= `LUI;
                end
                `opAUIPC: begin
                    rs1_read_out <= `ReadDisable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= `NOPRegAdder;
                    rs2_addr_out <= `NOPRegAdder;
                    //todo rs1_out <=
                    //todo rs2_out <=
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm_out <= {inst_in[31:12],12'b0};
                    inst_type_out <= `AUIPC;
                end
                `opJAL: begin
                    rs1_read_out <= `ReadDisable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= `NOPRegAdder;
                    rs2_addr_out <= `NOPRegAdder;
                    //todo rs1_out <=
                    //todo rs2_out <=
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm_out <= {{12{inst_in[31]}},inst_in[19:12],inst_in[20],inst_in[30:21],1'b0};
                    inst_type_out <= `JAL;
                end
                `opJALR: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= `NOPRegAdder;
                    //todo rs1_out <=
                    //todo rs2_out <=
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm_out <= {{20{inst_in[31]}},inst_in[31:20]};
                    inst_type_out <= `JALR;
                end
            endcase
        end
    end

endmodule : id