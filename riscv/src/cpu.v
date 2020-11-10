// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

    // Link pc_reg to if_id.
    wire [`InstAddrBus] pc;

    pc_reg PC(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .pc_out(pc),
        .stall(stall_info),
    );

    // Link if_id to id.
    wire [`InstAddrBus] pc_ifid_to_id;
    wire [`InstBus]     inst_ifid_to_id;

    if_id IF_ID(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .if_pc(pc),
        .if_inst(mem_dout),
        .id_pc(pc_ifid_to_id),
        .id_inst(inst_ifid_to_id),
        .stall(stall_info),
    );

    // Link regfile to id.
    wire [`RegBus] rs1_data_regfile_to_id;
    wire [`RegBus] rs2_data_regfile_to_id;

    // Link id to regfile.
    wire                rs1_read_id_to_regfile; //whether to read or not
    wire                rs2_read_id_to_regfile; //whether to read or not
    wire [`RegAddrBus]  rs1_addr_id_to_regfile;
    wire [`RegAddrBus]  rs2_addr_id_to_regfile;

    // Link id to id_ex.
    wire [`RegBus]      rs1_val_id_to_idex;
    wire [`RegBus]      rs2_val_id_to_idex;
    wire                rd_id_to_idex;          //whether have rd
    wire [`RegAddrBus]  rd_addr_id_to_idex;
    wire [`InstTypeBus] inst_type_id_to_idex;
    wire [`RegBus ]     imm_id_to_idex;
    wire [`InstAddrBus] pc_id_to_idex;

    id ID(
        .rst_in(rst_in),
        .pc_in(pc_ifid_to_id),
        .inst_in(inst_ifid_to_id),
        .ex_wreg_in(rd_ex_to_exmem),
        .ex_wdata_in(rd_val_ex_to_exmem),
        .ex_waddr_in(rd_addr_ex_to_exmem),
        .mem_wreg_in(rd_mem_to_memwb),
        .mem_wdata_in(rd_val_mem_to_memwb),
        .mem_waddr_in(rd_addr_mem_to_memwb),
        .rs1_data_in(rs1_data_regfile_to_id),
        .rs2_data_in(rs2_data_regfile_to_id),
        .rs1_read_out(rs1_read_id_to_regfile),
        .rs2_read_out(rs2_read_id_to_regfile),
        .rs1_addr_out(rs1_addr_id_to_regfile),
        .rs2_addr_out(rs2_addr_id_to_regfile),
        .rs1_val_out(rs1_val_id_to_idex),
        .rs2_val_out(rs2_val_id_to_idex),
        .rd_out(rd_id_to_idex),
        .rd_addr_out(rd_addr_id_to_idex),
        .inst_type_out(inst_type_id_to_idex),
        .imm(imm_id_to_idex),
        .pc_out(pc_id_to_idex),
        .stalleq_from_id(stallreq_from_id),
    );

    // Link id_ex to ex.
    wire [`RegBus ]         rs1_val_idex_to_ex;
    wire [`RegBus ]         rs2_val_idex_to_ex;
    wire                    rd_idex_to_ex;
    wire [`RegAddrBus ]     rd_addr_idex_to_ex;
    wire [`InstTypeBus ]    inst_type_idex_to_ex;
    wire [`RegBus ]         imm_idex_to_ex;
    wire [`InstAddrBus ]    pc_idex_to_ex;

    id_ex ID_EX(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rs1_val_id_in(rs1_val_id_to_idex),
        .rs2_val_id_in(rs2_val_id_to_idex),
        .rd_id_in(rd_id_to_idex),
        .rd_addr_id_in(rd_addr_id_to_idex),
        .inst_type_id_in(inst_type_id_to_idex),
        .imm_id_in(imm_id_to_idex),
        .pc_id_in(pc_id_to_idex),
        .rs1_val_ex_out(rs1_val_idex_to_ex),
        .rs2_val_ex_out(rs2_val_idex_to_ex),
        .rd_ex_out(rd_idex_to_ex),
        .rd_addr_ex_out(rd_addr_idex_to_ex),
        .inst_type_ex_out(inst_type_idex_to_ex),
        .imm_ex_out(imm_idex_to_ex),
        .pc_ex_out(pc_idex_to_ex),
        .stall(stall_info),
    );

    // Link ex to ex_mem, forwarding to id
    wire                    rd_ex_to_exmem;
    wire [`RegBus ]         rd_val_ex_to_exmem;
    wire [`RegAddrBus ]     rd_addr_ex_to_exmem;
    wire [`InstTypeBus ]    inst_type_ex_to_exmem;

    // Link ex to pc_reg
    wire [`InstAddrBus ]    pc_ex_to_pcreg;

    ex EX(
        .rst_in(rst_in),
        .rs1_val_in(rs1_val_idex_to_ex),
        .rs2_val_in(rs2_val_idex_to_ex),
        .rd_in(rd_idex_to_ex),
        .rd_addr_in(rd_addr_idex_to_ex),
        .inst_type_in(inst_type_idex_to_ex),
        .imm_in(imm_idex_to_ex),
        .pc_in(pc_idex_to_ex),
        .rd_out(rd_ex_to_exmem),
        .rd_val_out(rd_val_ex_to_exmem),
        .rd_addr_out(rd_addr_ex_to_exmem),
        .inst_type_out(inst_type_ex_to_exmem),
        .pc_out(pc_ex_to_pcreg),
        .stallreq_from_ex(stallreq_from_ex),
    );

    // Link ex_mem to mem, forwarding to id
    wire                    rd_exmem_to_mem;
    wire [`RegBus ]         rd_val_exmem_to_mem;
    wire [`RegAddrBus ]     rd_addr_exmem_to_mem;
    wire [`InstTypeBus ]    inst_type_exmem_to_mem;

    ex_mem EX_MEM(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .rd_ex_in(rd_ex_to_exmem),
        .rd_val_ex_in(rd_val_ex_to_exmem),
        .rd_addr_ex_in(rd_addr_ex_to_exmem),
        .inst_type_ex_in(inst_type_ex_to_exmem),
        .rd_mem_out(rd_exmem_to_mem),
        .rd_val_mem_out(rd_val_exmem_to_mem),
        .rd_addr_mem_out(rd_addr_exmem_to_mem),
        .inst_type_mem_out(inst_type_exmem_to_mem),
        .stall(stall_info),
    );

    // Link mem to mem_wb
    wire                    rd_mem_to_memwb;
    wire [`RegBus ]         rd_val_mem_to_memwb;
    wire [`RegAddrBus ]     rd_addr_mem_to_memwb;

    mem MEM(
        .rst_in(rst_in),
        .rd_in(rd_exmem_to_mem),
        .rd_val_out(rd_val_exmem_to_mem),
        .rd_addr_in(rd_addr_exmem_to_mem),
        .inst_type_in(inst_type_exmem_to_mem),  // todo: pc????
        .rd_out(rd_mem_to_memwb),
        .rd_val_out(rd_val_mem_to_memwb),
        .rd_addr_out(rd_addr_mem_to_memwb)
    );

    // Link mem_wb to regfile
    wire                    rd_wb_to_regfile;
    wire [`RegBus ]         rd_val_wb_to_regfile;
    wire [`RegAddrBus ]     rd_addr_wb_to_regfile;

    mem_wb MEM_WB(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .rd_mem_in(rd_mem_to_memwb),
        .rd_val_mem_in(rd_val_mem_to_memwb),
        .rd_addr_mem_in(rd_addr_mem_to_memwb),
        .rd_wb_out(rd_wb_to_regfile),
        .rd_val_wb_out(rd_val_wb_to_regfile),
        .rd_addr_wb_out(rd_addr_wb_to_regfile),
        .stall(stall_info),
    );

    regfile REGFILE(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .we(rd_wb_to_regfile),
        .wdata(rd_val_wb_to_regfile),
        .waddr(rd_addr_wb_to_regfile),
        .re1(rs1_read_id_to_regfile),
        .raddr1(rs1_addr_id_to_regfile),
        .rdata1(rs1_data_regfile_to_id),
        .re2(rs2_read_id_to_regfile),
        .raddr2(rs2_addr_id_to_regfile),
        .rdata2(rs2_data_regfile_to_id)
    );

    // Stall ctrl.
    wire stallreq_from_id;
    wire stallreq_from_ex;
    wire stall_info;

    ctrl CTRL(
        .rst_in(rst_in),
        .stallreq_from_id(stallreq_from_id),
        .stallreq_from_ex(stallreq_from_ex),
        .stall(stall_info),
    );


/*
always @(posedge clk_in)
  begin
    if (rst_in)
      begin
      
      end
    else if (!rdy_in)
      begin
      
      end
    else
      begin
      
      end
  end
*/
endmodule : cpu