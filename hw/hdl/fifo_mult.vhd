library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Fifo multiplexer
-- Select with select_idx

entity fifo_mult is
  port(
    -- FIFO1
		fifo1_data		: out std_logic_vector (31 downto 0);
		fifo1_rdreq		: out std_logic;
		fifo1_sclr		: out std_logic;
		fifo1_wrreq		: out std_logic;
		fifo1_empty		: in std_logic;
		fifo1_q		    : in std_logic_vector (31 downto 0);

    -- fifo2
		fifo2_data		: out std_logic_vector (31 downto 0);
		fifo2_rdreq		: out std_logic;
		fifo2_sclr		: out std_logic;
		fifo2_wrreq		: out std_logic;
		fifo2_empty		: in std_logic;
		fifo2_q		    : in std_logic_vector (31 downto 0);

    -- fifo3
		fifo3_data		: out std_logic_vector (31 downto 0);
		fifo3_rdreq		: out std_logic;
		fifo3_sclr		: out std_logic;
		fifo3_wrreq		: out std_logic;
		fifo3_empty		: in std_logic;
		fifo3_q		    : in std_logic_vector (31 downto 0);

    -- fifo4
		fifo4_data		: out std_logic_vector (31 downto 0);
		fifo4_rdreq		: out std_logic;
		fifo4_sclr		: out std_logic;
		fifo4_wrreq		: out std_logic;
		fifo4_empty		: in std_logic ;
		fifo4_q		    : in std_logic_vector (31 downto 0);

    -- Port to command all
    row_rdreq1        : in std_logic;
    row_rdreq2        : in std_logic;
    row_rdreq3        : in std_logic;

    row_q1            : out std_logic_vector(31 downto 0);
    row_q2            : out std_logic_vector(31 downto 0);
    row_q3            : out std_logic_vector(31 downto 0);

    row_wrreq        : in std_logic;
    row_data        : in std_logic_vector(31 downto 0);
    row_sclr        : in std_logic;

    row_empty1        : out std_logic;
    row_empty2        : out std_logic;
    row_empty3        : out std_logic;


    select_idx    : in std_logic_vector(1 downto 0);

    row_wrreq1        : in std_logic;
    row_wrreq2        : in std_logic;
    row_wrreq3        : in std_logic;

    row_data1        : in std_logic_vector(31 downto 0);
    row_data2        : in std_logic_vector(31 downto 0);
    row_data3        : in std_logic_vector(31 downto 0);

    clr_all          : in std_logic
  );
end fifo_mult;

architecture comp of fifo_mult is
begin

  -- IP -> FIFO
  with select_idx select
    fifo1_sclr  <= row_sclr or clr_all when "00",
                   clr_all when others;

  with select_idx select
    fifo1_wrreq <= row_wrreq when "00"  ,
                   row_wrreq3 when "01" ,
                   row_wrreq2 when "10" ,
                   row_wrreq1 when "11" ,
                   '0' when others;


  with select_idx select
    fifo1_data  <= row_data when "00"  ,
                   row_data3 when "01" ,
                   row_data2 when "10" ,
                   row_data1 when "11" ,
                   x"0000_0000" when others;

  with select_idx select
    fifo1_rdreq  <= row_rdreq3 when "01" ,
                   row_rdreq2 when "10" ,
                   row_rdreq1 when "11" ,
                   '0' when others;


  with select_idx select
    fifo2_sclr  <= row_sclr or clr_all when "01" ,
                   clr_all when others;

  with select_idx select
    fifo2_wrreq <= row_wrreq1 when "00" ,
                   row_wrreq when "01"  ,
                   row_wrreq3 when "10" ,
                   row_wrreq2 when "11" ,
                   '0' when others;


  with select_idx select
    fifo2_data  <= row_data1 when "00" ,
                   row_data  when "01" ,
                   row_data3 when "10" ,
                   row_data2 when "11" ,
                   x"0000_0000" when others;

  with select_idx select
    fifo2_rdreq <= row_rdreq1 when "00" ,
                   row_rdreq3 when "10" ,
                   row_rdreq2 when "11" ,
                   '0' when others;

  with select_idx select
    fifo3_sclr  <= row_sclr or clr_all when "10" ,
                   clr_all when others;

  with select_idx select
    fifo3_wrreq <= row_wrreq2 when "00" ,
                   row_wrreq1 when "01" ,
                   row_wrreq  when "10" ,
                   row_wrreq3 when "11" ,
                   '0' when others;


  with select_idx select
    fifo3_data  <= row_data2 when "00" ,
                   row_data1 when "01" ,
                   row_data  when "10" ,
                   row_data3 when "11" ,
                   x"0000_0000" when others;

  with select_idx select
    fifo3_rdreq  <= row_rdreq2 when "00" ,
                   row_rdreq1 when "01" ,
                   row_rdreq3 when "11" ,
                   '0' when others;

  with select_idx select
    fifo4_sclr  <= row_sclr or clr_all when "11" ,
                   clr_all when others;

  with select_idx select
    fifo4_wrreq <= row_wrreq3 when "00" ,
                   row_wrreq2 when "01" ,
                   row_wrreq1 when "10" ,
                   row_wrreq  when "11" ,
                   '0' when others;


  with select_idx select
    fifo4_data  <= row_data3 when "00" ,
                   row_data2 when "01" ,
                   row_data1 when "10" ,
                   row_data  when "11" ,
                   x"0000_0000" when others;

  with select_idx select
    fifo4_rdreq  <= row_rdreq3 when "00" ,
                   row_rdreq2 when "01" ,
                   row_rdreq1 when "10" ,
                   '0' when others;

  -- FIFO -> IP
  with select_idx select
    row_q1 <= fifo2_q when "00" ,
              fifo3_q when "01" ,
              fifo4_q when "10" ,
              fifo1_q when "11" ,
              x"0000_0000" when others;

  with select_idx select
    row_q2 <= fifo3_q when "00",
              fifo4_q when "01",
              fifo1_q when "10",
              fifo2_q when "11",
              x"0000_0000" when others;

  with select_idx select
    row_q3 <= fifo4_q when "00",
              fifo1_q when "01",
              fifo2_q when "10",
              fifo3_q when "11",
              x"0000_0000" when others;

  with select_idx select
    row_empty1 <= fifo2_empty when "00",
              fifo3_empty when "01",
              fifo4_empty when "10",
              fifo1_empty when "11",
              '0' when others;

  with select_idx select
    row_empty2 <= fifo3_empty when "00",
              fifo4_empty when "01",
              fifo1_empty when "10",
              fifo2_empty when "11",
              '0' when others;

  with select_idx select
    row_empty3 <= fifo4_empty when "00",
              fifo1_empty when "01",
              fifo2_empty when "10",
              fifo3_empty when "11",
              '0' when others;

end comp;
