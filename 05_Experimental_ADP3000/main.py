#!/usr/bin/python3

############################################## Chaos IQ system experiment ##############################################

# Ruslans Babajans
# Institute of Radioelectronics
# Riga Technical University
# 2024

# The following program is for driving the Analod Discovery-2 (AD2) device. The purpose is to record the received
# Master oscillators X1_PM and slave oscillators Y1 signals to later decode the info signal in MATLAB.

# Note - the program connects to the specific AD2 device using serial numbers stored as a variable.

# List of abbreviations:
# AWG - Arbitrary waveform generator
# W1, W2 - Channels of the arbitrary waveform generator
# Ch1, Ch2 - Oscilloscope channels (Analog input)

# Program:
#   1) Power the master chaos oscillator;
#   2)Generate info signal on AD2-X AWGN W1;
#	3)Record and save samples:
#		AD2-X Ch1 - received_info_signal (X1_PM);
#		AD2-X Ch2 - chaos signal_slave (Y1);
#		AD2-X Ch3 - chaos signal_slave (Y2);

from dwfconstants import *
import time
import sys
import matplotlib.pyplot as plt
import numpy as np
import csv
import os

# Parameters of the experiment

attenuation = [39]  # Attenuations in dB

max_experiment_number=100 # Number of experiment iterations 1 experiment = 1000 bits
experiment_iteration = list(range(1, max_experiment_number + 1))

# Serial numbers of the used devices
AD2 = 'b\'SN:210018B48845\''  # Change if device with different serial number is used

# Device handlers and variables
hdwf = c_int()  # AD2-A handler

sts = c_byte()  # Variable for oscilloscope acquisition on AD2-X
W1 = c_int(0)  # Arbitrary waveform generator (AWG) Channel 1 (W1)
W2 = c_int(1)  # Arbitrary waveform generator (AWG) Channel 2 (W2)
device_id = c_int()  # The ID of a discovered AD2-A device
cDevice = c_int()  # Stores the number of discovered AD2 devices

# Declare string variables
devicename = create_string_buffer(64)  # Character array to store the name of enumerated devices
serialnum = create_string_buffer(16)  # Character array to store the serial number of enumerated devices

# Custom waveform generator variables
bit_number = 1024
bit_length = 1/125e3
cSamples_gen_info_signal = 2 * 16384  # Number of samples for AWG
hzFreq_info = 1/(bit_length*bit_number);   # Parameter taken from the signal import window for the info signals

# Acquisition variables
Ch1 = c_int(0)
Ch2 = c_int(1)
Ch3 = c_int(2)

fAcq = 125e5  # Sample frequency for analog input channels in Hz
tAcq = bit_length*bit_number  # Signal acquisition time in sec.
hzAcq = c_double(fAcq)
nSamples = int(tAcq * fAcq)  # Number of samples for signal acquisition
rgdSamples_chaos_info_signal_master = (c_double * nSamples)()  # Create a buffer array of c_doubles with size nSamples
rgdSamples_chaos_ones_slave = (c_double * nSamples)()  # Create a buffer array of c_doubles with size nSamples
rgdSamples_chaos_zeros_slave = (c_double * nSamples)()  # Create a buffer array of c_doubles with size nSamples

# Scope acquisition variables
cAvailable = c_int()
cLost = c_int()
cCorrupted = c_int()

fLost = 0
fCorrupted = 0
cSamples = 0

path = os.getcwd()+"\Generated_bit_signals_and_measurement_data"
########################################################################################################################
# Load dwf library (contain functions to interact with AD2)
if sys.platform.startswith("win"):
    dwf = cdll.dwf
elif sys.platform.startswith("darwin"):
    dwf = cdll.LoadLibrary("/Library/Frameworks/dwf.framework/dwf")
else:
    dwf = cdll.LoadLibrary("libdwf.so")

version = create_string_buffer(16)
dwf.FDwfGetVersion(version)
print("DWF Version: " + str(version.value))
dwf.FDwfParamSet(DwfParamOnClose, c_int(1))  # 0 = run, 1 = stop, 2 = shutdown
########################################################################################################################
# Enumerate and print device information
dwf.FDwfEnum(enumfilterAll, byref(cDevice))  # Enumerate AD2 devices
print("Number of Devices: " + str(cDevice.value))

