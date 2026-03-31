# AXI_Infrastructure
This repository contains different AXI masters/slaves modules to perform different functions

## Contents
- `axil_regs/` — Generic AXI-Lite register bank with configurable number of read/write registers.
- `axil_register/` — AXI-Lite pipeline register: inserts configurable pipeline stages on each AXI-Lite channel.
- `axil_bram/` — Block RAM accessible via AXI-Lite interface.
- `axil_master/` — AXI-Lite master with a simple address/data interface for issuing read and write transactions.
- `axis_counter/` — AXI-Stream counter controlled via AXI-Lite: configurable count direction (up/down) and step size.
- `axis_tlast_gen/` — AXI-Stream tlast generator controlled via AXI-Lite. Supports packet and continuous modes, byte-count-based tlast, data swapping, and tkeep masking.
- `axis_interleaving/` — AXI-Stream interleaver that merges up to 5 input channels into a single output stream, with AXI-Lite register control and a configurable blocking threshold.
- `axi_gpio/` — General Purpose I/O peripheral with AXI-Lite control (configurable GPO write and GPI read ports).

Each module follows a common folder layout:
- `package.json` — Metadata for packaging/publishing the IP (name, version).
- `README.md` — Local module readme with version history.
- `doc/` — Diagrams and additional documentation.
- `src/` — VHDL source files.
- `tb/` — Testbenches and unit tests (cocotb + pytest).

## Per-module descriptions
### axil_regs
Generic AXI-Lite register bank. Exposes a flat array of read/write registers accessible over AXI-Lite. The number of registers, data width, and address width are configurable via generics. Optionally supports external `bresp` sourcing to allow the downstream logic to control the write response.

### axil_register
AXI-Lite pipeline register (register slice). Inserts one pipeline stage per AXI-Lite channel (AW, W, B, AR, R), with each channel's register type independently configurable. Used to break long AXI-Lite paths and improve timing closure without changing bus functionality.

### axil_bram
Block RAM memory accessible through an AXI-Lite slave interface. The memory depth (in 32-bit words) and AXI address width are configurable via generics. Suitable for on-chip scratchpad memories or coefficient tables accessible from a processor or DMA engine.

### axil_master
AXI-Lite master with a simple user-facing interface. Accepts an address, a write-valid or read-valid trigger, and data in/out signals, and translates them into full AXI-Lite transactions. Exposes a `done` flag and a `write_result` (bresp) output to signal transaction completion.

### axis_counter
AXI-Stream output counter controlled via AXI-Lite. The counter value is continuously output on the AXI-Stream master interface. Count direction (up/down) and step size are configurable at runtime through the AXI-Lite register interface. A software reset is also available via register.

### axis_tlast_gen
Configurable AXI-Stream tlast generator with AXI-Lite control. Operates in two modes:
- **Packet mode** (`packetsNum ≥ 1`): generates exactly N packets of a configurable byte length.
- **Continuous mode** (`packetsNum = 0`): generates tlast periodically every N bytes indefinitely.

Additional features: configurable data swapping (word or byte order), tkeep masking to align the last beat of each packet, optional passthrough of the input tlast signal, and a `busy` output indicating active operation.

### axis_interleaving
AXI-Stream interleaver that merges up to 5 input AXI-Stream channels of the same data width into a single output stream. The number of active channels (`g_CHANNELS_USED`, 1–5) and the data width (`g_AXIS_TDATA_WIDTH`) are configurable via generics. A configurable blocking threshold (`g_BLOCKING_THRESHOLD`) gates the output when too many input channels report NOK status. Runtime control is available through an AXI-Lite register interface exposing a version register, a user-control enable bit, and a per-channel status register.

### axi_gpio
General Purpose I/O peripheral with AXI-Lite slave interface. Provides independently configurable GPO (output) and GPI (input) port widths (1–32 bits each). GPO values are written via register and driven directly to output ports; GPI values are sampled from input ports and readable via register. A configurable default GPO reset value is supported.

## Running tests locally
These projects use cocotb and pytest for Python-based testbenches. To run tests locally:

1. Install simulator and Python dependencies (example for GHDL + cocotb):
```bash
sudo apt-get update
sudo apt-get install -y ghdl
python3 -m pip install --user cocotb pytest cocotb-test cocotbext-axi
```

2. Run a module's pytest test from its `tb/` directory, for example:
```bash
pytest -o log_cli=True ./axis_counter/tb/test_axis_counter.py
```

## Contributing
- Update or add tests when changing behavior.
- Keep `package.json/version` bumped when you want the CI to publish a new package version.
- Open PRs for changes and ensure CI passes before merge.
