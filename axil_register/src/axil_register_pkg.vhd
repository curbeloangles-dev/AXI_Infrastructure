
--! Librería estándar.
library ieee;
--! Elementos lógicos.
use ieee.std_logic_1164.all;

package axil_register_pkg is

  type typea_nslavesxaddrstd is array (natural range<>) of std_logic_vector;
  type typea_nslavesxdatastd is array (natural range<>) of std_logic_vector;

  type typea_nslavesxwstrbstd is array (natural range<>) of std_logic_vector;
  type typea_nslavesxrespstd is array (natural range<>) of std_logic_vector;
  type typea_nslavesxprotstd is array (natural range<>) of std_logic_vector;

end axil_register_pkg;
