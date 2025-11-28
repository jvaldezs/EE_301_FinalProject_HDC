--------------------------------------------------------------------------------
-- File: HAMM_accumulator.vhd
-- Author: 
-- Date: November 11, 2025
-- Description: 
-- 
-- Revision History:
-- Date          Version     Description
-- 11/11/2025    1.0         Initial creation
--------------------------------------------------------------------------------
--TEST FROM NOV 19
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HAMM_accumulator is
    port

    (
    clk         : in  STD_LOGIC; -- Clock input
    reset       : in  STD_LOGIC; -- Reset input to clear accumulator
    Load        : in  STD_LOGIC; -- Load signal from control this is the same as the RAM_EN
    ClassHV_Done : in  STD_LOGIC; -- Signal to clear accumulator after each ClassHV comparison
   --======================================================================
    A_data_in   : in  STD_LOGIC_VECTOR(1023 downto 0); -- Input A data from Class HV (4-bit hex digit)
    B_data_in   : in  STD_LOGIC_VECTOR(1023 downto 0); -- Input B data from Test HV (4-bit hex digit)
    sum_out     : out STD_LOGIC_VECTOR(13 downto 0) -- Accumulated sum output

);
end HAMM_accumulator;
architecture Behavioral of HAMM_accumulator is
signal accumulator : STD_LOGIC_VECTOR(13 downto 0);
signal first_load : std_logic := '0';
begin
    process(clk, reset)
        variable match_count : integer range 0 to 1024; -- Count matches in current comparison
        -- the hamming function is comparing two vectors of 4-bits so the max match would be 4 perfect matches
    begin
        if(rising_edge(clk)) then
            if(reset = '1') then
                accumulator <= (others => '0'); -- Clear accumulator on reset
                first_load <= '0'; --disables export until at least one load has occurred
            elsif(ClassHV_Done = '1') then -- Clear accumulator when ClassHV to current Test HV comparison is complete
                accumulator <= (others => '0'); -- Reset for next ClassHV
                first_load <= '0'; -- Reset first_load flag
            elsif(Load = '1') then --load signal active from controller. I was trying to use this to solve the timing issue but it seems to not be working. Im fine removing this variable and the functions related to it if we can find a better way to solve the timing issue of the hamming accumulator comparing empty vectors of 0000
            --this is active when we want to compare inputs for inference
                -- Count how many bits match
                match_count := 0; -- Reset count for this comparison. this is reseting every cycle
                -- below is the how this module compares the 4 individual bits of each vector against eachother at the same time
                for i in 0 to 1023 loop
                    if A_data_in(i) = B_data_in(i) then
                        match_count := match_count + 1;                    
                    end if; 
                end loop;
                -- Add all matches at once
                accumulator <= std_logic_vector(unsigned(accumulator) + match_count);
                first_load <= '1'; -- Signal that at least one load has occurred
            end if;
            if(first_load = '1') then -- Exports sum only after at least one load has occurred
                    sum_out <= accumulator;
            end if;
        end if;
    end process;

end Behavioral;
