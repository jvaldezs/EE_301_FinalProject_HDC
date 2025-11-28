--------------------------------------------------------------------------------
-- File: Inference_Top.vhd
-- Author: 
-- Date: November 11, 2025
-- Description: Top-level module for hypervector inference system
--              Connects all components: BIT_SELECT, RAMs, HAMM modules, 
--              Controller, and Guess output
-- 
-- Revision History:
-- Date          Version     Description
-- 11/11/2025    1.0         Initial creation
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Inference_Top is
    port(
        clk         : in  STD_LOGIC; -- System clock
        reset       : in  STD_LOGIC; -- System reset
        start       : in  STD_LOGIC; -- Start inference process
        
        -- Output
        Guess_out   : out STD_LOGIC_VECTOR(4 downto 0); -- Final classification (0-25)
        Done        : out STD_LOGIC;  -- Inference complete signal
        TestHV_done : out STD_LOGIC;  -- Signals when all TestHVs have been processed
        Current_bit_addr : out std_logic_vector(7 downto 0);  -- Current bit address being processed
        current_class_addr : out std_logic_vector(4 downto 0);  -- Current class address being processed
        current_testHV_addr : out std_logic_vector(6 downto 0);  -- Current TestHV address being processed
        hamm_sum_out : out std_logic_vector(13 downto 0)  -- Current Hamming distance accumulator output
    );
end Inference_Top;

architecture Structural of Inference_Top is
    
    -- Component Declarations
    component BIT_SELECT is
        port(
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            enable   : in  STD_LOGIC;
            ClassHV  : out std_logic_vector(4 downto 0);
            TestHV   : out std_logic_vector(6 downto 0);
            bit_addr : out std_logic_vector(7 downto 0);
            ClassHV_done : out std_logic;
            TestHV_done : out std_logic;
            Done     : out std_logic
        );
    end component;
    
    component ClassHV_RAM is
        port(
            class_select : in  std_logic_vector(4 downto 0);
            bit_addr     : in  std_logic_vector(7 downto 0);
            RAM_CLOCK    : in  std_logic;
            RAM_EN       : in  std_logic;
            reset        : in  std_logic;
            RAM_DATA_OUT : out std_logic_vector(1023 downto 0);
            CLASS_OUT    : out std_logic_vector(4 downto 0)
            
        );
    end component;
    
    component TestHV_RAM is
        port(
            clk          : in  std_logic;
            reset        : in  std_logic;
            TestHV_addr  : in  std_logic_vector(6 downto 0);
            bit_addr     : in  std_logic_vector(7 downto 0);           
            Read_en      : in  std_logic;
            data_out     : out std_logic_vector(1023 downto 0)
            
        );
    end component;
    
    component HAMM_accumulator is
        port(
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            Load      : in  STD_LOGIC;
            ClassHV_Done : in  STD_LOGIC;
            A_data_in : in  STD_LOGIC_VECTOR(1023 downto 0);
            B_data_in : in  STD_LOGIC_VECTOR(1023 downto 0);
            sum_out   : out STD_LOGIC_VECTOR(13 downto 0)
        );
    end component;
    
    component Hamm_MAX is
        port(
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            Load     : in  STD_LOGIC;
            TestHV_Done : in  STD_LOGIC;
            data_in  : in  STD_LOGIC_VECTOR(13 downto 0);
            sum_out  : out STD_LOGIC_VECTOR(13 downto 0);
            new_max  : out STD_LOGIC
        );
    end component;
    
    component Guess_compile is
        port(
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            TestHV_Done : in  STD_LOGIC;
            new_max  : in  STD_LOGIC;
            Class_in : in  std_logic_vector(4 downto 0);
            Guess_out: out std_logic_vector(4 downto 0)
        );
    end component;
    
    component Controller is
        port(
            clk                       : in  std_logic;
            reset                     : in  std_logic;
            start                     : in  std_logic;           
            RAM_EN                    : out std_logic;
            inference_done            : out  std_logic
 
        );
    end component;
    
    -- Internal Signals
    
    -- BIT_SELECT outputs
    signal ClassHV_addr  : std_logic_vector(4 downto 0);
    signal TestHV_addr_sig   : std_logic_vector(6 downto 0);
    signal bit_addr_sig      : std_logic_vector(7 downto 0);
    signal INF_Done_sig  : std_logic;
    signal ClassHV_Done_sig : std_logic;
    signal TestHV_Done_sig : std_logic;
    
    -- RAM outputs
    signal ClassHV_bit   : std_logic_vector(1023 downto 0);
    signal TestHV_bit    : std_logic_vector(1023 downto 0);
    signal class_out_sig : std_logic_vector(4 downto 0);
    
    
    -- HAMM accumulator signals
    signal hamm_sum      : std_logic_vector(13 downto 0);
    
    -- HAMM MAX signals
    signal max_sum       : std_logic_vector(13 downto 0);
    signal new_max_sig   : std_logic;
    
    -- Controller signals

    signal RAM_EN_sig             : std_logic;
    
    --Guess signal
    signal guess_out_sig : std_logic_vector(4 downto 0) ;
  
    
