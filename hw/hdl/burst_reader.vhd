library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity burst_reader is
  port(
    -- Clock/Reset
    clk:        in  std_logic;
    reset_n:    in  std_logic;

    -- Master Avalon (Reader)
    avm_rddata:       in  std_logic_vector(31 downto 0);
    avm_waitrequest:  in  std_logic;
    avm_rddatavalid:  in std_logic;
    avm_beginburst:  out std_logic;
    avm_rd:           out std_logic;
    avm_burstcount:   out std_logic_vector(6 downto 0);
    avm_address:      out std_logic_vector(31 downto 0);

    -- Interface to FIFO multiplexer
    row_wrreq        : out std_logic;
    row_data        : out std_logic_vector(31 downto 0);
    row_sclr        : out std_logic;

    -- Commands
    enable : in std_logic;
    done : out std_logic;
    burst_count : in std_logic_vector(6 downto 0);
    burst_address : in std_logic_vector(31 downto 0);
    dummy_read : in std_logic
  );
end;

architecture comp of burst_reader is
  type SM is(Idle, Read);
  signal state: SM := Idle;
begin
  Reader: process(clk, reset_n)
    variable count : unsigned(6 downto 0);
  begin 
    if reset_n = '0' then
      state <= Idle;
      row_wrreq <= '0';
      done <= '1';
      avm_rd <= '0';
      avm_beginburst <= '0';
    elsif rising_edge(clk) then
      case state is 
        when Idle =>
          row_sclr <= '0';
          row_wrreq <= '0';
          count := to_unsigned(0, 7);
          if enable = '1' then
            if dummy_read = '0' then
              state <= Read;
              row_sclr <= '1';
              done <= '0';

              -- start burst transfer
              avm_rd <= '1';
              avm_address <= burst_address;
              avm_burstcount <= burst_count;
              avm_beginburst <= '1';
            elsif dummy_read = '1' then
              state <= Idle;
              row_sclr <= '1';
              done <= '1';
            end if;
          end if;
        when Read => 
          avm_beginburst <= '0';
          row_sclr <= '0';
          row_wrreq <= '0';
          avm_rd <= '0';
          if avm_waitrequest = '0' and avm_rddatavalid = '1' then
            row_wrreq <= '1';
            row_data <= avm_rddata;
            count := count + 1;
            if count >= unsigned(burst_count) then
              done <= '1';
              state <= Idle;
            end if;
          end if;
        when others => null;
      end case;
    end if;
  end process;
end comp;
