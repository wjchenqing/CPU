`include "defines.v"
`define RstEnable       1'b1
`define CSRNum          256
`define NopCSR          8'hff
`define Mvendorid       8'h00
`define Marchid         8'h01
`define Mimpid          8'h02
`define Mhartid         8'h03
`define Mstatus         8'h04
`define Misa            8'h05
`define Medeleg         8'h06
`define Mideleg         8'h07
`define Mie             8'h08
`define Mtvec           8'h09
`define Mcounteren      8'h0a
`define Mscratch        8'h0b
`define Mepc            8'h0c
`define Mcause          8'h0d
`define Mtval           8'h0e
`define Mip             8'h0f
`define Pmpcfg          8'h10
`define Pmpaddr         8'h14
`define Mcycle          8'h24
`define Minstret        8'h25
`define Mhpmcounter     8'h26
`define Mcycleh         8'h43
`define Minstreth       8'h44
`define Mhpmcounterh    8'h45
`define Mhpmevent       8'h62
`define Tselect         8'h7f
`define Tdata           8'h80


module CSR (
    input   wire                clk_in,
    input   wire                rst_in,
    input   wire                rdy_in,

    input   wire[`RegBus]       source_val,
    input   wire                rd_enable,
    input   wire[`CSRAddrBus]   csr_addr_in,
    input   wire                inst_type_in,

    output  reg[`RegBus]        csr_val_out,

);

reg[`RegBus]    csr_regs[`CSRNum - 1 : 0];
reg [7:0]       csr_index;
reg [7:0]       csr_type;

wire[3:0]       num1;
wire[3:0]       num2;
wire[3:0]       num3;
assign num1 = csr_addr_in[11:8];
assign num2 = csr_addr_in[ 7:4];
assign num3 = csr_addr_in[ 3:0];

