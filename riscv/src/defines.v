
//----------Global----------
`define RstEnable       1'b1
`define RstDisable      1'b0
`define ZeroWord        32'h00000000
`define WriteEnable     1'b1
`define WriteDisable    1'b0
`define ReadEnable      1'b1
`define ReadDisable     1'b0
`define InstValid       1'b0
`define InstInvalid     1'b1
`define True_v          1'b1
`define False_v         1'b0
`define ChipEnable      1'b1
`define ChipDisable     1'b0
`define PCstep          32'h4
`define Stop            1'b1
`define NotStop         1'b0
`define Branch          1'b1
`define NotBranch       1'b0
`define Loading         1'b1
`define NotLoading      1'b0
`define RamBus          7:0

//-----------Regfile Related-----------
`define RegAddrBus      4:0
`define RegBus          31:0
`define RegWidth        32
`define RegNum          32
`define RegNumLog2      5
`define NOPRegAdder     5'b00000

//-------------CSR Related----------------
`define CSRAddrBus      11:0
`define CSRRange        31:20

//----------opCode----------
`define opCodeRange     6:0
`define opCodeWidth     7
`define opLUI           7'b0110111
`define opAUIPC         7'b0010111
`define opJAL           7'b1101111
`define opJALR          7'b1100111
`define opBranch        7'b1100011
`define opLoad          7'b0000011
`define opStore         7'b0100011
`define opRI            7'b0010011
`define opRR            7'b0110011
`define opCSR           7'b1110011

//----------Funct3-----------
`define func3Range      14:12
`define func3Width      3
`define f3BEQ           3'b000
`define f3BNE           3'b001
`define f3BLT           3'b100
`define f3BGE           3'b101
`define f3BLTU          3'b110
`define f3BGEU          3'b111
`define f3LB            3'b000
`define f3LH            3'b001
`define f3LW            3'b010
`define f3LBU           3'b100
`define f3LHU           3'b101
`define f3SB            3'b000
`define f3SH            3'b001
`define f3SW            3'b010
`define f3ADDI          3'b000
`define f3SLTI          3'b010
`define f3SLTIU         3'b011
`define f3XORI          3'b100
`define f3ORI           3'b110
`define f3ANDI          3'b111
`define f3SLLI          3'b001
`define f3SRLI_SRAI     3'b101
`define f3ADD_SUB       3'b000
`define f3SLL           3'b001
`define f3SLT           3'b010
`define f3SLTU          3'b011
`define f3XOR           3'b100
`define f3SRL_SRA       3'b101
`define f3OR            3'b110
`define f3AND           3'b111
`define f3MRET          3'b000
`define f3CSRRW         3'b001
`define f3CSRRS         3'b010
`define f3CSRRC         3'b011
`define f3CSRRWI        3'b101
`define f3CSRRSI        3'b110
`define f3CSRRCI        3'b111

//----------Funct7----------
`define func7Range      31:25
`define func7Width      7
`define f7SRLI          7'b0000000
`define f7SRAI          7'b0100000
`define f7ADD           7'b0000000
`define f7SUB           7'b0100000
`define f7SRL           7'b0000000
`define f7SRA           7'b0100000
`define f7MRET          7'b0011000

//----------Reg_Pos_In_Inst----------
`define rs1Range        19:15
`define rs1Width        5
`define rs2Range        24:20
`define rs2Width        5
`define rdRange         11:7
`define rdWidth         5

//----------Instruction_Type----------
`define InstTypeBus     5:0
`define InstTypeWidth   6
`define NOPInstType     6'b000000
`define LUI             6'b000001
`define AUIPC           6'b000010
`define JAL             6'b000011
`define JALR            6'b000100
`define BEQ             6'b000101
`define BNE             6'b000110
`define BLT             6'b000111
`define BGE             6'b001000
`define BLTU            6'b001001
`define BGEU            6'b001010
`define LB              6'b001011
`define LH              6'b001100
`define LW              6'b001101
`define LBU             6'b001110
`define LHU             6'b001111
`define SB              6'b010000
`define SH              6'b010001
`define SW              6'b010010
`define ADDI            6'b010011
`define SLTI            6'b010100
`define SLTIU           6'b010101
`define XORI            6'b010110
`define ORI             6'b010111
`define ANDI            6'b011000
`define SLLI            6'b011001
`define SRLI            6'b011010
`define SRAI            6'b011011
`define ADD             6'b011100
`define SUB             6'b011101
`define SLL             6'b011110
`define SLT             6'b011111
`define SLTU            6'b100000
`define XOR             6'b100001
`define SRL             6'b100010
`define SRA             6'b100011
`define OR              6'b100100
`define AND             6'b100101
`define MRET            6'b100110
`define CSRRW           6'b100111
`define CSRRS           6'b101000
`define CSRRC           6'b101001
`define CSRRWI          6'b101010
`define CSRRSI          6'b101011 
`define CSRRCI          6'b101100

//----------ROM Related----------
`define InstAddrBus     31:0
`define InstBus         31:0

//---------ICACHE-------------
`define ICacheNum       128
`define CacheAddrRange  8:2
`define TagBus          8:0
`define TagRange        17:9


