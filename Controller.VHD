--------------------------------------------------------------------------------
-- File: Controller.vhd
-- Author: 
-- Date: November 11, 2025
-- Description: 
-- 
-- Revision History:
-- Date          Version     Description
-- 11/11/2025    1.0         Initial creation
-- 11/13/2025                Modified just enough for Vivado to accept it
--------------------------------------------------------------------------------





library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;




entity Controller is
    port(
        clk : in std_logic; -- Clock input
        reset : in std_logic; -- Reset input
        start : in std_logic; -- Start signal to begin processing
        Load_HAMM : out std_logic; -- Load signal to HAMM accumulator
        export_HAMM : out std_logic; -- Export signal to HAMM accumulator
        Load_HAMM_MAX : out std_logic; -- Load signal to HAMM max
        --^^signal to load accumulated hamm value into hamm max for comparison
        -- is tied to Vect_Done from ClassHV RAM
        enable_inference_iteration : out std_logic; -- Enable signal for BIT_SELECT
        RAM_EN : out std_logic; -- Enable signal for ClassHV RAM
        INF_Done : in std_logic; -- Input from BIT_SELECT indicating all classes and bits have been output
        Vect_Done : in std_logic; -- Input from ClassHV RAM indicating last bit read
       
        new_max : in std_logic; -- Input from HAMM max indicating a new max found
        Update_Guess : out std_logic -- Signal to Guess module to update its output

    );
end Controller;

architecture Behavioral of Controller is 
begin




end Behavioral;
