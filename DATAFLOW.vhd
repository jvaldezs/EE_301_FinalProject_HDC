--------------------------------------------------------------------------------
-- File: DATAFLOW.vhd
-- Author: 
-- Date: December 11, 2025
-- Description: Dataflow module encapsulating RAMs, HAMM processing, and training
--              Handles all data pipelining between ClassHV_RAM, TestHV_RAM, 
--              HAMM_COMPLETE, and TrainingHV_RAM modules
-- 
-- Revision History:
-- Date          Version     Description
-- 12/11/2025    1.0         Initial creation - extracted from Inference_Top
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TrainingHV_types.all;

entity DATAFLOW is
    port(
        clk                 : in  STD_LOGIC;
        Master_reset               : in  STD_LOGIC;
        start               : in  STD_LOGIC;
        
        -- Control inputs
        inference_done      : in  STD_LOGIC;
        
        -- Address inputs from BIT_SELECT
        ClassHV_addr        : in  STD_LOGIC_VECTOR(4 downto 0);
        TestHV_addr         : in  STD_LOGIC_VECTOR(6 downto 0);
        TestHV_Done         : in  STD_LOGIC;
        
        -- Outputs to top level
        Guess_out           : out STD_LOGIC_VECTOR(4 downto 0);
        Current_sum         : out STD_LOGIC_VECTOR(13 downto 0);
        MAX_sum             : out STD_LOGIC_VECTOR(13 downto 0);
        Class0_processed    : out STD_LOGIC;
        training_done       : out STD_LOGIC;
        ClassHV_changed     : out STD_LOGIC;
        class_array_changed : out STD_LOGIC;
        
        -- Controller outputs
        RAM_EN              : out STD_LOGIC;
        Train_EN            : out STD_LOGIC;
        state_out           : out string(1 to 5);
        reset               : out STD_LOGIC
    );
end DATAFLOW;

architecture Behavioral of DATAFLOW is

    -- Component Declarations
    component ClassHV_RAM is
        port(
            class_select      : in  std_logic_vector(4 downto 0);
            RAM_CLOCK         : in  std_logic;
            RAM_EN            : in  std_logic;
            Train_EN          : in  std_logic;
            reset             : in  std_logic;
            training_done     : in  std_logic;
            ClassHV_array_in  : in  Class_RAM_ARRAY;
            RAM_DATA_OUT      : out std_logic_vector(1023 downto 0);
            CLASS_OUT         : out std_logic_vector(4 downto 0);
            Class_array_corrected : out std_logic
        );
    end component;
    
    component TestHV_RAM is
        port(
            clk          : in  std_logic;
            reset        : in  std_logic;
            TestHV_addr  : in  std_logic_vector(6 downto 0);           
            Read_en      : in  std_logic;
            data_out     : out std_logic_vector(1023 downto 0)
        );
    end component;
    
    component HAMM_COMPLETE is
        port(
            clk             : in  STD_LOGIC;
            reset           : in  STD_LOGIC;
            Load            : in  STD_LOGIC;
            TestHV_Done     : in  STD_LOGIC;
            A_data_in       : in  STD_LOGIC_VECTOR(1023 downto 0);
            B_data_in       : in  STD_LOGIC_VECTOR(1023 downto 0);
            Class_in        : in  STD_LOGIC_VECTOR(4 downto 0);
            Current_sum     : out STD_LOGIC_VECTOR(13 downto 0);
            MAX_sum_out     : out STD_LOGIC_VECTOR(13 downto 0);
            Guess_out       : out STD_LOGIC_VECTOR(4 downto 0);
            new_max         : out STD_LOGIC;
            Class0_processed: out STD_LOGIC
        );
    end component;
    
    component TrainingHV_RAM is
        port(
            clk               : in  STD_LOGIC; 
            reset             : in  STD_LOGIC; 
            TestHV_Done       : in  STD_LOGIC; 
            Class0_processed  : in  STD_LOGIC; 
            current_TestHV    : in  STD_LOGIC_VECTOR(6 downto 0); 
            best_guess        : in  STD_LOGIC_VECTOR(4 downto 0);               
            Train_EN          : in  STD_LOGIC;
            ClassHV_array_out : out Class_RAM_ARRAY;    
            training_done     : out STD_LOGIC   
        );
    end component;
    
    component Controller is
        port(
            clk                     : in  std_logic;
            Master_reset                   : in  std_logic;
            start                   : in  std_logic;
            class_array_corrected   : in  std_logic;
            inference_done          : in  std_logic;
            RAM_EN                  : out std_logic;
            Train_EN                : out std_logic;
            state_out               : out string(1 to 5);
            reset                   : out std_logic
        );
    end component;
    
    -- Internal Signals
    signal bit_addr_sig         : std_logic_vector(7 downto 0) := (others => '0'); -- Tied to 0
    signal ClassHV_bit          : std_logic_vector(1023 downto 0);
    signal TestHV_bit           : std_logic_vector(1023 downto 0);
    signal class_out_sig        : std_logic_vector(4 downto 0);
    signal guess_out_sig        : std_logic_vector(4 downto 0);
    signal max_sum_sig          : std_logic_vector(13 downto 0);
    signal current_sum_sig      : std_logic_vector(13 downto 0);
    signal class0_processed_sig : std_logic;
    signal new_max_sig          : std_logic;
    signal training_done_sig    : std_logic;
    signal ClassHV_array_out_sig: Class_RAM_ARRAY;
    signal Class_corrected_sig  : std_logic;
    
    -- Controller signals
    signal RAM_EN_sig           : std_logic;
    signal Train_EN_sig         : std_logic;
    signal state_out_sig        : string(1 to 5);
    signal reset_sig            : std_logic;
    
