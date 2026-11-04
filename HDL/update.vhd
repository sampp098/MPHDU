----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/02/2026 10:21:04 AM
-- Design Name: 
-- Module Name: update - Behavioral
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

entity update is
      generic(
        SLICE_WIDTH  : natural := 32; -- Doit être une puissance de 2
        G_LOG2_SLICE_WIDTH  : natural := 5; -- = log2c(SLICE_WIDTH)
		Model_NUM           : natural := 7; -- Class number or action model number
		--G_Dimentsion            : integer := 1024; Dimentione size of a full MHV element
        G_Segments_ADDR_WIDTH   : integer := 5 -- LOG2(G_Dimentsion/SLICE_WIDTH)
      );
      Port (
        clk      :     in std_logic;
        update_en:     in std_logic;
        update_wr:     in std_logic;
		update_valid: out std_logic;
        Penalty   : in  std_logic; 
        QHV       : in  STD_LOGIC_VECTOR (SLICE_WIDTH-1 downto 0);
        MHV       : in  STD_LOGIC_VECTOR ((Model_NUM*SLICE_WIDTH)-1 downto 0);
		MHV_addr  : in  std_logic_vector(G_Segments_ADDR_WIDTH-1 downto 0);
		
		argMin_in : in  std_logic_vector(15 downto 0);
		argMin_out: out std_logic_vector(15 downto 0);
		Updated_MHV_slice: out STD_LOGIC_VECTOR (SLICE_WIDTH-1 downto 0)
      );
end update;

architecture Behavioral of update is

component LFSR is
    port (
        clk   : in  std_logic;
        state : out std_logic_vector(47 downto 0)
    );
end component;
signal MHV_t: STD_LOGIC_VECTOR ((Model_NUM*SLICE_WIDTH)-1 downto 0);
signal QHV_t: STD_LOGIC_VECTOR ((SLICE_WIDTH)-1 downto 0);
signal lfsr_state: std_logic_vector(47 downto 0);
signal RA: std_logic_vector(G_LOG2_SLICE_WIDTH-1 downto 0);
signal RB: std_logic_vector(G_Segments_ADDR_WIDTH-1 downto 0);
--signal RC: std_logic_vector(15 downto 0);
--signal argMin:  std_logic_vector(15 downto 0):= (others => '0');
signal second : std_logic:= '0'; 
begin
    
    
    -- If the comming MHV slice is the one pointing by random LFSR index
    --    So then we flip a random bit of the slice from the element which 
    --    is equal to the argmin, according to the penaly and QHV slice
    
    -- MHV is an array of 32-bit word, argmin is the index for this array
    -- in MHV_t we want to change one bit of the selected MHV element pointed by argmin
    process(clk)
        variable selected_mhv : std_logic_vector(SLICE_WIDTH-1 downto 0);
        variable argmin_int   : integer;
        variable ra_int       : integer;
    begin
        if rising_edge(clk) then
            -- Default: no update this cycle
            --------------------------------------------------------------
            -- Default output-valid behavior
            --------------------------------------------------------------
            update_valid <= '0';
            
            if update_en = '0' then
                RA <= lfsr_state(G_LOG2_SLICE_WIDTH-1 downto 0);
                RB <= lfsr_state( G_LOG2_SLICE_WIDTH + G_Segments_ADDR_WIDTH - 1 downto G_LOG2_SLICE_WIDTH );
                --RC <= lfsr_state(47 downto 32);
                --argMin <= argMin_in;
            -- Process the incoming MHV slice
            elsif update_en = '1' and MHV_addr = RB then
                second <= '1';
                
                -- Record selected QHV slice
                QHV_t <= QHV;
                
                -- Record selected MHV  slice for all the Classes
                MHV_t <= MHV;
            end if;
            --------------------------------------------------------------
            -- argMin is now ready.
            -- Select only the candidate belonging to argMin.
            --------------------------------------------------------------
            if update_wr = '1' then
    
                argmin_int := to_integer(unsigned(argMin_in));
                ra_int     := to_integer(unsigned(RA));
                if argmin_int < Model_NUM then
                    
                    -- Select the current class slice and generate its update candidate
                    selected_mhv := MHV_t( (argmin_int+1)*SLICE_WIDTH-1 downto argmin_int*SLICE_WIDTH );

                    -- Copy or inverted-copy the selected QHV bit
                    selected_mhv(ra_int) := QHV_t(ra_int) xor Penalty;
                    
                    Updated_MHV_slice <=  selected_mhv;
    
                    argMin_out   <= argMin_in;
                    update_valid <= '1' and second; -- Skips first time update when there is not en
    
                end if;
    
            end if;
        end if;
    end process;
    
    u_LFSR: LFSR
	port map( clk=> clk,
			  state => lfsr_state );
end Behavioral;
