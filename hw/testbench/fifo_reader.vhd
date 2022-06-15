library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_reader is
  port(
    clk : in std_logic;
    enable : in std_logic;
    rdreq : out std_logic;
    q : in std_logic_vector(31 downto 0);
    result : out std_logic_vector(31 downto 0)
  );
end;

architecture comp of fifo_reader is
  type SM is(Idle, ReadStop, ReadBack, Done);
  signal StateM: SM := Idle;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      case StateM is
        when Idle => 
          if enable = '1' then
            rdreq <= '1';
            StateM <= ReadBack;
          end if;
        when ReadStop =>
          rdreq <= '0';
          StateM <= ReadBack;
        when ReadBack =>
          rdreq <= '0';
          result <= q;
          StateM <= Done;

        when others => null;
      end case;
    end if;
  end process;
end comp;
