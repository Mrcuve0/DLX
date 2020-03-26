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
    MICROCODE_MEM_SIZE : integer := 30;   -- Microcode Memory Size (27 base)
    ALU_OPC_MEM_SIZE   : integer := 9;    -- AluOpcode Memory Size (9 per ora)
    IR_SIZE            : integer := 32;   -- Instruction Register Size
    OPCODE_SIZE        : integer := 6;    -- Op Code Size
    FUNC_SIZE          : integer := 11;   -- Func Field Size for R-Type Ops
    ALU_OPC_SIZE       : integer := 4;    -- ALU Op Code Word Size
    CW_SIZE            : integer := 31);  -- Control Word Size (CWs + ALUOPCODE)

  port (
    Clk   : in std_logic;               -- Clock
    Rst_n : in std_logic;               -- Reset:Active-Low

    -- Rst-PipeRegisters Control Signals
    Rst_IF_ID   : out std_logic;
    Rst_ID_EXE  : out std_logic;
    Rst_EXE_MEM : out std_logic;
    Rst_MEM_WB  : out std_logic;

    -- IR Input (from DataPath)
    IR_IN : in std_logic_vector(IR_SIZE - 1 downto 0);

    -- IF-Stage Control Signals
    PC_LATCH_EN  : out std_logic;       -- Program Counter Latch Enable
    NPC_LATCH_EN : out std_logic;       -- NextProgramCounter Latch Enable
    IR_LATCH_EN  : out std_logic;       -- Instruction Register Latch Enable

    -- ID-Stage Control Signals
    BRANCH_SEL         : out std_logic;
    JUMP_EN            : out std_logic;
    JUMP_SEL           : out std_logic;
    NPC_LATCH_EN_ID    : out std_logic;
    RegA_LATCH_EN_ID   : out std_logic;  -- Register A Latch Enable
    RegB_LATCH_EN_ID   : out std_logic;  -- Register B Latch Enable
    RegImm_LATCH_EN_ID : out std_logic;  -- Immediate Register Latch Enable
    Rd_LATCH_EN_ID     : out std_logic;
    RegMux_SEL         : out std_logic_vector(1 downto 0);
    Sign_SEL           : out std_logic;

    -- EX-Stage Control Signals
    MuxB_SEL          : out std_logic;  -- MUX-B Sel
    -- Alu Operation Code
    ALU_OPCODE        : out aluOp;  -- choose between implicit or explicit coding, like std_logic_vector(ALU_OPC_SIZE -1 downto 0);
    NPC_LATCH_EN_EXE  : out std_logic;
    ALU_OUTREG_EN_EXE : out std_logic;  -- ALU Output Register Enable
    RegB_LATCH_EN_EXE : out std_logic;
    RD_LATCH_EN_EXE   : out std_logic;

    -- MEM-Stage Control Signals
    DRAM_WE           : out std_logic;  -- Data RAM Write Enable
    NPC_LATCH_EN_MEM  : out std_logic;
    LMD_LATCH_EN      : out std_logic;  -- LMD Register Latch Enable
    ALU_OUTREG_EN_MEM : out std_logic;
    RD_LATCH_EN_MEM   : out std_logic;

    -- WB Control signals
    WB_MUX_SEL : out std_logic_vector(1 downto 0);  -- Write Back MUX Sel
    RF_WE      : out std_logic;         -- Register File Write Enable
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


  signal OPCODE : std_logic_vector(OPCODE_SIZE - 1 downto 0);  -- OPCODE part of IR
  signal FUNC   : std_logic_vector(FUNC_SIZE - 1 downto 0);  -- Func part of IR when Rtype


  -- Each CW is retrieved from the cw_mem. The FSM simply changes the pointer to the cw_mem memory location
  type mem_array is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);
  type alu_mem_array is array (integer range 0 to ALU_OPC_MEM_SIZE - 1) of std_logic_vector(ALU_OPC_SIZE - 1 downto 0);

  signal cw_mem : mem_array := (
    "111100010000111",  -- R-type: (Da cambiare, ho riordinato i control signals per stage di appartenenza)
    "000000000000000",
    "111011111001100",  -- J (0X02) instruction encoding corresponds to the address to this ROM
    "000000000000000",                  -- JAL to be filled
    "000000000000000",                  -- BEQZ to be filled
    "000000000000000",                  -- BNEZ
    "000000000000000",                  --
    "000000000000000",
    "000000000000000",                  -- ADD i (0X08): FILL IT!!!
    "000000000000000");  -- to be completed (enlarged and filled)

  type aluOpcode_mem : alu_mem_array := (  -- Indirizzata da FUNC
    "0000",                                -- SLL
    "0001",                                -- SRL
    "0010",                                -- ADD
    "0011",                                -- SUB
    "0100",                                -- AND
    "0101",                                -- OR
    "0110",                                -- XOR
    "0111",                                -- NE
    "1000",                                -- LE
    "1001",                                -- GE
    )

                                        signal cw : std_logic_vector(CW_SIZE - 1 downto 0);  -- full control word read from cw_mem
  signal aluOpcode : std_logic_vector(ALU_OPC_SIZE -1 downto 0);  -- ALU OPCODE Control Word read from aluOpcode_mem

