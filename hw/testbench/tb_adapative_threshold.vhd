library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_adapative_threshold is
end tb_adapative_threshold;

architecture test of tb_adapative_threshold is 
  constant CLK_PERIOD : time := 1000 ns;

  signal sim_finished : boolean := false;

  -- Clock/Reset
  signal clk : std_logic;
  signal reset_n : std_logic;

  -- FIFO1
  signal fifo1_data		: std_logic_vector (31 downto 0);
  signal fifo1_rdreq		: std_logic;
  signal fifo1_sclr		: std_logic;
  signal fifo1_wrreq		: std_logic;
  signal fifo1_empty		: std_logic;
  signal fifo1_q		    : std_logic_vector (31 downto 0);
  signal fifo1_usedw    : std_logic_vector (6 downto 0);

  -- fifo2
  signal fifo2_data		: std_logic_vector (31 downto 0);
  signal fifo2_rdreq		: std_logic;
  signal fifo2_sclr		: std_logic;
  signal fifo2_wrreq		: std_logic;
  signal fifo2_empty		: std_logic;
  signal fifo2_q		    : std_logic_vector (31 downto 0);
  signal fifo2_usedw    : std_logic_vector (6 downto 0);

  -- fifo3
  signal fifo3_data		: std_logic_vector (31 downto 0);
  signal fifo3_rdreq		: std_logic;
  signal fifo3_sclr		: std_logic;
  signal fifo3_wrreq		: std_logic;
  signal fifo3_empty		: std_logic;
  signal fifo3_q		    : std_logic_vector (31 downto 0);
  signal fifo3_usedw    : std_logic_vector (6 downto 0);

  -- fifo4
  signal fifo4_data		: std_logic_vector (31 downto 0);
  signal fifo4_rdreq		: std_logic;
  signal fifo4_sclr		: std_logic;
  signal fifo4_wrreq		: std_logic;
  signal fifo4_empty		: std_logic ;
  signal fifo4_q		    : std_logic_vector (31 downto 0);
  signal fifo4_usedw    : std_logic_vector (6 downto 0);

  signal row_rdreq1        : std_logic;
  signal row_rdreq2        : std_logic;
  signal row_rdreq3        : std_logic;
  signal row_q1            : std_logic_vector(31 downto 0);
  signal row_q2            : std_logic_vector(31 downto 0);
  signal row_q3            : std_logic_vector(31 downto 0);
  signal row_wrreq        : std_logic;
  signal row_data        : std_logic_vector(31 downto 0);
  signal row_empty1        : std_logic;
  signal row_empty2        : std_logic;
  signal row_empty3        : std_logic;
  signal row_sclr        : std_logic;
  signal select_idx    : std_logic_vector(1 downto 0);

  -- output FIFO
  signal ofifo_data		: STD_LOGIC_VECTOR (31 DOWNTO 0);
  signal ofifo_rdreq		: STD_LOGIC ;
  signal ofifo_wrreq		: STD_LOGIC ;
  signal ofifo_empty		: STD_LOGIC ;
  signal ofifo_q		: STD_LOGIC_VECTOR (31 DOWNTO 0);
  signal ofifo_sclr : STD_LOGIC;
  signal ofifo_usedw : STD_LOGIC_VECTOR(6 downto 0);

  signal row_wrreq1        : std_logic;
  signal row_wrreq2        : std_logic;
  signal row_wrreq3        : std_logic;
  signal row_data1        : std_logic_vector(31 downto 0);
  signal row_data2        : std_logic_vector(31 downto 0);
  signal row_data3        : std_logic_vector(31 downto 0);

  signal enable            : std_logic;

