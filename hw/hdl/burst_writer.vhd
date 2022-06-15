library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity burst_writer is
  port(
    -- Clock/Reset
    clk:        in  std_logic;
    reset_n:    in  std_logic;

    -- Master Avalon (Writer)
    avm_waitrequest:  in  std_logic;
    avm_wr:           out std_logic;
    avm_wrdata:       out std_logic_vector(31 downto 0);
    avm_address:      out std_logic_vector(31 downto 0);
    avm_burstcount:   out std_logic_vector(6 downto 0);
    avm_beginburst:  out std_logic;

    -- Interface to Output FIFO (lookahead)
    ofifo_q		    : in std_logic_vector(31 downto 0);
    ofifo_rdreq		: out std_logic;

    -- Commands
    enable : in std_logic;
    done : out std_logic;
    burst_count : in std_logic_vector(6 downto 0);
    burst_address : in std_logic_vector(31 downto 0)
  );
end;

architecture comp of burst_writer is
  -- 
  -- The system can be in multiple states
  -- Req 
  -- |  |       Buf
  --            |  | 
  type SM is(Idle, HasReq, HasData, WaitDone, WaitDoneNext);
  signal state: SM := Idle;
  signal buf : std_logic_vector(31 downto 0);
begin
  Reader: process(clk, reset_n)
    variable count : unsigned(6 downto 0);
  begin 
    if reset_n = '0' then
      state <= Idle;
      done <= '1';
      avm_wr <= '0';
      avm_beginburst <= '0';
    elsif rising_edge(clk) then
      case state is 
        when Idle =>
          avm_wr <= '0';
          ofifo_rdreq <= '0';
          count := to_unsigned(0, 7);
          if enable = '1' then
            state <= HasReq;
            done <= '0';
            avm_wr <= '1';
            avm_wrdata <= ofifo_q;
            ofifo_rdreq <= '1';
            count := count + 1;
            avm_beginburst <= '1';
            avm_address <= burst_address;
            avm_burstcount <= burst_count;
          end if;
        when HasReq => 
          avm_beginburst <= '0';
          avm_wr <= '0';
          state <= HasData;
          ofifo_rdreq <= '0';
        when HasData => 
          if avm_waitrequest = '0' then
            avm_wr <= '1';
            avm_wrdata <= ofifo_q;

            count := count + 1;
            if count = unsigned(burst_count) then
              state <= WaitDone;
              ofifo_rdreq <= '0';
            else
              ofifo_rdreq <= '1';
              state <= HasReq;
            end if;
          else
            avm_wr <= '0';
          end if;
        when WaitDone =>
          avm_wr <= '0';
          state <= WaitDoneNext;
        when WaitDoneNext =>
          if avm_waitrequest = '0' then
            state <= Idle;
            done <= '1';
          end if;
        when others => null;
      end case;
    end if;
  end process;
end comp;
