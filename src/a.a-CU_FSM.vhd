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
    MICROCODE_MEM_SIZE : integer := 47;   -- Microcode Memory Size (27 base)
    ALU_OPC_MEM_SIZE   : integer := 46;    -- AluOpcode Memory Size (9 per ora)
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
    ALU_OPCODE        : out std_logic_vector(ALU_OPC_SIZE - 1 downto 0);  -- choose between implicit or explicit coding, like std_logic_vector(ALU_OPC_SIZE -1 downto 0);
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
    RF_WE      : out std_logic         -- Register File Write Enable
    );

end dlx_cu;


--------------------------------------------------------------------------------
-- Behavioral Architecture
--------------------------------------------------------------------------------

architecture dlx_cu_fsm of dlx_cu is

  signal OPCODE : std_logic_vector(OPCODE_SIZE - 1 downto 0);  -- OPCODE part of IR
  signal FUNC   : std_logic_vector(FUNC_SIZE - 1 downto 0);  -- Func part of IR when Rtype


  -- Each CW is retrieved from the cw_mem. The FSM simply changes the pointer to the cw_mem memory location
  type mem_array is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);
  type alu_mem_array is array (integer range 0 to ALU_OPC_MEM_SIZE - 1) of std_logic_vector(ALU_OPC_SIZE - 1 downto 0);

  signal cw_mem : mem_array := (
  "1010010110101001010010100011101",  -- R type
  "0000000000000000000000000000000",
  "1110110000011101010000000000110",  -- J (0X02) instruction encoding corresponds to the address to this ROM
  "1110111000110101010100101001001",  -- JAL to be filled
  "1110000000011101010000000000110",  -- BEQZ to be filled
  "1111000000011101010000000000110",  -- BNEZ
  "0000000000000000000000000000000",  -- BFPT
  "0000000000000000000000000000000",  -- BFPF
  "1010010101100110010010100011101",  -- ADDI
  "0000000000000000000000000000000",  -- ADDUI
  "1010010101100110011010100011101",  -- SUBI
  "0000000000000000000000000000000",
  "1010010101100010100010100011101",  -- ANDI
  "1010010101100010101010100011101",  -- ORI
  "1010010101100010110010100011101",  -- XORI
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "1010010101100010000010100011101",  -- SLLI
  "0000000000000000000000000000000",  -- NOP!!
  "1010010101100010001010100011101",  -- SRLI
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "1010010101100110111010100011101",  -- SNEI
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "1010010101100111000010100011101",  -- SLEI
  "1010010101100111001010100011101",  -- SGEI
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "1010010101100110010010100101011",  -- LW
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "1010010111000110010011010000110",  -- SW
  "0000000000000000000000000000000",
  "0000000000000000000000000000000",
  "0000000000000000000000000000000"
  );

  signal aluOpcode_mem : alu_mem_array := (  -- Indirizzata da FUNC
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",                                -- SLL
  "0000",
  "0001",                                -- SRL
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0000",
  "0010",                                -- ADD
  "0000",
  "0011",                                -- SUB
  "0000",
  "0100",                                -- AND
  "0101",                                -- OR
  "0110",                                -- XOR
  "0000",
  "0000",
  "0111",                                -- (S)NE
  "0000",
  "0000",
  "1000",                                -- (S)LE
  "1001"                                 -- (S)GE
  );

  signal cw0, cw1_current, cw1_next, cw2_current, cw2_next, cw3_current, cw3_next, cw4_current, cw4_next : std_logic_vector(CW_SIZE - 1 downto 0);  -- full control word read from cw_mem
  signal aluOpcode0, aluOpcode1_current, aluOpcode1_next, aluOpcode2_current, aluOpcode2_next : std_logic_vector(ALU_OPC_SIZE - 1 downto 0);  -- ALU OPCODE Control Word read from aluOpcode_mem

