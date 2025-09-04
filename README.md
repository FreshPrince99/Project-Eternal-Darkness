# Project Eternal Darkness

A hardware-accelerated arcade game implemented in **Verilog** for the **Digilent Nexys A7** FPGA board.
The design drives a VGA display and implements gameplay entities (player, zombies, bullets) with modular logic blocks.

> Key modules include `vga.v`, `drawcon.v`, `bullet_logic.v`, `zombie.v`, `random_number.v`, and the top-level `game_top.v`. A `clk_conv.v` generates derived clocks, and an optional `pdm_mic_interface.v` is provided for experimenting with PDM microphone input. ([GitHub][1])

---

## Table of contents

* [Overview](#overview)
* [Hardware & display](#hardware--display)
* [Repository structure](#repository-structure)
* [Getting started](#getting-started)
* [Build & program (Vivado)](#build--program-vivado)
* [Simulation](#simulation)
* [Configuration](#configuration)
* [Design notes](#design-notes)
* [Troubleshooting](#troubleshooting)
* [Documentation](#documentation)
* [Roadmap](#roadmap)
* [License](#license)

---

## Overview

Project Eternal Darkness is a self-contained Verilog game targeting the **Nexys A7 (Artix-7)**. The system generates VGA timing, renders sprites, and updates simple game mechanics each frame. The design is partitioned into small, testable RTL units composed under a single `game_top` integration module. ([GitHub][1])

---

## Hardware & display

* **Target board:** Digilent **Nexys A7** (Artix-7). The board provides a **100 MHz** oscillator and an onboard **VGA** connector with 4-bit-per-channel RGB plus HS/VS sync. ([digilent.com][2])
* **Video mode (typical):** 640×480 @ 60 Hz, **25 MHz** pixel clock (common for VGA demos on Nexys family boards). Timing is standard VGA 640×480. ([digilent.com][3])
* **Constraints:** Use the Digilent **Master XDC** for Nexys A7 as a starting point, then enable the specific VGA pins (R/G/B, HS, VS) and the 100 MHz clock net. ([GitHub][4], [digilent.com][5])

> Note: Exact pin assignments depend on the physical connector and color-channel width you choose. Refer to the Nexys A7 reference manual and your selected Master XDC. ([digilent.com][6], [GitHub][4])

---

## Repository structure

```
.
├─ game_top.v                 # Top-level integration (set this as your Vivado top)
├─ vga.v                      # HS/VS timing & (x,y) pixel coordinate generator
├─ drawcon.v                  # Simple renderer / sprite composition
├─ bullet_logic.v             # Bullet update & lifetime logic
├─ zombie.v                   # Enemy movement / spawn logic
├─ random_number.v            # Pseudo-random number generator for gameplay variety
├─ clk_conv.v                 # Clock division / generation for video/game logic
├─ pdm_mic_interface.v        # (Optional) PDM mic interface for audio-driven effects
├─ u5529041_ES2E3_Lab_Report.pdf  # Course/lab report describing the project
└─ README.md
```

(See the repo file list for the authoritative set of sources.) ([GitHub][1])

---

## Getting started

### Prerequisites

* **AMD/Xilinx Vivado** (2022.1 or newer recommended)
* **Nexys A7** board, USB programming cable
* VGA monitor and cable

### Clone

```bash
git clone https://github.com/FreshPrince99/Project-Eternal-Darkness
cd Project-Eternal-Darkness
```

---

## Build & program (Vivado)

1. **Create a Vivado project** (RTL project, **do not** add sources at creation if you prefer adding them manually later). Vivado’s New Project wizard guides device selection and source import. ([docs.amd.com][7])
2. **Add RTL sources**: add all `*.v` files and set **`game_top`** as the top module.
3. **Add constraints**: start from the Digilent **Master XDC** for Nexys A7; enable and map:

   * 100 MHz system clock input
   * VGA **HS**, **VS**, and **RGB** pins (according to your chosen color width)
   * Any buttons/switches you wire for control
     See Digilent’s XDC collection and Vivado constraints guides. ([GitHub][4], [AMD][8])
4. **Synthesize → Implement → Generate Bitstream.**
5. **Program device** via Hardware Manager (USB-JTAG). Digilent’s getting-started notes cover the basic flow. ([digilent.com][9])

> Tip: If you target **640×480\@60 Hz**, ensure your design provides a \~**25 MHz** pixel clock to `vga.v` (e.g., using an MMCM/PLL or a safe divider depending on jitter/closure). ([digilent.com][3])

---

## Simulation

Although the repository does not ship explicit testbenches, you can quickly sanity-check modules:

* **`vga.v`** — verify HS/VS timing and visible area (x,y) sweep.
* **`random_number.v`** — check repeatability/period (LFSR-style PRNGs are common).
* **`bullet_logic.v` / `zombie.v`** — step state machines through movement and lifetime rules.

Use the Vivado simulator or your preferred HDL simulator; add simple self-checking benches and run behavioral sim before synthesis.

---

## Configuration

* **Video mode & clocks:** Adjust `clk_conv.v` and any timing parameters in `vga.v` or `drawcon.v` if you change resolution.
* **Controls:** Map board buttons/switches in your `.xdc` and propagate nets into `game_top.v`.
* **Color depth:** Nexys A7 supports up to **4 bits per channel** on its VGA connector; you may reduce this in RTL to save LUTs or routing. ([digilent.com][6])
* **Audio (optional):** `pdm_mic_interface.v` is provided for experiments with PDM microphones; wire and constrain only if you intend to use it. ([GitHub][1])

---

## Design notes

* **Top-down composition:** `game_top.v` instantiates timing (VGA), render (`drawcon`), entities (`zombie`, `bullet_logic`), PRNG, and clocking. ([GitHub][1])
* **Determinism:** With a fixed seed in `random_number.v`, gameplay remains repeatable for debug.
* **Resource budgeting:** Simple sprites and a 640×480 pipeline keep utilization modest on the A7-100T.

---

## Troubleshooting

* **No picture on VGA:**

  * Confirm your monitor accepts **640×480\@60 Hz** and the pixel clock is \~25 MHz. ([digilent.com][3])
  * Re-check HS/VS polarity and active video ranges in `vga.v`.
  * Verify all VGA pins are correctly enabled in the `.xdc`. ([GitHub][4])
* **Timing failures:** Use an MMCM/PLL for clean clock generation; verify constraints per Vivado docs. ([AMD][10])
* **Controls not responding:** Ensure button/switch nets are constrained and debounced if necessary.

---

## Documentation

A project report is included: **`u5529041_ES2E3_Lab_Report.pdf`**. Refer to it for background, design rationale, and implementation details captured during development. ([GitHub][1])

---

## Roadmap

* Add ready-to-use **Nexys A7 `.xdc`** tailored for this design
* Provide **testbenches** for core modules
* Optional **higher resolutions** (e.g., 800×600 with appropriate timing/clocking)
* Sprite sheet and **score/health HUD** in `drawcon`
* Simple audio feedback path using the PDM interface

---

## License

This repository does not currently include a license file. If you plan to reuse code, please open an issue to discuss terms. ([GitHub][1])

---

**Maintainer:** *FreshPrince99* — contributions and suggestions are welcome.

[1]: https://github.com/FreshPrince99/Project-Eternal-Darkness "GitHub - FreshPrince99/Project-Eternal-Darkness: This repository contains a game developed on Verilog using the NEXYS A7 board."
[2]: https://digilent.com/reference/programmable-logic/nexys-a7/reference-manual?srsltid=AfmBOorwx4HEep1KRpWP7t-3tlYjApQOd2rCeEvA8sGgK48zPw7IDPXm&utm_source=chatgpt.com "Nexys A7 Reference Manual"
[3]: https://digilent.com/reference/nexys_vga/refmanual?srsltid=AfmBOor4zzqNHv2hGAL6O1Fqq1wbIEammYvSKNxDRA7NRnvXTKgAKawE&utm_source=chatgpt.com "Nexys VGA Reference Manual"
[4]: https://github.com/Digilent/digilent-xdc?utm_source=chatgpt.com "Digilent/digilent-xdc: A collection of Master XDC files ..."
[5]: https://digilent.com/reference/programmable-logic/guides/vivado-xdc-file?srsltid=AfmBOop-XkDvpwSobDqGQnWNHdyeZPd2POWA50of-1hnzfR5fBtI1zu_&utm_source=chatgpt.com "What is a Constraints File?"
[6]: https://digilent.com/reference/programmable-logic/nexys-a7/reference-manual?srsltid=AfmBOoq-0Kn3lBeZzEVAH3zOFmHQ1WyuFBDcXU6N_QkCwYoWBPrYX9G9&utm_source=chatgpt.com "Nexys A7 Reference Manual"
[7]: https://docs.amd.com/r/en-US/ug986-vivado-tutorial-implementation/Step-1-Creating-a-Project-Using-the-Vivado-New-Project-Wizard?utm_source=chatgpt.com "Creating a Project Using the Vivado New Project Wizard - ..."
[8]: https://www.xilinx.com/support/documents/sw_manuals/xilinx2022_1/ug945-vivado-using-constraints-tutorial.pdf?utm_source=chatgpt.com "Vivado Design Suite Tutorial: Using Constraints"
[9]: https://digilent.com/reference/vivado/getting_started_tutorial/start?srsltid=AfmBOoq2gBGHetDs7WEjYl1nZN-EaP3Tn7i9POzoVNW9CMIE-RYJsdT8&utm_source=chatgpt.com "Getting Started with Vivado"
[10]: https://www.xilinx.com/support/documents/sw_manuals/xilinx2022_1/ug903-vivado-using-constraints.pdf?utm_source=chatgpt.com "Using Constraints | Vivado Design Suite User Guide"
