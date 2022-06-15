library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_test is
end tb_test;

architecture test of tb_test is 
  constant CLK_PERIOD : time := 100 ns;

  signal sim_finished : boolean := false;

  -- Clock/Reset
  signal clk : std_logic;
  signal reset_n : std_logic;

  -- Internal interface (i.e. Avalon slave).
  signal a : std_logic;
  signal b : std_logic;
  signal c : std_logic;
begin
  dut : entity work.test
  port map( 
    a => a,
    b => b,
    c => c);

  clk_generation : process
  begin
    if not sim_finished then
      CLK <= '1';
      wait for CLK_PERIOD/2;
      CLK <= '0';
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
    reset_n <= '1';
    a <= '0';
    b <= '0';

    async_reset;

    a <= '1';

    wait for CLK_PERIOD*15;

    a <= '0';
    b <= '1';

    wait for CLK_PERIOD;

    b <= '0';

    wait for CLK_PERIOD;

    b <= '1';

    wait for CLK_PERIOD;

    b <= '0';

    wait for CLK_PERIOD;

    b <= '1';

    wait for CLK_PERIOD;

    sim_finished <= true;
    wait;
  end process simulation;
end test;
