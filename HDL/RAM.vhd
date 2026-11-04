----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/04/2025 02:21:53 PM
-- Design Name: 
-- Module Name: binary_cache - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RAM is
    generic(
            ram_data_size: integer := 32;
            ram_depth:           integer := 128;
            ram_depth_clogb2:    integer := 7
    );
    port(
        clk: in std_logic;
        rst: in std_logic;
        --port1
        addr : in  std_logic_vector(ram_depth_clogb2-1 downto 0);
        wr_en: in  std_logic;
        rd_en: in  std_logic;
        din  : in  std_logic_vector(ram_data_size-1 downto 0);
        dout : out std_logic_vector(ram_data_size-1 downto 0)
    );
end RAM;

architecture Behavioral of RAM is

type memory is array(0 to ram_depth-1) of std_logic_vector(ram_data_size-1 downto 0);
signal mem: memory := (others => (others => '0'));

begin
    write_process:process(clk)
    begin
        if rising_edge (clk) then
            if rst ='1' then
                mem <= (others => (others => '0'));
            else
                if    wr_en = '1' then
                    mem(to_integer(unsigned(addr))) <= din  after 5ps;
                end if;   
            end if;
        end if;  
    end process;
    
    read_process:process(clk)
    begin
        if rising_edge (clk) then
            if rst ='1' then
                dout <= (others => '0');
            else
                if    rd_en = '1' then
                    dout <= mem(to_integer(unsigned(addr)))  after 5ps;
                else
                    dout <= (others => '0');
                end if;
            end if;
        end if;  
    end process;
    
end Behavioral;