for iDev in range(0, cDevice.value):
    dwf.FDwfEnumDeviceName(c_int(iDev), devicename)
    dwf.FDwfEnumSN(c_int(iDev), serialnum)
    print("------------------------------")
    print("Device " + str(iDev) + " : ")
    print("\tName:\'" + str(devicename.value) + "' " + str(serialnum.value))
print("------------------------------")
########################################################################################################################
# Detect and connect to the AD device
for iDev in range(0, cDevice.value):
    dwf.FDwfEnumSN(c_int(iDev), serialnum)
    deviceserialnum_string = str(serialnum.value)

    if deviceserialnum_string == AD2:
        device_id = iDev
        print("------------------------------")
        print("Opening AD2 : " + deviceserialnum_string + ". Device ID: " + str(device_id))
        dwf.FDwfDeviceOpen(c_int(device_id), byref(hdwf))

print("------------------------------")

if hdwf.value == 0:
    print("Failed to open device ADPro")
    szerr = create_string_buffer(512)
    dwf.FDwfGetLastErrorMsg(szerr)
    print(str(szerr.value))
else:
    print("Connected to ADPro")
    print("------------------------------")
########################################################################################################################

# Set up acquisition
dwf.FDwfAnalogInChannelEnableSet(hdwf, Ch1, c_bool(True))
dwf.FDwfAnalogInChannelEnableSet(hdwf, Ch2, c_bool(True))
dwf.FDwfAnalogInChannelEnableSet(hdwf, Ch3, c_bool(True))
dwf.FDwfAnalogInChannelRangeSet(hdwf, Ch1, c_double(4)) # 6 - measured +/-6V
dwf.FDwfAnalogInChannelRangeSet(hdwf, Ch2, c_double(4))
dwf.FDwfAnalogInChannelRangeSet(hdwf, Ch3, c_double(8))
dwf.FDwfAnalogInAcquisitionModeSet(hdwf, acqmodeRecord)
dwf.FDwfAnalogInFrequencySet(hdwf, hzAcq)
dwf.FDwfAnalogInRecordLengthSet(hdwf, c_double(tAcq))  # Set record length

