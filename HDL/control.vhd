----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/16/2023 09:40:31 PM
-- Design Name: 
-- Module Name: control - Behavioral
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

entity control is
    generic(
            --------- AXI Generics
            -- Width of S_AXI data bus
            C_S_AXI_DATA_WIDTH	: integer	:= 32;
            -- Width of S_AXI address bus
            C_S_AXI_ADDR_WIDTH	: integer	:= 6;
            
            ----------------------------
    
            G_AXI_DATA_WIDTH:   integer	:= 128;
            i_cache_port2_data_size:      integer := 32;
            i_cache_depth:                integer := 128;
            i_cache_depth_clogb2:         integer := 7;
            int_cache_depth:                integer := 32;
            int_cache_depth_clogb2:         integer := 5;
            binary_cache_depth:           integer := 128;
            binary_cache_depth_clogb2:    integer := 7;
            
            --No need! its always fix
            bcache_In_select_size:   integer := 2;  --clogb2(ROT_threads+XOR_threads+MAJ_threads); clogb2(1+1+1) = 2
            intcache_In_select_size: integer := 1; --clogb2(PSUM_threads);
            
            int_size:                     integer := 2;
            total_cache_count         :   integer   := 4;
            total_cache_count_clogb2  :   integer   := 2;
            
            ROT_amount_clog2:             integer := 3
    );
    port(
        clk     : in std_logic;
        reset   : in std_logic;
        irq     : out std_logic;
        --port1
        addr1 : in std_logic_vector((i_cache_depth_clogb2 - 2)-1 downto 0);
        wr_en1  : in std_logic;
        rd_en1  : in std_logic;
        din1    : in std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0);
        dout1   : out std_logic_vector(G_AXI_DATA_WIDTH-1 downto 0); 
        
        ------------------------------------
        ------    AXI Ports ----------------
        ------------------------------------
        
        -- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic;
        
        
        ----------------------------------
        --------- Control registers ------

        ----------------------------------
        --------- Control signals   ------
        rst     : out std_logic;
        ctrl_sw_busy      : in std_logic;
        ctrl_sw_cmd_valid : out std_logic;
        ctrl_sw_wr_nrd    : out std_logic;
        ctrl_sw_mem_select: out std_logic_vector(total_cache_count_clogb2-1 downto 0) := (others => '0');
        ctrl_sw_bcache_base_addr: out std_logic_vector(31 downto 0) := X"34001000";
        ctrl_sw_bcache_depth: out std_logic_vector(binary_cache_depth_clogb2-2   downto 0); --m_axi_arlen_t +1 bit
        ctrl_sw_bcache_start: out std_logic_vector(binary_cache_depth_clogb2-2-1 downto 0); --depth in 128-bit words 128 rows in 32-bit becomes 32 in 128-bit mode
        
        
        --ctrl_wr_en_bus    : out std_logic_vector(total_cache_count-1 downto 0);
        --ctrl_rd_en_bus    : out std_logic_vector(total_cache_count-1 downto 0);
        ctrl_wr_en_1    : out std_logic; --binary cache
		ctrl_wr_en_2    : out std_logic; --integer cache
        ctrl_rd_en_1    : out std_logic; --binary cache
		ctrl_rd_en_2    : out std_logic; --integer cache
		
		--ctrl_addr_bus     : out std_logic_vector((total_cache_count*max_cache_depth_clogb2)-1 downto 0); --address_bus;
		ctrl_addr1     : out std_logic_vector(binary_cache_depth_clogb2-1 downto 0); --address_bus; binary cache
		ctrl_addr2     : out std_logic_vector(i_cache_depth_clogb2-1 downto 0); --address_bus; integer cache
        
        --ctrl_xor_cache_selects     : out binary_cache_select_array(1-1 downto 0);
        ctrl_xor_in_valids         : out std_logic_vector(1-1 downto 0);
        ctrl_xor_Load_A_nBs        : out std_logic_vector(1-1 downto 0);
        ctrl_xor_rstB              : out std_logic;
        
        --ctrl_rot_cache_selects     : out binary_cache_select_array(1-1 downto 0);
        ctrl_rot_in_valids         : out std_logic_vector(1-1 downto 0);
        ctrl_rot_load_carry_in     : out std_logic_vector(1-1 downto 0);
        ctrl_rot_amounts           : out std_logic_vector(ROT_amount_clog2-1 downto 0);--ROT_amount_vector(ROT_threads-1 downto 0); 
        
        --ctrl_psum_cache_selects    : out binary_cache_select_array(PSUM_threads-1 downto 0);
        ctrl_psum_in_valids        : out std_logic_vector(1-1 downto 0);
        ctrl_psum_reloads          : out std_logic_vector(1-1 downto 0);
        
        --ctrl_maj_cache_selects     : out int_cache_select_array(1-1 downto 0);
        ctrl_maj_in_valids         : out std_logic_vector(1-1 downto 0);
        ctrl_maj_load_Ts           : out std_logic_vector(1-1 downto 0);
        ctrl_maj_T                 : out std_logic_vector(int_size-1 downto 0); --int_vector(MAJ_threads-1 downto 0);
        
        ctrl_bcache_In_sels        : out std_logic_vector(bcache_In_select_size-1 downto 0);    --bcache_In_selects := (others => (others =>'0'));
        ctrl_intcache_In_sels      : out std_logic_vector(intcache_In_select_size-1 downto 0);   --intcache_selects:= (others => (others =>'0')) 
        
        ctrl_HmmD_clear            : out std_logic;
        ctrl_HmmD_en               : out std_logic;
        ctrl_HmmD_QHV_sel          : out std_logic_vector(1 downto 0); -- XORStr, ROTStr, MAJStr
        ctrl_HmmD_MHV_index        : out std_logic_vector(15 downto 0);-- number of slices in a D
        
        ctrl_UPD_wr                : out std_logic;
        ctrl_UPD_en                : out std_logic;
        ctrl_UPD_argMin            : out std_logic_vector(15 downto 0); 
        ctrl_UPD_Penalty           : out std_logic;
        
        dbg_PC: out std_logic_vector(i_cache_depth_clogb2-1 downto 0);
        dbg_ctrl_state: out std_logic_vector(2 downto 0);
        dbg_inst: out std_logic_vector(i_cache_port2_data_size-1 downto 0)
        );
end control;

architecture Behavioral of control is 
        -- Attribute declarations
    attribute X_INTERFACE_INFO : string;
    attribute X_INTERFACE_PARAMETER : string;
            -- Attribute specifications
    attribute X_INTERFACE_INFO of irq : signal is "xilinx.com:signal:interrupt:1.0 irq INTERRUPT";
    attribute X_INTERFACE_PARAMETER of irq : signal is "SENSITIVITY EDGE_RISING";