begin
    
    -- Instantiate BIT_SELECT
    U_BIT_SELECT: BIT_SELECT
        port map(
            clk      => clk,--==============================
            reset    => reset,--inputs
            enable   => RAM_EN_sig,--============================
            ClassHV  => ClassHV_addr,--===========================
            TestHV   => TestHV_addr_sig,--outputs
            bit_addr => bit_addr_sig,
            ClassHV_done => ClassHV_Done_sig,--=========================
            TestHV_done => TestHV_Done_sig,--=========================
            Done     => INF_Done_sig--=========================
        );
    
    -- Instantiate ClassHV_RAM
    U_ClassHV_RAM: ClassHV_RAM
        port map(
            class_select => ClassHV_addr,--=========================
            bit_addr     => bit_addr_sig,-- inputs
            RAM_CLOCK    => clk,
            reset        => reset,
            RAM_EN       => RAM_EN_sig,--=========================
           --=========================
            RAM_DATA_OUT => ClassHV_bit,-- outputs
            CLASS_OUT    => class_out_sig--=========================
        );
    
    -- Instantiate TestHV_RAM
    U_TestHV_RAM: TestHV_RAM
        port map(
            clk          => clk,--==============================
            reset        => reset,--inputs
            read_en      => RAM_EN_sig,
            TestHV_addr  => TestHV_addr_sig,
            bit_addr     => bit_addr_sig,--===========================
            data_out     => TestHV_bit --test hypervector bit output
            );
    
    -- Instantiate HAMM_accumulator
    U_HAMM_accumulator: HAMM_accumulator
        port map(
            clk       => clk,--==============================
            reset     => reset,--inputs
            Load      => RAM_EN_sig,--============================
            ClassHV_Done => ClassHV_Done_sig,--============================
            A_data_in => ClassHV_bit,--===========================      
            B_data_in => TestHV_bit,--outputs
            sum_out   => hamm_sum--=============================
        );
    
    -- Instantiate HAMM_MAX
    U_HAMM_MAX: Hamm_MAX
        port map(
            clk      => clk,--==============================
            reset    => reset,--inputs
            Load     => RAM_EN_sig,--============================
            TestHV_Done => TestHV_Done_sig,--============================
            data_in  => hamm_sum,--===========================
            sum_out  => max_sum,--outputs
            new_max  => new_max_sig
        );
    
    -- Instantiate Guess_compile
    U_Guess_compile: Guess_compile
        port map(
            clk       => clk,--==============================
            reset     => reset,--inputs
            TestHV_Done => TestHV_Done_sig,--============================
            new_max   => new_max_sig,--============================
            Class_in  => class_out_sig,--===========================
            Guess_out => guess_out_sig--outputs
        );
    
    -- Instantiate Controller
    U_Controller: Controller
        port map(
            clk                        => clk,--=====================
            reset                      => reset,--inputs
            start                      => start,
            inference_done            => INF_Done_sig,--=====================

            RAM_EN                     => RAM_EN_sig
         
        );
    
    -- Output assignments
        -- i added these so i can monitor them in the test bench/ simulation
    Done <= INF_Done_sig;
    Guess_out <= guess_out_sig;
    Current_bit_addr <= bit_addr_sig;
    TestHV_done <= TestHV_Done_sig;
    current_class_addr <= ClassHV_addr;
    current_testHV_addr <= TestHV_addr_sig;
    hamm_sum_out <= hamm_sum;

end Structural;

