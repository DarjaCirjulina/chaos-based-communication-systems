close all, clear all;
format compact, format long;
%% Fundamental frequency
% L = 1e-6;
% C = .54e-9;
% Ceq = C^2/(2*C);
% f = 1/(2*pi*sqrt(L*Ceq))
% return
%% Data
dati = csvread(['data']);
t1 = unique(dati(:,1)); t1 = t1 - t1(1);
V1 = dati(:,2);  % V(1)
V2 = dati(:,3);  % V(2)
I1 = dati(:,4);  % I(L1)

tau1 = 1e-10;

t1r = 0:tau1:t1(end)-tau1;
V1_res = interp1(t1, V1(1:length(t1)), t1r');
V2_res = interp1(t1, V2(1:length(t1)), t1r');
I1_res = interp1(t1, I1(1:length(t1)), t1r');

% figure()
% plot(t1r*1e3, V1_res, 'b-', t1r*1e3, V2_res, 'r-')
% grid on, grid minor, xlabel('t, ms'), ylabel('V, V'), xlim([1.8 2.2])
% return

V1_res = V1_res - mean(V1_res);
V2_res = V2_res - mean(V2_res);
I1_res = I1_res - mean(I1_res);

% Z1test_C1 = formula(V1_res(1:200:end))
% Z1test_C2 = formula(V2_res(1:200:end))
% Z1test_L1 = formula(I1_res(1:200:end))

Corr_V1_V2 = corr2(V1_res,V2_res)
Corr_V1_V3 = corr2(V1_res,I1_res)
Corr_V2_V3 = corr2(V2_res,I1_res)
%% Correlation
%   XCORR(...,SCALEOPT), normalizes the correlation according to SCALEOPT:
%     'biased'   - scales the raw cross-correlation by 1/M.
%     'unbiased' - scales the raw correlation by 1/(M-abs(lags)).
%     'coeff'    - normalizes the sequence so that the auto-correlations
%                  at zero lag are identically 1.0.
%     'none'     - no scaling (this is the default).
% V1 = sin(2*pi*f.*t1r);
% V2 = cos(2*pi*f.*t1r);
V1 = V1_res;
V2 = V2_res;
V3 = I1_res;
lag = 5e-3/tau1;  % nolases, cik ir nemtas
[r1,lags1] = xcorr(V1, V2, lag,'coeff');
[r2,lags2] = xcorr(V1, V3, lag,'coeff');
[r3,lags3] = xcorr(V2, V3, lag,'coeff');
[r4,lags4] = xcorr(V1, V1, lag,'coeff');
[r5,lags5] = xcorr(V2, V2, lag,'coeff');
[r6,lags6] = xcorr(V3, V3, lag,'coeff');

% figure()
% subplot(2,1,1), plot(V1), grid on, grid minor,
% subplot(2,1,2), plot(V3), grid on, grid minor,
dt = (-lag:1:lag)'*tau1;
figure()
subplot(2,3,1)
% subplot(1,3,1)
plot(dt*1e6, r1), grid on, grid minor, title('xcorr V_{C1} & V_{C2}'), xlabel('\Deltat, \mus'), ylabel('Cross-Correlation'), %\mus
% figure()
subplot(2,3,2)
% subplot(1,3,2)
plot(dt*1e6, r2), grid on, grid minor, title('xcorr V_{C1} & I_{L1}'), xlabel('\Deltat, \mus'), ylabel('Cross-Correlation'),
% figure()
subplot(2,3,3)
% subplot(1,3,3)
plot(dt*1e6,r3), grid on, grid minor, title('xcorr V_{C2} & V_{L1}'), xlabel('\Deltat, \mus'), ylabel('Cross-Correlation'),
% figure()
subplot(2,3,4)
plot(dt*1e6, r4), grid on, grid minor, title('acorr V_{C1}'), xlabel('\Deltat, \mus'), ylabel('Autocorrelation'),
% figure()
subplot(2,3,5)
plot(dt*1e6, r5), grid on, grid minor, title('acorr V_{C2}'), xlabel('\Deltat, \mus'), ylabel('Autocorrelation'),
% figure()
subplot(2,3,6)
plot(dt*1e6,r6), grid on, grid minor, title('acorr I_{L1}'), xlabel('\Deltat, \mus'), ylabel('Autocorrelation'),
% return
%% Plots

[spectrV1, fr1] = win_fft(V1_res, 1/tau1, 10^4, 10^3);
[spectrV2, fr2] = win_fft(V2_res, 1/tau1, 10^4, 10^3);
[spectrI1, fr3] = win_fft(I1_res, 1/tau1, 10^4, 10^3);


figure()
subplot(1, 3, 1)
plot(V2_res, I1_res*1e3, 'b-'), grid on, grid minor,
xlabel('V_{C_2}, V'), ylabel('I_{L_1}, mA'), %axis([-25 70 -27 18])
subplot(1, 3, 2)
plot(V1_res, I1_res*1e3, 'c-'), grid on, grid minor,
xlabel('V_{C_1}, V'), ylabel('I_{L_1}, mA'), %axis([-2.5 1.5 -27 18])
subplot(1, 3, 3)
plot(V2_res, V1_res, 'r-'), grid on, grid minor,
xlabel('V_{C_2}, V'), ylabel('V_{C_1}, V'), %axis([-25 70 -2.5 1.5])


figure(), hold on, grid on, grid minor
plot(fr1*1e-3, 20*log10(spectrV1),'b.-'),
plot(fr2*1e-3, 20*log10(spectrV2),'r.-'),
plot(fr3*1e-3, 20*log10(spectrI1),'c.-'),
legend('V_{C1}','V_{C2}','I_{L1}')
xlabel('f, kHz'), ylabel('dB')
xlim([0 1000])
hold off