begin
    
    -- Instantiate Controller
    U_Controller: Controller
        port map(
            clk                   => clk,
            Master_reset          => Master_reset,
            start                 => start,
            class_array_corrected => Class_corrected_sig,
            inference_done        => inference_done,
            RAM_EN                => RAM_EN_sig,
            Train_EN              => Train_EN_sig,
            state_out             => state_out_sig,
            reset                 => reset_sig
        );
    
    -- Instantiate ClassHV_RAM
    U_ClassHV_RAM: ClassHV_RAM
        port map(
            class_select      => ClassHV_addr,
            RAM_CLOCK         => clk,
            reset             => reset_sig,
            RAM_EN            => RAM_EN_sig,
            Train_EN          => Train_EN_sig,
            training_done     => training_done_sig,
            ClassHV_array_in  => ClassHV_array_out_sig,
            RAM_DATA_OUT      => ClassHV_bit,
            CLASS_OUT         => class_out_sig,
            Class_array_corrected => Class_corrected_sig
        );
    
    -- Instantiate TestHV_RAM
    U_TestHV_RAM: TestHV_RAM
        port map(
            clk          => clk,
            reset        => reset_sig,
            read_en      => RAM_EN_sig,
            TestHV_addr  => TestHV_addr,
            data_out     => TestHV_bit
        );
    
    -- Instantiate HAMM_COMPLETE
    U_HAMM_COMPLETE: HAMM_COMPLETE
        port map(
            clk              => clk,
            reset            => reset_sig,
            Load             => RAM_EN_sig,
            TestHV_Done      => TestHV_Done,
            A_data_in        => ClassHV_bit,
            B_data_in        => TestHV_bit,
            Class_in         => class_out_sig,
            Guess_out        => guess_out_sig,
            new_max          => new_max_sig,
            MAX_sum_out      => max_sum_sig,
            Current_sum      => current_sum_sig,
            Class0_processed => class0_processed_sig
        );
    
    -- Instantiate TrainingHV_RAM
    U_Trainer: TrainingHV_RAM
        port map(
            clk               => clk,
            reset             => reset_sig,
            TestHV_Done       => TestHV_Done,
            Class0_processed  => class0_processed_sig,
            current_TestHV    => TestHV_addr,
            best_guess        => guess_out_sig,
            Train_EN          => Train_EN_sig,
            ClassHV_array_out => ClassHV_array_out_sig,
            training_done     => training_done_sig
        );
    
    -- Output assignments
    Guess_out        <= guess_out_sig;
    Current_sum      <= current_sum_sig;
    MAX_sum          <= max_sum_sig;
    Class0_processed <= class0_processed_sig;
    training_done    <= training_done_sig;
    RAM_EN           <= RAM_EN_sig;
    Train_EN         <= Train_EN_sig;
    state_out        <= state_out_sig;
    class_array_changed  <= Class_corrected_sig;

end Behavioral;