begin  -- dlx_cu_rtl

  -- OPCODE(5 downto 0) <= IR_IN(31 downto 26);
  -- FUNC(10 downto 0)  <= IR_IN(FUNC_SIZE - 1 downto 0);

  -- -- EXE-Stage: Generation of ALU OPCODE
  -- -- Questo processo decide solamente l'OPCODE/CW specifica dell'ALU,
  -- -- usato sia per R-TYPE (es. ADD) che per I-TYPE (es. ADDI)
  -- ALU_OP_CODE_P : process (OPCODE, FUNC)
  -- begin
  --   case OPCODE is
  --     -- If the instruction is of RTYPE...
  --     when RTYPE =>
  --       case FUNC is
  --         when RTYPE_ADD => aluOpcode_i <= ALU_ADD;  -- aluOpcode_i assume valori enumerati (numeri da 1 in poi?), 
  --         when RTYPE_SUB => aluOpcode_i <= ALU_SUB;  -- che useremo per puntare alla memoria della CW per l'ALU
  --         when RTYPE_AND => aluOpcode_i <= ALU_AND;
  --                                                    -- to be continued and filled with all the other instructions
  --         when others    => aluOpcode_i <= ALU_NOP;
  --       end case;

  --     -- If the instruction is of ITYPE...
  --     when ITYPE_ADDI1 => aluOpcode_i <= ALU_ADD;
  --     when ITYPE_SUBI1 => aluOpcode_i <= ALU_SUB;
  --     when ITYPE_ANDI1 => aluOpcode_i <= ALU_AND;
  --     when ITYPE_ORI1  => aluOpcode_i <= ALU_OR;

  --     when 3      => aluOpcode_i <= ALU_NOP;  -- jal
  --     when 8      => aluOpcode_i <= ALU_ADD;  -- addi
  --                                             -- to be continued and filled with other cases
  --     when others => aluOpcode_i <= ALU_NOP;
  --   end case;
  -- end process ALU_OP_CODE_P;


  -- -----------------------------------------------------
  -- -- FSM
  -- -- Stage progression and Jump/Branch exceptions are 
  -- -- handled here.
  -- -----------------------------------------------------
  -- P_currentState : process(currentState)
  -- begin
  --   case currentState is
  --     when RESET =>                             IF | OPCODE1 --> ID | OPCODE2 -->
  --       nextState <= IF_STAGE;
        
  --       Rst_ID_EXE  <= '0';
  --       Rst_EXE_MEM <= '0';
  --       Rst_MEM_WB  <= '0';
  --       -- cw0        <= cw_mem(to_integer(unsigned(OPCODE)));
  --     when IF_STAGE =>
  --       nextState <= ID_STAGE;
  --       cw        <= cw_mem(to_integer(unsigned(OPCODE)));
  --       cw1 <= cw(da bit 31 a bit 28);
  --       -- aluOpcode <= aluOpcode_mem(to_integer(unsigned(FUNC)));
  --     when ID_STAGE =>
  --       nextState <= EXE_STAGE;
  --       --cw2        <= cw_mem(to_integer(unsigned(OPCODE)));
  --       cw2 <= cw(da bit 27 a bit 25)
  --     when EXE_STAGE =>
  --       nextState <= MEM_STAGE;
  --       cw3        <= cw_mem(to_integer(unsigned(OPCODE)));
  --     when MEM_STAGE =>
  --       nextState <= WB_STAGE;
  --       cw4        <= cw_mem(to_integer(unsigned(OPCODE)));
  --     when WB_STAGE =>
  --       nextState <= IF_STAGE;
  --       cw5        <= cw_mem(to_integer(unsigned(OPCODE)));
  --   end case;
  -- end process P_currentState;

  -- --------------------------------------------------------------------------------
  -- -- Per ogni stage, andiamo ad assegnare solo i segnali relativi ad esso
  -- -- estraendoli dalla CW_mem
  -- --------------------------------------------------------------------------------
  -- P_OUTPUTS : process()
  -- begin
  --   -- IF-Stage Control Signals
  --   PC_LATCH_EN  <= cw1(CW_SIZE - 1);  -- 27
  --   NPC_LATCH_EN <= cw1(CW_SIZE - 2);
  --   IR_LATCH_EN  <= cw1(CW_SIZE - 3);

  --   -- ID-Stage Control Signals
  --   BRANCH_SEL         <= cw2(CW_SIZE - 4);
  --   JUMP_EN            <= cw2(CW_SIZE - 5);
  --   JUMP_SEL           <= cw2(CW_SIZE - 6);
  --   NPC_LATCH_EN_ID    <= cw2(CW_SIZE - 7);
  --   RegA_LATCH_EN_ID   <= cw2(CW_SIZE - 8);
  --   RegB_LATCH_EN_ID   <= cw2(CW_SIZE - 9);
  --   RegImm_LATCH_EN_ID <= cw2(CW_SIZE - 10);
  --   Rd_LATCH_EN_ID     <= cw2(CW_SIZE - 11);
  --   RegMux_SEL         <= cw2(CW_SIZE - 12 downto CW_SIZE - 13);
  --   Sign_SEL           <= cw2(CW_SIZE - 14);

    



  -- end process P_OUTPUTS;



  -- P_OPC : process(Clk, Rst_n)
  -- begin
  --   if Rst_n = '0' then                 -- Asynchronous Reset
  --     currentState <= RESET;
  --   elsif rising_edge(Clk) then
  --     currentState <= nextState;
  --   end if;
  -- end process P_OPC;

