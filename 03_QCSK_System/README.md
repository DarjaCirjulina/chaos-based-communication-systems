# QCSK Communication System

This folder implements the simulation framework for the Quadrature Chaos Shift Keying (QCSK) communication system.

MATLAB generates bit sequences, performs symbol mapping, and controls LTspice simulations of the drive and response chaotic oscillators using `.net` netlists. Waveforms are exported as `.txt` files for post-processing.

The system includes channel noise modeling, demodulation procedures, Bit Error Rate (BER) evaluation, and adaptive threshold–based detection to improve decision-making under varying noise conditions.

This module extends chaotic synchronization principles to secure the implementation of a digital communication system.
