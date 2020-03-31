library ieee;
use ieee.std_logic_1164.all;

package myTypes is

  -- Constants Definitions

  --    _____ ____  _   _ _______ _____   ____  _        _    _ _   _ _____ _______ 
  --   / ____/ __ \| \ | |__   __|  __ \ / __ \| |      | |  | | \ | |_   _|__   __|
  --  | |   | |  | |  \| |  | |  | |__) | |  | | |      | |  | |  \| | | |    | |   
  --  | |   | |  | | . ` |  | |  |  _  /| |  | | |      | |  | | . ` | | |    | |   
  --  | |___| |__| | |\  |  | |  | | \ \| |__| | |____  | |__| | |\  |_| |_   | |   
  --   \_____\____/|_| \_|  |_|  |_|  \_\\____/|______|  \____/|_| \_|_____|  |_|   
  --                                                                                
  --                                                                                

  constant MICROCODE_MEM_SIZE : integer := 47;  -- Microcode Memory Size (27 Base)
  constant ALU_OPC_MEM_SIZE   : integer := 20;  -- AluOpcode Memory Size (9 per ora)
  constant IR_SIZE            : integer := 32;  -- Instruction Register Size
  constant OPCODE_SIZE        : integer := 6;   -- Op Code Size
  constant FUNC_SIZE          : integer := 11;  -- Func Field Size for R-Type Ops
  constant ALU_OPC_SIZE       : integer := 4;   -- ALU Op Code Word Size
  constant CW_SIZE            : integer := 31;  -- Control Word Size

  -- R-Type instructions -> OPCODE field
  constant RTYPE         : std_logic_vector(OPCODE_SIZE - 1 downto 0) := "000000";
  -- R-Type instructions -> FUNC field
  constant RTYPE_SLL     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000000100";  -- (Base) (0x04) SLL  RD,RS1,RS2
  constant RTYPE_SRL     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000000110";  -- (Base) (0x06) SRL  RD,RS1,RS2
  constant RTYPE_SRA     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000000111";  -- (0x07) SRA  RD,RS1,RS2
  constant RTYPE_ADD     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000100000";  -- (Base) (0x20) ADD  RD,RS1,RS2
  constant RTYPE_ADDU    : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000100001";  -- (0x21) ADDU RD,RS1,RS2
  constant RTYPE_SUB     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000100010";  -- (Base) (0x22) SUB  RD,RS1,RS2
  constant RTYPE_SUBU    : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000100011";  -- (0x23) SUBU RD,RS1,RS2
  constant RTYPE_AND     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000100100";  -- (Base) (0x24) AND  RD,RS1,RS2
  constant RTYPE_OR      : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000100101";  -- (Base) (0x25) OR   RD,RS1,RS2
  constant RTYPE_XOR     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000100110";  -- (Base) (0x26) XOR  RD,RS1,RS2
  constant RTYPE_SEQ     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000101000";  -- (0x28) SEQ  RD,RS1,RS2
  constant RTYPE_SNE     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000101001";  -- (Base) (0x29) SNE  RD,RS1,RS2
  constant RTYPE_SLT     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000101010";  -- (0x2A) SLT  RD,RS1,RS2
  constant RTYPE_SGT     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000101011";  -- (0x2B) SGT  RD,RS1,RS2
  constant RTYPE_SLE     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000101100";  -- (Base) (0x2C) SLE  RD,RS1,RS2
  constant RTYPE_SGE     : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000101101";  -- (Base) (0x2D) SGE  RD,RS,RS2
  constant RTYPE_MOVI2S  : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000110000";  -- (0x30) MOVI2S  RD,RS1,RS2
  constant RTYPE_MOVS2I  : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000110001";  -- (0x31) MOVS2I  RD,RS1,RS2
  constant RTYPE_MOVF    : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000110010";  -- (0x32) MOVF RD,RS1,RS2
  constant RTYPE_MOVD    : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000110011";  -- (0x33) MOVD RD,RS1,RS2
  constant RTYPE_MOVFP2I : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000110100";  -- (0x34) MOVFP2I RD,RS1,RS2
  constant RTYPE_MOVI2FP : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000110101";  -- (0x35) MOVI2FP RD,RS1,RS2
  constant RTYPE_MOVI2T  : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000110110";  -- (0x36) MOVI2T RD,RS1,RS2
  constant RTYPE_MOVT2I  : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000110111";  -- (0x37) MOVT2I RD,RS1,RS2
  constant RTYPE_SLTU    : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000111010";  -- (0x3A) SLTU RD,RS1,RS2
  constant RTYPE_SGTU    : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000111011";  -- (0x3B) SGTU RD,RS1,RS2
  constant RTYPE_SLEU    : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000111100";  -- (0x3C) SLEU RD,RS1,RS2
  constant RTYPE_SGEU    : std_logic_vector(FUNC_SIZE - 1 downto 0)   := "00000111101";  -- (0x3D) SGEU RD,RS1,RS2

  constant NOP : std_logic_vector(FUNC_SIZE - 1 downto 0) := "11111111111";  -- (Base) NOP

  -- I-Type instructions -> OPCODE Field
  constant ITYPE_BEQZ : std_logic_vector(OPCODE_SIZE-1 downto 0) := "000100";  -- (Base) (0x04) BEQZ
  constant ITYPE_BNEZ : std_logic_vector(OPCODE_SIZE-1 downto 0) := "000101";  -- (Base) (0x05) BNEZ

  constant ITYPE_ADDI : std_logic_vector(OPCODE_SIZE-1 downto 0) := "000001";  -- (Base) (0x08) ADDI
  constant ITYPE_SUBI : std_logic_vector(OPCODE_SIZE-1 downto 0) := "000010";  -- (Base) (0x0A) SUBI
  constant ITYPE_ANDI : std_logic_vector(OPCODE_SIZE-1 downto 0) := "000011";  -- (Base) (0x0C) ANDI
  constant ITYPE_ORI  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "000100";  -- (Base) (0x0D) ORI
  constant ITYPE_SLLI : std_logic_vector(OPCODE_SIZE-1 downto 0) := "010100";  -- (Base) (0x14) SLLI
  constant ITYPE_NOP  : std_logic_vector(OPCODE_SIZE-1 downto 0) := "010101";  -- (Base) (0x15) NOP
  constant ITYPE_SRLI : std_logic_vector(OPCODE_SIZE-1 downto 0) := "010110";  -- (Base) (0x16) SRLI
  constant ITYPE_SNEI : std_logic_vector(OPCODE_SIZE-1 downto 0) := "011001";  -- (Base) (0x19) SNEI
  constant ITYPE_SLEI : std_logic_vector(OPCODE_SIZE-1 downto 0) := "011101";  -- (Base) (0x1C) SLEI
  constant ITYPE_SGEI : std_logic_vector(OPCODE_SIZE-1 downto 0) := "011110";  -- (Base) (0x1D) SGEI
  constant ITYPE_LW   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "100011";  -- (Base) (0x23) LW
  constant ITYPE_SW   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "101011";  -- (Base) (0x2B) SW


  -- J-Type instructions -> OPCODE Field
  -- --> Jump, Jump & Link
  -- --> Trap and Return from exception
  constant ITYPE_J   : std_logic_vector(OPCODE_SIZE-1 downto 0) := "000010";  -- (Base) (0x02) J
  constant ITYPE_JAL : std_logic_vector(OPCODE_SIZE-1 downto 0) := "000011";  -- (Base) (0x03) JAL

  -- Control Word specific to the ALU component
  type aluOp is (
    ALU_SLL,
    ALU_SRL,
    ALU_ADD,
    ALU_SUB,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_NE,
    ALU_LE,
    ALU_GE,
    ALU_NOP
  );

end myTypes;

