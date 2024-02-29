function [cohxy,f,gxx,gyy,gerr] = ComputeCoh(x,y,Fs,option)

% COMPUTECOH - Compute coherence and PSD spectra.
% [cohxy,f,gxx,gyy,gerr] = ComputeCoh(x,y,Fs)
% [cohxy,f,gxx,gyy,gerr] = ComputeCoh(x,y,Fs,'dB')
%
% Computes the complex-valued coherence function between 
% equal-length time series 'x' and 'y', along with the 
% corresponding frequency vector 'f'. Input 'Fs' specifies 
% the sampling frequency.  
%
% Also returns power spectral density estimates of 'x', 
% 'y', and error time series (y-x) in outputs 'gxx','gyy', 
% and 'gerr', respectively.  These real-valued outputs are 
% returned in units of (.)^2/Hz.  However, if 'dB' is 
% specified as as final argument, they are returned in dB. 
%
% The frequency resolution of the results is specified 
% by a fixed VTool parameter 'df', which governs the 
% employed window length.  The window length is not 
% restricted to be a power of 2. 
%
% Modeled after code by A.S. Deshpande. 
%
% P.G. Bonanni
% 5/24/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.

% This function requires Signal Processing Toolbox. 


if nargin < 4
  option = '';
end

% Frequency resolution parameter (1/T)
df = GetParam('FrequencyResolution');  % Hz

% Window length
window = round(Fs/df);

% Check window length
if window > length(x)
  fprintf('\n');
  fprintf('FFT window length cannot be longer than data record.\n');
  error(' Parameter ''FrequencyResolution'' too small.  Adjust value in "GetParam" function.')
end

% Make zero-mean
x = x - mean(x);
y = y - mean(y);

% Compute error
e = y - x;

% Compute cross, PSD, and error spectra
[gxy, f] = cpsd(x,y,window,[],window,Fs);
[gxx, ~] = cpsd(x,x,window,[],window,Fs);
[gyy, ~] = cpsd(y,y,window,[],window,Fs);
[gerr,~] = cpsd(e,e,window,[],window,Fs);

% Coherence function
cohxy = gxy./(sqrt(abs(gxx)).*sqrt(abs(gyy)));

% Convert to dB, if specified (psd outputs only)
if strcmpi(option,'dB')
  gxx  = 10*log10(abs(gxx));
  gyy  = 10*log10(abs(gyy));
  gerr = 10*log10(abs(gerr));
end
