----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/21/2026 11:58:24 PM
-- Design Name: 
-- Module Name: HDC_Interconnect - Behavioral
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

entity HDC_Interconnect is
    generic(
            
            --bcache_depth:           integer := 32; --128/(128/4)
            bcache_depth_clogb2:    integer := 5;
            --bcache_base_addr   :    std_logic_vector(31 downto 0) := X"34001000"; 
             
            Icache_depth:           integer := 8;
            Icache_depth_clogb2:    integer := 3;
            Icache_base_addr   :    std_logic_vector(31 downto 0) := X"34002000";
            
            instcache_depth:           integer := 128;
            instcache_depth_clogb2:    integer := 7;
            Instcache_base_addr   :    std_logic_vector(31 downto 0) := X"34000000";
            
            Mcache_depth:           integer := 128;
            Mcache_depth_clogb2:    integer := 7;
            Mcache_base_addr   :    std_logic_vector(31 downto 0) := X"34003000";
            Mcache_result_addr :    std_logic_vector(31 downto 0) := X"34004000";
            Mcache_result_depth:    integer := 1;
            
            --AXI Master Bus
            G_AXI_ADDR_WIDTH : integer := 32;
            G_AXI_DATA_WIDTH : integer := 128;
            RWSIZE: std_logic_vector := "100"; -- Transfer size per Beat: 000: 1Byte, 001: 2 Byte, 010: 4 Byte, 011: 8 Byte, 100: 16 Byte, 101: 32 Byte, 110: 64 Byte, , 111: 128 Byte
            --G_LEN_WIDTH      : integer := 4; --128 bits = 16 bytes
            G_ID_WIDTH       : integer := 1 
    );
    Port (
        
        --switch control signals
        clk       : in  STD_LOGIC;
        rst       : in  STD_LOGIC;
        cmd_valid : in  STD_LOGIC;
        wr_nrd    : in  std_logic;
        mem_select: in  std_logic_vector(1 downto 0); --Two bit select for Binary Chache sel(0), Int Cache sel(1), INST_cache sel(2), and Mchache sel(3)
        busy      : out std_logic;
        
        -- cache ports
        data_out     : out std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
        
        Bcache_wr_en    : out std_logic;
        Bcache_rd_en    : out std_logic;
        Bcache_addr     : out std_logic_vector(bcache_depth_clogb2-1 downto 0);
        Bcache_In_Data  : in std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
        ctrl_bcache_base_addr: in std_logic_vector(31 downto 0) := X"34001000";
        ctrl_bcache_depth    : in std_logic_vector(bcache_depth_clogb2   downto 0); --m_axi_arlen_t +1 bit 
        ctrl_bcache_start    : in std_logic_vector(bcache_depth_clogb2-1 downto 0);
        
        Icache_wr_en    : out std_logic;
        Icache_rd_en    : out std_logic;
        Icache_addr     : out std_logic_vector(Icache_depth_clogb2-1 downto 0);
        Icache_In_Data  : in std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
        
        Instcache_wr_en    : out std_logic;
        Instcache_rd_en    : out std_logic;
        Instcache_addr     : out std_logic_vector(Instcache_depth_clogb2-1 downto 0);
        Instcache_In_Data  : in std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
        
        Mcache_wr_en    : out std_logic;
        Mcache_rd_en    : out std_logic;
        Mcache_addr     : out std_logic_vector(Mcache_depth_clogb2-1 downto 0);
        Mcache_In_Data  : in std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
        ------------------------------------------------------------------------
        -- AXI ports
        -- AXI4 master write address
        m_axi_awid     : out std_logic_vector(G_ID_WIDTH-1 downto 0);
        m_axi_awaddr   : out std_logic_vector(G_AXI_ADDR_WIDTH-1 downto 0);
        m_axi_awlen    : out std_logic_vector(7 downto 0); -- Number of Beats in Burst = awlen+1
        m_axi_awsize   : out std_logic_vector(2 downto 0); -- Transfer size per Beat: 000: 1Byte, 001: 2 Byte, 010: 4 Byte, 011: 8 Byte, 100: 16 Byte, 101: 32 Byte, 110: 64 Byte, , 111: 128 Byte
        m_axi_awburst  : out std_logic_vector(1 downto 0); -- 00: Fixed, 01: INCR, 10: WRAP, 11: Resereved
        m_axi_awvalid  : out std_logic;
        m_axi_awready  : in  std_logic;
    
        -- AXI4 master write data
        m_axi_wdata    : out std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
        m_axi_wstrb    : out std_logic_vector((G_AXI_DATA_WIDTH/8)-1 downto 0);
        m_axi_wlast    : out std_logic;
        m_axi_wvalid   : out std_logic;
        m_axi_wready   : in  std_logic;
    
        -- AXI4 master write response
        m_axi_bid      : in  std_logic_vector(G_ID_WIDTH-1 downto 0);
        m_axi_bresp    : in  std_logic_vector(1 downto 0);
        m_axi_bvalid   : in  std_logic;
        m_axi_bready   : out std_logic;
    
        -- AXI4 master read address
        m_axi_arid     : out std_logic_vector(G_ID_WIDTH-1 downto 0);
        m_axi_araddr   : out std_logic_vector(G_AXI_ADDR_WIDTH-1 downto 0);
        m_axi_arlen    : out std_logic_vector(7 downto 0);
        m_axi_arsize   : out std_logic_vector(2 downto 0);
        m_axi_arburst  : out std_logic_vector(1 downto 0);
        m_axi_arvalid  : out std_logic;
        m_axi_arready  : in  std_logic;
    
        -- AXI4 master read data
        m_axi_rid      : in  std_logic_vector(G_ID_WIDTH-1 downto 0);
        m_axi_rdata    : in  std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
        m_axi_rresp    : in  std_logic_vector(1 downto 0);
        m_axi_rlast    : in  std_logic;
        m_axi_rvalid   : in  std_logic;
        m_axi_rready   : out std_logic 
    );