-- We retrieve the actual CW from the cw_mem, depending on the OPCODE pointer
  -- cw <= cw_mem(to_integer(unsigned(OPCODE)));
  -- aluOpcode <= aluOpcode_mem(to_integer(unsigned(FUNC)));
  
-- Questa parte sotto forse non è necessaria: possiamo farlo direttamente nel processo P_OUTPUTS
-- stage one control signals
--   IR_LATCH_EN  <= cw1(CW_SIZE - 1);
--   NPC_LATCH_EN <= cw1(CW_SIZE - 2);

-- -- stage two control signals
--   RegA_LATCH_EN_ID   <= cw2(CW_SIZE - 3);
--   RegB_LATCH_EN_ID   <= cw2(CW_SIZE - 4);
--   RegImm_LATCH_EN_ID <= cw2(CW_SIZE - 5);

-- -- stage three control signals
--   MUXA_SEL          <= cw3(CW_SIZE - 6);
--   MuxB_SEL          <= cw3(CW_SIZE - 7);
--   ALU_OUTREG_EN_EXE <= cw3(CW_SIZE - 8);
--   EQ_COND           <= cw3(CW_SIZE - 9);

-- -- stage four control signals
--   DRAM_WE      <= cw4(CW_SIZE - 10);
--   LMD_LATCH_EN <= cw4(CW_SIZE - 11);
--   JUMP_EN      <= cw4(CW_SIZE - 12);
--   PC_LATCH_EN  <= cw4(CW_SIZE - 13);

-- -- stage five control signals
--   WB_MUX_SEL <= cw5(CW_SIZE - 14);
--   RF_WE      <= cw5(CW_SIZE - 15);


cw_retrieve: process(rst_n, IR_IN)
begin

  if rst_n = '0' then
    cw0 <=  (others =>  '0');
  else
    
    if IR_IN(31 downto 26) = RTYPE then
      if (to_integer(unsigned(IR_IN(FUNC_SIZE - 1 downto 0))) >= 0 and to_integer(unsigned(IR_IN(FUNC_SIZE - 1 downto 0))) <= ALU_OPC_MEM_SIZE - 1) then
        aluOpcode0 <= aluOpcode_mem(to_integer(unsigned(IR_IN(FUNC_SIZE - 1 downto 0))));
      else
        -- TODO: STACCAH STACCAH (throw error)
      end if;
    else
      -- If I-Type, aluOpcode is hardcoded into CW (retrieved from CW_memory)
      aluOpcode0 <= (others => '1');
    end if;
    
    if (to_integer(unsigned(IR_IN(31 downto 26))) >= 0 and to_integer(unsigned(IR_IN(31 downto 26))) <= MICROCODE_MEM_SIZE - 1) then
      cw0 <= cw_mem(to_integer(unsigned(IR_IN(31 downto 26))));
    else
      -- TODO: STACCAH STACCAH (throw error)
    end if;
  end if;

end process cw_retrieve;

--------------------------------------------------------------------------------
-- IF
--------------------------------------------------------------------------------
IF_STAGE_proc: process(clk, rst_n)
begin

  if rst_n = '0' then
    Rst_IF_ID   <= '0';
    cw1_next <= (others => '0');
  else
    if rising_edge(clk) then
      cw1_current <=  cw1_next;
      aluOpcode1_current <= aluOpcode1_next;
    end if;
    -- Combinazionale
    -- IF-Stage Control Signals
    cw1_next <= cw0;
    aluOpcode1_next <= aluOpcode0;
    PC_LATCH_EN  <= cw0(CW_SIZE - 1);  -- 27
    NPC_LATCH_EN <= cw0(CW_SIZE - 2);
    IR_LATCH_EN  <= cw0(CW_SIZE - 3);
  end if;
  
