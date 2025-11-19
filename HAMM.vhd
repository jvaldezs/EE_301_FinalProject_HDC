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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HAMM_accumulator is
    port

    (
    clk         : in  STD_LOGIC; -- Clock input
    reset       : in  STD_LOGIC; -- Reset input to clear accumulator
    Load        : in  STD_LOGIC; -- Load signal from control this is the same as the RAM_EN
   --======================================================================
    A_data_in   : in  STD_LOGIC_VECTOR(3 downto 0); -- Input A data from Class HV (4-bit hex digit)
    B_data_in   : in  STD_LOGIC_VECTOR(3 downto 0); -- Input B data from Test HV (4-bit hex digit)
    sum_out     : out STD_LOGIC_VECTOR(10 downto 0) -- Accumulated sum output

);
end HAMM_accumulator;
architecture Behavioral of HAMM_accumulator is
signal accumulator : STD_LOGIC_VECTOR(10 downto 0);
signal first_load : std_logic := '0';
begin
    process(clk, reset)
    begin
        if(rising_edge(clk)) then
            if(reset = '1') then
                accumulator <= (others => '0'); -- Clear accumulator on reset
                first_load <= '0'; --disables export until at least one load has occurred
            elsif(Load = '1') then --load signal active from controller
            --this is active when we want to compare inputs for inference
                -- Compare bit 0
                if(A_data_in(0) = B_data_in(0)) then --if bit 0 matches
                    accumulator <= std_logic_vector(unsigned(accumulator) + 1);
                end if;
                -- Compare bit 1
                if(A_data_in(1) = B_data_in(1)) then --if bit 1 matches
                    accumulator <= std_logic_vector(unsigned(accumulator) + 1);
                end if;
                -- Compare bit 2
                if(A_data_in(2) = B_data_in(2)) then --if bit 2 matches
                    accumulator <= std_logic_vector(unsigned(accumulator) + 1);
                end if;
                -- Compare bit 3
                if(A_data_in(3) = B_data_in(3)) then --if bit 3 matches
                    accumulator <= std_logic_vector(unsigned(accumulator) + 1);
                end if;
                first_load <= '1'; -- Signal that at least one load has occurred
            end if;
            if(first_load = '1') then -- Exports sum only after at least one load has occurred
                    sum_out <= accumulator;
            end if;
        end if;
    end process;
end Behavioral;