end HDC_Interconnect;

architecture Behavioral of HDC_Interconnect is

    signal mem_select_lached: std_logic_vector(1 downto 0) := "00"; 
    signal cmd_valid_last: std_logic := '0';
--/////////////////////////////////////////////////////////	 
--/////////////////////////////////////////////////////////
--/////////////////	AXI MM         //////////////////////
-- AXI Memory Map Signals
    --signal rd_data_reg : std_logic_vector(G_NUM_SEGMENTS*G_AXI_DATA_WIDTH-1 downto 0);
    signal m_axi_awid_t     : std_logic_vector(G_ID_WIDTH-1 downto 0) := (others => '0');
    signal m_axi_awaddr_t   : std_logic_vector(G_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal m_axi_awlen_t    : std_logic_vector(7 downto 0) := (others => '0');
    signal m_axi_awsize_t   : std_logic_vector(2 downto 0) := (others => '0');
    signal m_axi_awburst_t  : std_logic_vector(1 downto 0) := (others => '0');
    signal m_axi_awvalid_t  : std_logic := '0';
    --signal m_axi_awready_t  : std_logic := '0';
    
    -- AXI4 master write data 
    signal m_axi_wdata_t    : std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal m_axi_wstrb_t    : std_logic_vector((G_AXI_DATA_WIDTH/8)-1 downto 0) := (others => '0');
    signal m_axi_wlast_t    : std_logic := '0';
    signal m_axi_wvalid_t   : std_logic := '0';
    --signal m_axi_wready_t   : std_logic := '0';
    
    -- AXI4 master write response
    --signal m_axi_bid_t      : std_logic_vector(G_ID_WIDTH-1 downto 0) := (others => '0');
    --signal m_axi_bresp_t    : std_logic_vector(1 downto 0) := (others => '0');
    --signal m_axi_bvalid_t   : std_logic := '0';
    signal m_axi_bready_t   : std_logic := '0';
    
    -- AXI4 master read address
    signal m_axi_arid_t     : std_logic_vector(G_ID_WIDTH-1 downto 0) := (others => '0');
    signal m_axi_araddr_t   : std_logic_vector(G_AXI_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal m_axi_arlen_t    : std_logic_vector(7 downto 0) := (others => '0');
    signal m_axi_arsize_t   : std_logic_vector(2 downto 0) := (others => '0');
    signal m_axi_arburst_t  : std_logic_vector(1 downto 0) := (others => '0');
    signal m_axi_arvalid_t  : std_logic := '0';

    signal m_axi_rready_t   : std_logic := '0';
    signal en_last: std_logic := '0';
    signal write_counter: std_logic_vector( 9 downto 0 ) := (others => '0'); 
    
    signal Bcache_addr_t     : std_logic_vector(bcache_depth_clogb2-1 downto 0):= (others => '0'); 
    
    type t_state is (
        S_IDLE,
        S_RD_ADDR,
        S_RD_DATA,
        S_WR_ADDR,
        S_WR_DATA_1,
        S_WR_DATA_2,
        S_WR_RESP,
        S_DONE,
        S_ERR
      );
    signal state            : t_state;	  
	 
begin
 
process(clk)
    variable read_counter: integer := 0;
    variable C_Max_idx: integer := 0;
    
    begin
    if rising_edge(clk) then
      if rst = '1' then
      
        read_counter:= 0;
        write_counter  <= (others => '0');
        --Address read reset
        m_axi_araddr_t<= (others=>'0');
        m_axi_arvalid_t<= '0';
        --Read reset
        m_axi_rready_t <= '0';
        
        --B reset
        m_axi_bready_t <= '0';
        
        --Write reset
        m_axi_wvalid_t<= '0';
        m_axi_wlast_t<= '0';
        m_axi_wstrb_t <= (others => '0');
        m_axi_wdata_t <= (others => '0');
        
        -- Address Write reset
        m_axi_awvalid_t <= '0';
        m_axi_awaddr_t<= (others => '0');
        
        en_last <= '0';
        busy <= '0';
        state<= S_IDLE;
    
        Bcache_addr_t   <= (others => '0');
        Bcache_rd_en  <= '0';
        Bcache_wr_en  <= '0';
        
        Icache_addr   <= (others => '0');
        Icache_rd_en  <= '0';
        Icache_wr_en  <= '0';
        
        Instcache_addr   <= (others => '0');
        Instcache_rd_en  <= '0';
        Instcache_wr_en  <= '0';
        
        Mcache_addr   <= (others => '0');
        Mcache_rd_en  <= '0';
        Mcache_wr_en  <= '0';
        
        cmd_valid_last <= '0';
        
        m_axi_arlen_t <=(others=>'0');
        m_axi_awlen_t <=(others=>'0');
        
      else
        cmd_valid_last <= cmd_valid;
        --Bcache_addr_t   <= (others => '0');
        --Bcache_rd_en  <= '0';
        Bcache_wr_en  <= '0';
        
        --Icache_addr   <= (others => '0');
        --Icache_rd_en  <= '0';
        Icache_wr_en  <= '0';
        
        --Instcache_addr   <= (others => '0');
        --Instcache_rd_en  <= '0';
        Instcache_wr_en  <= '0';
        
        --Mcache_addr   <= (others => '0');
        --Mcache_rd_en  <= '0';
        Mcache_wr_en  <= '0';
        case state is
          when S_IDLE =>
            busy <= '0';
            m_axi_arlen_t <=(others=>'0');
            m_axi_awlen_t <=(others=>'0');
            
            m_axi_rready_t <= '0';
            m_axi_araddr_t<= (others=>'0');
            m_axi_arvalid_t<= '0';
            m_axi_wstrb_t <= (others=>'0');
            
            Bcache_addr_t   <= (others => '0');
            Bcache_rd_en  <= '0';
            Bcache_wr_en  <= '0';
            
            Icache_addr   <= (others => '0');
            Icache_rd_en  <= '0';
            Icache_wr_en  <= '0';
            
            Instcache_addr   <= (others => '0');
            Instcache_rd_en  <= '0';
            Instcache_wr_en  <= '0';
            
            Mcache_addr   <= (others => '0');
            Mcache_rd_en  <= '0';
            Mcache_wr_en  <= '0';
            
            if wr_nrd = '0' and cmd_valid_last ='0' and cmd_valid ='1' then
                busy <= '1';
                mem_select_lached <= mem_select;
                if mem_select = "00" then    -- Binary Cache (BCache)
                   --m_axi_arlen_t <= std_logic_vector(to_unsigned(bcache_depth - 1, 8)); --32-1=31
                   --C_Max_idx := BCache_depth -1;
                   m_axi_arlen_t(bcache_depth_clogb2 downto 0) <= std_logic_vector(unsigned(ctrl_bcache_depth) - 1);     
                   C_Max_idx := to_integer(unsigned(ctrl_BCache_depth)) -1;   
                   m_axi_araddr_t <= ctrl_bcache_base_addr;
                   
                   Bcache_addr_t   <= ctrl_bcache_start;
                   --Bcache_wr_en  <= '1';
                elsif mem_select = "01" then    -- Int Cache (ICache)
                   m_axi_arlen_t <= std_logic_vector(to_unsigned(Icache_depth - 1, 8));
                   C_Max_idx := ICache_depth -1;
                   m_axi_araddr_t <= Icache_base_addr;
                   
                   Icache_addr   <= (others => '0');
                   --Icache_wr_en  <= '1';
                elsif mem_select = "10" then    -- Instruction Cache (InstCache)
                   m_axi_arlen_t <= std_logic_vector(to_unsigned(Instcache_depth - 1, 8));
                   C_Max_idx := InstCache_depth -1;
                   m_axi_araddr_t <= Instcache_base_addr;
                   
                   Instcache_addr   <= (others => '0');
                   --Instcache_wr_en  <= '1';
                else                      --Model Cache (MCache)
                   m_axi_arlen_t <= std_logic_vector(to_unsigned(Mcache_depth - 1, 8));
                   C_Max_idx := MCache_depth -1;
                   m_axi_araddr_t <= Mcache_base_addr;
                   
                   Mcache_addr   <= (others => '0');
                   --Mcache_wr_en  <= '1';
                end if;
                
                state <= S_RD_ADDR;
            elsif wr_nrd = '1' and cmd_valid_last ='0' and cmd_valid ='1' then
                busy <= '1';
                mem_select_lached <= mem_select;
                if mem_select = "00" then    -- Binary Cache (BCache)
                   m_axi_awlen_t(bcache_depth_clogb2 downto 0)  <= std_logic_vector(unsigned(ctrl_bcache_depth) - 1);  
                   C_Max_idx := to_integer(unsigned(ctrl_BCache_depth)) -1;
                   m_axi_awaddr_t <= ctrl_bcache_base_addr;
                elsif mem_select = "01" then    -- Int Cache (ICache)
                   m_axi_awlen_t <= std_logic_vector(to_unsigned(Icache_depth - 1, 8));
                   C_Max_idx := ICache_depth -1;
                   m_axi_awaddr_t <= Icache_base_addr; 
                elsif mem_select = "10" then    -- Instruction Cache (InstCache)
                   m_axi_awlen_t <= std_logic_vector(to_unsigned(Instcache_depth - 1, 8));
                   C_Max_idx := InstCache_depth -1;
                   m_axi_awaddr_t <= Instcache_base_addr;
                else                      --Model Cache (MCache)
                   m_axi_awlen_t <= std_logic_vector(to_unsigned(Mcache_result_depth - 1, 8));
                   C_Max_idx := Mcache_result_depth -1;
                   m_axi_awaddr_t <= Mcache_result_addr;
                end if;
                
                state <= S_WR_ADDR;
            end if;
            
          when S_RD_ADDR =>
                m_axi_arvalid_t <= '1';
                write_counter  <= (others => '0');
                if m_axi_arvalid_t = '1' and m_axi_arready = '1' then
                    m_axi_arvalid_t <= '0';
                    m_axi_rready_t  <= '1';
                    read_counter := 0;
                    state <= S_RD_DATA;
                end if;  
          when S_RD_DATA =>
            m_axi_rready_t <= '1';
            if m_axi_rvalid = '1' then
                if mem_select_lached = "00" then    -- Binary Cache (BCache)
                   Bcache_addr_t   <= std_logic_vector(to_unsigned(read_counter, Bcache_addr_t'length));
                   Bcache_wr_en  <= '1';
                elsif mem_select_lached = "01" then    -- Int Cache (ICache)
                   Icache_addr   <= std_logic_vector(to_unsigned(read_counter, Icache_addr'length));
                   Icache_wr_en  <= '1';
                elsif mem_select_lached = "10" then    -- Instruction Cache (InstCache)
                   Instcache_addr   <= std_logic_vector(to_unsigned(read_counter, Instcache_addr'length));
                   Instcache_wr_en  <= '1';
                else                      --Model Cache (MCache)
                   Mcache_addr   <= std_logic_vector(to_unsigned(read_counter, Mcache_addr'length));
                   Mcache_wr_en  <= '1';
                end if;
                data_out <= m_axi_rdata; -- Read from AXI, write to cache
                
                if read_counter < C_Max_idx then
                    read_counter := read_counter + 1;
                end if;
        
                if m_axi_rlast = '1' then
                    m_axi_rready_t <= '0';
                    busy <= '0';
                    state <= S_IDLE;
                end if;
            end if;
          when S_WR_ADDR =>
                m_axi_awvalid_t <= '1';
                m_axi_wlast_t <= '0';
                m_axi_wvalid_t  <= '0';
                -- Prepare first data beat
                write_counter  <= (others => '0'); 
                -- Move on once address is accepted
                if (m_axi_awvalid_t = '1' and m_axi_awready = '1') then
                    
                    if mem_select_lached = "00" then    -- Binary Cache (BCache)
                                        
                       Bcache_addr_t   <= ctrl_bcache_start;
                       Bcache_rd_en  <= '1';
                    elsif mem_select_lached = "01" then    -- Int Cache (ICache)
                       
                       Icache_addr   <= (others => '0');
                       Icache_rd_en  <= '1';
                    elsif mem_select_lached = "10" then    -- Instruction Cache (InstCache)
                       
                       Instcache_addr   <= (others => '0');
                       Instcache_rd_en  <= '1';
                    else                      --Model Cache (MCache)
                       
                       Mcache_addr   <= (others => '0');
                       Mcache_rd_en  <= '1';
                    end if;
                    --m_axi_wstrb_t   <= (others => '1');
                    m_axi_awvalid_t <= '0';
                    state <= S_WR_DATA_1;
                end if;
          when S_WR_DATA_1 =>
                m_axi_wvalid_t  <= '1';
                if TO_INTEGER(unsigned(write_counter))  = C_Max_idx then -- to transfer the Last Beat
                    m_axi_wlast_t <= '1';
                else -- Its not Last Beat
                    m_axi_wlast_t <= '0';
                end if;
                if mem_select_lached = "00" then    -- Binary Cache (BCache)
                   m_axi_wdata_t <= Bcache_In_Data; -- This is the data already valid from address 0 of the cache and rd_en = '1'
                   m_axi_wstrb_t <= (others => '1');
                   Bcache_rd_en  <= '0';
                elsif mem_select_lached = "01" then    -- Int Cache (ICache)
                   m_axi_wdata_t <= Icache_In_Data; -- This is the data already valid from address 0 of the cache and rd_en = '1'
                   m_axi_wstrb_t <= (others => '1');
                   Icache_rd_en  <= '0';
                elsif mem_select_lached = "10" then    -- Instruction Cache (InstCache)
                   m_axi_wdata_t <= Instcache_In_Data; -- This is the data already valid from address 0 of the cache and rd_en = '1'
                   m_axi_wstrb_t <= (others => '1');
                   Instcache_rd_en  <= '0';
                else                      --Model Cache (MCache)
                   m_axi_wdata_t <= Mcache_In_Data; -- This is the data already valid from address 0 of the cache and rd_en = '1'
                   m_axi_wstrb_t <= (others => '1');
                   Mcache_rd_en  <= '0';
                end if;
                state <= S_WR_DATA_2;
          when S_WR_DATA_2 => 
            if (m_axi_wvalid_t = '1' and m_axi_wready = '1') then --Finished Beat transfer
                -- Current beat just got accepted
                if TO_INTEGER(unsigned(write_counter)) = C_Max_idx then --Last transfer Finished
                    m_axi_wvalid_t <= '0';
                    m_axi_wlast_t  <= '0';
                    m_axi_bready_t <= '1';
                    state          <= S_WR_RESP;
                elsif TO_INTEGER(unsigned(write_counter)+1)  = C_Max_idx then -- to transfer the Last Beat
                    m_axi_wvalid_t <= '0';
                    m_axi_wlast_t <= '1';
                    if mem_select_lached = "00" then    -- Binary Cache (BCache)
                       Bcache_addr_t   <= std_logic_vector(to_unsigned(to_integer(unsigned(write_counter)) + 1, Bcache_addr_t'length));
                       Bcache_rd_en  <= '1';
                    elsif mem_select_lached = "01" then    -- Int Cache (ICache)
                       Icache_addr   <= std_logic_vector(to_unsigned(to_integer(unsigned(write_counter)) + 1, Icache_addr'length));
                       Icache_rd_en  <= '1';
                    elsif mem_select_lached = "10" then    -- Instruction Cache (InstCache)
                       Instcache_addr   <= std_logic_vector(to_unsigned(to_integer(unsigned(write_counter)) + 1, Instcache_addr'length));
                       Instcache_rd_en  <= '1';
                    else                      --Model Cache (MCache)
                       Mcache_addr   <= std_logic_vector(to_unsigned(to_integer(unsigned(write_counter)) + 1, Mcache_addr'length));
                       Mcache_rd_en  <= '1';
                    end if;
                    state          <= S_WR_DATA_1;
                else -- One Beat transfered
                    -- Advance to next beat
                    m_axi_wvalid_t <= '0';
                    m_axi_wlast_t <= '0';
                    if mem_select_lached = "00" then    -- Binary Cache (BCache)
                       Bcache_addr_t   <= std_logic_vector(to_unsigned(to_integer(unsigned(write_counter)) + 1, Bcache_addr_t'length));
                       Bcache_rd_en  <= '1';
                    elsif mem_select_lached = "01" then    -- Int Cache (ICache)
                       Icache_addr   <= std_logic_vector(to_unsigned(to_integer(unsigned(write_counter)) + 1, Icache_addr'length));
                       Icache_rd_en  <= '1';
                    elsif mem_select_lached = "10" then    -- Instruction Cache (InstCache)
                       Instcache_addr   <= std_logic_vector(to_unsigned(to_integer(unsigned(write_counter)) + 1, Instcache_addr'length));
                       Instcache_rd_en  <= '1';
                    else                      --Model Cache (MCache)
                       Mcache_addr   <= std_logic_vector(to_unsigned(to_integer(unsigned(write_counter)) + 1, Mcache_addr'length));
                       Mcache_rd_en  <= '1';
                    end if;
                    state          <= S_WR_DATA_1;
                end if;
                write_counter <= std_logic_vector(unsigned(write_counter) + 1);
            end if;
          when S_WR_RESP =>
            if (m_axi_bvalid = '1' and m_axi_bready_t = '1') then
                m_axi_bready_t <= '0';
                if m_axi_bresp = "00" then
                    busy  <= '0';
                    state <= S_IDLE;
                else
                    --state <= S_ERR;
                    busy  <= '0';
                    state <= S_IDLE;
                end if;
            end if;
          when others =>
            state <= S_IDLE;
            busy <= '0';
        end case;
      end if;
    end if;
    end process;

--------------------- Assignments-----------------
--IO mapping
m_axi_awid<= m_axi_awid_t;--    : out std_logic_vector(G_ID_WIDTH-1 downto 0);
m_axi_awaddr<= m_axi_awaddr_t;--   : out std_logic_vector(G_AXI_ADDR_WIDTH-1 downto 0);
m_axi_awlen<= m_axi_awlen_t;--    : out std_logic_vector(7 downto 0); -- Number of Beats in Burst = awlen+1
m_axi_awsize<= m_axi_awsize_t;--   : out std_logic_vector(2 downto 0); -- Transfer size per Beat: 000: 1Byte, 001: 2 Byte, 010: 4 Byte, 011: 8 Byte, 100: 16 Byte, 101: 32 Byte, 110: 64 Byte, , 111: 128 Byte
m_axi_awburst<= m_axi_awburst_t;--  : out std_logic_vector(1 downto 0); -- 00: Fixed, 01: INCR, 10: WRAP, 11: Resereved
m_axi_awvalid<=m_axi_awvalid_t;--  : out std_logic;
--m_axi_awready_t<=m_axi_awready;--  : in  std_logic;

-- AXI4 master write data
--m_axi_wdata<=m_axi_wdata_t;--    : out std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);

m_axi_wdata<= Bcache_In_Data    when mem_select_lached = "00" else
              Icache_In_Data    when mem_select_lached = "01" else
              Instcache_In_Data when mem_select_lached = "10" else
              Mcache_In_Data;


m_axi_wstrb<=m_axi_wstrb_t;--    : out std_logic_vector((G_AXI_DATA_WIDTH/8)-1 downto 0);
m_axi_wlast<=m_axi_wlast_t;--    : out std_logic;
m_axi_wvalid<=m_axi_wvalid_t;--   : out std_logic;
--m_axi_wready_t<=m_axi_wready;--   : in  std_logic;

-- AXI4 master write response
--m_axi_bid_t<=m_axi_bid;--      : in  std_logic_vector(G_ID_WIDTH-1 downto 0);
--m_axi_bresp_t<=m_axi_bresp;--    : in  std_logic_vector(1 downto 0);
--m_axi_bvalid_t<=m_axi_bvalid;--   : in  std_logic;
m_axi_bready<=m_axi_bready_t;--   : out std_logic;

-- AXI4 master read address
m_axi_arid<=m_axi_arid_t;--     : out std_logic_vector(G_ID_WIDTH-1 downto 0);
m_axi_araddr<=m_axi_araddr_t;--   : out std_logic_vector(G_AXI_ADDR_WIDTH-1 downto 0);
m_axi_arlen<=m_axi_arlen_t;--    : out std_logic_vector(7 downto 0);
m_axi_arsize<=m_axi_arsize_t;--   : out std_logic_vector(2 downto 0);
m_axi_arburst<=m_axi_arburst_t;--  : out std_logic_vector(1 downto 0);
m_axi_arvalid<=m_axi_arvalid_t;--  : out std_logic;
--m_axi_arready_t<=m_axi_arready;--  : in  std_logic;

-- AXI4 master read data
--m_axi_rid_t<=m_axi_rid;--      : in  std_logic_vector(G_ID_WIDTH-1 downto 0);
--m_axi_rdata_t<=m_axi_rdata;--    : in  std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
--m_axi_rresp_t<=m_axi_rresp;--    : in  std_logic_vector(1 downto 0);
--m_axi_rlast_t<=m_axi_rlast;--    : in  std_logic;
--m_axi_rvalid_t<=m_axi_rvalid;--   : in  std_logic;
m_axi_rready<=m_axi_rready_t;--   : out std_logic


-- Constant setup
m_axi_awsize_t <= RWSIZE; --010: 4 Byte
m_axi_arsize_t <= RWSIZE; --000: 4 Byte
m_axi_awburst_t <= "01"; -- 00: Fixed, 01: INCR, 10: WRAP, 11: Resereved
m_axi_arburst_t <= "01"; -- 00: Fixed, 01: INCR, 10: WRAP, 11: Resereved
--m_axi_awlen_t<= std_logic_vector(to_unsigned(G_NUM_Classes, 8)-1);-- 7 Beats transfer out std_logic_vector(7 downto 0); -- Number of Beats in Burst = awlen+1
--m_axi_arlen_t<= std_logic_vector(to_unsigned(G_alen_t, 8));-- 224 Beats transfer out std_logic_vector(7 downto 0); -- Number of Beats in Burst = arlen+1

Bcache_addr <= std_logic_vector(unsigned(Bcache_addr_t)+unsigned(ctrl_bcache_start));

end Behavioral;