# AXI4-Lite Peripheral Subsystem: Design & Verification Showcase

This repository showcases a complete, end-to-end digital design and verification project built entirely from scratch. I designed the RTL for the AXI4-Lite peripheral subsystem (bridging to custom SPI, I2C, and UART controllers) based on a custom Microarchitecture Specification. To validate the design, I developed a full-scope verification environment demonstrating industry-standard practices, including constrained-random stimulus, SystemVerilog Assertions, and formal verification.

---

## Architecture and Environment

### Hardware Block Diagram
The subsystem splits the AXI4-Lite write and read channels into independent skid-buffered FSMs to isolate bus stalls from peripheral logic. The address is decoded to one of three memory-mapped peripheral pages (SPI, I2C, UART), and a centralized multiplexer routes the selected peripheral's read data and response back onto the bus.

![AXI4-Lite Subsystem Block Diagram](docs/rtl_microarch.png)

### Verification Environment Topology
The verification environment is a class-based SystemVerilog testbench using virtual interfaces for DUT pin coupling and mailboxes for transaction communication between test classes, drivers/monitors, and the scoreboard.

![Verification Environment Topology](docs/dv_environment.png)

---

## Verification Results and Sign-off Metrics

*   **Regression Status:** PASS
    *   15,000+ transactions driven.
    *   0 errors across all five test classes.
*   **SystemVerilog Assertions:** 20 properties active and verified.
    *   9 boundary-protocol assertions for AXI4-Lite compliance.
    *   11 white-box design assertions for internal state validation.
*   **Formal Verification:** Exhaustive proofs applied to the skid buffer and UART TX queue using SymbiYosys. This mathematically closes corner cases unreachable by dynamic simulation.
*   **Functional Coverage:** 100% Overall Coverage
    *   100% Register and transaction type coverage.
    *   100% Write-strobe pattern coverage.
    *   100% Peripheral configuration cross-coverage.
*   **Bugs Captured:** 5 RTL bugs isolated, fixed, and documented in the [Bug-Hunt Log](docs/vPlan.md#11-bug-hunt-log).
*   **Waivers and Honesty Check:** Any coverage gaps structurally unreachable by dynamic simulation are explicitly documented in the [Waivers table](docs/vPlan.md#9-waivers) and mapped directly to their equivalent Formal Verification proofs.

---

## Verification Methodology

*   **Stimulus Generation:** Test classes randomize and drive transactions into the environment mailboxes. Timing and data properties are constrained strictly according to the Verification Plan.
*   **Checking Mechanism:** A self-checking scoreboard validates AXI and peripheral traffic against abstract reference models. It explicitly avoids re-implementing the design logic.
*   **Protocol Assertions:** Concurrent SystemVerilog assertions monitor both the AXI4-Lite boundary and internal white-box invariants.
*   **Formal Verification:** SymbiYosys proves structural invariants directly on the RTL. This is utilized specifically for states that constrained-random simulation cannot reach organically.
*   **Functional Coverage:** Covergroups track essential configuration spaces, protocol behavior, and cross-coverage metrics to ensure stimulus quality.

---

## Quick Start

### Prerequisites
*   Simulation Tool: `dsim` (Altair DSim)
*   Formal Tool (optional — skid buffer & UART FIFO proofs): SymbiYosys with the Boolector engine
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
    *   [dv/formal/](dv/formal) - SymbiYosys proofs for the skid buffer and UART TX queue.
    *   [dv/cov/](dv/cov) - functional coverage groups.
*   [docs/](docs) - Architectural Specifications & Verification Planning:
    *   [Microarchitecture Specification (MAS)](docs/MAS.md)
    *   [Verification Plan (vPlan)](docs/vPlan.md)
