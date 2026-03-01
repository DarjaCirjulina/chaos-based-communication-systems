# Design and Performance Evaluation of Chaos-Based Communication Systems under Noise and Multipath Conditions

## Overview

This repository provides reproducible LTspice, MATLAB (R2023b), and Python example codes developed for the PhD thesis *Design and Performance Evaluation of Chaos-Based Communication Systems under Noise and Multipath Conditions*. It includes chaotic oscillator modeling, synchronization under noisy conditions, QCSK and FM-CSK communication system simulations, and experimental validation using Analog Discovery Pro 3000. The repository is structured for academic reproducibility and research use in nonlinear dynamics and chaos-based communication systems.

---

## Repository Structure

chaos-based-communication-systems/

│  
├── 01_Chaotic_Oscillators/  
│   ├── LTspice/  
│   └── MATLAB_PostProcessing/  
│  
├── 02_Synchronization_Noise_Immunity/  
│   ├── LTspice_Drive/  
│   ├── LTspice_Response/  
│   └── MATLAB_Control_and_Analysis/  
│  
├── 03_QCSK_System/  
│   ├── Bits/   
│   ├── LTspice_Drive/  
│   ├── LTspice_Response/  
│   └── MATLAB_Data_Control_Analysis/  
│  
├── 04_FMCSK_System/  
│   ├── Bits/   
│   ├── LTspice_Drive/  
│   ├── LTspice_Response/  
│   └── MATLAB_Data_Control_Analysis/  
│  
└── 05_Experimental_ADP3000/  
    ├── MATLAB_Bit_Generation/  
    └── Python_Control_ADP3000/  
    
---

## 1. Chaotic Oscillators

This section contains LTspice models of chaotic oscillators and MATLAB scripts for nonlinear signal processing and analysis.

Implemented functionality includes:
- Cross-correlation computation  
- Z1Test calculation  
- Two-dimensional attractor projections  
- Power spectral density 

Workflow:

LTspice Simulation → Waveform Export (.txt) → MATLAB Post-Processing

This module establishes the nonlinear dynamic foundation used in synchronization and communication system sections.

---

## 2. Synchronization Noise Immunity

This module evaluates the stability of chaotic synchronization under noisy channel conditions.

System architecture:

Drive Oscillator (LTspice) → Channel Noise Injection (MATLAB) → Response Oscillator (LTspice) → Synchronization Evaluation (MATLAB)

MATLAB performs simulation control, additive noise injection, and synchronization evaluation, including correlation analysis.

---

## 3. QCSK Communication System

This section implements a Quadrature Chaos Shift Keying communication system.

System flow:

Bit Generation → Drive Oscillator → Symbol Mapping and Transmission Channel → Response Oscillator → Demodulation and BER Evaluation

MATLAB generates bit sequences, formats symbols, launches simulations, and evaluates Bit Error Rate performance.

---

## 4. FM-CSK Communication System

This module implements Frequency Modulated Chaos Shift Keying.

The architecture follows the same general structure as QCSK but differs in modulation implementation within the transmitter model.

System flow:

Bit Generation → Drive Oscillator → Symbol Mapping and Transmission Channel → Response Oscillator → Demodulation and BER Evaluation


---

## 5. Experimental Validation – Analog Discovery Pro

This section contains example scripts for hardware-based validation of the chaotic communication system.

System flow:

MATLAB (Bit Generation) → Python (ADP3000 Control) → Hardware Transmission → Signal Acquisition → Performance Evaluation

Python scripts configure and control the Analog Discovery Pro, generate excitation signals, acquire response oscillator signals, and store measurement data for further analysis.

---

## Important Notes

- All codes are provided as research examples.  
- Users must manually adjust:
  - LTspice installation paths  
  - File directories  
  - Hardware identifiers  
  - Sampling parameters  
  - Simulation durations  
- Scripts are not plug-and-play and require environment-specific configuration.  

This repository is intended as a reproducible academic reference for nonlinear dynamical systems and chaos-based communication research.

---

## Intended Audience

- Researchers in nonlinear dynamics  
- Chaos-based communication researchers  
- Physical-layer security researchers  
- Synchronization theory specialists  

---

## Citation

If this repository supports your research, please cite the associated thesis:

Author: Darja Cirjulina  
Title: Design and Performance Evaluation of Chaos-Based Communication Systems under Noise and Multipath Conditions  
Institution: Riga Technical University  
Year: 2025  

