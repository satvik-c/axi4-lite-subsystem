# AXI4-Lite Peripheral Subsystem: RTL and Verification

This repository presents an AXI4-Lite peripheral subsystem and its full verification environment, both built from scratch. I designed and wrote all of the RTL — the AXI4-Lite bridge and all three peripheral cores (SPI, I2C, and UART) — from a custom Microarchitecture Specification. To validate it, I developed a class-based verification environment using constrained-random stimulus, SystemVerilog Assertions, functional coverage closure, and formal verification. A living [Bug-Hunt Log](docs/vPlan.md#11-bug-hunt-log) records every RTL defect the environment caught, root-caused, and closed.

---

## Architecture

The subsystem splits the AXI4-Lite write and read channels into independent skid-buffered FSMs to isolate bus stalls from peripheral logic. The address is decoded to one of three memory-mapped peripheral pages (SPI, I2C, UART), and a centralized multiplexer routes the selected peripheral's read data and response back onto the bus.

![AXI4-Lite Subsystem Block Diagram](docs/rtl_microarch.png)

---

## Verification Results and Sign-off Metrics

*   **Regression Status:** PASS
    *   15,000+ transactions checked by the scoreboard (AXI accesses plus the SPI/I2C/UART round-trips they trigger).
    *   0 errors across all five test classes.
*   **Bugs Captured:** 5 RTL bugs isolated, root-caused, and fixed — each documented with its root cause and resolution in the [Bug-Hunt Log](docs/vPlan.md#11-bug-hunt-log).
*   **SystemVerilog Assertions:** 20 concurrent assertions — 16 active in simulation, 4 targeting sim-unreachable states and discharged by formal proof.
    *   9 boundary-protocol assertions for AXI4-Lite compliance.
    *   11 white-box design assertions for internal state validation.
*   **Formal Verification:** Exhaustive proofs applied to the skid buffer and UART transmit FIFO using SymbiYosys. This mathematically closes corner cases unreachable by dynamic simulation.
*   **Functional Coverage:** 100% Overall Coverage
    *   100% Register and transaction type coverage.
    *   100% Write-strobe pattern coverage.
    *   100% Peripheral configuration cross-coverage.
*   **Coverage Waivers & Traceability:** Every coverage gap structurally unreachable by dynamic simulation is explicitly documented in the [Waivers table](docs/vPlan.md#9-waivers) and mapped directly to the formal proof that discharges it.

---

## Verification Environment and Methodology

The verification environment is a class-based SystemVerilog testbench using virtual interfaces for DUT pin coupling and mailboxes for transaction communication between test classes, drivers/monitors, and the scoreboard.

![Verification Environment Topology](docs/dv_environment.png)

*   **Stimulus Generation:** Test classes randomize and drive transactions into the environment mailboxes. Timing and data properties are constrained strictly according to the Verification Plan.
*   **Checking Mechanism:** A self-checking scoreboard validates AXI and peripheral traffic against abstract reference models. It explicitly avoids re-implementing the design logic.
*   **Protocol Assertions:** Concurrent SystemVerilog assertions monitor both the AXI4-Lite boundary and internal white-box invariants.
*   **Formal Verification:** SymbiYosys proves structural invariants directly on the RTL, targeting states that constrained-random simulation cannot reach organically.
*   **Functional Coverage:** Covergroups track essential configuration spaces, protocol behavior, and cross-coverage metrics to ensure stimulus quality.

---

## Quick Start

### Prerequisites
*   Simulation Tool: `dsim` (Altair DSim)
*   Formal Tool (optional — skid buffer & UART transmit FIFO proofs): SymbiYosys with the Boolector engine
*   Waveform Viewer: `gtkwave`

### Run the Full Regression
```bash
make all
```

### Run a Single Test Class
```bash
make run TEST=test_random_regression
```

### Dump and View Waveforms
```bash
make wave TEST=test_peripheral_roundtrip
gtkwave test_peripheral_roundtrip.fst
```

### Run the Formal Proofs
```bash
sby -f dv/formal/skid_buffer.sby
sby -f dv/formal/uart_fifo.sby
```

### Clean Up Artifacts
```bash
make clean
```

---

## Repository Layout

*   [rtl/](rtl) - Synthesizable subsystem RTL: AXI write/read handlers and skid buffers ([rtl/axi/](rtl/axi)), and the SPI ([rtl/spi/](rtl/spi)), I2C ([rtl/i2c/](rtl/i2c)), and UART ([rtl/uart/](rtl/uart)) peripheral cores.
*   [dv/](dv) - Verification environment:
    *   [dv/env/](dv/env) - drivers, monitors, reference models, and the scoreboard, organized per interface.
    *   [dv/tests/](dv/tests) - the five test classes in the Test Case Inventory.
    *   [dv/sva/](dv/sva) - bound SystemVerilog Assertions (boundary protocol + white-box design).
    *   [dv/formal/](dv/formal) - SymbiYosys proofs for the skid buffer and UART transmit FIFO.
    *   [dv/cov/](dv/cov) - functional coverage groups.
*   [docs/](docs) - Architectural Specifications & Verification Planning:
    *   [Microarchitecture Specification (MAS)](docs/MAS.md)
    *   [Verification Plan (vPlan)](docs/vPlan.md)
