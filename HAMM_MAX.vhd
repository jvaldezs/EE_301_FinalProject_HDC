--------------------------------------------------------------------------------
-- File: HAMM_MAX.vhd
-- Author: 
-- Date: November 11, 2025
-- Description: 
-- 
-- Revision History:
-- Date          Version     Description
-- 11/11/2025    1.0         Initial creation
-- 11/13/2025                Debugged Syntax Error
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- This component compares current hamming distance caluclated with
-- The previous maximum hamming distance stored. If the current distance
-- is greater than the stored maximum, it updates the maximum value.
--When ever there is a new Maximum value, This component sends a signal to the controller
-- So the controller can signal the guess module to update its output so that
--the guess in process is reflected bu giving the guess the value
-- The value of the current Class HV being tested. 
--since that is the new best guess so far.
entity Hamm_MAX is
    port
    (
    clk         : in  STD_LOGIC; -- Clock input
    reset       : in  STD_LOGIC; -- Reset input to clear accumulator
    Load        : in  STD_LOGIC; -- Load signal from control
    --===========Load signal should be active when we want to compare
    --===========the current hamming distance with the stored maximum
    --=========== but only when the hamming_accumulator module is done calculating
    data_in     : in  STD_LOGIC_VECTOR(10 downto 0);-- Input data from HAMM module
    sum_out     : out STD_LOGIC_VECTOR(10 downto 0);  -- Max count is 1024, needs 11 bits
    new_max     : out STD_LOGIC -- Signal to controller indicating a new max found


);
end Hamm_MAX;

architecture Behavioral of Hamm_MAX is
    signal Current_Max : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(reset = '1') then
                Current_Max <= (others => '0'); -- Clear on reset
                sum_out <= (others => '0'); -- Reset output to 0 for first comparison
            elsif(Load = '1') then -- Load signal active from controller
                if(unsigned(data_in) > unsigned(Current_Max)) then --if new max found
                    new_max <= '1'; -- Signal to controller that a new max is found
                    --this is a pulse signal that updates the guess module
                    --to the current class as the current best guess
                    Current_Max <= data_in; -- Update max if new data is greater
                else
                    new_max <= '0'; -- No new max found
                end if;
            end if;
            sum_out <= Current_Max; -- Always output the current max
        end if;
    end process;
end Behavioral;
--Current_Max is used to store the maximum value encountered so far.
--this value is updated only when the Load signal is active and

--the new input data exceeds the current maximum.