begin
  fifo1 : entity work.fifo
  port map( 
    clock => clk,
    data => fifo1_data,
    rdreq => fifo1_rdreq,
    sclr => fifo1_sclr,
    wrreq => fifo1_wrreq,
    empty => fifo1_empty,
    usedw => fifo1_usedw,
    q => fifo1_q
  );

  fifo2 : entity work.fifo
  port map( 
    clock => clk,
    data => fifo2_data,
    rdreq => fifo2_rdreq,
    sclr => fifo2_sclr,
    wrreq => fifo2_wrreq,
    empty => fifo2_empty,
    usedw => fifo2_usedw,
    q => fifo2_q
  );

  fifo3 : entity work.fifo
  port map( 
    clock => clk,
    data => fifo3_data,
    rdreq => fifo3_rdreq,
    sclr => fifo3_sclr,
    wrreq => fifo3_wrreq,
    empty => fifo3_empty,
    usedw => fifo3_usedw,
    q => fifo3_q
  );

  fifo4 : entity work.fifo
  port map( 
    clock => clk,
    data => fifo4_data,
    rdreq => fifo4_rdreq,
    sclr => fifo4_sclr,
    wrreq => fifo4_wrreq,
    empty => fifo4_empty,
    q => fifo4_q
  );

  ofifo : entity work.fifolookahead
  port map(
		clock => clk,
		data => ofifo_data,
		rdreq => ofifo_rdreq,
		sclr => ofifo_sclr,
		wrreq => ofifo_wrreq,
		empty => ofifo_empty,
    usedw => ofifo_usedw,
		q => ofifo_q
  );

  fifo_mult : entity work.fifo_mult
  port map( 
		fifo1_data => fifo1_data,
		fifo1_rdreq => fifo1_rdreq,
		fifo1_sclr => fifo1_sclr,
		fifo1_wrreq => fifo1_wrreq,
		fifo1_empty => fifo1_empty,
		fifo1_q => fifo1_q,

    -- fifo2
		fifo2_data => fifo2_data,
		fifo2_rdreq => fifo2_rdreq,
		fifo2_sclr => fifo2_sclr,
		fifo2_wrreq => fifo2_wrreq,
		fifo2_empty => fifo2_empty,
		fifo2_q => fifo2_q,

    -- fifo3
		fifo3_data => fifo3_data,
		fifo3_rdreq => fifo3_rdreq,
		fifo3_sclr => fifo3_sclr,
		fifo3_wrreq => fifo3_wrreq,
		fifo3_empty => fifo3_empty,
		fifo3_q => fifo3_q,

    -- fifo4
		fifo4_data => fifo4_data,
		fifo4_rdreq => fifo4_rdreq,
		fifo4_sclr => fifo4_sclr,
		fifo4_wrreq => fifo4_wrreq,
		fifo4_empty => fifo4_empty,
		fifo4_q => fifo4_q,

    -- Port to command all
    row_rdreq1 => row_rdreq1,
    row_rdreq2 => row_rdreq2,
    row_rdreq3 => row_rdreq3,
    row_q1     => row_q1    ,
    row_q2     => row_q2    ,
    row_q3     => row_q3    ,
    row_wrreq  => row_wrreq ,
    row_data   => row_data  ,
    row_empty1 => row_empty1,
    row_empty2 => row_empty2,
    row_empty3 => row_empty3,
    row_sclr   => row_sclr  ,
    select_idx => select_idx,
    row_wrreq1 =>  row_wrreq1,
    row_wrreq2 =>  row_wrreq2,
    row_wrreq3 =>  row_wrreq3,
    row_data1  =>  row_data1 ,
    row_data2  =>  row_data2 ,
    row_data3  =>  row_data3,
    clr_all => '0'
  );

  dut : entity work.adaptive_threshold
  port map(
    clk    => clk,    
    reset_n => reset_n,

    -- Interface to FIFO multiplexer
    row_rdreq1   =>     row_rdreq1,
    row_rdreq2   =>     row_rdreq2,
    row_rdreq3   =>     row_rdreq3,

    row_q1       => row_q1,
    row_q2       => row_q2,
    row_q3       => row_q3,

    row_empty1 => row_empty1,
    row_empty2 => row_empty2,
    row_empty3 => row_empty3,

    row_wrreq1 => row_wrreq1,
    row_wrreq2 => row_wrreq2,
    row_wrreq3 => row_wrreq3,

    row_data1  => row_data1,
    row_data2  => row_data2,
    row_data3  => row_data3,

    -- Interface to output FIFO
		ofifo_data	=> ofifo_data,
		ofifo_sclr	=> ofifo_sclr,
		ofifo_wrreq	=> ofifo_wrreq,

    -- Interface to Avalon Master
    enable => enable,
    col_size  => x"0020"
  );

  clk_generation : process
  begin
    if not sim_finished then
      clk <= '1';
      wait for CLK_PERIOD/2;
      clk <= '0';
      wait for CLK_PERIOD/2;
    else
      wait;
    end if;
  end process clk_generation;

  simulation: process
    procedure async_reset is
    begin
      wait until rising_edge(clk);
      wait for CLK_PERIOD/4;
      reset_n <= '0';

      wait for CLK_PERIOD/2;
      reset_n <= '1';
    end procedure async_reset;

  begin
    enable <= '0';
    ofifo_rdreq <= '0';

    async_reset;

    select_idx <= "00";
    wait for CLK_PERIOD;

    -- Fill FIFOs first
    wait for CLK_PERIOD;

    for i in 1 to 8 loop
      row_data <= std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(i, 8))& std_logic_vector(to_unsigned(i, 8));
      row_wrreq <= '1';

      wait for CLK_PERIOD;
    end loop;

    row_wrreq <= '0';
    select_idx <= "01";

    wait for 3*CLK_PERIOD;

    for i in 1 to 8 loop
      row_data <= std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(i, 8))& std_logic_vector(to_unsigned(i, 8));
      row_wrreq <= '1';

      wait for CLK_PERIOD;
    end loop;

    row_wrreq <= '0';

    wait for 3*CLK_PERIOD;

    select_idx <= "10";

    wait for CLK_PERIOD;
    enable <= '1';

    wait for CLK_PERIOD;
    enable <= '0';

    wait for 20*CLK_PERIOD;

    for i in 1 to 8 loop
      row_data <= std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(i, 8))& std_logic_vector(to_unsigned(i, 8));
      row_wrreq <= '1';

      wait for CLK_PERIOD;
    end loop;

    row_wrreq <= '0';

    wait for 3*CLK_PERIOD;

    select_idx <= "11";

    wait for CLK_PERIOD;
    enable <= '1';

    wait for CLK_PERIOD;
    enable <= '0';

    wait for 20*CLK_PERIOD;

    sim_finished <= true;
    wait;
  end process simulation;
end test;
