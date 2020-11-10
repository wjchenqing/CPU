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

    output  reg                 rd_out,
    output  reg[`RegBus]        rd_val_out,
    output  reg[`RegAddrBus]    rd_addr_out,
    output  reg[`InstTypeBus]   inst_type_out,


    output  reg[`InstAddrBus]   pc_out,

    output  wire                stallreq_from_ex
);

    always @ (*) begin
        if (rst_in == `RstEnable) begin
            rd_out <= `WriteDisable;
            rd_val_out <= `ZeroWord;
            rd_addr_out <= `NOPRegAdder;
            inst_type_out <= `NOPInstType;
            mem_addr_out <= `ZeroWord;
            mem_val_out <= `ZeroWord;
            pc_out <= `ZeroWord;
        end else begin
            rd_out <= rd_in;
            rd_addr_out <= rd_addr_in;
            inst_type_out <= inst_type_in;
            pc_out <= pc_in;
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
                `JAL: rd_val_out <= pc_in + `PCstep;
                `JALR: rd_val_out <= pc_in +`PCstep;
            endcase
        end

    end

endmodule : ex