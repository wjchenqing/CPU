`include "defines.v"

module id(
    input   wire                rst_in,
    input   wire[`InstAddrBus]  pc_in,
    input   wire[`InstBus]      inst_in,

    //forwarding from ex.
    input   wire                ex_is_loading,
    input   wire                ex_wreg_in,     //1'b1 stands for having rd.
    input   wire[`RegBus]       ex_wdata_in,
    input   wire[`RegAddrBus]   ex_waddr_in,

    //forwarding from mem.
    input   wire                mem_wreg_in,
    input   wire[`RegBus]       mem_wdata_in,
    input   wire[`RegAddrBus]   mem_waddr_in,

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
    output  reg[`InstAddrBus]   pc_out,
    output  reg[`RegBus]        imm_val_out,
    output  reg                 is_loading_out,
    output  reg[`CSRAddrBus]    csr_addr,

    //stall ctrl
    output  wire                stalleq_from_id
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
            rd_out <= `ZeroWord ;
            rd_addr_out <= `NOPRegAdder;
            inst_type_out <= `NOPInstType;
            imm <= `ZeroWord;
            imm_val_out <= `ZeroWord;
            pc_out <= `ZeroWord;
            is_loading_out <= `NotLoading;
            csr_addr <= `NopCSR;
        end else begin
            inst_type_out <= `NOPInstType;
            case (opcode)
                `opRI: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= `NOPRegAdder;
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    is_loading_out <= `NotLoading ;
                    csr_addr <= `NopCSR;
                    case (func3)
                        `f3ADDI: begin
                            inst_type_out <= `ADDI;
                            imm <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3SLTI: begin
                            inst_type_out <= `SLTI;
                            imm <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3SLTIU: begin
                            inst_type_out <= `SLTIU;
                            imm <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3XORI: begin
                            inst_type_out <= `XORI;
                            imm <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3ORI: begin
                            inst_type_out <= `ORI;
                            imm <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3ANDI: begin
                            inst_type_out <= `ANDI;
                            imm <= {{20{inst_in[31]}},inst_in[31:20]};
                        end
                        `f3SLLI: begin
                            inst_type_out <= `SLLI;
                            imm <= {{27'b0},inst_in[24:20]};
                        end
                        `f3SRLI_SRAI: begin
                            if (func7 == `f7SRLI) begin
                                inst_type_out <= `SRLI;
                                imm <= {{27'b0},inst_in[24:20]};
                            end else begin
                                inst_type_out <= `SRAI;
                                imm <= {{27'b0},inst_in[24:20]};
                            end
                        end
                        default: begin
                            inst_type_out <= `NOPInstType;
                            imm <= `ZeroWord;
                        end
                    endcase
                end
                `opRR: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadEnable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= inst_in[`rs2Range];
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm <= `ZeroWord;
                    is_loading_out <= `NotLoading ;
                    csr_addr <= `NopCSR;

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
                        default: begin
                            inst_type_out <= `NOPInstType;
                        end
                    endcase
                end
                `opBranch: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadEnable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= inst_in[`rs2Range];
                    rd_out <= `WriteDisable;
                    rd_addr_out <= `NOPRegAdder;
                    pc_out <= pc_in;
                    imm <= {{20{inst_in[31]}},inst_in[7],inst_in[30:25],inst_in[11:8],1'b0};
                    is_loading_out <= `NotLoading ;
                    csr_addr <= `NopCSR;

                    case (func3)
                        `f3BEQ: begin
                            inst_type_out <= `BEQ;
                        end
                        `f3BNE: begin
                            inst_type_out <= `BNE;
                        end
                        `f3BLT: begin
                            inst_type_out <= `BLT;
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
                        default: begin
                            inst_type_out <= `NOPInstType;
                        end
                    endcase
                end
                `opLoad: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= `NOPRegAdder;
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm <= {{20{inst_in[31]}},inst_in[31:20]};
                    is_loading_out <= `Loading ;
                    csr_addr <= `NopCSR;

                    case (func3)
                        `f3LB: inst_type_out <= `LB;
                        `f3LH: inst_type_out <= `LH;
                        `f3LW: inst_type_out <= `LW;
                        `f3LBU: inst_type_out <= `LBU;
                        `f3LHU: inst_type_out <= `LHU;
                        default: inst_type_out <= `NOPInstType;
                    endcase
                end
                `opStore: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadEnable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= inst_in[`rs2Range];
                    rd_out <= `WriteDisable;
                    rd_addr_out <= `NOPRegAdder;
                    pc_out <= pc_in;
                    imm <= {{20{inst_in[31]}},inst_in[31:25],inst_in[11:7]};
                    is_loading_out <= `NotLoading ;
                    csr_addr <= `NopCSR;

                    case (func3)
                        `f3SB: inst_type_out <= `SB;
                        `f3SH: inst_type_out <= `SH;
                        `f3SW: inst_type_out <= `SW;
                        default: inst_type_out <= `NOPInstType;
                    endcase
                end
                `opLUI: begin
                    rs1_read_out <= `ReadDisable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= `NOPRegAdder;
                    rs2_addr_out <= `NOPRegAdder;
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm <= {inst_in[31:12],12'b0};
                    inst_type_out <= `LUI;
                    is_loading_out <= `NotLoading ;
                    csr_addr <= `NopCSR;
                end
                `opAUIPC: begin
                    rs1_read_out <= `ReadDisable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= `NOPRegAdder;
                    rs2_addr_out <= `NOPRegAdder;
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm <= {inst_in[31:12],12'b0};
                    inst_type_out <= `AUIPC;
                    is_loading_out <= `NotLoading ;
                    csr_addr <= `NopCSR;
                end
                `opJAL: begin
                    rs1_read_out <= `ReadDisable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= `NOPRegAdder;
                    rs2_addr_out <= `NOPRegAdder;
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm <= {{12{inst_in[31]}},inst_in[19:12],inst_in[20],inst_in[30:21],1'b0};
                    inst_type_out <= `JAL;
                    is_loading_out <= `NotLoading ;
                    csr_addr <= `NopCSR;
                end
                `opJALR: begin
                    rs1_read_out <= `ReadEnable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= inst_in[`rs1Range];
                    rs2_addr_out <= `NOPRegAdder;
                    rd_out <= `WriteEnable;
                    rd_addr_out <= inst_in[`rdRange];
                    pc_out <= pc_in;
                    imm <= {{20{inst_in[31]}},inst_in[31:20]};
                    inst_type_out <= `JALR;
                    is_loading_out <= `NotLoading ;
                    csr_addr <= `NopCSR;
                end
                `opCSR: begin
                    rs2_read_out <= `ReadDisable;
                    rs2_addr_out <= `NOPRegAdder;
                    pc_out <= pc_in;
                    is_loading_out <= `NotLoading;
                    case (func3)
                        `f3MRET: begin
                            rs1_read_out <= `ReadDisable;
                            rs1_addr_out <= `ZeroWord;
                            rd_out <= `WriteEnable;
                            rd_addr_out <= `NOPRegAdder;
                            imm <= `ZeroWord;
                            csr_addr <= 12'h341;
                        end
                        `f3CSRRW: begin
                            rs1_read_out <= `ReadEnable;
                            rs1_addr_out <= inst_in[`rs1Range];
                            rd_out <= (inst_in[`rdRange] == 5'b0) ? `WriteDisable : `WriteEnable;
                            rd_addr_out <= inst_in[`rdRange];   
                            inst_type_out <= `CSRRW;
                            imm <= `ZeroWord;
                            csr_addr <= inst_in[31:20];
                        end
                        `f3CSRRS: begin
                            rs1_read_out <= `ReadEnable;
                            rs1_addr_out <= inst_in[`rs1Range];
                            rd_out <= (inst_in[`rdRange] == 5'b0) ? `WriteDisable : `WriteEnable;
                            rd_addr_out <= inst_in[`rdRange];   
                            inst_type_out <= `CSRRS;
                            imm <= `ZeroWord;
                            csr_addr <= inst_in[31:20];
                        end
                        `f3CSRRC: begin
                            rs1_read_out <= `ReadEnable;
                            rs1_addr_out <= inst_in[`rs1Range];
                            rd_out <= (inst_in[`rdRange] == 5'b0) ? `WriteDisable : `WriteEnable;
                            rd_addr_out <= inst_in[`rdRange];   
                            inst_type_out <= `CSRRC;
                            imm <= `ZeroWord;
                            csr_addr <= inst_in[31:20];
                        end
                        `f3CSRRWI:begin
                            rs1_read_out <= `ReadDisable;
                            rs1_addr_out <= `NOPInstType;
                            rd_out <= (inst_in[`rdRange] == 5'b0) ? `WriteDisable : `WriteEnable;
                            rd_addr_out <= inst_in[`rdRange];   
                            inst_type_out <= `CSRRWI;
                            imm <= {28'b0, inst_in[`rs1Range]};
                            csr_addr <= inst_in[31:20];
                        end
                        `f3CSRRSI:begin
                            rs1_read_out <= `ReadDisable;
                            rs1_addr_out <= `NOPInstType;
                            rd_out <= (inst_in[`rdRange] == 5'b0) ? `WriteDisable : `WriteEnable;
                            rd_addr_out <= inst_in[`rdRange];   
                            inst_type_out <= `CSRRSI;
                            imm <= {28'b0, inst_in[`rs1Range]};
                            csr_addr <= inst_in[31:20];
                        end
                        `f3CSRRCI:begin
                            rs1_read_out <= `ReadDisable;
                            rs1_addr_out <= `NOPInstType;
                            rd_out <= (inst_in[`rdRange] == 5'b0) ? `WriteDisable : `WriteEnable;
                            rd_addr_out <= inst_in[`rdRange];   
                            inst_type_out <= `CSRRCI;
                            imm <= {28'b0, inst_in[`rs1Range]};
                            csr_addr <= inst_in[31:20];
                        end
                        default : begin
                            rs1_read_out <= `ReadDisable;
                            rs1_addr_out <= `NOPRegAdder;
                            rd_out <= `ZeroWord ;
                            rd_addr_out <= `NOPRegAdder;
                            inst_type_out <= `NOPInstType;
                            imm <= `ZeroWord;
                            csr_addr <= inst_in[31:20];
                        end
                    endcase
                end
                default : begin
                    rs1_read_out <= `ReadDisable;
                    rs2_read_out <= `ReadDisable;
                    rs1_addr_out <= `NOPRegAdder;
                    rs2_addr_out <= `NOPRegAdder;
                    rd_out <= `ZeroWord ;
                    rd_addr_out <= `NOPRegAdder;
                    inst_type_out <= `NOPInstType;
                    imm <= `ZeroWord;
                    pc_out <= `ZeroWord;
                    is_loading_out <= `NotLoading;
                    csr_addr <= 12'b0;
                end
            endcase
            imm_val_out <= imm;
        end
    end

    reg stalleq1, stalleq2;

    always @ (*) begin
        if ((rst_in == `RstEnable) || (rs1_read_out == `ReadDisable)) begin
            rs1_val_out <= `ZeroWord ;
            stalleq1 <= `NotStop ;
        end else if ((ex_is_loading == `Loading) && (ex_wreg_in == 1'b1) && (ex_waddr_in == rs1_addr_out)) begin
            rs1_val_out <= `ZeroWord ;
            stalleq1 <= `Stop ;
        end else if ((ex_wreg_in == 1'b1) && (ex_waddr_in == rs1_addr_out)) begin
            rs1_val_out <= ex_wdata_in;
            stalleq1 <= `NotStop ;
        end else if ((mem_wreg_in == 1'b1) && (mem_waddr_in == rs1_addr_out)) begin
            rs1_val_out <= mem_wdata_in;
            stalleq1 <= `NotStop ;
        end else if (rs1_read_out == `ReadEnable ) begin
            rs1_val_out <= rs1_data_in;
            stalleq1 <= `NotStop ;
        end
    end

    always @ (*) begin
        if ((rst_in == `RstEnable) || (rs2_read_out == `ReadDisable)) begin
            rs2_val_out <= `ZeroWord ;
            stalleq2 <= `NotStop ;
        end else if ((ex_is_loading == `Loading) && (ex_wreg_in == 1'b1) && (ex_waddr_in == rs2_addr_out)) begin
            rs2_val_out <= `ZeroWord ;
            stalleq2 <= `Stop ;
        end else if ((ex_wreg_in == 1'b1) && (ex_waddr_in == rs2_addr_out)) begin
            rs2_val_out <= ex_wdata_in;
            stalleq2 <= `NotStop ;
        end else if ((mem_wreg_in == 1'b1) && (mem_waddr_in == rs2_addr_out)) begin
            rs2_val_out <= mem_wdata_in;
            stalleq2 <= `NotStop ;
        end else if (rs2_read_out == `ReadEnable ) begin
            rs2_val_out <= rs2_data_in;
            stalleq2 <= `NotStop ;
        end else if (rs2_read_out == `ReadDisable ) begin
            rs2_val_out <= `ZeroWord ;
            stalleq2 <= `NotStop ;
        end
    end

    assign stalleq_from_id = stalleq1 | stalleq2;

endmodule : id