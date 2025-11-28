--------------------------------------------------------------------------------
-- File: Guess_compile.VHD
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

entity Guess_compile is
    port(
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        TestHV_Done : in STD_LOGIC; --signal when TestHV completes to reset guess
        new_max : in STD_LOGIC; --signal from HAMM_MAX indicating new max found
        Class_in : in std_logic_vector(4 downto 0); --class input ClassHV_RAM (CLASS_OUT)
        Guess_out : out std_logic_vector(4 downto 0) --output guess

    );
end Guess_compile;
-- This component takes the input of the current RAM class selected and translates that class value
--to the best guest value when the HAMM MAX module signals that a new maximum hamming distance has been found
--This means that the current class being tested is now the best guess so far
-- So as we update the best guess, at the end of the inference process, the guess output will be the class
-- that had the maximum hamming distance with the test hypervector.

architecture Behavioral of Guess_compile is

    signal current_guess : std_logic_vector(4 downto 0) := (others => '0');
    signal prev_TestHV_Done : std_logic := '0';
begin
    process(clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '1' then
             current_guess <= (others => '0');
             prev_TestHV_Done <= '0';
             --clear guess on reset
        
            else
                prev_TestHV_Done <= TestHV_Done;
                
                -- Clear guess one cycle after TestHV_Done (on falling edge) so each test HV is starting its comparison from scratch
                if prev_TestHV_Done = '1' and TestHV_Done = '0' then
                    current_guess <= (others => '0');
                elsif new_max = '1' then
                    --when the HAMM_MAX signals a new max found
                    --update the guess to the current class being tested
                    current_guess <= Class_in;
                end if;
            end if;
        end if;
        Guess_out <= current_guess;
    end process;
    
end Behavioral;
