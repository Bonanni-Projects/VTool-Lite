function [gxx,f] = ComputePSD(x,Fs,option)

% COMPUTEPSD - Compute PSD of a signal.
% [gxx,f] = ComputePSD(x,Fs)
% [gxx,f] = ComputePSD(x,Fs,'dB')
%
% Computes the power spectral density estimate of a 
% single time series 'x' given sampling frequency 'Fs'.  
% Output 'gxx' is returned in units of (.)^2/Hz. However, 
% if 'dB' is specified as as final argument, 'gxx' is 
% returned in dB. 
%
% Output 'f' is the corresponding frequency vector. 
% The frequency resolution of the result is specified 
% by a fixed VTool parameter 'df', which governs the 
% employed window length.  The window length is not 
% restricted to be a power of 2. 
%
% P.G. Bonanni
% 8/13/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  option = '';
end

% Frequency resolution parameter (1/T)
df = GetParam('FrequencyResolution');  % Hz

% Window length
window = round(Fs/df);

% Check for NaNs
if all(isnan(x))
  z = zeros(size(x));
  [gxx,f] = cpsd(z,z,window,[],window,Fs);
  gxx = nan(size(gxx));
  return
elseif any(isnan(x))
  error('Embedded NaNs not permitted.')
end

% Make zero-mean
x = x - mean(x);

% Compute PSD
[gxx,f] = cpsd(x,x,window,[],window,Fs);

% Convert to dB, if specified
if strcmpi(option,'dB')
  gxx = 10*log10(abs(gxx));
end
