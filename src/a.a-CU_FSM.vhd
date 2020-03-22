library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.myTypes.all;

--------------------------------------------------------------------------------
-- Definition of the FSM based Control Unit
-- The FSM reflects the 5 different stages of the datapath:
-- Reset, IF-Stage, ID-Stage, EXE-Stage, MEM-Stage, WB-Stage
--------------------------------------------------------------------------------

entity dlx_cu is
  generic (
    MICROCODE_MEM_SIZE : integer := 10;   -- Microcode Memory Size
    FUNC_SIZE          : integer := 11;   -- Func Field Size for R-Type Ops
    OPCODE_SIZE        : integer := 6;    -- Op Code Size
    -- ALU_OPC_SIZE       :     integer := 6; -- ALU Op Code Word Size
    IR_SIZE            : integer := 32;   -- Instruction Register Size
    CW_SIZE            : integer := 15);  -- Control Word Size

  port (
    Clk : in std_logic;                 -- Clock
    Rst : in std_logic;                 -- Reset:Active-Low

    -- IR Input (from DataPath)
    IR_IN : in std_logic_vector(IR_SIZE - 1 downto 0);

    -- IF-Stage Control Signal
    IR_LATCH_EN  : out std_logic;       -- Instruction Register Latch Enable
    NPC_LATCH_EN : out std_logic;  -- NextProgramCounter Register Latch Enable
    PC_LATCH_EN  : out std_logic;       -- Program Counte Latch Enable

    -- ID-Stage Control Signals
    RF_WE           : out std_logic;    -- Register File Write Enable
    RegA_LATCH_EN   : out std_logic;    -- Register A Latch Enable
    RegB_LATCH_EN   : out std_logic;    -- Register B Latch Enable
    RegIMM_LATCH_EN : out std_logic;    -- Immediate Register Latch Enable

    -- EX-Stage Control Signals
    MUXA_SEL      : out std_logic;      -- MUX-A Sel
    MUXB_SEL      : out std_logic;      -- MUX-B Sel
    -- Alu Operation Code
    ALU_OPCODE    : out aluOp;  -- choose between implicit or explicit coding, like std_logic_vector(ALU_OPC_SIZE -1 downto 0);
    ALU_OUTREG_EN : out std_logic;      -- ALU Output Register Enable
    EQ_COND       : out std_logic;      -- Branch if (not) Equal to Zero

    -- MEM Control Signals
    DRAM_WE      : out std_logic;       -- Data RAM Write Enable
    LMD_LATCH_EN : out std_logic;       -- LMD Register Latch Enable
    JUMP_EN      : out std_logic;       -- JUMP Enable Signal for PC input MUX

    -- WB Control signals
    WB_MUX_SEL : out std_logic          -- Write Back MUX Sel
    );

end dlx_cu;


--------------------------------------------------------------------------------
-- Behavioral Architecture
--------------------------------------------------------------------------------

