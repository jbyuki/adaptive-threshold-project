library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_finite_state_machine is
end tb_finite_state_machine;

architecture test of tb_finite_state_machine is 
  constant CLK_PERIOD : time := 1000 ns;

  signal sim_finished : boolean := false;

  -- Clock/Reset
  signal clk : std_logic;
  signal reset_n : std_logic;

  -- Master Avalon
  signal avm_add:          std_logic_vector(31 downto 0);
  signal avm_wr:           std_logic;
  signal avm_rd:           std_logic;
  signal avm_wrdata:       std_logic_vector(31 downto 0);
  signal avm_rddata:       std_logic_vector(31 downto 0);
  signal avm_waitrequest:  std_logic;
  signal avm_beginbursttransfer: std_logic;
  signal avm_burstcount:    std_logic_vector(6 downto 0);
  signal avm_rddatavalid:  std_logic;

  -- Avalon interface to burst reader and burst writer
  signal avm_add_burst_reader: std_logic_vector(31 downto 0);
  signal avm_rd_burst_reader: std_logic;
  signal avm_rddata_burst_reader: std_logic_vector(31 downto 0);
  signal avm_waitrequest_burst_reader: std_logic;
  signal avm_beginbursttransfer_burst_reader: std_logic;
  signal avm_burstcount_burst_reader: std_logic_vector(6 downto 0);
  signal avm_rddatavalid_burst_reader: std_logic;

  signal avm_add_burst_writer: std_logic_vector(31 downto 0);
  signal avm_wr_burst_writer: std_logic;
  signal avm_wrdata_burst_writer: std_logic_vector(31 downto 0);
  signal avm_waitrequest_burst_writer: std_logic;
  signal avm_beginbursttransfer_burst_writer: std_logic;
  signal avm_burstcount_burst_writer: std_logic_vector(6 downto 0);

  -- Commands
  signal enable:     std_logic;
  signal start_address:     std_logic_vector(31 downto 0);
  signal done:       std_logic;

  signal enable_burst_writer : std_logic;
  signal enable_burst_reader : std_logic;
  signal enable_compute : std_logic;

  signal add_burst_writer : std_logic_vector(31 downto 0);
  signal add_burst_reader : std_logic_vector(31 downto 0);

  signal burst_count_burst_writer : std_logic_vector(6 downto 0);
  signal burst_count_burst_reader : std_logic_vector(6 downto 0);

  signal done_burst_writer : std_logic;
  signal done_burst_reader : std_logic;
  signal done_compute : std_logic;
  signal dummy_read_burst_reader : std_logic;

  signal select_idx : std_logic_vector(1 downto 0);

  signal clr_all : std_logic;
begin
  dut : entity work.finite_state_machine
  port map(
    clk => clk,
    reset_n => reset_n,

    avm_add => avm_add,
    avm_wr => avm_wr,
    avm_rd => avm_rd,
    avm_wrdata => avm_wrdata,
    avm_rddata => avm_rddata,
    avm_waitrequest => avm_waitrequest,
    avm_beginbursttransfer => avm_beginbursttransfer,
    avm_burstcount => avm_burstcount,
    avm_rddatavalid => avm_rddatavalid,

    avm_add_burst_reader => avm_add_burst_reader,
    avm_rd_burst_reader => avm_rd_burst_reader,
    avm_rddata_burst_reader => avm_rddata_burst_reader,
    avm_waitrequest_burst_reader => avm_waitrequest_burst_reader,
    avm_beginbursttransfer_burst_reader => avm_beginbursttransfer_burst_reader,
    avm_burstcount_burst_reader => avm_burstcount_burst_reader,
    avm_rddatavalid_burst_reader => avm_rddatavalid_burst_reader,

    avm_add_burst_writer => avm_add_burst_writer,
    avm_wr_burst_writer => avm_wr_burst_writer,
    avm_wrdata_burst_writer => avm_wrdata_burst_writer,
    avm_waitrequest_burst_writer => avm_waitrequest_burst_writer,
    avm_beginbursttransfer_burst_writer => avm_beginbursttransfer_burst_writer,
    avm_burstcount_burst_writer => avm_burstcount_burst_writer,

    enable => enable,
    start_address => start_address,
    done => done,

    enable_burst_writer  => enable_burst_writer ,
    enable_burst_reader  => enable_burst_reader ,
    enable_compute  => enable_compute ,

    add_burst_writer  => add_burst_writer ,
    add_burst_reader  => add_burst_reader ,

    burst_count_burst_writer  => burst_count_burst_writer ,
    burst_count_burst_reader  => burst_count_burst_reader ,

    done_burst_writer  => done_burst_writer ,
    done_burst_reader  => done_burst_reader ,
    done_compute  => done_compute ,
    dummy_read_burst_reader  => dummy_read_burst_reader ,

    clr_all => clr_all,
    select_idx  => select_idx
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

    enable <= '0';
    done_burst_writer <= '0';
    done_burst_reader <= '0';
    done_compute <= '0';

    add_burst_writer <= x"9000_0000";
    add_burst_reader <= x"5000_0000";

    wait for CLK_PERIOD;

    start_address <= x"0000_0000";
    enable <= '1';

    wait for CLK_PERIOD;

    enable <= '0';

    for i in 1 to 250 loop
      wait for 4*CLK_PERIOD;
      done_burst_reader <= '1';
      done_compute <= '1';
      wait for CLK_PERIOD;
      done_burst_reader <= '0';
      done_compute <= '0';
      wait for 4*CLK_PERIOD;
      done_burst_writer <= '1';
      wait for CLK_PERIOD;
      done_burst_writer <= '0';
    end loop;

    sim_finished <= true;
    wait;
  end process simulation;
end test;