end process IF_STAGE_proc;


--------------------------------------------------------------------------------
-- ID
--------------------------------------------------------------------------------
ID_STAGE_proc: process(clk, rst_n, cw1_current, aluOpcode1_current)
begin

  if rst_n = '0' then
    Rst_ID_EXE   <= '0';
    cw2_next <= (others => '0');
  else
    if rising_edge(clk) then
      cw2_current <= cw2_next;
      aluOpcode2_current <= aluOpcode2_next;
    end if;
    -- Combinazionale
    -- ID-Stage Control Signals
    cw2_next <=  cw1_current;
    aluOpcode2_next <= aluOpcode1_current;
    BRANCH_SEL         <= cw1_current(CW_SIZE - 4);
    JUMP_EN            <= cw1_current(CW_SIZE - 5);
    JUMP_SEL           <= cw1_current(CW_SIZE - 6);
    NPC_LATCH_EN_ID    <= cw1_current(CW_SIZE - 7);
    RegA_LATCH_EN_ID   <= cw1_current(CW_SIZE - 8);
    RegB_LATCH_EN_ID   <= cw1_current(CW_SIZE - 9);
    RegImm_LATCH_EN_ID <= cw1_current(CW_SIZE - 10);
    Rd_LATCH_EN_ID     <= cw1_current(CW_SIZE - 11);
    RegMux_SEL         <= cw1_current(CW_SIZE - 12 downto CW_SIZE - 13);
    Sign_SEL           <= cw1_current(CW_SIZE - 14);
    
  end if;

end process ID_STAGE_proc;


--------------------------------------------------------------------------------
-- EXE
--------------------------------------------------------------------------------
EXE_STAGE_proc: process(clk, rst_n, cw2_current, aluOpcode2_current)
begin

  if rst_n = '0' then
    Rst_EXE_MEM   <= '0';
    cw3_next <= (others => '0');
  else
    if rising_edge(clk) then
      cw3_current <= cw3_next;
    end if;

    -- Combinazionale
    -- EXE-Stage Control Signals
    cw3_next <= cw2_current;
    MuxB_SEL          <= cw2_current(CW_SIZE - 15);
    -- Alu Operation Code
    if aluOpcode2_current = "1111" then
      ALU_OPCODE <= cw2_current(CW_SIZE - 16 downto CW_SIZE - 19);
    else
      ALU_OPCODE <= aluOpcode2_current;
    end if;
    NPC_LATCH_EN_EXE  <= cw2_current(CW_SIZE - 20);
    ALU_OUTREG_EN_EXE <= cw2_current(CW_SIZE - 21);
    RegB_LATCH_EN_EXE <= cw2_current(CW_SIZE - 22);
    RD_LATCH_EN_EXE   <= cw2_current(CW_SIZE - 23);
  end if;
  
end process EXE_STAGE_proc;


--------------------------------------------------------------------------------
-- MEM
--------------------------------------------------------------------------------
MEM_STAGE_proc: process(clk, rst_n, cw3_current)
begin

  if rst_n = '0' then
    Rst_MEM_WB   <= '0';
    cw4_next <= (others => '0');
  else
    if rising_edge(clk) then
      cw4_current <= cw4_next;
    end if;

    -- Combinazionale
    -- MEM-Stage Control Signals
    cw4_next <= cw3_current;
    DRAM_WE           <= cw3_current(CW_SIZE - 24);
    NPC_LATCH_EN_MEM  <= cw3_current(CW_SIZE - 25);
    LMD_LATCH_EN      <= cw3_current(CW_SIZE - 26);
    ALU_OUTREG_EN_MEM <= cw3_current(CW_SIZE - 27);
    RD_LATCH_EN_MEM   <= cw3_current(CW_SIZE - 28);
        
  end if;
  
end process MEM_STAGE_proc;

--------------------------------------------------------------------------------
-- WB
--------------------------------------------------------------------------------
WB_STAGE_proc: process(clk, rst_n, cw4_current)
begin

  if rst_n = '0' then
    
  else
    if rising_edge(clk) then
    end if;

    -- Combinazionale
    -- WB Control signals
    WB_MUX_SEL <= cw4_current(CW_SIZE - 29 downto CW_SIZE - 30);
    RF_WE      <= cw4_current(CW_SIZE - 31);
  end if;
  
end process WB_STAGE_proc;

end dlx_cu_fsm;