########################################################################################################################
# Run the measurements part for every attenuation level
for num in range(len(experiment_iteration)):
    for a in range(len(attenuation)):
        if hdwf.value != 0:
            print("======================================")
            print( "ATTENUATION = " + str(attenuation[a]) + ", ITERATION: " + str(experiment_iteration[num]))
            print("======================================")

            ############################################################################################################
            # Read info signal file
            with open(path + "\Colpitts_info_signal" + "_attenuation_" + str(attenuation[a]) + "_iteration_" + str(experiment_iteration[num]) + ".csv", newline='') as File:
                txtlist = [j for sub in csv.reader(File) for j in sub]
                fa = list(map(float, txtlist))
                genSamples_info_signal = (c_double * len(fa))(*fa)
            ############################################################################################################
            # Generate info SIGNAL on AD2-X
            print("Running info signal...")
            print("------------------------------")
            dwf.FDwfAnalogOutNodeEnableSet(hdwf, W1, AnalogOutNodeCarrier, c_bool(True))
            dwf.FDwfAnalogOutNodeFunctionSet(hdwf, W1, AnalogOutNodeCarrier, funcCustom)
            dwf.FDwfAnalogOutNodeDataSet(hdwf, W1, AnalogOutNodeCarrier, genSamples_info_signal,
                                         c_int(cSamples_gen_info_signal))
            dwf.FDwfAnalogOutNodeFrequencySet(hdwf, W1, AnalogOutNodeCarrier, c_double(hzFreq_info))
            dwf.FDwfAnalogOutNodeAmplitudeSet(hdwf, W1, AnalogOutNodeCarrier, c_double(5)) # 5 V logic


            dwf.FDwfAnalogOutNodeEnableSet(hdwf, W2, AnalogOutNodeCarrier, c_bool(True))
            dwf.FDwfAnalogOutNodeFunctionSet(hdwf, W2, AnalogOutNodeCarrier, funcDC)
            dwf.FDwfAnalogOutNodeOffsetSet(hdwf, W2, AnalogOutNodeCarrier, c_double(4.5)) # Add DC


            dwf.FDwfAnalogOutConfigure(hdwf, W1, c_bool(True))
            dwf.FDwfAnalogOutConfigure(hdwf, W2, c_bool(True))
            ############################################################################################################
            # Acquire scope data
            # wait at least 2 seconds for the offset to stabilize
            # time.sleep(0.034)
            print("Starting oscilloscope acquisition...")
            print("------------------------------")

            dwf.FDwfAnalogInConfigure(hdwf, c_int(0), c_int(1))

            while cSamples < nSamples:

                dwf.FDwfAnalogInStatus(hdwf, c_int(1), byref(sts))
                if cSamples == 0 and (sts == DwfStateConfig or sts == DwfStatePrefill or sts == DwfStateArmed):
                    # Acquisition not yet started.
                    continue

                dwf.FDwfAnalogInStatusRecord(hdwf, byref(cAvailable), byref(cLost), byref(cCorrupted))
                cSamples += cLost.value

                if cLost.value:
                    fLost = 1

                if cCorrupted.value:
                    fCorrupted = 1

                if cAvailable.value == 0:
                    continue

                if cSamples + cAvailable.value > nSamples:
                    cAvailable = c_int(nSamples - cSamples)

                dwf.FDwfAnalogInStatusData(hdwf, Ch1,
                                           byref(rgdSamples_chaos_info_signal_master, sizeof(c_double) * cSamples),
                                           cAvailable)  # get ADPro channel 1 data
                dwf.FDwfAnalogInStatusData(hdwf, Ch2,
                                           byref(rgdSamples_chaos_ones_slave, sizeof(c_double) * cSamples),
                                           cAvailable)  # get ADPro channel 2 data
                dwf.FDwfAnalogInStatusData(hdwf, Ch3,
                                           byref(rgdSamples_chaos_zeros_slave, sizeof(c_double) * cSamples),
                                           cAvailable)  # get ADPro channel 3 data


                cSamples += cAvailable.value

            print("Data acquisition is done.")
            print("------------------------------")
            ############################################################################################################
            # Saving to file
            print("Saving data to .csv files...")
            print("------------------------------")

            f = open(path + "\Chaos_info_signal_master" + "_attenuation_" + str(attenuation[a]) + "_iteration_" + str(experiment_iteration[num]) + ".csv", "w")
            for v in rgdSamples_chaos_info_signal_master:
                f.write("%s\n" % v)
            f.close()

            f = open(path + "\Chaos_ones_slave" + "_attenuation_" + str(attenuation[a]) + "_iteration_" + str(experiment_iteration[num]) + ".csv", "w")
            for v in rgdSamples_chaos_ones_slave:
                f.write("%s\n" % v)
            f.close()

            f = open(path + "\Chaos_zeros_slave" + "_attenuation_" + str(attenuation[a]) + "_iteration_" + str(experiment_iteration[num]) + ".csv", "w")
            for v in rgdSamples_chaos_zeros_slave:
                f.write("%s\n" % v)
            f.close()

            print("Measurement results saved to .csv files.")
            print("------------------------------")

            ############################################################################################################
            # Reset scope variables for the next iteration
            fLost = 0
            fCorrupted = 0
            cSamples = 0

            ############################################################################################################
            time.sleep(1)  # Wait 1 sec.
########################################################################################################################
# Close devices
dwf.FDwfDeviceCloseAll()
time.sleep(1)  # Wait 1 sec.
print("======================================")
print("Measurements are done!")
print("======================================")
########################################################################################################################
# Plot data
# plot1 = plt.figure(1)
# plt.plot(np.fromiter(rgdSamples_chaos_info_signal_master, dtype=float))
# plot2 = plt.figure(2)
# plt.plot(np.fromiter(rgdSamples_chaos_ones_slave, dtype=float))
# plot3 = plt.figure(3)
# plt.plot(np.fromiter(rgdSamples_chaos_zeros_slave, dtype=float))
# plt.show()
