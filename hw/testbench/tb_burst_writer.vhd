library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_burst_writer is
end tb_burst_writer;

architecture test of tb_burst_writer is 
  constant CLK_PERIOD : time := 1000 ns;

  signal sim_finished : boolean := false;

  -- Clock/Reset
  signal clk : std_logic;
  signal reset_n : std_logic;

  -- output FIFO
  signal ofifo_data		: STD_LOGIC_VECTOR (31 DOWNTO 0);
  signal ofifo_rdreq		: STD_LOGIC ;
  signal ofifo_wrreq		: STD_LOGIC ;
  signal ofifo_empty		: STD_LOGIC ;
  signal ofifo_q		: STD_LOGIC_VECTOR (31 DOWNTO 0);
  signal ofifo_sclr : STD_LOGIC;
  signal ofifo_usedw : STD_LOGIC_VECTOR(6 downto 0);

  signal avm_address:           std_logic_vector(31 downto 0);
  signal avm_beginburst:           std_logic;
  signal avm_burstcount:           std_logic_vector(6 downto 0);
  signal avm_wr:           std_logic;
  signal avm_wrdata:       std_logic_vector(31 downto 0);
  signal avm_waitrequest:  std_logic;

  signal enable : std_logic;
  signal done : std_logic;
  signal burst_count : std_logic_vector(6 downto 0);

begin
  dut : entity work.burst_writer
  port map(
    clk => clk,
    reset_n => reset_n,

    avm_waitrequest => avm_waitrequest,
    avm_wr => avm_wr,
    avm_wrdata => avm_wrdata,

    -- Interface to Output FIFO (lookahead)
    ofifo_q		    => ofifo_q		  ,
    ofifo_rdreq		=> ofifo_rdreq		,

    enable => enable,
    done => done,
    avm_beginburst => avm_beginburst,
    avm_burstcount => avm_burstcount,
    avm_address => avm_address,
    burst_address => X"0000_0000",
    burst_count => burst_count
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

    burst_count <= std_logic_vector(to_unsigned(6, 7));
    enable <= '0';

    wait for CLK_PERIOD;

    -- fill FIFO
    for i in 1 to 6 loop
      ofifo_wrreq <= '1';
      ofifo_data <= std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(i, 8)) & std_logic_vector(to_unsigned(i, 8))& std_logic_vector(to_unsigned(i, 8));
      wait for CLK_PERIOD;
    end loop;

    ofifo_wrreq <= '0';
    enable <= '1';
    avm_waitrequest <= '0';

    wait for CLK_PERIOD;

    enable <= '0';

    wait for CLK_PERIOD;

    avm_waitrequest <= '0';

    wait for 2*CLK_PERIOD;

    avm_waitrequest <= '1';

    wait for CLK_PERIOD;

    avm_waitrequest <= '0';

    wait for 10*CLK_PERIOD;

    sim_finished <= true;
    wait;
  end process simulation;
end test;
