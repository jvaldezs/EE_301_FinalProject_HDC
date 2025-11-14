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
-- 11/13/2025                Edits to allow inter-component communication in Vivado
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
        Done        : out STD_LOGIC  -- Inference complete signal
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
            bit_addr : out std_logic_vector(9 downto 0);
            Done     : out std_logic
        );
    end component;
    
    component ClassHV_RAM is
        port(
            class_select : in  std_logic_vector(4 downto 0);
            bit_addr     : in  std_logic_vector(9 downto 0);
            RAM_CLOCK    : in  std_logic;
            RAM_EN       : in  std_logic;
            RAM_DATA_OUT : out std_logic;
            done         : out std_logic
        );
    end component;
    
    component TestHV_RAM is
        port(
            test_select  : in  std_logic_vector(6 downto 0);
            bit_addr     : in  std_logic_vector(9 downto 0);
            RAM_CLOCK    : in  std_logic;
            RAM_EN       : in  std_logic;
            RAM_DATA_OUT : out std_logic;
            done         : out std_logic
        );
    end component;
    
    component HAMM_accumulator is
        port(
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            Load      : in  STD_LOGIC;
            export    : in  STD_LOGIC;
            A_data_in : in  STD_LOGIC;
            B_data_in : in  STD_LOGIC;
            sum_out   : out STD_LOGIC_VECTOR(10 downto 0)
        );
    end component;
    
    component Hamm_MAX is
        port(
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            Load     : in  STD_LOGIC;
            data_in  : in  STD_LOGIC_VECTOR(10 downto 0);
            sum_out  : out STD_LOGIC_VECTOR(10 downto 0);
            new_max  : out STD_LOGIC
        );
    end component;
    
    component Guess_compile is
        port(
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
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
            Load_HAMM                 : out std_logic;
            export_HAMM               : out std_logic;
            Load_HAMM_MAX             : out std_logic;
            enable_inference_iteration: out std_logic;
            RAM_EN                    : out std_logic;
            INF_Done                  : in  std_logic;
            Vect_Done                 : in  std_logic;
            new_max                   : in  std_logic;
            Update_Guess              : out std_logic
        );
    end component;
    
    -- Internal Signals
    
    -- BIT_SELECT outputs
    signal ClassHV_addr  : std_logic_vector(4 downto 0);
    signal TestHV_addr   : std_logic_vector(6 downto 0);
    signal bit_addr      : std_logic_vector(9 downto 0);
    signal INF_Done_sig  : std_logic;
    
    -- RAM outputs
    signal ClassHV_bit   : std_logic;
    signal TestHV_bit    : std_logic;
    signal ClassHV_done  : std_logic;
    signal TestHV_done   : std_logic;
    
    -- HAMM accumulator signals
    signal hamm_sum      : std_logic_vector(10 downto 0);
    
    -- HAMM MAX signals
    signal max_sum       : std_logic_vector(10 downto 0);
    signal new_max_sig   : std_logic;
    
    -- Controller signals
    signal Load_HAMM_sig          : std_logic;
    signal export_HAMM_sig        : std_logic;
    signal Load_HAMM_MAX_sig      : std_logic;
    signal enable_iteration_sig   : std_logic;
    signal RAM_EN_sig             : std_logic;
    signal Update_Guess_sig       : std_logic;
    
begin
    
    -- Instantiate BIT_SELECT
    U_BIT_SELECT: BIT_SELECT
        port map(
            clk      => clk,
            reset    => reset,
            enable   => enable_iteration_sig,
            ClassHV  => ClassHV_addr,
            TestHV   => TestHV_addr,
            bit_addr => bit_addr,
            Done     => INF_Done_sig
        );
    
    -- Instantiate ClassHV_RAM
    U_ClassHV_RAM: ClassHV_RAM
        port map(
            class_select => ClassHV_addr,
            bit_addr     => bit_addr,
            RAM_CLOCK    => clk,
            RAM_EN       => RAM_EN_sig,
            RAM_DATA_OUT => ClassHV_bit,
            done         => ClassHV_done
        );
    
    -- Instantiate TestHV_RAM
    U_TestHV_RAM: TestHV_RAM
        port map(
            test_select  => TestHV_addr,
            bit_addr     => bit_addr,
            RAM_CLOCK    => clk,
            RAM_EN       => RAM_EN_sig,
            RAM_DATA_OUT => TestHV_bit,
            done         => TestHV_done
        );
    
    -- Instantiate HAMM_accumulator
    U_HAMM_accumulator: HAMM_accumulator
        port map(
            clk       => clk,
            reset     => reset,
            Load      => Load_HAMM_sig,
            export    => export_HAMM_sig,
            A_data_in => ClassHV_bit,
            B_data_in => TestHV_bit,
            sum_out   => hamm_sum
        );
    
    -- Instantiate HAMM_MAX
    U_HAMM_MAX: Hamm_MAX
        port map(
            clk      => clk,
            reset    => reset,
            Load     => Load_HAMM_MAX_sig,
            data_in  => hamm_sum,
            sum_out  => max_sum,
            new_max  => new_max_sig
        );
    
    -- Instantiate Guess_compile
    U_Guess_compile: Guess_compile
        port map(
            clk       => clk,
            reset     => reset,
            new_max   => new_max_sig,
            Class_in  => ClassHV_addr,
            Guess_out => Guess_out
        );
    
    -- Instantiate Controller
    U_Controller: Controller
        port map(
            clk                        => clk,
            reset                      => reset,
            start                      => start,
            Load_HAMM                  => Load_HAMM_sig,
            export_HAMM                => export_HAMM_sig,
            Load_HAMM_MAX              => Load_HAMM_MAX_sig,
            enable_inference_iteration => enable_iteration_sig,
            RAM_EN                     => RAM_EN_sig,
            INF_Done                   => INF_Done_sig,
            Vect_Done                  => ClassHV_done,
            new_max                    => new_max_sig,
            Update_Guess               => Update_Guess_sig
        );
    
    -- Output assignments
    Done <= INF_Done_sig;
    
end Structural;
