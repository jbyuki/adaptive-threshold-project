library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity finite_state_machine is
  port(
    -- Clock/Reset
    clk:        in  std_logic;
    reset_n:    in  std_logic;

    -- Master Avalon
    avm_add:          out std_logic_vector(31 downto 0);
    avm_wr:           out std_logic;
    avm_rd:           out std_logic;
    avm_wrdata:       out std_logic_vector(31 downto 0);
    avm_rddata:       in  std_logic_vector(31 downto 0);
    avm_waitrequest:  in  std_logic;
    avm_beginbursttransfer: out std_logic;
    avm_burstcount:    out std_logic_vector(6 downto 0);
    avm_rddatavalid:  in std_logic;

    -- Avalon interface to burst reader and burst writer
    avm_add_burst_reader: in std_logic_vector(31 downto 0);
    avm_rd_burst_reader: in std_logic;
    avm_rddata_burst_reader: out std_logic_vector(31 downto 0);
    avm_waitrequest_burst_reader: out std_logic;
    avm_beginbursttransfer_burst_reader: in std_logic;
    avm_burstcount_burst_reader: in std_logic_vector(6 downto 0);
    avm_rddatavalid_burst_reader: out std_logic;

    avm_add_burst_writer: in std_logic_vector(31 downto 0);
    avm_wr_burst_writer: in std_logic;
    avm_wrdata_burst_writer: in std_logic_vector(31 downto 0);
    avm_waitrequest_burst_writer: out std_logic;
    avm_beginbursttransfer_burst_writer: in std_logic;
    avm_burstcount_burst_writer: in std_logic_vector(6 downto 0);

    -- Commands
    enable:     in std_logic;
    start_address:     in std_logic_vector(31 downto 0);
    done:       out std_logic;

    enable_burst_writer : out std_logic;
    enable_burst_reader : out std_logic;
    enable_compute : out std_logic;

    add_burst_writer : out std_logic_vector(31 downto 0);
    add_burst_reader : out std_logic_vector(31 downto 0);

    burst_count_burst_writer : out std_logic_vector(6 downto 0);
    burst_count_burst_reader : out std_logic_vector(6 downto 0);

    done_burst_writer : in std_logic;
    done_burst_reader : in std_logic;
    done_compute : in std_logic;
    dummy_read_burst_reader : out std_logic;

    select_idx : out std_logic_vector(1 downto 0);
    clr_all : out std_logic

  );

end finite_state_machine;

architecture comp of finite_state_machine is
  type SM is(Idle, ReadFirstRow, ReadFirstRowWait, ReadSecondRow, ReadSecondRowWait, ReadCompute, ReadComputeWait, Write, WriteWait );
  signal state : SM;

  constant row_count : unsigned(7 downto 0) := to_unsigned(240, 8);
  constant col_count : unsigned(6 downto 0) := to_unsigned(80, 7);
begin

  with state select
    avm_add <= avm_add_burst_writer when Write,
            avm_add_burst_writer when WriteWait,
            avm_add_burst_reader when others;

  with state select
    avm_beginbursttransfer <= avm_beginbursttransfer_burst_writer when Write,
            avm_beginbursttransfer_burst_writer when WriteWait,
            avm_beginbursttransfer_burst_reader when others;

  with state select
    avm_burstcount <= avm_burstcount_burst_writer when Write,
            avm_burstcount_burst_writer when WriteWait,
            avm_burstcount_burst_reader when others;

  avm_rd <= avm_rd_burst_reader;
  avm_wr <= avm_wr_burst_writer;
  avm_rddata_burst_reader <= avm_rddata;
  avm_wrdata <= avm_wrdata_burst_writer;
  avm_rddatavalid_burst_reader <= avm_rddatavalid;
  avm_waitrequest_burst_reader <= avm_waitrequest;
  avm_waitrequest_burst_writer <= avm_waitrequest;

  -- Read entire row, 320/4 = 80
  burst_count_burst_writer <= std_logic_vector(col_count);
  burst_count_burst_reader <= std_logic_vector(col_count);

  fsm : process(clk, reset_n)
    variable read_row : unsigned(7 downto 0);
    variable write_row : unsigned(7 downto 0);
    variable read_address : unsigned(31 downto 0);
    variable write_address : unsigned(31 downto 0);
  begin
    if reset_n = '0' then
      state <= Idle;
      enable_burst_reader <= '0';
      enable_burst_writer <= '0';
      enable_compute <= '0';
      dummy_read_burst_reader <= '0';
      done <= '1';
      select_idx <= "00";
      clr_all <= '0';
    elsif rising_edge(clk) then
      clr_all <= '0';
      case state is 
        when Idle => 
          dummy_read_burst_reader <= '0';
          select_idx <= "00";
          if enable = '1' then
            read_address := unsigned(start_address);
            write_address := unsigned(start_address);

            state <= ReadFirstRowWait;
            enable_burst_reader <= '1';
            clr_all <= '1';
            add_burst_reader <= std_logic_vector(read_address);
            read_row := x"00";
            write_row := x"00";
            select_idx <= std_logic_vector(read_row(1 downto 0));
            done <= '0';
          end if;
        -- Always need to wait an extra cycle
        -- because the done flag in the subcomponents
        -- will have a 1 cycle delay before being lowered
        when ReadFirstRowWait =>
          enable_burst_reader <= '0';
          state <= ReadFirstRow;
        when ReadFirstRow =>
          if done_burst_reader = '1' then
            read_row := read_row + 1;
            read_address := read_address + 4*col_count;
            add_burst_reader <= std_logic_vector(read_address);
            select_idx <= std_logic_vector(read_row(1 downto 0));
            enable_burst_reader <= '1';
            state <= ReadSecondRowWait;
          end if;
        when ReadSecondRowWait =>
          enable_burst_reader <= '0';
          state <= ReadSecondRow;
        when ReadSecondRow =>
          if done_burst_reader = '1' then
            read_row := read_row + 1;
            read_address := read_address + 4*col_count;
            add_burst_reader <= std_logic_vector(read_address);
            select_idx <= std_logic_vector(read_row(1 downto 0));
            enable_burst_reader <= '1';
            enable_compute <= '1';
            state <= ReadComputeWait;
          end if;
        when ReadComputeWait => 
          enable_burst_reader <= '0';
          enable_compute <= '0';
          state <= ReadCompute;
        when ReadCompute =>
          if done_burst_reader = '1' and done_compute = '1' then
            read_row := read_row + 1;
            select_idx <= std_logic_vector(read_row(1 downto 0));


            state <= WriteWait;
            enable_burst_writer <= '1';
            add_burst_writer <= std_logic_vector(write_address);
          end if;
        when WriteWait =>
          enable_burst_writer <= '0';
          state <= Write;
        when Write =>
          if done_burst_writer = '1' then
            write_row := write_row + 1;
            write_address := write_address + 4*col_count;
            if write_row < row_count then

              read_address := read_address + 4*col_count;
              enable_burst_reader <= '1';
              add_burst_reader <= std_logic_vector(read_address);
              if read_row > row_count  then
                dummy_read_burst_reader <= '1';
              end if;

              enable_compute <= '1';
              state <= ReadComputeWait;
            else
              state <= Idle;
              done <= '1';
            end if;
          end if;
        when others => null;
      end case;
    end if;
  end process;
end comp;