architecture dlx_cu_fsm of dlx_cu is

  type stateType is (
    RESET, IF_STAGE, ID_STAGE, EXE_STAGE, MEM_STAGE, WB_STAGE
    );

  signal currentState : stateType := RESET;
  signal nextState    : stateType := IF_STAGE;


  signal OPCODE : std_logic_vector(OPCODE_SIZE - 1 downto 0);  -- OpCode part of IR
  signal FUNC   : std_logic_vector(FUNC_SIZE downto 0);  -- Func part of IR when Rtype


  -- Each CW is retrieved from the cw_mem. The FSM simply changes the pointer to the cw_mem memory location
  type mem_array is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);
  signal cw_mem_IF_STAGE : mem_array := (
  "111100010000111",  -- R type: IS IT CORRECT?
  "000000000000000",
  "111011111001100",  -- J (0X02) instruction encoding corresponds to the address to this ROM
  "000000000000000",  -- JAL to be filled
  "000000000000000",  -- BEQZ to be filled
  "000000000000000",  -- BNEZ
  "000000000000000",  --
  "000000000000000",
  "000000000000000",  -- ADD i (0X08): FILL IT!!!
  "000000000000000");  -- to be completed (enlarged and filled)

  signal cw_mem_ID_STAGE : mem_array := (
  "111100010000111",  -- R type: IS IT CORRECT?
  "000000000000000",
  "111011111001100",  -- J (0X02) instruction encoding corresponds to the address to this ROM
  "000000000000000",  -- JAL to be filled
  "000000000000000",  -- BEQZ to be filled
  "000000000000000",  -- BNEZ
  "000000000000000",  --
  "000000000000000",
  "000000000000000",  -- ADD i (0X08): FILL IT!!!
  "000000000000000");  -- to be completed (enlarged and filled)

  signal cw_mem_EXE_STAGE : mem_array := (
  "111100010000111",  -- R type: IS IT CORRECT?
  "000000000000000",
  "111011111001100",  -- J (0X02) instruction encoding corresponds to the address to this ROM
  "000000000000000",  -- JAL to be filled
  "000000000000000",  -- BEQZ to be filled
  "000000000000000",  -- BNEZ
  "000000000000000",  --
  "000000000000000",
  "000000000000000",  -- ADD i (0X08): FILL IT!!!
  "000000000000000");  -- to be completed (enlarged and filled)

  signal cw_mem_MEM_STAGE : mem_array := (
  "111100010000111",  -- R type: IS IT CORRECT?
  "000000000000000",
  "111011111001100",  -- J (0X02) instruction encoding corresponds to the address to this ROM
  "000000000000000",  -- JAL to be filled
  "000000000000000",  -- BEQZ to be filled
  "000000000000000",  -- BNEZ
  "000000000000000",  --
  "000000000000000",
  "000000000000000",  -- ADD i (0X08): FILL IT!!!
  "000000000000000");  -- to be completed (enlarged and filled)

  signal cw_mem_WB_STAGE : mem_array := (
  "111100010000111",  -- R type: IS IT CORRECT?
  "000000000000000",
  "111011111001100",  -- J (0X02) instruction encoding corresponds to the address to this ROM
  "000000000000000",  -- JAL to be filled
  "000000000000000",  -- BEQZ to be filled
  "000000000000000",  -- BNEZ
  "000000000000000",  --
  "000000000000000",
  "000000000000000",  -- ADD i (0X08): FILL IT!!!
  "000000000000000");  -- to be completed (enlarged and filled)

  signal cw_IF_STAGE : std_logic_vector(CW_SIZE - 1 downto 0);  -- full control word read from cw_mem
  signal cw_ID_STAGE : std_logic_vector(CW_SIZE - 1 downto 0);  -- full control word read from cw_mem
  signal cw_EXE_STAGE : std_logic_vector(CW_SIZE - 1 downto 0);  -- full control word read from cw_mem
  signal cw_MEM_STAGE : std_logic_vector(CW_SIZE - 1 downto 0);  -- full control word read from cw_mem
  signal cw_WB_STAGE : std_logic_vector(CW_SIZE - 1 downto 0);  -- full control word read from cw_mem

  -- signal aluOpcode_i : std_logic_vector(ALU_OPC_SIZE - 1 downto 0);
  signal aluOpcode_i : aluOp;

