library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_burst_reader is
end tb_burst_reader;

architecture test of tb_burst_reader is 
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

  signal row_wrreq1        : std_logic;
  signal row_wrreq2        : std_logic;
  signal row_wrreq3        : std_logic;
  signal row_data1        : std_logic_vector(31 downto 0);
  signal row_data2        : std_logic_vector(31 downto 0);
  signal row_data3        : std_logic_vector(31 downto 0);

  signal avm_rd:           std_logic;
  signal avm_rddata:       std_logic_vector(31 downto 0);
  signal avm_waitrequest:  std_logic;
  signal avm_rddatavalid:  std_logic;
  signal avm_address:           std_logic_vector(31 downto 0);
  signal avm_beginburst:           std_logic;
  signal avm_burstcount:           std_logic_vector(6 downto 0);

  signal enable : std_logic;
  signal done : std_logic;
  signal burst_count : std_logic_vector(6 downto 0);

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
    usedw => fifo4_usedw,
    q => fifo4_q
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

  dut : entity work.burst_reader
  port map(
    clk => clk,
    reset_n => reset_n,

    avm_rd            =>     avm_rd         ,
    avm_rddata        =>     avm_rddata     ,
    avm_waitrequest   =>     avm_waitrequest,
    avm_rddatavalid   =>     avm_rddatavalid,
    avm_beginburst => avm_beginburst,
    avm_burstcount => avm_burstcount,
    avm_address => avm_address,

    row_wrreq  => row_wrreq  ,
    row_data   => row_data   ,
    row_sclr   => row_sclr   ,

    enable => enable,
    done => done,
    burst_count => burst_count,
    burst_address => X"0000_0000"
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
    async_reset;

    select_idx <= "00";
    burst_count <= std_logic_vector(to_unsigned(6, 7));
    enable <= '0';

    wait for CLK_PERIOD;

    enable <= '1';
    avm_waitrequest <= '1';

    wait for CLK_PERIOD;

    enable <= '0';
    avm_waitrequest <= '1';

    wait for CLK_PERIOD;

    avm_waitrequest <= '0';

    wait for CLK_PERIOD;

    for i in 1 to 6 loop
      avm_rddata <= std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(i, 8))& std_logic_vector(to_unsigned(i, 8));
      avm_rddatavalid <= '1';
      wait for CLK_PERIOD;
    end loop;

    wait for 10*CLK_PERIOD;

    sim_finished <= true;
    wait;
  end process simulation;
end test;
