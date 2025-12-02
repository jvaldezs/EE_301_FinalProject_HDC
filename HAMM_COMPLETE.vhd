--------------------------------------------------------------------------------
-- File: HAMM_COMPLETE.vhd
-- Author: 
-- Date: November 29, 2025
-- Description: Combined Hamming Distance Calculator and Max/Guess Logic.
--              Performs bitwise comparison, population count, and max update in one cycle.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HAMM_COMPLETE is
    port
    (
    clk         : in  STD_LOGIC; -- Clock input
    reset       : in  STD_LOGIC; -- Reset input
    Load        : in  STD_LOGIC; -- Load signal (Enable calculation)
    TestHV_Done : in  STD_LOGIC; -- Signal to clear max/guess when starting new TestHV
    
    A_data_in   : in  STD_LOGIC_VECTOR(1023 downto 0); -- Class HV
    B_data_in   : in  STD_LOGIC_VECTOR(1023 downto 0); -- Test HV
    Class_in    : in  STD_LOGIC_VECTOR(4 downto 0);    -- Current Class ID
    Current_sum : out STD_LOGIC_VECTOR(13 downto 0); -- Current Hamming Distance
    MAX_sum_out : out STD_LOGIC_VECTOR(13 downto 0); -- Current Max Hamming Distance
    Guess_out   : out STD_LOGIC_VECTOR(4 downto 0);  -- Current Best Guess
    new_max     : out STD_LOGIC; -- Signal indicating a new max was found
    Class0_processed : out STD_LOGIC -- Pulses when class 0 has been loaded and processed
);
end HAMM_COMPLETE;

architecture Behavioral of HAMM_COMPLETE is
    signal Current_Max : STD_LOGIC_VECTOR(13 downto 0) := (others => '0');
    signal Current_Guess : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    signal prev_TestHV_Done : std_logic := '0';
    signal prev_Class_in : STD_LOGIC_VECTOR(4 downto 0) := (others => '1');
begin
    process(clk, reset)
        variable match_count : integer range 0 to 1024;
        variable dist_vector : std_logic_vector(13 downto 0);
    begin
        if(rising_edge(clk)) then
            if(reset = '1') then
                Current_Max <= (others => '0');
                Current_Guess <= (others => '0');
                MAX_sum_out <= (others => '0');
                Guess_out <= (others => '0');
                new_max <= '0';
                prev_TestHV_Done <= '0';
                prev_Class_in <= (others => '1');
                Class0_processed <= '0';
            else
                prev_TestHV_Done <= TestHV_Done;
                prev_Class_in <= Class_in;
                
                -- Detect when class 0 has been loaded (transitions from non-zero to 0)
                if Load = '1' and Class_in = "00000" and prev_Class_in = "00000" then
                    Class0_processed <= '1';
                    
                else
                    Class0_processed <= '0';
                end if;
                
                -- Calculate Hamming Distance (Combinatorial logic inside process, registered output)
                match_count := 0;
                if Load = '1' then
                    for i in 0 to 1023 loop
                        if A_data_in(i) = B_data_in(i) then
                            match_count := match_count + 1;                    
                        end if; 
                    end loop;
                end if;
                dist_vector := std_logic_vector(to_unsigned(match_count, 14));

                -- Max/Guess Logic
                -- Reset when transitioning from class 0 to class 25 (new TestHV starting)
                if Load = '1' and prev_Class_in = "00000" and Class_in = "11001" then
                    -- Starting new TestHV with class 25, set it as default max
                    Current_Max <= dist_vector;
                    Current_Guess <= Class_in;
                    new_max <= '1';
                    
                elsif(Load = '1') then
                    if(unsigned(dist_vector) >= unsigned(Current_Max)) then
                        new_max <= '1'; 
                        Current_Max <= dist_vector;
                        Current_Guess <= Class_in;
                    else
                        new_max <= '0';
                    end if;
                end if;
                Current_sum <= dist_vector;
                MAX_sum_out <= Current_Max;
                Guess_out <= Current_Guess;
            end if;
        end if;
    end process;
end Behavioral;
