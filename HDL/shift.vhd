----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2025 11:17:04 PM
-- Design Name: 
-- Module Name: shift - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library xil_defaultlib;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity shift is
      generic(
        binary_cache_port2_data_size: integer := 32;
        ROT_amount_num  :             integer := 8; -- 2^ ROT_amount_clog2
        amount: integer := 1
      );
      Port (
        carry_in      : in  std_logic_vector(ROT_amount_num-1 downto 0); 
        din         : in  std_logic_vector(binary_cache_port2_data_size-1 downto 0);
        dout          : out std_logic_vector(binary_cache_port2_data_size-1 downto 0);
        carry_out     : out std_logic_vector(ROT_amount_num-1 downto 0)
      );
end shift;

architecture Behavioral of shift is
constant zero: std_logic_vector(ROT_amount_num-1 downto 0) := (others => '0');
begin
    
    dout      <= carry_in(amount-1 downto 0)&din(binary_cache_port2_data_size-1 downto amount);
    carry_out <= zero(ROT_amount_num-1 downto amount) & din(amount-1 downto 0);

end Behavioral;