component inst_cache is
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
end component;


component UHDC_Regs is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
	);
	port (
		-- Users to add ports here

		-- User ports ends
		REG0_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG1_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG2_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG3_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG4_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG5_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG6_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG7_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG8_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG9_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG10_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG11_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG12_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG13_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG14_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG15_i	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		
		REG0_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG1_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG2_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG3_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG4_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG5_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG6_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG7_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG8_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG9_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG10_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG11_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG12_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG13_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG14_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		REG15_o	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		     
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end component;

type reg_sig is array(15 downto 0) of std_logic_vector(31 downto 0);
signal registers : reg_sig := (others => (others => '0'));

signal rst_tmp : std_logic := '0';
signal start_ff : std_logic := '0';
signal IRQ_release_ff: std_logic := '0';

signal PC      : std_logic_vector(i_cache_depth_clogb2-1 downto 0) := (others => '0');
constant LAST_PC: std_logic_vector(i_cache_depth_clogb2-1 downto 0) := (others => '1');
signal opcode  : std_logic_vector(4 downto 0) := (others => '0');
--signal wr_en2  : std_logic := '0';
signal rd_en2  : std_logic := '0';
--signal din2    : std_logic_vector(i_cache_port2_data_size-1 downto 0) := (others => '0');
signal inst   : std_logic_vector(i_cache_port2_data_size-1 downto 0) := (others => '0');
--signal ctrl_sw_cmd_valid : std_logic := '0';
--signal ctrl_sw_wr_nrd    : std_logic := '0';
--signal ctrl_sw_mem_select:  std_logic_vector(clogb2(total_cache_count)-1 downto 0) := (others => '0');
signal ctrl_sw_busy_ff      : std_logic := '0';

signal inst_A   : std_logic_vector(12 downto 0) := (others => '0');
signal inst_B   : std_logic_vector(12 downto 0) := (others => '0');
signal inst_C   : std_logic_vector(12 downto 0) := (others => '0');
signal inst_D   : std_logic_vector(12 downto 0) := (others => '0');
signal LOOP_cnt : std_logic_vector(12 downto 0) := (others => '0');
signal src_tmp : std_logic_vector(12 downto 0) := (others => '0');
signal src_tmp2 : std_logic_vector(12 downto 0) := (others => '0');
signal dst_tmp : std_logic_vector(12 downto 0) := (others => '0');
signal HmmD_MHV_index_tmp: std_logic_vector(15 downto 0) := (others => '0');
type execute_states is ( 
						fetch,
						--fetch_simulation,
						decode,
						NOP_1,
						BLD_1,
						BLD_2,
						BSTR_1,
						BSTR_2,
						MLD_1,
						MLD_2,
						MSTR_1,
						MSTR_2,  
						ILD_1,  
						ISTR_1, 
						XORLDA_1,
						XORLDB_1,
						XORSTR_1,
						ROTLDB_1,
						ROTLDS_1,
						ROTSTR_1,
						PSUMLDS_1,
						PSUMSTR_1,
						MAJLDL_1,
						MAJLDS_1,
						MAJSTR_1,
						
						
						XORLOOP_1,
						
						ROTLOOP_1,
						ROTLOOP_2,
						ROTLOOP_3,
						ROTLOOP_4,
						ROTLOOP_5,
						ROTLOOP_6,
						
						XORACC_1,
						XORACC_2,
						XORACC_3,
						XORACC_4,
						XORACC_5,
						XORACC_6,
						
						BINLOOP_1,
						BINLOOP_2,
						BINLOOP_3,
						
						PSUMLOOP_1,
						PSUMLOOP_2,
						PSUMLOOP_3,
						
						HmD_En_1
					   );
signal execute_state  : execute_states;


constant inst_NOP     : std_logic_vector(4 downto 0) := "00000";--0
constant inst_BLD     : std_logic_vector(4 downto 0) := "00001";--1
constant inst_BSTR    : std_logic_vector(4 downto 0) := "00010";--2
constant inst_ILD     : std_logic_vector(4 downto 0) := "00011";--3
constant inst_ISTR    : std_logic_vector(4 downto 0) := "00100";--4

constant inst_XORLDA  : std_logic_vector(4 downto 0) := "00101";--5
constant inst_XORLDB  : std_logic_vector(4 downto 0) := "00110";--6
constant inst_XORSTR  : std_logic_vector(4 downto 0) := "00111";--7

constant inst_ROTLDB  : std_logic_vector(4 downto 0) := "01000";--8
constant inst_ROTLDS  : std_logic_vector(4 downto 0) := "01001";--9
constant inst_ROTSTR  : std_logic_vector(4 downto 0) := "01010";--10

constant inst_PSUMLDS : std_logic_vector(4 downto 0) := "01011";--11
constant inst_PSUMSTR : std_logic_vector(4 downto 0) := "01100";--12

constant inst_MAJLDL  : std_logic_vector(4 downto 0) := "01101";--13
constant inst_MAJLDS  : std_logic_vector(4 downto 0) := "01110";--14
constant inst_MAJSTR  : std_logic_vector(4 downto 0) := "01111";--15

constant inst_XORLOOP : std_logic_vector(4 downto 0) := "10000";--16
constant inst_ROTLOOP : std_logic_vector(4 downto 0) := "10001";--17
constant inst_XORACC  : std_logic_vector(4 downto 0) := "10010";--18
constant inst_BINLOOP : std_logic_vector(4 downto 0) := "10011";--19
constant inst_PSUMLOOP: std_logic_vector(4 downto 0) := "10100";--20
constant inst_EPI     : std_logic_vector(4 downto 0) := "10101";--21 --End of Program Interrup
constant inst_UPD     : std_logic_vector(4 downto 0) := "10110";--22 -- update
--constant inst_-     : std_logic_vector(4 downto 0) := "10111";--23
--constant inst_-     : std_logic_vector(4 downto 0) := "11000";--24
--constant inst_-     : std_logic_vector(4 downto 0) := "11001";--25
--constant inst_-     : std_logic_vector(4 downto 0) := "11010";--26

constant inst_MLD     : std_logic_vector(4 downto 0) := "11011";--27
constant inst_MSTR    : std_logic_vector(4 downto 0) := "11100";--28
constant inst_XORHmD  : std_logic_vector(4 downto 0) := "11101";--29
constant inst_ROTHmD  : std_logic_vector(4 downto 0) := "11110";--30
constant inst_MAJHmD  : std_logic_vector(4 downto 0) := "11111";--31
function minimum(a : integer; b : integer) return integer is
begin
    if a < b then
        return a;
    else
        return b;
    end if;
end function; 
constant T_size : positive := minimum(int_size, 13);  

    type control_states is (
                       --reset     -- 000
					   idle,       -- 001
					   inst_read,  -- 010
					   execute,    -- 011
					   IRQ_assert, -- 101
					   finish);    -- 111
	signal cstate : control_states := idle;
begin
    
-- add instruction cache here
   U_Icache: inst_cache
        generic map(
            G_AXI_DATA_WIDTH => G_AXI_DATA_WIDTH,
            i_cache_port2_data_size => i_cache_port2_data_size,
            i_cache_depth => i_cache_depth,
            i_cache_depth_clogb2 => i_cache_depth_clogb2 
        )
        port map(clk => clk,
                 rst => rst_tmp,
                 --port1
                 addr1  => addr1,
                 wr_en1 => wr_en1,
                 rd_en1 => rd_en1,
                 din1   => din1,
                 dout1  => dout1,
                 --port2
                 addr2 =>  PC,
                 --wr_en2 => wr_en2,
                 rd_en2 => rd_en2,
                 --din2   => din2,
                 dout2  => inst
                 );

-----------------------------------
-----------------------------------
---------- control      -----------
-----------------------------------
-----------------------------------
    status_process: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rst_tmp <= '1';
                start_ff <= '0';
                ctrl_sw_busy_ff <= '0';
            else
                ctrl_sw_busy_ff <= ctrl_sw_busy;
                
                rst_tmp  <=  registers(0)(0);
                start_ff <=  registers(0)(1);
            end if;
        end if;   
    end process;   
    

    execute_process: process(clk)
    variable value:        std_logic_vector(26 downto 0)  := (others => '0');
    variable cache_select: std_logic_vector(5 downto 0)  := (others => '0');
    variable row_select:   std_logic_vector(21 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            if rst_tmp ='1' then
                cstate <= idle;
                
                ctrl_sw_cmd_valid <= '0';
                ctrl_sw_wr_nrd    <= '0';

                ctrl_xor_rstB       <= '0'; 
                ctrl_xor_in_valids  <= (others => '0');
                ctrl_rot_in_valids  <= (others => '0');
                ctrl_maj_in_valids  <= (others => '0');
                ctrl_psum_in_valids <= (others => '0');
                
                --ctrl_rd_en_bus      <= (others => '0');
                --ctrl_wr_en_bus      <= (others => '0');
				ctrl_rd_en_1      <= '0';
				ctrl_rd_en_2      <= '0';
				ctrl_wr_en_1      <= '0';
				ctrl_wr_en_2      <= '0';
				
				
				ctrl_sw_bcache_start <= (others => '0');
				ctrl_sw_bcache_depth <= (others => '0');
				
                --ctrl_addr_bus       <= (others =>  '0');
				ctrl_addr1			<= (others =>  '0');
				ctrl_addr2			<= (others =>  '0');
                                    
                rd_en2 <= '1';
                
                execute_state <= fetch;
                
                -------------------------
                -------------------------
                ctrl_rot_amounts <= (others =>  '0');
                ctrl_maj_T <= (others =>  '0');
                
                PC <= (others => '0');
                dbg_ctrl_state<= "000"; --debug
                
                ctrl_HmmD_QHV_sel <= "00";
                ctrl_HmmD_clear <= '1';
                ctrl_HmmD_en    <= '0';
                HmmD_MHV_index_tmp <= (others =>'0');
                
                irq <= '0';
                IRQ_release_ff <=  '0';
            elsif cstate = idle then
                ctrl_sw_bcache_start <= (others => '0');
				ctrl_sw_bcache_depth <= (others => '0');
                
                dbg_ctrl_state<= "001"; --debug
                PC <= (others => '0');
                irq <= '0';
                IRQ_release_ff <=  '0';
                if registers(0)(1) = '1' and start_ff = '0' then
                    --To Load the App
                    if registers(0)(3)='0' then
                        cstate <= inst_read;
                        ctrl_sw_cmd_valid <= '1';
                        ctrl_sw_wr_nrd    <= '0';
                        ctrl_sw_mem_select<= "10"; --i_cache std_logic_vector(to_unsigned(total_cache_count-1, ctrl_sw_mem_select'length));
                    --Or to rerun the same App
                    else
                        cstate <= execute;
                        execute_state <= fetch;
                        ctrl_sw_cmd_valid <= '0';
                        ctrl_sw_wr_nrd    <= '0';
                        PC<= (others=>'0');
                        rd_en2 <= '1';  -- request instruction 0
                    end if;    
                end if;
            elsif cstate = inst_read then
                dbg_ctrl_state<= "010"; --debug
                ctrl_sw_cmd_valid <= '0';
                ctrl_sw_wr_nrd    <= '0';
                
                if ctrl_sw_busy_ff='1' and ctrl_sw_busy='0' then
                    cstate <= execute;
                    execute_state <= fetch;
                    PC<= (others=>'0');
                    rd_en2 <= '1';  -- request instruction 0
                end if;
            elsif cstate = IRQ_assert then
                dbg_ctrl_state<= "101"; --debug
                IRQ_release_ff <=  registers(0)(2);
                if IRQ_release_ff= '1' and registers(0)(2) = '0' then
                   irq <= '0';
                   cstate <= Idle;
                end if;
            elsif cstate = execute and to_integer(unsigned(PC)) < i_cache_depth then
                dbg_ctrl_state<= "011"; --debug
                case execute_state is
                    when fetch  =>
                        
                        ctrl_sw_cmd_valid <= '0';
                        ctrl_sw_wr_nrd    <= '0';
                        
                        ctrl_bcache_In_sels    <= (others =>  '0');
                        ctrl_intcache_In_sels  <= (others => '0');
                        
                        ctrl_sw_bcache_start <= (others => '0');
				        ctrl_sw_bcache_depth <= (others => '0');
                        
                        --ctrl_rd_en_bus         <= (others=>'0');
                        --ctrl_wr_en_bus         <= (others=>'0');
                        ctrl_rd_en_1      <= '0';
                        ctrl_rd_en_2      <= '0';
                        ctrl_wr_en_1      <= '0';
                        ctrl_wr_en_2      <= '0';
                        
                        ctrl_xor_in_valids     <= (others => '0');
                        ctrl_xor_Load_A_nBs    <= (others => '0');
                        ctrl_xor_rstB          <= '0';
                        --ctrl_xor_cache_selects <= (others => (others => '0'));
                        
                        --ctrl_rot_cache_selects   <= (others => (others => '0'));
                        ctrl_rot_in_valids       <= (others => '0');
                        ctrl_rot_load_carry_in   <= (others => '0');
                        
                        --ctrl_psum_cache_selects  <= (others => (others => '0'));
                        ctrl_psum_in_valids      <= (others => '0');
                        ctrl_psum_reloads        <= (others => '0');
                        
                        --ctrl_maj_cache_selects   <= (others => (others => '0'));
                        ctrl_maj_in_valids       <= (others => '0');
                        ctrl_maj_load_Ts         <= (others => '0');
                        
                        --Hamming Distance Module
                        ctrl_HmmD_en    <= '0';
                        ctrl_HmmD_MHV_index <= HmmD_MHV_index_tmp;
                        
                        
                        
                        rd_en2 <= '0';
                        
                        ctrl_HmmD_clear <= '0';
                        --execute_state <= fetch_simulation;
                        if PC = LAST_PC then
                           cstate <= IRQ_assert;
                           execute_state <= fetch;
                           irq <= '1';
                        else
                            execute_state <= decode;
                        end if;
                    --when fetch_simulation => --remove before synthesis 
                        --execute_state <= decode;
                    when decode =>
                        if opcode = inst_NOP     then
                            execute_state <= NOP_1;
                        elsif opcode = inst_BLD   then
                            --Now BLD is a two word instruction ||Opcode||size/depth||start
                            ctrl_sw_bcache_start(binary_cache_depth_clogb2-2-1 downto 0) <= inst(binary_cache_depth_clogb2-2-1+2    downto 0+2   );--two bit shift right (bcache_start/4);
                            ctrl_sw_bcache_depth(binary_cache_depth_clogb2-2   downto 0) <= inst(binary_cache_depth_clogb2-2+13+2   downto 0+13+2);--two bit shift right (bcache_start/4);
                            
                            --Read Next Word
                            PC <= std_logic_vector(unsigned(PC)+1);
                            --execute_state <= fetch; We dont go back to fetch!
                            rd_en2 <= '1';
                            execute_state <= BLD_1;
						elsif opcode = inst_BSTR   then
						    --Now BSTR is a two word instruction ||Opcode||size/depth||start
						    ctrl_sw_bcache_start(binary_cache_depth_clogb2-2-1 downto 0) <= inst(binary_cache_depth_clogb2-2-1+2    downto 0+2   );--two bit shift right (bcache_start/4);
                            ctrl_sw_bcache_depth(binary_cache_depth_clogb2-2   downto 0) <= inst(binary_cache_depth_clogb2-2+13+2   downto 0+13+2);--two bit shift right (bcache_start/4);
                            
                            --Read Next Word
                            PC <= std_logic_vector(unsigned(PC)+1);
                            --execute_state <= fetch; We dont go back to fetch!
                            
                            rd_en2 <= '1'; 
                            execute_state <= BSTR_1;
                        elsif opcode = inst_MLD   then
                            execute_state <= MLD_1;
						elsif opcode = inst_MSTR   then
                            execute_state <= MSTR_1;
                        elsif opcode = inst_ILD   then
                            execute_state <= ILD_1;
                        elsif opcode = inst_ISTR  then
                            execute_state <= ISTR_1;
                        elsif opcode = inst_EPI then
                            cstate <= IRQ_assert;
                            execute_state <= fetch;
                            irq <= '1';
                            --dbg_ctrl_state<= "100"; --debug
                        elsif opcode = inst_XORLDA  then
                            execute_state <= XORLDA_1;
                            ctrl_rd_en_1 <= '1';
                            ctrl_rd_en_2 <= '0';
                            ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= inst(binary_cache_depth_clogb2-1 downto 0);
                        elsif opcode = inst_XORLDB     then
                            execute_state <= XORLDB_1;
                            ctrl_rd_en_1 <= '1'; -- binary cache
                            ctrl_rd_en_2 <= '0'; -- integer cache
                            ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= inst(binary_cache_depth_clogb2-1 downto 0);
						elsif opcode = inst_XORSTR     then
                            ctrl_xor_rstB      <=  '1';
                            ctrl_xor_in_valids(0) <= '1';
                            
                            ctrl_bcache_In_sels<= "00"; -- read form XOR
                            ctrl_wr_en_1 <= '1'; -- binary cache
                            ctrl_wr_en_2 <= '0'; -- integer cache
                            ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= inst(binary_cache_depth_clogb2-1 downto 0);
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                        elsif opcode = inst_ROTLDB     then
                            value := inst(26 downto 0);
                            ctrl_rot_load_carry_in(0) <= '1';
                            ctrl_rot_amounts <= value((ROT_amount_clog2)-1 downto 0);
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
						elsif opcode = inst_ROTLDS     then
                            execute_state <= ROTLDS_1;
                            ctrl_rd_en_1 <= '1'; -- binary cache
                            ctrl_rd_en_2 <= '0'; -- integer cache
                            ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= inst(binary_cache_depth_clogb2-1 downto 0);
						elsif opcode = inst_ROTSTR     then
                            ctrl_bcache_In_sels<= "01"; -- read form ROT
                            ctrl_wr_en_1 <= '1'; -- binary cache
                            ctrl_wr_en_2 <= '0'; -- integer cache
                            ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= inst(binary_cache_depth_clogb2-1 downto 0);
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                        elsif opcode = inst_PSUMLDS    then 
                            execute_state <= PSUMLDS_1;
                            ctrl_rd_en_1 <= '1'; -- binary cache
                            ctrl_rd_en_2 <= '0'; -- integer cache
                            ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= inst(binary_cache_depth_clogb2-1 downto 0);
                        elsif opcode = inst_PSUMSTR then
                            ctrl_psum_reloads(0) <= '1';
                            ctrl_wr_en_1 <= '0'; -- binary cache
                            ctrl_wr_en_2 <= '1'; -- integer cache
                            ctrl_addr2(i_cache_depth_clogb2-1 downto 0)  <= inst(i_cache_depth_clogb2-1 downto 0);
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                        elsif opcode = inst_MAJLDL    then
                            value := inst(26 downto 0);
                            ctrl_maj_load_Ts(0) <= '1';
                            ctrl_maj_T(int_size-1 downto 0) <= value(int_size-1 downto 0);
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                        elsif opcode = inst_MAJLDS     then
                            execute_state <= MAJLDS_1;
                            ctrl_rd_en_1 <= '0'; -- binary cache
                            ctrl_rd_en_2 <= '1'; -- integer cache
                            ctrl_addr2(i_cache_depth_clogb2-1 downto 0)  <= inst(i_cache_depth_clogb2-1 downto 0);
						elsif opcode = inst_MAJSTR     then
                            ctrl_bcache_In_sels<= "10"; -- read form MAJ
                            ctrl_wr_en_1 <= '1'; -- binary cache
                            ctrl_wr_en_2 <= '0'; -- integer cache
                            ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= inst(binary_cache_depth_clogb2-1 downto 0);
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                        
                        --MmmD
                        
                        elsif opcode = inst_XORHmD     then
                            
                            --reset XOR module after
                            ctrl_xor_rstB      <=  '1';
                            ctrl_xor_in_valids(0) <= '1';
                            
                            --load hmm from XOR output
                            ctrl_HmmD_QHV_sel <= "00";
                            ctrl_HmmD_clear <= '0';
                            ctrl_HmmD_en    <= '1';
                            --execute_state <= HmD_En_1;
                            HmmD_MHV_index_tmp <= std_logic_vector(unsigned(HmmD_MHV_index_tmp)+1); -- Ready to next?
                            
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';

                        elsif opcode = inst_ROTHmD     then
                            ctrl_HmmD_QHV_sel <= "01";
                            ctrl_HmmD_clear <= '0';
                            ctrl_HmmD_en    <= '1';

                            --execute_state <= HmD_En_1;
                            HmmD_MHV_index_tmp <= std_logic_vector(unsigned(HmmD_MHV_index_tmp)+1); -- Ready to next?
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                        elsif opcode = inst_MAJHmD     then
                            ctrl_HmmD_QHV_sel <= "10";
                            ctrl_HmmD_clear <= '0';
                            ctrl_HmmD_en    <= '1';
                            --execute_state <= HmD_En_1;
                            HmmD_MHV_index_tmp <= std_logic_vector(unsigned(HmmD_MHV_index_tmp)+1); -- Ready to next?
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                        -- Update
                        elsif opcode = inst_UPD then
                            ctrl_UPD_argMin  <= registers(to_integer(unsigned(inst(3 downto 0))))(15 downto 0); --opcode: 31,30,29,28,27,    update_en: 26, update_wr: 25,       UPD_Penalty: 24
                            ctrl_UPD_Penalty <= registers(to_integer(unsigned(inst(3 downto 0))))(31);          -- UPD_Penalty = '1' applying penalty to the action, when UPD_Penalty='1' applying encouragement to the action vector
                            
                            ctrl_UPD_en      <= inst(26);          -- UPD_en = '0' to get LFSR, UPD_en = '1', to start the process
                            ctrl_UPD_wr      <= inst(25);          -- UPD_wr to get update_valid for applying the MHV update in the cache
                            
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                            
                        elsif opcode = inst_ROTLOOP     then
                            if inst(26) = '0' then
                                --Read current instruction contents
                                inst_A <= inst(25 downto 13);
                                inst_B <= inst(12 downto 0);
                                PC <= std_logic_vector(unsigned(PC)+1);
                                
                                -----------------------------
                                -- set the ROT
                                src_tmp <= inst(25 downto 13);--source address
                                -- set the loop counter to 0
                                LOOP_cnt <= (others=> '0');
                                
                                --ROT LOAD Bits
                                value := "0" & "0000000000000" & inst(12 downto 0);--This is B
                                ctrl_rot_load_carry_in(0) <= '1';
                                ctrl_rot_amounts <= value((ROT_amount_clog2)-1 downto 0);
                                
                                rd_en2 <= '1';--read cache
                                execute_state<= fetch;
                            else
                                
                                inst_C <= inst(25 downto 13);
                                inst_D <= inst(12 downto 0);
                                dst_tmp <= inst(12 downto 0);--inst_D
                                
                                execute_state<= ROTLOOP_1;
                                
                                ctrl_rot_load_carry_in(0) <= '0';
                            end if;
                        elsif opcode = inst_XORACC     then
                            if inst(26) = '0' then
                                --Read current instruction contents
                                inst_A <= inst(25 downto 13);
                                inst_B <= inst(12 downto 0);
                                PC <= std_logic_vector(unsigned(PC)+1);
                                
                                -----------------------------
                                -- set the XOR
                                src_tmp  <= inst(25 downto 13);--source address
                                src_tmp2 <= inst(12 downto  0);--source address
                                -- set the loop counter to 0
                                LOOP_cnt <= (others=> '0');
                                
                                rd_en2 <= '1';--read cache
                                execute_state<= fetch;
                            else
                                
                                inst_C <= inst(25 downto 13);
                                inst_D <= inst(12 downto 0);
                                dst_tmp <= inst(12 downto 0);--inst_D
                                
                                execute_state<= XORACC_1;
                                
                            end if;
                        elsif opcode = inst_BINLOOP     then
                            if inst(26) = '0' then
                                --Read current instruction contents
                                inst_A <= inst(25 downto 13);
                                inst_B <= inst(12 downto 0);--Level
                                PC <= std_logic_vector(unsigned(PC)+1);
                                
                                -----------------------------
                                -- set the XOR
                                src_tmp  <= inst(25 downto 13);--source address
                                ctrl_maj_load_Ts(0) <= '1';
                                --if int_size < 13 then
                                ctrl_maj_T(T_size-1 downto 0) <= inst(T_size-1 downto 0);
                                --else
                                --    ctrl_maj_T(12 downto 0) <= inst(12 downto 0);
                                --end if;
                                -- set the loop counter to 0
                                LOOP_cnt <= (others=> '0');
                                
                                rd_en2 <= '1';--read cache
                                execute_state<= fetch;
                            else
                                
                                inst_C <= inst(25 downto 13);--Count
                                inst_D <= inst(12 downto 0);
                                dst_tmp <= inst(12 downto 0);--inst_D
                                
                                execute_state<= BINLOOP_1;
                                
                            end if;
                        elsif opcode = inst_PSUMLOOP     then
                            if inst(26) = '0' then
                                --Read current instruction contents
                                inst_A <= inst(25 downto 13);
                                inst_B <= inst(12 downto 0);
                                PC <= std_logic_vector(unsigned(PC)+1);
                                rd_en2 <= '1';--read cache
                                execute_state<= fetch;
                                -----------------------------
                                -- set the PSUM
                                src_tmp  <= inst(25 downto 13);--source address

                                -- set the loop counter to 0
                                LOOP_cnt <= (others=> '0');
                                
                                
                            else
                                
                                inst_C <= inst(25 downto 13);
                                inst_D <= inst(12 downto 0);
                                dst_tmp <= inst(12 downto 0);--inst_D
                                
                                execute_state<= BINLOOP_1;
                                
                            end if;
                        else
                            execute_state <= NOP_1;
                        end if;
                    when NOP_1 =>
                        PC <= std_logic_vector(unsigned(PC)+1);
                        execute_state <= fetch;
                        rd_en2 <= '1';
                    when BLD_1  =>
                        ctrl_sw_bcache_base_addr <= registers(to_integer(unsigned(inst(3 downto 0))));-- To read the base addr
                        rd_en2 <= '0';
                        
                        --ctrl_sw_cmd_valid <= '1';
                        --ctrl_sw_wr_nrd    <= '0';
                        ctrl_sw_mem_select<= "00"; -- std_logic_vector(to_unsigned(0, ctrl_sw_mem_select'length));
                        execute_state <= BLD_2;
                    when BLD_2  =>
                        ctrl_sw_bcache_base_addr <= registers(to_integer(unsigned(inst(3 downto 0))));-- To read the base addr
                        ctrl_sw_cmd_valid <= '1';
                        ctrl_sw_wr_nrd    <= '0';
                        if ctrl_sw_busy_ff='1' and ctrl_sw_busy='0' then
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                        end if;
                    when BSTR_1  =>
                        ctrl_sw_bcache_base_addr <= registers(to_integer(unsigned(inst(3 downto 0))));-- To read the base addr
                        rd_en2 <= '0';
                        
                        ctrl_sw_cmd_valid <= '0';
                        ctrl_sw_wr_nrd    <= '1';
                        ctrl_sw_mem_select<= "00"; -- std_logic_vector(to_unsigned(0, ctrl_sw_mem_select'length));
                        execute_state <= BSTR_2;
                    when BSTR_2  =>
                        ctrl_sw_bcache_base_addr <= registers(to_integer(unsigned(inst(3 downto 0))));-- To read the base addr
                        ctrl_sw_cmd_valid <= '1';
                        ctrl_sw_wr_nrd    <= '1';
                        if ctrl_sw_busy_ff='1' and ctrl_sw_busy='0' then
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                        end if;
                    when MLD_1  =>
                        ctrl_sw_cmd_valid <= '1';
                        ctrl_sw_wr_nrd    <= '0';
                        ctrl_sw_mem_select<= "11"; -- std_logic_vector(to_unsigned(0, ctrl_sw_mem_select'length));
                        execute_state <= MLD_2;
                    when MLD_2  =>
                        ctrl_sw_cmd_valid <= '0';
                        ctrl_sw_wr_nrd    <= '0';
                        if ctrl_sw_busy_ff='1' and ctrl_sw_busy='0' then
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                        end if;
                    when MSTR_1  =>
                        ctrl_sw_cmd_valid <= '1';
                        ctrl_sw_wr_nrd    <= '1';
                        ctrl_sw_mem_select<= "11"; -- std_logic_vector(to_unsigned(0, ctrl_sw_mem_select'length));
                        execute_state <= MSTR_2;
                    when MSTR_2  =>
                        ctrl_sw_cmd_valid <= '0';
                        ctrl_sw_wr_nrd    <= '0';
                        if ctrl_sw_busy_ff='1' and ctrl_sw_busy='0' then
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                            --Lets reset HMMD
                            ctrl_HmmD_clear <= '1';
                            HmmD_MHV_index_tmp <= (others =>'0');
                        end if;
                    when ILD_1 =>
                    
                    when ISTR_1 =>
                    
                    when XORLDA_1    =>
                        ctrl_rd_en_1 <= '0';
                        ctrl_rd_en_2 <= '0';
                        ctrl_xor_Load_A_nBs(0)    <=  '1';
                        ctrl_xor_in_valids (0)    <=  '1';
                        ctrl_xor_rstB             <= '0';
                        PC <= std_logic_vector(unsigned(PC)+1);
                        execute_state <= fetch;
                        rd_en2 <= '1';
                    when XORLDB_1    =>
                        ctrl_rd_en_1 <= '0';
                        ctrl_rd_en_2 <= '0';
                        ctrl_xor_Load_A_nBs(0)    <=  '0';
                        ctrl_xor_in_valids (0)    <=  '1';
                        ctrl_xor_rstB             <= '0';
                        PC <= std_logic_vector(unsigned(PC)+1);
                        execute_state <= fetch;
                        rd_en2 <= '1';
                    when XORSTR_1    =>
                        --OK
                    when ROTLDB_1    =>
                        --OK
                    when ROTLDS_1    =>
                        ctrl_rd_en_1 <= '0';
                        ctrl_rd_en_2 <= '0';
                        ctrl_rot_in_valids (0)    <=  '1';
                        PC <= std_logic_vector(unsigned(PC)+1);
                        execute_state <= fetch;
                        rd_en2 <= '1';
                    when ROTSTR_1    =>
                        --OK
                    when PSUMLDS_1   =>
                        ctrl_rd_en_1 <= '0';
                        ctrl_rd_en_2 <= '0';
                        ctrl_psum_in_valids (0)    <=  '1';
                        PC <= std_logic_vector(unsigned(PC)+1);
                        execute_state <= fetch;
                        rd_en2 <= '1';
                    when PSUMSTR_1=>
                        --OK
                    when MAJLDL_1   =>
                        --OK
                    when MAJLDS_1    =>
                        ctrl_rd_en_1 <= '0';
                        ctrl_rd_en_2 <= '0';
                        ctrl_maj_in_valids (0)    <=  '1';
                        PC <= std_logic_vector(unsigned(PC)+1);
                        execute_state <= fetch;
                        rd_en2 <= '1';
                    when MAJSTR_1    =>
                    --OK
                    when HmD_En_1 => --No Call, To be removed in future
                        ctrl_HmmD_en    <= '0';
                        HmmD_MHV_index_tmp <= std_logic_vector(unsigned(HmmD_MHV_index_tmp)+1); -- Ready to next?
                        PC <= std_logic_vector(unsigned(PC)+1);
                        execute_state <= fetch;
                        rd_en2 <= '1';
                    --------------------------------------
                    -------------        -----------------
                    -------------  MACRO -----------------
                    --------------------------------------
                    when ROTLOOP_1    =>
                        if LOOP_cnt = "0000000000000" then
                            --first condition
                            ctrl_rot_load_carry_in(0) <= '0';
                        else
                        --other conditions
                            dst_tmp <= std_logic_vector(unsigned(dst_tmp)+1);
                        end if;
                        --disable write
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        -- Start fetching data
                        ctrl_rd_en_1 <= '1'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= src_tmp(binary_cache_depth_clogb2-1 downto 0);
                        ctrl_rot_in_valids (0)<=  '0';
                        
                        
                        
                        execute_state <= ROTLOOP_2;
                    when ROTLOOP_2 =>
                        src_tmp <= std_logic_vector(unsigned(src_tmp)+1);
                        ctrl_rd_en_1 <= '0'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        ctrl_rot_in_valids (0)<=  '1';
                        
                        --finish condition
                        --dst_tmp <= std_logic_vector(unsigned(dst_tmp)+1);
                        --execute_state <= fetch;
                        --rd_en2 <= '1';
                        LOOP_cnt <= std_logic_vector(unsigned(LOOP_cnt)+1);
                        execute_state <= ROTLOOP_3;
                    when ROTLOOP_3 =>
                        if LOOP_cnt < inst_C then
                            execute_state <= ROTLOOP_1;
                        else
                            --Fix the first carry in
                            execute_state <= ROTLOOP_4;--fetch
                        end if;
                        ctrl_rot_in_valids (0)<=  '0';
                        -- Write the results into the cache
                        ctrl_bcache_In_sels<= "01"; -- read form ROT
                        ctrl_wr_en_1 <= '1'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= dst_tmp(binary_cache_depth_clogb2-1 downto 0);

                    when ROTLOOP_4 =>
                        --Finish and store
                        --disable write
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        -- Start fetching data
                        ctrl_rd_en_1 <= '1'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= inst_A(binary_cache_depth_clogb2-1 downto 0);
                        ctrl_rot_in_valids (0)<=  '0';
                        
                        execute_state <= ROTLOOP_5;
                    when ROTLOOP_5 =>
                        ctrl_rd_en_1 <= '0'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        ctrl_rot_in_valids (0)<=  '1';
                        
                        --finish condition
                        --dst_tmp <= std_logic_vector(unsigned(dst_tmp)+1);
                        --execute_state <= fetch;
                        --rd_en2 <= '1';
                        --LOOP_cnt <= std_logic_vector(unsigned(LOOP_cnt)+1);
                        execute_state <= ROTLOOP_6;
                    when ROTLOOP_6 =>
                        ctrl_rot_in_valids (0)<=  '0';
                        -- Write the results into the cache
                        ctrl_bcache_In_sels<= "01"; -- read form ROT
                        ctrl_wr_en_1 <= '1'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= inst_D(binary_cache_depth_clogb2-1 downto 0);
                        
                        PC <= std_logic_vector(unsigned(PC)+1);
                        execute_state <= fetch;
                        rd_en2 <= '1';
                    
                    --------------------------------------
                    --------------------------------------
                    when XORACC_1    =>
                        if LOOP_cnt = "0000000000000" then
                            --first condition
                        else
                        --other conditions
                            dst_tmp <= std_logic_vector(unsigned(dst_tmp)+1);
                            ctrl_psum_in_valids (0)    <=  '1';
                        end if;
                        --disable write
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        -- Start fetching data
                        ctrl_rd_en_1 <= '1'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= src_tmp(binary_cache_depth_clogb2-1 downto 0);
                        ctrl_xor_in_valids (0)<=  '0';
                        
                        
                        
                        execute_state <= XORACC_2;
                    when XORACC_2 => --LOAD A
                        src_tmp <= std_logic_vector(unsigned(src_tmp)+1);
                        --disable write
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        -- Start fetching data
                        ctrl_rd_en_1 <= '1'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= src_tmp2(binary_cache_depth_clogb2-1 downto 0);
                        
                        ctrl_xor_Load_A_nBs(0)    <=  '1';
                        ctrl_xor_in_valids (0)    <=  '1';
                        ctrl_xor_rstB             <= '0';
                        
                        ctrl_psum_in_valids (0)    <=  '0';
                        --finish condition
                        --dst_tmp <= std_logic_vector(unsigned(dst_tmp)+1);
                        --execute_state <= fetch;
                        --rd_en2 <= '1';
                        execute_state <= XORACC_3;
                    when XORACC_3 => -- Load B
                        src_tmp2 <= std_logic_vector(unsigned(src_tmp2)+1);
                        
                        --disable write
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        -- Start fetching data
                        ctrl_rd_en_1 <= '0'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        
                        ctrl_xor_Load_A_nBs(0)    <=  '0';
                        ctrl_xor_in_valids (0)    <=  '1';
                        ctrl_xor_rstB             <= '0';
                        
                        ctrl_psum_in_valids (0)    <=  '0';
                        
                        LOOP_cnt <= std_logic_vector(unsigned(LOOP_cnt)+1);
                        execute_state <= XORACC_4;
                    when XORACC_4 => 
                        
                        ctrl_rot_in_valids (0)<=  '0';
                        -- Write the results into the cache
                        ctrl_bcache_In_sels<= "00"; -- read form XOR
                        ctrl_wr_en_1 <= '1'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= dst_tmp(binary_cache_depth_clogb2-1 downto 0);
                        ctrl_psum_in_valids (0)    <=  '0';
                        ctrl_xor_in_valids (0)    <=  '0';
                        execute_state <= XORACC_5;
                    when XORACC_5 => -- Read for PSUM
                        if LOOP_cnt < inst_C then
                            execute_state <= XORACC_1;
                        else
                            --Fix the first carry in
                            execute_state <= XORACC_6;--fetch
                        end if;
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        ctrl_rd_en_1 <= '1'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        -- Read for PSUM
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= dst_tmp(binary_cache_depth_clogb2-1 downto 0);
                        ctrl_psum_in_valids (0)    <=  '0';
                        ctrl_xor_in_valids (0)    <=  '0';
                        
                    when XORACC_6 =>
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        ctrl_rd_en_1 <= '0'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        ctrl_psum_in_valids (0)    <=  '1';
                        ctrl_xor_in_valids (0)    <=  '0';
                        --finish condition
                        PC <= std_logic_vector(unsigned(PC)+1);
                        execute_state <= fetch;
                        rd_en2 <= '1';
                    --------------------------------------
                    --------------------------------------
                    when BINLOOP_1    =>
                        if LOOP_cnt = "0000000000000" then
                            --first condition
                        else
                        --other conditions
                            dst_tmp <= std_logic_vector(unsigned(dst_tmp)+1);
                        end if;
                        --disable write
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        -- Start fetching data
                        ctrl_rd_en_1 <= '0'; -- binary cache
                        ctrl_rd_en_2 <= '1'; -- integer cache
                        
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= src_tmp(binary_cache_depth_clogb2-1 downto 0);
                        ctrl_maj_in_valids (0)    <=  '0';
                        
                        execute_state <= BINLOOP_2;
                    when BINLOOP_2 => -- Load SRC
                        src_tmp <= std_logic_vector(unsigned(src_tmp)+1);
                        
                        --disable write
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        -- Start fetching data
                        ctrl_rd_en_1 <= '0'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        ctrl_maj_in_valids (0)    <=  '1';
                        
                        LOOP_cnt <= std_logic_vector(unsigned(LOOP_cnt)+1);
                        execute_state <= BINLOOP_3;
                    when BINLOOP_3 =>
                        if LOOP_cnt < inst_C then
                            execute_state <= BINLOOP_1;
                        else
                            --Fix the first carry in
                            execute_state <= fetch;--fetch
                            PC <= std_logic_vector(unsigned(PC)+1);
                            execute_state <= fetch;
                            rd_en2 <= '1';
                        end if;
                        
                        -- Write the results into the cache
                        ctrl_bcache_In_sels<= "10"; -- read form MAJ
                        ctrl_wr_en_1 <= '1'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= dst_tmp(binary_cache_depth_clogb2-1 downto 0);
                        
                        ctrl_maj_in_valids (0)    <=  '0';
                    --------------------------------------
                    --------------------------------------
                    when PSUMLOOP_1    =>
                        if LOOP_cnt = "0000000000000" then
                            --first condition
                            ctrl_psum_reloads(0) <= '1';
                        else
                        --other conditions
                            --dst_tmp <= std_logic_vector(unsigned(dst_tmp)+1);
                        end if;
                        --disable write
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        -- Start fetching data
                        ctrl_rd_en_1 <= '1'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= src_tmp(binary_cache_depth_clogb2-1 downto 0);
                        ctrl_psum_in_valids (0)    <=  '0';
                        
                        execute_state <= PSUMLOOP_2;
                    when PSUMLOOP_2 => -- Load SRC
                        if LOOP_cnt < inst_C then
                            execute_state <= PSUMLOOP_1;
                        else
                            execute_state <= PSUMLOOP_3;
                        end if;
                        src_tmp <= std_logic_vector(unsigned(src_tmp)+1);
                        
                        --disable write
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '0'; -- integer cache
                        -- Start fetching data
                        ctrl_rd_en_1 <= '0'; -- binary cache
                        ctrl_rd_en_2 <= '0'; -- integer cache
                        ctrl_psum_in_valids (0)    <=  '1';
                        
                        LOOP_cnt <= std_logic_vector(unsigned(LOOP_cnt)+1);
                        
                    when PSUMLOOP_3 =>
                        execute_state <= fetch;--fetch
                        PC <= std_logic_vector(unsigned(PC)+1);
                        execute_state <= fetch;
                        rd_en2 <= '1';
                        
                        -- Write the results into the cache
                        ctrl_wr_en_1 <= '0'; -- binary cache
                        ctrl_wr_en_2 <= '1'; -- integer cache
                        ctrl_addr1(binary_cache_depth_clogb2-1 downto 0)  <= dst_tmp(binary_cache_depth_clogb2-1 downto 0);
                        
                        ctrl_psum_in_valids (0)    <=  '0';
                    --------------------------------------
                    --------------------------------------
                    when others =>
                        PC <= std_logic_vector(unsigned(PC)+1);
                        execute_state <= fetch;
                        rd_en2 <= '1';
                end case;
            elsif cstate = execute and to_integer(unsigned(PC)) >= i_cache_depth then
                cstate <= IRQ_assert;
                execute_state <= fetch;
                irq <= '1';
                dbg_ctrl_state<= "100"; --debug
            end if;
        end if; 
    end process;
opcode <= inst(31 downto 27);
--------------------------------------
--- Thread and  cache interconnect ---

dbg_PC<= PC;     --debug
dbg_inst<= inst; --debug






---------------------------------
------ Registers Port Map -------

Regs: UHDC_Regs
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH
	) 
	port map(
		REG0_i	=> registers(0),
		REG1_i	=> registers(1),
		REG2_i	=> registers(2),
		REG3_i	=> registers(3),
		REG4_i	=> registers(4),
		REG5_i	=> registers(5),
		REG6_i	=> registers(6),
		REG7_i	=> registers(7),
		REG8_i	=> registers(8),
		REG9_i	=> registers(9),
		REG10_i	=> registers(10),
		REG11_i	=> registers(11),
		REG12_i	=> registers(12),
		REG13_i	=> registers(13),
		REG14_i	=> registers(14),
		REG15_i	=> registers(15),
		
		REG0_o	=> registers(0),  
		REG1_o	=> registers(1),  
		REG2_o	=> registers(2),  
		REG3_o	=> registers(3),  
		REG4_o	=> registers(4),  
		REG5_o	=> registers(5),  
		REG6_o	=> registers(6),  
		REG7_o	=> registers(7),  
		REG8_o	=> registers(8),  
		REG9_o	=> registers(9),  
		REG10_o	=> registers(10),
		REG11_o	=> registers(11),
		REG12_o	=> registers(12),
		REG13_o	=> registers(13),
		REG14_o	=> registers(14),
		REG15_o	=> registers(15),
		     
		S_AXI_ACLK	    =>S_AXI_ACLK,
		S_AXI_ARESETN	=> S_AXI_ARESETN,
		S_AXI_AWADDR	=> S_AXI_AWADDR	,
		S_AXI_AWPROT	=> S_AXI_AWPROT	,
		S_AXI_AWVALID	=> S_AXI_AWVALID,
		S_AXI_AWREADY	=> S_AXI_AWREADY,
		S_AXI_WDATA     => S_AXI_WDATA  ,
		S_AXI_WSTRB     => S_AXI_WSTRB  ,
		S_AXI_WVALID	=> S_AXI_WVALID	,
		S_AXI_WREADY	=> S_AXI_WREADY	,
		S_AXI_BRESP     => S_AXI_BRESP  ,
		S_AXI_BVALID	=> S_AXI_BVALID	,
		S_AXI_BREADY	=> S_AXI_BREADY	,
		S_AXI_ARADDR	=> S_AXI_ARADDR	,
		S_AXI_ARPROT	=> S_AXI_ARPROT	,
		S_AXI_ARVALID	=> S_AXI_ARVALID,
		S_AXI_ARREADY	=> S_AXI_ARREADY,
		S_AXI_RDATA     => S_AXI_RDATA  ,
		S_AXI_RRESP     => S_AXI_RRESP  ,
		S_AXI_RVALID	=> S_AXI_RVALID	,
		S_AXI_RREADY	=> S_AXI_RREADY
	);










end Behavioral;