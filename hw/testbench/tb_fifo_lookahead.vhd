library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fifo_lookahead is
end tb_fifo_lookahead;

architecture test of tb_fifo_lookahead is 
  constant CLK_PERIOD : time := 100 ns;

  signal sim_finished : boolean := false;

  -- Clock/Reset
  signal clk : std_logic;
  signal reset_n : std_logic;

  signal data		: STD_LOGIC_VECTOR (31 DOWNTO 0);
  signal rdreq		: STD_LOGIC ;
  signal sclr		: STD_LOGIC ;
  signal wrreq		: STD_LOGIC ;
  signal empty		: STD_LOGIC ;
  signal q		: STD_LOGIC_VECTOR (31 DOWNTO 0);

begin
  dut : entity work.fifolookahead
  port map( 
    clock => clk,
    data => data,
    rdreq => rdreq,
    sclr =>sclr,
    wrreq => wrreq,
    empty => empty,
    q => q
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

    wrreq <= '1';
    data <= (0 => '1', 2 => '1', others => '0');

    wait for CLK_PERIOD;

    wrreq <= '1';
    data <= (0 => '1', 1 => '1', others => '0');

    wait for CLK_PERIOD;

    wrreq <= '1';
    data <= (0 => '1', others => '0');

    wait for CLK_PERIOD;

    wrreq <= '0';
    rdreq <= '1';

    wait for CLK_PERIOD;

    rdreq <= '1';

    wait for CLK_PERIOD;

    rdreq <= '1';

    wait for CLK_PERIOD;

    rdreq <= '0';

    wait for 3*CLK_PERIOD;

    sim_finished <= true;
    wait;
  end process simulation;
end test;
