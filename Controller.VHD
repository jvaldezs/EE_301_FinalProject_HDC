library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Controller is
    generic (
        N_CLASSES : integer := 26  -- number of class hypervectors
    );
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        start          : in  std_logic;  -- pulse or level to begin inference

        -- Outputs to rest of system
        class_select   : out std_logic_vector(4 downto 0); -- 0..25
        RAM_EN         : out std_logic;    -- enables ClassHV/TestHV RAM reads
        Load           : out std_logic;    -- 1-cycle pulse to HAMM_accumulator
        ClassHV_Done   : out std_logic;    -- 1-cycle pulse to clear HAMM between classes
        inference_done : out std_logic     -- goes high when all classes processed
    );
end Controller;

architecture Behavioral of Controller is

    type state_type is (
        S_RESET,
        S_IDLE,
        S_SET_CLASS,
        S_LOAD,         -- pulse Load = '1'
        S_CLEAR_HAMM,   -- pulse ClassHV_Done = '1'
        S_NEXT_CLASS,
        S_DONE
    );

    signal state, next_state : state_type := S_RESET;

    -- class index counter: 0 .. N_CLASSES-1
    signal class_idx : unsigned(4 downto 0) := (others => '0');

begin

    --------------------------------------------------------------------
    -- State register
    --------------------------------------------------------------------
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state     <= S_RESET;
                class_idx <= (others => '0');
            else
                state <= next_state;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Next state logic & outputs
    --------------------------------------------------------------------
    process (state, start, class_idx)
        -- default outputs
        variable v_RAM_EN         : std_logic := '0';
        variable v_Load           : std_logic := '0';
        variable v_ClassHV_Done   : std_logic := '0';
        variable v_inference_done : std_logic := '0';
        variable v_next_state     : state_type := state;
        variable v_class_idx_next : unsigned(4 downto 0) := class_idx;
    begin
        -- default: stay in same state, all outputs low
        v_RAM_EN         := '0';
        v_Load           := '0';
        v_ClassHV_Done   := '0';
        v_inference_done := '0';
        v_next_state     := state;
        v_class_idx_next := class_idx;

        case state is

            ----------------------------------------------------------------
            when S_RESET =>
                v_class_idx_next := (others => '0');
                v_next_state     := S_IDLE;
                -- outputs all low

            ----------------------------------------------------------------
            when S_IDLE =>
                v_class_idx_next := (others => '0');
                if start = '1' then
                    -- begin inference with class 0
                    v_next_state := S_SET_CLASS;
                else
                    v_next_state := S_IDLE;
                end if;

            ----------------------------------------------------------------
            when S_SET_CLASS =>
                -- Drive current class index, enable RAMs to produce HVs
                v_RAM_EN     := '1';
                v_next_state := S_LOAD;  -- next cycle we pulse Load

            ----------------------------------------------------------------
            when S_LOAD =>
                -- One-cycle pulse: HAMM compares the two 1024-bit HVs
                v_RAM_EN := '1';
                v_Load   := '1';
                -- After this cycle, result for this class is in HAMM accumulator
                v_next_state := S_CLEAR_HAMM;

            ----------------------------------------------------------------
            when S_CLEAR_HAMM =>
                -- One-cycle pulse: clear HAMM accumulator for next class
                v_ClassHV_Done := '1';
                v_RAM_EN       := '1';  -- optional: keep RAM enabled
                v_next_state   := S_NEXT_CLASS;

            ----------------------------------------------------------------
            when S_NEXT_CLASS =>
                -- Decide whether to move to next class or finish
                if class_idx = to_unsigned(N_CLASSES - 1, class_idx'length) then
                    -- last class completed
                    v_next_state := S_DONE;
                else
                    -- increment class index and go set next class
                    v_class_idx_next := class_idx + 1;
                    v_next_state     := S_SET_CLASS;
                end if;

            ----------------------------------------------------------------
            when S_DONE =>
                -- Inference finished: raise inference_done; stay here until reset
                v_inference_done := '1';
                -- RAM_EN, Load, ClassHV_Done all low
                v_next_state := S_DONE;

            ----------------------------------------------------------------
            when others =>
                v_next_state     := S_RESET;
                v_class_idx_next := (others => '0');
        end case;

        -- assign registers/outputs from variables
        next_state      <= v_next_state;
        class_idx       <= v_class_idx_next;
        RAM_EN          <= v_RAM_EN;
        Load            <= v_Load;
        ClassHV_Done    <= v_ClassHV_Done;
        inference_done  <= v_inference_done;
    end process;

    --------------------------------------------------------------------
    -- Drive class_select output from internal counter
    --------------------------------------------------------------------
    class_select <= std_logic_vector(class_idx);

end Behavioral;


