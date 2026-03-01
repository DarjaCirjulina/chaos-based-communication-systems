function[amps, freqs]=win_fft(x,Fs,win,olap)
% win_fft evaluates mean spectral components of signal x
%          x - signal, being analyzed
%         Fs - signal sampling frequency
%        win - window width
%       olap - overlap length [0 ... win-1]

% Checking window overlap
if (olap<0)||(olap>(win-1)); disp('Incorrect overlap value');return;end

% Calculate averaged spectral components
AmpT=zeros(1,win); Ptr=0;
while (Ptr+win)<=length(x)
    AmpT=AmpT+abs(fft(x(Ptr+(1:win))));
    Ptr=Ptr+win-olap;
end

% Normalizing spectral amplitudes
AmpT=AmpT/max(AmpT);
dN=ceil((win+1)/2);

% Determine whether signal is real -> half-band spectrum
if sum(imag(x)~=0)==0
    amps=AmpT(1:dN);
    freqs=(Fs/2)*(0:dN-1)/dN;
else % or complex -> full-band spectrum
    Fs
    amps=fftshift(AmpT);
    freqs=(Fs/2)/(win/2)*(ceil(-win/2):floor((win-1)/2));
end


