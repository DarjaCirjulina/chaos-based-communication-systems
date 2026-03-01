# Synchronization Noise Immunity

This folder contains simulation scripts and models for evaluating the stability of chaotic synchronization under noisy channel conditions.

MATLAB controls LTspice drive and response oscillator simulations using `.net` netlists and processes exported waveform data (`.txt`). Additive channel noise is injected in MATLAB between drive and response simulations.

The implemented analysis includes cross-correlation and noise-immunity assessment.

This module establishes the performance limits of chaotic synchronization prior to its application in communication systems.
