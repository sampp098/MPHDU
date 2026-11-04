----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/11/2023 05:19:53 PM
-- Design Name: 
-- Module Name: inst_cache - Behavioral
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

entity inst_cache is
    generic(
            G_AXI_DATA_WIDTH:   integer	:= 128;
            i_cache_port2_data_size: integer := 32;
            i_cache_depth:           integer := 128;
            i_cache_depth_clogb2:    integer := 7
            --int_size:                     integer := 32
    );
    port(
        clk: in std_logic;
        rst: in std_logic;
        --port1
        addr1 : in std_logic_vector((i_cache_depth_clogb2 - 2)-1 downto 0);
        wr_en1: in  std_logic;
        rd_en1: in  std_logic;
        din1  : in  std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
        dout1 : out std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
        
        --port2
        addr2 : in  std_logic_vector(i_cache_depth_clogb2-1 downto 0);
        --wr_en2: in  std_logic;
        rd_en2: in  std_logic;
        --din2  : in  std_logic_vector(i_cache_port2_data_size-1 downto 0);
        dout2 : out std_logic_vector(i_cache_port2_data_size-1 downto 0)
    );
end inst_cache;

architecture Behavioral of inst_cache is

type memory is array(0 to i_cache_depth-1) of std_logic_vector(i_cache_port2_data_size-1 downto 0);
signal mem: memory := (others => (others => '0'));

constant PORT1_WORD_RATIO : integer := G_AXI_DATA_WIDTH / i_cache_port2_data_size; -- 4
constant PORT1_ADDR_WIDTH : integer := i_cache_depth_clogb2 - 2; -- for 4 words per AXI beat

begin
    write_process:process(clk)
    begin
        if rising_edge (clk) then
            if rst ='1' then
                mem <= (others => (others => '0'));
            else
                --if    wr_en1 = '1' and wr_en2='0' then
                if    wr_en1 = '1' then
                    mem(to_integer(unsigned(addr1))*4 + 0) <= din1(31 downto 0)     after 5 ps;
                    mem(to_integer(unsigned(addr1))*4 + 1) <= din1(63 downto 32)    after 5 ps;
                    mem(to_integer(unsigned(addr1))*4 + 2) <= din1(95 downto 64)    after 5 ps;
                    mem(to_integer(unsigned(addr1))*4 + 3) <= din1(127 downto 96)   after 5 ps;
                end if;   
            end if;
        end if;  
    end process;
    
    read_process:process(clk)
    begin
        if rising_edge (clk) then
            if rst ='1' then
                dout1 <= (others => '0');
                dout2 <= (others => '0');
            else
                if    rd_en1 = '1' and to_integer(unsigned(addr1)) < i_cache_depth then
                    dout1(31 downto 0)    <= mem(to_integer(unsigned(addr1))*4 + 0) after 5 ps;
                    dout1(63 downto 32)   <= mem(to_integer(unsigned(addr1))*4 + 1) after 5 ps;
                    dout1(95 downto 64)   <= mem(to_integer(unsigned(addr1))*4 + 2) after 5 ps;
                    dout1(127 downto 96)  <= mem(to_integer(unsigned(addr1))*4 + 3) after 5 ps;
                else
                    --dout1 <= (others => '0');
                end if;   
                
                if   rd_en2 = '1' and to_integer(unsigned(addr2)) < i_cache_depth then
                    dout2 <= mem(to_integer(unsigned(addr2)))  after 5ps;
                else
                    --dout2 <= (others => '0');
                end if;   
            end if;
        end if;  
    end process;
    
end Behavioral;
