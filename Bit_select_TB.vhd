--Bit Select TB
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bit_select_TB is
    --===============
end bit_select_TB;

architecture Behavioral of bit_select_TB is
        signal clk : STD_LOGIC:= '0' ; -- Clock input
        signal reset : STD_LOGIC := '0'; -- Reset input
        signal enable :  STD_LOGIC :='0'; -- Enable signal to start the selection process
        --this is controlled by the state when the FSM wants to start reading bits for ClassHV RAM and TestHV RAM
        signal ClassHV : std_logic_vector(4 downto 0); -- class output (1-26)
        signal TestHV : std_logic_vector(6 downto 0); -- Test Hypervector class address (0-125)
        signal bit_addr : std_logic_vector(9 downto 0); -- Bit address (0-1023)
        signal Done : std_logic; -- Signals when all classes and bits have been output
--====== internal signals of Test Bench

component BIT_SELECT
-- Call Bit Select operator and Declare ports
port(
        clk : in STD_LOGIC; -- Clock input
        reset : in STD_LOGIC; -- Reset input
        enable : in STD_LOGIC; -- Enable signal to start the selection process
        --this is controlled by the state when the FSM wants to start reading bits for ClassHV RAM and TestHV RAM
        ClassHV : out std_logic_vector(4 downto 0); -- class output (1-26)
        TestHV : out std_logic_vector(6 downto 0); -- Test Hypervector class address (0-125)
        bit_addr : out std_logic_vector(9 downto 0); -- Bit address (0-1023)
        Done : out std_logic -- Signals when all classes and bits have been output

    );
    end component; 

begin
    DUT: BIT_SELECT
    port map (
    clk => clk,
    reset => reset,
    enable => enable,
    ClassHV => ClassHV,
    TestHV => TestHV,
    bit_addr => bit_addr,
    Done => Done
    );

     -- Clock generation
    clk_process : process
    begin
        while true loop
            clk
            <= '0';
            wait for 20 ns;
            clk
            <= '1';
            wait for 20 ns;
        end loop;
    end process;

     --Stimulus process
    stim_proc: process
    begin

        enable <= '1';
        --set enable signal high to let bit selector cycle for 10k nano seconds
        wait for 10000 ns;

--        reset <= '1';
--        wait; 


    end process; 
    end architecture;