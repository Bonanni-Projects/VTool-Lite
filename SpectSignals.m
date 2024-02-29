function [Pxx,f] = SpectSignals(obj,Ts,option)

% SPECTSIGNALS - Compute power spectral density for a signal group.
% [Pxx,f] = SpectSignals(Signals,Ts)
% [Pxx,f] = SpectSignals(SIGNALS,Ts)
% [Pxx,f] = SpectSignals(..., 'dB')
%
% Computes the power spectral density of signals in a signal 
% group.  Input 'Signals' is a signal group containing M signal 
% channels of time series data, and output 'Pxx' is a signal 
% group containing the corresponding M spectra.  Input 'Ts' 
% specifies the sample time in sec.  Output 'f' is the frequency 
% vector in 'Hz'. 
%
% Output spectra are returned in units of (.)^2/Hz. However, 
% if 'dB' is specified as as final argument, they are returned 
% in dB instead. 
%
% If one or more signals within 'Signals1' or 'Signals2' consists 
% of all NaNs, the corresponding spectra are represented as all 
% NaNs in the output. 
%
% Also works if input is a signal-group array 'SIGNALS', in which 
% case 'Pxx' is returned as a signal-group array of matching length. 
%
% See also "CrossSpectSignals". 
%
% P.G. Bonanni
% 1/26/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 3
  option = '';
end

% Input length
N = length(obj);

% If input is a signal-group array ...
if IsSignalGroupArray(obj) && N > 1

  % Compute spectra
  Pxx  = obj;  % initialize
  for k = 1:N
    [Pxx(k),f] = SpectSignals(obj(k),Ts,option);
    if N > 50 && fix(20*k/N) ~= fix(20*(k-1)/N)
      fprintf('%3.0f%% done.\n', 5*fix(20*k/N));
    end
  end

else
  Signals = obj;

  % Check 'Signals' input
  [flag,valid,errmsg] = IsSignalGroup(Signals);
  if ~flag
    error('Input ''Signals'' is not a signal group: %s',errmsg)
  elseif ~valid
    error('Input ''Signals'' is not a valid signal group: %s  See "IsSignalGroup".',errmsg)
  end

  % Check 'Ts' input
  if ~isnumeric(Ts) || ~isscalar(Ts)
    error('Input ''Ts'' must be a scalar numeric value.')
  elseif Ts <= 0
    error('Sample time ''Ts'' must be positive.')
  end

  % Number of signals
  nsignals = size(Signals.Values,2);

  % Data length
  npoints = size(Signals.Values,1);

  % Determine number of frequency points
  % (Use this method to avoid all-NaNs.)
  [~,f] = ComputePSD(zeros(npoints,1),1/Ts);
  Nf = length(f);

  % Initialize output to all NaNs
  Pxx = Signals;
  Pxx.Values = nan(Nf,nsignals);

  % Compute spectra
  for k = 1:nsignals
    x = Signals.Values(:,k);
    if ~all(isnan(x))
      [pxx,f] = ComputePSD(x,1/Ts);
      Pxx.Values(:,k) = pxx;
    end
    Pxx.Units{k} = PsdUnits(Pxx.Units{k});
  end

  % Convert to dB, if specified
  if strcmpi(option,'dB')
    Pxx.Values = 10*log10(abs(Pxx.Values));
    [Pxx.Units{:}] = deal('dB');
  end
end