begin  -- dlx_cu_rtl

  OPCODE(5 downto 0) <= IR_IN(31 downto 26);
  FUNC(10 downto 0)  <= IR_IN(FUNC_SIZE - 1 downto 0);

  -- EXE-Stage: Generation of ALU OpCode
  ALU_OP_CODE_P : process (OPCODE, FUNC)
  begin
    case OPCODE is
      -- If the instruction is of RTYPE...
      when RTYPE =>
        case FUNC is
          when RTYPE_ADD => aluOpcode_i <= ALU_ADD;
          when RTYPE_SUB => aluOpcode_i <= ALU_SUB;
          when RTYPE_AND => aluOpcode_i <= ALU_AND;
                                        -- to be continued and filled with all the other instructions
          when others    => aluOpcode_i <= ALU_NOP;
        end case;

      -- If the instruction is of ITYPE...
      when ITYPE_ADDI1 => aluOpcode_i <= ALU_ADD;
      when ITYPE_SUBI1 => aluOpcode_i <= ALU_SUB;
      when ITYPE_ANDI1 => aluOpcode_i <= ALU_AND;
      when ITYPE_ORI1  => aluOpcode_i <= ALU_OR;

      -- TODO: Non posso, magari, mergiare ADDI1 con ADDI2 e così via? In modo da indicare solo una volta,
      -- tanto l'operazione alu è sempre la stessa...
      when ITYPE_ADDI2 => aluOpcode_i <= ALU_ADD;
      when ITYPE_SUBI2 => aluOpcode_i <= ALU_SUB;
      when ITYPE_ANDI2 => aluOpcode_i <= ALU_AND;
      when ITYPE_ORI2  => aluOpcode_i <= ALU_OR;


      when 3      => aluOpcode_i <= ALU_NOP;  -- jal
      when 8      => aluOpcode_i <= ALU_ADD;  -- addi
                                              -- to be continued and filled with other cases
      when others => aluOpcode_i <= ALU_NOP;
    end case;
  end process ALU_OP_CODE_P;


  -----------------------------------------------------
  -- FSM
  -- This is a very simplified starting point for a fsm
  -- up to you to complete it and to improve it
  -----------------------------------------------------
  P_currentState : process(currentState, OpCode)
  begin
    --currentState <= currentState;
    case currentState is
      when RESET =>
        nextState <= IF_STAGE;

      when IF_STAGE =>
      -- if OPCODE = to BE COMPLETED!!! then
      --currentState <= ID_STAGE;
      --elsif
            ----
                  ----
                        ----
      --end if;
      when ID_STAGE =>
      when EXE_STAGE =>
      when MEM_STAGE =>
      when WB_STAGE =>

      --- TO BE COMPLETED

    end case;
  end process P_currentState;


-- Depending on the current stage of the FSM, set the
  P_OUTPUTS : process(currentState)
  begin
    case currentState is
      when RESET =>

        nextState <= IF_STAGE;

      when IF_STAGE =>

      -- when ID_STAGE => cw <= to BE COMPLETED
            -- TO BE COMPLETED
                  --
                        --
                              --
      when others => cw <= "000000000000000";  -- error
    end case;
  end process P_OUTPUTS;



  P_OPC : process(Clk, Rst)
  begin
    if Rst = '0' then                   -- Asynchronous Reset
      currentState <= RESET;
    elsif rising_edge(Clk) then
      currentState <= currentState;
    end if;
  end process P_OPC;

-- We retrieve the actual CW from the cw_mem, depending on the OPCODE pointer
  cw <= cw_mem(to_integer(unsigned(OPCODE)));


-- stage one control signals
  IR_LATCH_EN  <= cw1(CW_SIZE - 1);
  NPC_LATCH_EN <= cw1(CW_SIZE - 2);

-- stage two control signals
  RegA_LATCH_EN   <= cw2(CW_SIZE - 3);
  RegB_LATCH_EN   <= cw2(CW_SIZE - 4);
  RegIMM_LATCH_EN <= cw2(CW_SIZE - 5);

-- stage three control signals
  MUXA_SEL      <= cw3(CW_SIZE - 6);
  MUXB_SEL      <= cw3(CW_SIZE - 7);
  ALU_OUTREG_EN <= cw3(CW_SIZE - 8);
  EQ_COND       <= cw3(CW_SIZE - 9);

-- stage four control signals
  DRAM_WE      <= cw4(CW_SIZE - 10);
  LMD_LATCH_EN <= cw4(CW_SIZE - 11);
  JUMP_EN      <= cw4(CW_SIZE - 12);
  PC_LATCH_EN  <= cw4(CW_SIZE - 13);

-- stage five control signals
  WB_MUX_SEL <= cw5(CW_SIZE - 14);
  RF_WE      <= cw5(CW_SIZE - 15);

end dlx_cu_fsm;
