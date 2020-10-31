`include "defines.v"

module mem(
    input   wire        rst_in,

    input   wire                rd_in,
    input   wire[`RegBus]       rd_val_in,
    input   wire[`RegAddrBus]   rd_addr_in,
    input   wire[`InstTypeBus]  inst_type_in,
    input   wire[`InstAddrBus]  pc_in,

    output  reg                 rd_out,
    output  reg[`RegBus]        rd_val_out,
    output  reg[`RegAddrBus]    rd_addr_out,
);

    always @ (*) begin
        if (rst_in == `RstEnable) begin
            rd_out <= `WriteDisable;
            rd_val_out <= `ZeroWord;
            rd_addr_out <= `NOPRegAdder;
        end else begin
            rd_out <= rd_in;
            rd_addr_out <= rd_addr_in;
            case (inst_type_in)
                default : rd_val_out <= rd_val_in;
            endcase
        end
    end

endmodule : mem