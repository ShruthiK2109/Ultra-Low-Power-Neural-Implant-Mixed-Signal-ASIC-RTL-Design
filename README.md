# Ultra-Low-Power-Neural-Implant-Mixed-Signal-ASIC-RTL-Design

Project Overview:

This repository contains a SystemVerilog RTL implementation of an ultra‑miniature neural implant data acquisition system designed for Parkinson’s disease research and treatment. The project models the digital backend of a mixed‑signal ASIC, focusing on power efficiency, minimal area, and CDC‑safe data transfer—key constraints for implantable biomedical devices.

The system captures digitized neural signals from an external ADC, timestamps each sample at acquisition time, safely transfers data across clock domains using Gray‑coded asynchronous FIFOs, and outputs structured data packets for logging or further processing.



Design Goals & Constraints:

Ultra‑low power consumption (implantable medical device)

Small silicon area

Robust clock‑domain crossing (CDC)

Scalable & parameterized architecture

Clean analog–digital boundary suitable for mixed‑signal ASICs



System Architecture:

Analog Front End → ADC (adc_clk)

↓

Timestamping & Channel Tagging

↓

Gray‑Coded Asynchronous FIFO (CDC)

↓

System Clock Domain (sys_clk)

↓

Data Output / Logger



Key Architectural Features:

Dual‑clock design (adc_clk and sys_clk)

Timestamp captured at acquisition time

CDC‑safe data transfer using:

Binary‑to‑Gray pointer conversion

2‑Flip‑Flop synchronizers

Parameterized FIFO depth and data widths



Functional Blocks:

1. ADC Interface (Acquisition Domain)

Receives digitized neural samples from ADC

Attaches:

Channel ID

Timestamp

Operates in the adc_clk domain

2. Timestamp Generator

Monotonic counter incremented on each valid ADC sample

Ensures temporal alignment of neural data

3. Asynchronous FIFO (CDC Core)

Gray‑coded read/write pointers

2‑FF synchronizers for safe pointer transfer

Prevents metastability and data corruption

4. System Domain Interface

Reads data from FIFO in sys_clk domain

Outputs structured packets:

{ Channel ID | Timestamp | Neural Sample }



Simulation files:

neural_implant_parkinson_rtl.sv # Top‑level RTL + async FIFO

tb_neural_implant_parkinson.sv # Self‑checking testbench



Simulation Tools:

EDAPlayground

ModelSim / QuestaSim

Synopsys VCS

Xcelium



CDC & Reliability Considerations:

1. Gray‑coded pointers minimize bit toggling across domains
   
2. 2‑FF synchronizers mitigate metastability

3. No multi‑bit data directly crosses clock domains
   
4. FIFO depth parameterized for throughput vs power trade‑offs
   

Future Enhancements:

i. Power gating / clock gating hooks

ii. SPI or AXI‑Lite control interface

iii. Error detection (FIFO overflow/underflow flags)

iv. Multi‑channel neural streaming

v. Formal CDC verification assertions