begin  -- dlx_cu_rtl

  OPCODE(5 downto 0) <= IR_IN(31 downto 26);
  FUNC(10 downto 0)  <= IR_IN(FUNC_SIZE - 1 downto 0);

  -- EXE-Stage: Generation of ALU OPCODE
  -- Questo processo decide solamente l'OPCODE/CW specifica dell'ALU,
  -- usato sia per R-TYPE (es. ADD) che per I-TYPE (es. ADDI)
  ALU_OP_CODE_P : process (OPCODE, FUNC)
  begin
    case OPCODE is
      -- If the instruction is of RTYPE...
      when RTYPE =>
        case FUNC is
          when RTYPE_ADD => aluOpcode_i <= ALU_ADD;  -- aluOpcode_i assume valori enumerati (numeri da 1 in poi?), 
          when RTYPE_SUB => aluOpcode_i <= ALU_SUB;  -- che useremo per puntare alla memoria della CW per l'ALU
          when RTYPE_AND => aluOpcode_i <= ALU_AND;
                                                     -- to be continued and filled with all the other instructions
          when others    => aluOpcode_i <= ALU_NOP;
        end case;

      -- If the instruction is of ITYPE...
      when ITYPE_ADDI1 => aluOpcode_i <= ALU_ADD;
      when ITYPE_SUBI1 => aluOpcode_i <= ALU_SUB;
      when ITYPE_ANDI1 => aluOpcode_i <= ALU_AND;
      when ITYPE_ORI1  => aluOpcode_i <= ALU_OR;

      when 3      => aluOpcode_i <= ALU_NOP;  -- jal
      when 8      => aluOpcode_i <= ALU_ADD;  -- addi
                                              -- to be continued and filled with other cases
      when others => aluOpcode_i <= ALU_NOP;
    end case;
  end process ALU_OP_CODE_P;


  -----------------------------------------------------
  -- FSM
  -- Stage progression and Jump/Branch exceptions are 
  -- handled here.
  -----------------------------------------------------
  P_currentState : process(currentState, OPCODE)
  begin
    case currentState is
      when RESET =>
        nextState <= IF_STAGE;
        cw        <= cw_mem(OPCODE);
      when IF_STAGE =>
        nextState <= ID_STAGE;
        cw        <= cw_mem(OPCODE);
      when ID_STAGE =>
        nextState <= EXE_STAGE;
        cw        <= cw_mem(OPCODE);
      when EXE_STAGE =>
        nextState <= MEM_STAGE;
        cw        <= cw_mem(OPCODE);
      when MEM_STAGE =>
        nextState <= WB_STAGE;
        cw        <= cw_mem(OPCODE);
      when WB_STAGE =>
        nextState <= IF_STAGE;
        cw        <= cw_mem(OPCODE);
    end case;
  end process P_currentState;

  --------------------------------------------------------------------------------
  -- Per ogni stage, andiamo ad assegnare solo i segnali relativi ad esso
  -- estraendoli dalla CW_mem
  --------------------------------------------------------------------------------
  P_OUTPUTS : process(currentState, OPCODE, FUNC)
  begin
    case currentState is
      when RESET =>
        Rst_IF_ID   <= '0';
        Rst_ID_EXE  <= '0';
        Rst_EXE_MEM <= '0';
        Rst_MEM_WB  <= '0';

      when IF_STAGE =>
        -- IF-Stage Control Signals
        PC_LATCH_EN  <= cw(CW_SIZE - 1);  -- 27
        NPC_LATCH_EN <= cw(CW_SIZE - 2);
        IR_LATCH_EN  <= cw(CW_SIZE - 3);
      when ID_STAGE =>
        -- ID-Stage Control Signals
        BRANCH_SEL         <= cw(CW_SIZE - 4);
        JUMP_EN            <= cw(CW_SIZE - 5);
        JUMP_SEL           <= cw(CW_SIZE - 6);
        NPC_LATCH_EN_ID    <= cw(CW_SIZE - 7);
        RegA_LATCH_EN_ID   <= cw(CW_SIZE - 8);
        RegB_LATCH_EN_ID   <= cw(CW_SIZE - 9);
        RegImm_LATCH_EN_ID <= cw(CW_SIZE - 10);
        Rd_LATCH_EN_ID     <= cw(CW_SIZE - 11);
        RegMux_SEL         <= cw(CW_SIZE - 12 downto CW_SIZE - 13);
        Sign_SEL           <= cw(CW_SIZE - 14);
      when EXE_STAGE =>
        -- EX-Stage Control Signals
        MuxB_SEL          <= cw(CW_SIZE - 15);
        -- Alu Operation Code
        if OPCODE = RTYPE then
          ALU_OPCODE <= aluOpcode;
        else
          ALU_OPCODE <= cw(CW_SIZE - 16 downto CW_SIZE - 19);
        end if;
        NPC_LATCH_EN_EXE  <= cw(CW_SIZE - 20);
        ALU_OUTREG_EN_EXE <= cw(CW_SIZE - 21);
        RegB_LATCH_EN_EXE <= cw(CW_SIZE - 22);
        RD_LATCH_EN_EXE   <= cw(CW_SIZE - 23);
      when MEM_STAGE =>
        -- MEM-Stage Control Signals
        DRAM_WE           <= cw(CW_SIZE - 24);
        NPC_LATCH_EN_MEM  <= cw(CW_SIZE - 25);
        LMD_LATCH_EN      <= cw(CW_SIZE - 26);
        ALU_OUTREG_EN_MEM <= cw(CW_SIZE - 27);
        RD_LATCH_EN_MEM   <= cw(CW_SIZE - 28);
      when WB_STAGE =>
        -- WB Control signals
        WB_MUX_SEL <= cw(CW_SIZE - 29 downto CW_SIZE - 30);
        RF_WE      <= cw(CW_SIZE - 31);

      when others =>
        Rst_IF_ID   <= '0';
        Rst_ID_EXE  <= '0';
        Rst_EXE_MEM <= '0';
        Rst_MEM_WB  <= '0';
    end case;
  end process P_OUTPUTS;



  P_OPC : process(Clk, Rst_n)
  begin
    if Rst_n = '0' then                 -- Asynchronous Reset
      currentState <= RESET;
    elsif rising_edge(Clk) then
      currentState <= currentState;
    end if;
  end process P_OPC;

