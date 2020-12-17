// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "defines.v"

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

    wire rdy;
    assign rdy = rdy_in & (!io_buffer_full);

    // Link pc_reg to if.
    wire [`InstAddrBus] pc;
    wire                iccorect;

    // Link ex to ps_reg
    wire                branch_flag_ex_out;
    wire [`InstAddrBus] branch_target_addr_ex_out;
    wire[`InstAddrBus ] branch_pc_ex_to_pcreg;

    // Link if to if_id.
    wire[`InstAddrBus ] pc_if_to_ifid;
    wire[`InstBus ]     inst_if_to_ifid;

    // Link if to ctrl.
    wire                stall_req_if_to_ctrl;

    // Link if to mem_ctrl.
    wire                if_req_if_to_memctrl;
    wire[`InstAddrBus ] inst_addr_if_to_memctrl;

    // Link mem_ctrl to if.
    wire[`InstBus ]     inst_memctrl_to_if;
    wire[1:0]           busy_memctrl_to_if_and_mem;
    wire                inst_done_memctrl_to_if;

    // Link if_id to id.
    wire [`InstAddrBus] pc_ifid_to_id;
    wire [`InstBus]     inst_ifid_to_id;

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
    wire                loading_id_to_idex;

    // Link id_ex to ex.
    wire [`RegBus ]         rs1_val_idex_to_ex;
    wire [`RegBus ]         rs2_val_idex_to_ex;
    wire                    rd_idex_to_ex;
    wire [`RegAddrBus ]     rd_addr_idex_to_ex;
    wire [`InstTypeBus ]    inst_type_idex_to_ex;
    wire [`RegBus ]         imm_idex_to_ex;
    wire [`InstAddrBus ]    pc_idex_to_ex;
    wire                    loading_idex_to_ex;

    // Link ex to ex_mem, forwarding to id
    wire                    rd_ex_to_exmem;
    wire [`RegBus ]         rd_val_ex_to_exmem;
    wire [`RegAddrBus ]     rd_addr_ex_to_exmem;
    wire [`InstTypeBus ]    inst_type_ex_to_exmem;

    // Link ex to ex_mem
    wire                    load_ex_to_exmem;
    wire                    store_ex_to_exmem;
    wire [`InstAddrBus ]    mem_addr_ex_to_exmem;
    wire [`RegBus ]         mem_val_ex_to_exmem;

    // ex forwarding to id
    wire                    ex_is_loading_ex_to_id;

    // Link ex to pc_reg
    wire [`InstAddrBus ]    pc_ex_to_pcreg;

    // Link ex_mem to mem
    wire                    rd_exmem_to_mem;
    wire [`RegBus ]         rd_val_exmem_to_mem;
    wire [`RegAddrBus ]     rd_addr_exmem_to_mem;
    wire [`InstTypeBus ]    inst_type_exmem_to_mem;
    wire                    load_exmem_to_mem;
    wire                    store_exmem_to_mem;
    wire [`InstAddrBus ]    mem_addr_exmem_to_mem;
    wire [`RegBus ]         mem_val_exmem_to_mem;

    // Link mem to mem_wb
    wire                    rd_mem_to_memwb;
    wire [`RegBus ]         rd_val_mem_to_memwb;
    wire [`RegAddrBus ]     rd_addr_mem_to_memwb;

    // Link mem to mem_ctrl
    wire                    read_req_mem_to_memctrl;
    wire                    write_req_mem_to_memctrl;
    wire[`InstAddrBus ]     mem_addr_mem_to_memctrl;
    wire[`RegBus ]          mem_val_mem_to_memctrl;
    wire[2:0]               store_len_mem_to_memctrl;

    // Link mem_ctrl to mem
    wire                    mem_done_memctrl_to_mem;
    wire[`RegBus ]          mem_val_read_memctrl_to_mem;

    // Link mem to ctrl
    wire                    stall_req_mem_to_ctrl;

    // Link mem_wb to regfile
    wire                    rd_wb_to_regfile;
    wire [`RegBus ]         rd_val_wb_to_regfile;
    wire [`RegAddrBus ]     rd_addr_wb_to_regfile;

    // Stall ctrl.
    wire stallreq_from_id;
    wire stallreq_from_ex;
    wire[5:0] stall_info;

    pc_reg PC(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy),
        .pc_out(pc),
        .stall(stall_info),
        .branch_flag_in(branch_flag_ex_out),
        .branch_target_addr_in(branch_target_addr_ex_out),
        .branch_pc_in(branch_pc_ex_to_pcreg),
        .incorrect(iccorect)
    );

    If IF(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy(rdy),
        .pc(pc),
        .if_req_out(if_req_if_to_memctrl),
        .inst_addr_out(inst_addr_if_to_memctrl),
        .inst_in(inst_memctrl_to_if),
        .busy_in(busy_memctrl_to_if_and_mem),
        .inst_done_in(inst_done_memctrl_to_if),
        .branch_flag_in(iccorect),
        .branch_target_addr_in(branch_target_addr_ex_out),
        .stall_req_from_if(stall_req_if_to_ctrl),
        .if_pc_out(pc_if_to_ifid),
        .if_inst_out(inst_if_to_ifid)
    );

    if_id IF_ID(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy),
        .branch_flag_in(iccorect),
        .if_pc(pc_if_to_ifid),
        .if_inst(inst_if_to_ifid),
        .id_pc(pc_ifid_to_id),
        .id_inst(inst_ifid_to_id),
        .stall(stall_info)
    );

    id ID(
        .rst_in(rst_in),
        .pc_in(pc_ifid_to_id),
        .inst_in(inst_ifid_to_id),
        .ex_is_loading(ex_is_loading_ex_to_id),
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
        .imm_val_out(imm_id_to_idex),
        .pc_out(pc_id_to_idex),
        .stalleq_from_id(stallreq_from_id),
        .is_loading_out(loading_id_to_idex)
    );

    id_ex ID_EX(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy),
        .branch_flag_in(iccorect),
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
        .id_loading(loading_id_to_idex),
        .ex_loading(loading_idex_to_ex)
    );

    ex EX(
        .rst_in(rst_in),
        .rs1_val_in(rs1_val_idex_to_ex),
        .rs2_val_in(rs2_val_idex_to_ex),
        .rd_in(rd_idex_to_ex),
        .rd_addr_in(rd_addr_idex_to_ex),
        .inst_type_in(inst_type_idex_to_ex),
        .imm_in(imm_idex_to_ex),
        .pc_in(pc_idex_to_ex),
        .is_loading_in(loading_idex_to_ex),
        .ex_is_loading_out(ex_is_loading_ex_to_id),
        .rd_out(rd_ex_to_exmem),
        .rd_val_out(rd_val_ex_to_exmem),
        .rd_addr_out(rd_addr_ex_to_exmem),
        .inst_type_out(inst_type_ex_to_exmem),
        .load_out(load_ex_to_exmem),
        .store_out(store_ex_to_exmem),
        .mem_addr_out(mem_addr_ex_to_exmem),
        .mem_val_out(mem_val_ex_to_exmem),
        .stallreq_from_ex(stallreq_from_ex),
        .branch_flag_out(branch_flag_ex_out),
        .branch_target_addr_out(branch_target_addr_ex_out),
        .rd_val_from_mem(rd_val_mem_to_memwb),
        .branch_pc_out(branch_pc_ex_to_pcreg)
    );

    ex_mem EX_MEM(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy),
        .rd_ex_in(rd_ex_to_exmem),
        .rd_val_ex_in(rd_val_ex_to_exmem),
        .rd_addr_ex_in(rd_addr_ex_to_exmem),
        .inst_type_ex_in(inst_type_ex_to_exmem),
        .load_ex_in(load_ex_to_exmem),
        .store_ex_in(store_ex_to_exmem),
        .mem_addr_ex_in(mem_addr_ex_to_exmem),
        .mem_val_ex_in(mem_val_ex_to_exmem),
        .rd_mem_out(rd_exmem_to_mem),
        .rd_val_mem_out(rd_val_exmem_to_mem),
        .rd_addr_mem_out(rd_addr_exmem_to_mem),
        .inst_type_mem_out(inst_type_exmem_to_mem),
        .load_mem_out(load_exmem_to_mem),
        .store_mem_out(store_exmem_to_mem),
        .mem_addr_mem_out(mem_addr_exmem_to_mem),
        .mem_val_mem_out(mem_val_exmem_to_mem),
        .stall(stall_info)
    );

    mem MEM(
        .rst_in(rst_in),
        .mem_done_in(mem_done_memctrl_to_mem),
        .mem_val_read_in(mem_val_read_memctrl_to_mem),
        .memctrl_busy_in(busy_memctrl_to_if_and_mem),
        .read_req_out(read_req_mem_to_memctrl),
        .write_req_out(write_req_mem_to_memctrl),
        .mem_addr_out(mem_addr_mem_to_memctrl),
        .mem_val_out(mem_val_mem_to_memctrl),
        .rd_in(rd_exmem_to_mem),
        .rd_val_in(rd_val_exmem_to_mem),
        .rd_addr_in(rd_addr_exmem_to_mem),
        .inst_type_in(inst_type_exmem_to_mem),
        .load_in(load_exmem_to_mem),
        .store_in(store_exmem_to_mem),
        .mem_addr_in(mem_addr_exmem_to_mem),
        .mem_val_in(mem_val_exmem_to_mem),
        .store_len(store_len_mem_to_memctrl),
        .rd_out(rd_mem_to_memwb),
        .rd_val_out(rd_val_mem_to_memwb),
        .rd_addr_out(rd_addr_mem_to_memwb),
        .stall_req_from_mem(stall_req_mem_to_ctrl)
    );

    mem_wb MEM_WB(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy),
        .rd_mem_in(rd_mem_to_memwb),
        .rd_val_mem_in(rd_val_mem_to_memwb),
        .rd_addr_mem_in(rd_addr_mem_to_memwb),
        .rd_wb_out(rd_wb_to_regfile),
        .rd_val_wb_out(rd_val_wb_to_regfile),
        .rd_addr_wb_out(rd_addr_wb_to_regfile),
        .stall(stall_info)
    );

    regfile REGFILE(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy),
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

    ctrl CTRL(
        .rst_in(rst_in),
        .stallreq_from_if(stall_req_if_to_ctrl),
        .stallreq_from_mem(stall_req_mem_to_ctrl),
        .stallreq_from_id(stallreq_from_id),
        .stallreq_from_ex(stallreq_from_ex),
        .stall(stall_info)
    );

    mem_ctrl MEM_CTRL(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy),
        .if_req_in(if_req_if_to_memctrl),
        .inst_addr_in(inst_addr_if_to_memctrl),
        .inst_done(inst_done_memctrl_to_if),
        .inst_out(inst_memctrl_to_if),
        .read_req_in(read_req_mem_to_memctrl),
        .write_req_in(write_req_mem_to_memctrl),
        .mem_addr_in(mem_addr_mem_to_memctrl),
        .mem_val_in(mem_val_mem_to_memctrl),
        .mem_done(mem_done_memctrl_to_mem),
        .mem_val_read_out(mem_val_read_memctrl_to_mem),
        .store_len(store_len_mem_to_memctrl),
        .rw_req_out(mem_wr),
        .mem_addr_out(mem_a),
        .mem_val_out(mem_dout),
        .mem_val_read_in(mem_din),
        .busy(busy_memctrl_to_if_and_mem)
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