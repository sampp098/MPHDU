----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2025 11:17:04 PM
-- Design Name: 
-- Module Name: PSUM_thread - Behavioral
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

entity PSUM_PE is
    generic(
            binary_cache_port2_data_size: integer := 32;
            int_size: integer := 2
    );
    port(   -- control
                clk             : in  std_logic;
                rst             : in  std_logic;
                in_valid        : in  std_logic;
                reload          : in  std_logic;
            -- data I/O
                din             : in  STD_LOGIC_VECTOR (binary_cache_port2_data_size -1 downto 0);
                dout            : out std_logic_vector((binary_cache_port2_data_size * int_size) - 1 downto 0) --int_vector
        );
end PSUM_PE;

architecture Behavioral of PSUM_PE is
component ADD_1bit is
    generic(
            int_size: integer := 32
    );
    port(   clk             : in  std_logic;
            rst             : in  std_logic;
            in_valid        : in  std_logic;
            reload          : in  std_logic;
    
            din             : in  std_logic;
            dout            : out std_logic_vector(int_size-1 downto 0)
        );
end component;

begin
    
    add_1bit_vector: for i in 0 to binary_cache_port2_data_size-1 generate
        uAdd_1bit: ADD_1bit
            generic map(
                int_size => int_size
            )
            port map( 
                      clk      => clk,
                      rst      => rst,
                      in_valid => in_valid,
                      reload   => reload,
                      din    => din(i),
                      dout   => dout(((i+1)*int_size)-1 downto i*int_size) -- output(i)
                     );
    end generate add_1bit_vector;
    

end Behavioral;