-- We retrieve the actual CW from the cw_mem, depending on the OPCODE pointer
  cw <= cw_mem(to_integer(unsigned(OPCODE)));
  aluOpcode <= aluOpcode_mem(to_integer(unsigned(FUNC)));
  
-- Questa parte sotto forse non è necessaria: possiamo farlo direttamente nel processo P_OUTPUTS
-- stage one control signals
  IR_LATCH_EN  <= cw1(CW_SIZE - 1);
  NPC_LATCH_EN <= cw1(CW_SIZE - 2);

-- stage two control signals
  RegA_LATCH_EN_ID   <= cw2(CW_SIZE - 3);
  RegB_LATCH_EN_ID   <= cw2(CW_SIZE - 4);
  RegImm_LATCH_EN_ID <= cw2(CW_SIZE - 5);

-- stage three control signals
  MUXA_SEL          <= cw3(CW_SIZE - 6);
  MuxB_SEL          <= cw3(CW_SIZE - 7);
  ALU_OUTREG_EN_EXE <= cw3(CW_SIZE - 8);
  EQ_COND           <= cw3(CW_SIZE - 9);

-- stage four control signals
  DRAM_WE      <= cw4(CW_SIZE - 10);
  LMD_LATCH_EN <= cw4(CW_SIZE - 11);
  JUMP_EN      <= cw4(CW_SIZE - 12);
  PC_LATCH_EN  <= cw4(CW_SIZE - 13);

-- stage five control signals
  WB_MUX_SEL <= cw5(CW_SIZE - 14);
  RF_WE      <= cw5(CW_SIZE - 15);

end dlx_cu_fsm;