always @ (*) begin
    if (rst_in == `RstEnable) begin
        csr_index <= `NopCSR;
        csr_type  <= `NopCSR;
    end else begin
        case (num1)
            4'hf: begin
                case (num2)
                    4'h1: begin
                        case (num3) 
                            4'h1: begin
                                csr_index <= `Mvendorid;
                                csr_type  <= `Mvendorid;
                            end
                            4'h2: begin
                                csr_index <= `Marchid;
                                csr_type  <= `Marchid;
                            end
                            4'h3: begin
                                csr_index <= `Mimpid;
                                csr_type  <= `Mimpid
                            end
                            4'h4: begin
                                csr_index <= `Mhartid;
                                csr_type  <= `Mhartid;
                            end
                            default: begin
                                csr_index <= `NopCSR;
                                csr_type  <= `NopCSR;
                            end
                        endcase
                    end
                    default: begin
                        csr_index <= `NopCSR;
                        csr_type  <= `NopCSR;
                    end
                endcase
            end
            4'h3: begin
                case (num2)
                    4'h0: begin
                        case (num3)
                            4'h0: begin
                                csr_index <= `Mstatus;
                                csr_type  <= `Mstatus;
                            end
                            4'h1: begin
                                csr_index <= `Misa;
                                csr_type  <= `Misa;
                            end
                            4'h2: begin
                                csr_index <= `Medeleg;
                                csr_type  <= `Medeleg;
                            end
                            4'h3: begin
                                csr_index <= `Mideleg;
                                csr_type  <= `Mideleg;
                            end
                            4'h4: begin
                                csr_index <= `Mie;
                                csr_type  <= `Mie;
                            end
                            4'h5: begin
                                csr_index <= `Mtvec;
                                csr_type  <= `Mtvec;
                            end
                            4'h6: begin
                                csr_index <= `Mcounteren;
                                csr_type  <= `Mcounteren;
                            end
                            default: begin
                                csr_index <= `NopCSR;
                                csr_type  <= `NopCSR;
                            end
                        endcase
                    end
                    4'h4: begin
                        case (num3)
                            4'h0: begin
                                csr_index <= `Mscratch;
                                csr_type  <= `Mscratch;
                            end
                            4'h1: begin
                                csr_index <= `Mepc;
                                csr_type  <= `Mepc;
                            end
                            4'h2: begin
                                csr_index <= `Mcause;
                                csr_type  <= `Mcause;
                            end
                            4'h3: begin
                                csr_index <= `Mtval;
                                csr_type  <= `Mtval;
                            end
                            4'h4: begin
                                csr_index <= `Mip;
                                csr_type  <= `Mip;
                            end
                            default: begin
                                csr_index <= `NopCSR;
                                csr_type  <= `NopCSR;
                            end
                        endcase
                    end
                    4'h2: begin
                        case (num3)
                            4'h0: begin
                                csr_index <= `NopCSR;
                                csr_type  <= `NopCSR;
                            end
                            4'h1: begin
                                csr_index <= `NopCSR;
                                csr_type  <= `NopCSR;
                            end
                            4'h2: begin
                                csr_index <= `NopCSR;
                                csr_type  <= `NopCSR;
                            end
                            default: begin
                                csr_index <= 'Mhpmevent + num3 - 4'h3;
                                csr_type  <= 'Mhpmevent;
                            end
                        endcase
                    end
                    4'h3: begin
                        csr_index <= `Mhpmevent + num3 + 4'hd;
                        csr_type  <= `Mhpmevent;
                    end
                    4'ha: begin
                        case (num3): begin
                            4'h0: begin
                                csr_index <= `Pmpcfg;
                                csr_type  <= `Pmpcfg;
                            end
                            4'h1: begin
                                csr_index <= `Pmpcfg + 4'h1;
                                csr_type  <= `Pmpcfg;
                            end
                            4'h2: begin
                                csr_index <= `Pmpcfg + 4'h2;
                                csr_type  <= `Pmpcfg;
                            end
                            4'h3: begin
                                csr_index <= `Pmpcfg + 4'h3;
                                csr_type  <= `Pmpcfg;
                            end
                            default: begin
                                csr_index <= `NopCSR;
                                csr_type  <= `NopCSR;
                            end
                        end
                    end
                    4'hb: begin
                        csr_index <= `Pmpaddr + num3;
                        csr_type  <= `Pmpaddr;
                    end
                    default: begin
                        csr_index <= `NopCSR;
                        csr_type  <= `NopCSR;
                    end
                endcase
            end
            4'h7: begin
                case (num2)
                    4'ha: begin
                        case (num3) 
                            4'h0: begin
                                csr_index <= `Tselect;
                                csr_type  <= `Tselect;
                            end
                            4'h1: begin
                                csr_index <= `Tdata;
                                csr_type  <= `Tdata;
                            end
                            4'h2: begin
                                csr_index <= `Tdata + 1'b1;
                                csr_type  <= `Tdata;
                            end
                            4'h3: begin
                                csr_index <= `Tdata + 2'b10;
                                csr_type  <= `Tdata;
                            end
                            default: begin
                                csr_index <= `NopCSR;
                                csr_type  <= `NopCSR;
                            end
                        endcase
                    end
                    default: begin
                        csr_index <= `NopCSR;
                        csr_type  <= `NopCSR;
                    end
                endcase
            end
            4'hb: begin
                case (num2)
                    4'h0: begin
                        case(num3)
                            4'h0: begin
                                csr_index <= `Mcycle;
                                csr_type  <= `Mcycle;
                            end
                            4'h1: begin
                                csr_index <= `NopCSR;
                                csr_type  <= `NopCSR;
                            end
                            4'h2: begin
                                csr_index <= `Minstret;
                                csr_type  <= `Minstret;
                            end
                            default: begin
                                csr_index <= `Mhpmcounter + num3 - 4'h3;
                                csr_type  <= `Mhpmcounter;
                            end
                        endcase
                    end
                    4'h1: begin
                        csr_index <= `Mhpmcounter + num3 + 4'hd;
                        csr_type  <= `Mhpmcounter;
                    end
                    4'h8: begin
                        case(num3)
                            4'h0: begin
                                csr_index <= `Mcycleh;
                                csr_type  <= `Mcycleh;
                            end
                            4'h1: begin
                                csr_index <= `NopCSR;
                                csr_type  <= `NopCSR;
                            end
                            4'h2: begin
                                csr_index <= `Minstreth;
                                csr_type  <= `Minstreth;
                            end
                            default: begin
                                csr_index <= `Mhpmcounterh + num3 - 4'h3;
                                csr_type  <= `Mhpmcounterh;
                            end
                        endcase
                    end
                    4'h1: begin
                        csr_index <= `Mhpmcounterh + num3 + 4'hd;
                        csr_type  <= `Mhpmcounterh;
                    end
                    default: begin
                        csr_index <= `NopCSR;
                        csr_type  <= `NopCSR;
                    end
                endcase
            end
        endcase
    end
end

always @ (*) begin
    if (rst_in == `RstEnable) begin
        csr_val_out <= `Zeroword;
    end else begin
        if ((csr_index != `NopCSR) && (rd_enable == `WriteEnable)) begin
            csr_val_out <= csr_regs[csr_index];
        end else begin
            csr_val_out <= `Zeroword;
        end
    end
end

always @ (posedge clk_in) begin
    if (rst_in == `RstDisable) begin
        if (rdy == 1'b1) begin
            if (csr_index != `NopCSR) begin
                case (inst_type_in)
                    `CSRRW: begin
                        csr_regs[csr_index] <= source_val;
                    end
                    `CSRRS: begin
                        if (source_val != `Zeroword) begin
                            csr_regs[csr_index] <= (csr_regs[csr_index] | source_val);
                        end
                    end
                    `CSRRC: begin
                        if (source_val != `Zeroword) begin
                            csr_regs[csr_index] <= (csr_regs[csr_index] & ~source_val);
                        end
                    end
                    `CSRRWI: begin
                        csr_regs[csr_index] <= source_val;
                    end
                    `CSRRSI: begin
                        if (source_val != `Zeroword) begin
                            csr_regs[csr_index] <= (csr_regs[csr_index] | source_val);
                        end
                    end
                    `CSRRCI: begin
                        if (source_val != `Zeroword) begin
                            csr_regs[csr_index] <= (csr_regs[csr_index] & ~source_val);
                        end
                    end
                endcase
            end
        end
    end
end
    
endmodule