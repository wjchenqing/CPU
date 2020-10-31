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
                `XOR: rd_val_out <= rs1_val_in ^ rs2_val_in;
                `OR: rd_val_out <= rs1_val_in | rs2_val_in;
                `AND: rd_val_out <= rs1_val_in & rs2_val_in;
            endcase
        end

    end

endmodule : ex