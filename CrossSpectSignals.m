function [Pxy,f,Pxx,Pyy,Perr] = CrossSpectSignals(obj1,Ts1,obj2,Ts2,option)

% CROSSSPECTSIGNALS - Cross power spectral density for signal groups.
% [Pxy,f,Pxx,Pyy,Perr] = CrossSpectSignals(Signals1,Ts1,Signals2,Ts2)
% [Pxy,f,Pxx,Pyy,Perr] = CrossSpectSignals(SIGNALS1,Ts1,SIGNALS2,Ts2)
% [Pxy,f,Pxx,Pyy,Perr] = CrossSpectSignals(..., 'dB')
%
% Given signal groups 'Signals1' and 'Signals2' with matching 
% order of signals, computes the cross spectra of corresponding 
% signsls within the two groups.  The signals in the two groups 
% need not have matching length.  Input 'Ts1' specifies the sample 
% time for 'Signals1' and 'Ts2' the sample time for 'Signals2', in 
% sec.  Returns the complex-valued cross spectra as output signal 
% group 'Pxy' with the corresponding signal names, and vector 'f' 
% giving frequency in 'Hz'.  Also returns signal groups 'Pxx', 
% 'Pyy', and 'Perr', giving the real-valued power spectra of 
% 'Signals1', 'Signals2', and the Signal2-Signal1 differences, 
% respectively. 
%
% The real-valued power spectra (Pxx,Pyy,Perr) are returned in units 
% of (.)^2/Hz. However, if 'dB' is specified as as final argument, 
% they are returned in dB instead. 
%
% The sampling frequency is determined by the first signal group.  
% Signals are re-sampled to the common 'Ts1' time grid and their 
% means removed before computing the spectra. 
%
% If one or more signals within 'Signals1' or 'Signals2' consists 
% of all NaNs, the corresponding spectra are represented as all 
% NaNs in the output. 
%
% Also works for signal-group arrays 'SIGNALS1' and 'SIGNALS2', 
% in which case 'Pxy', 'Pxx', 'Pyy', and 'Perr' are returned as 
% signal-group arrays of the matching length. 
%
% See also "SpectSignals". 
%
% P.G. Bonanni
% 1/26/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 5
  option = '';
end

% Input length
N = length(obj1);

% If input is a signal-group array ...
if IsSignalGroupArray(obj1) && N > 1
  if ~IsSignalGroupArray(obj2)
    error('Both ''Signals1'' and ''Signals2'' must be signal groups or signal-group arrays.')
  elseif length(obj2) ~= N
    error('Input arrays ''SIGNALS1'' and ''SIGNALS2'' must have matching length.')
  end

  % Compute cross spectra
  Pxy  = obj1;  % initialize
  Pxx  = obj1;  % initialize
  Pyy  = obj1;  % initialize
  Perr = obj1;  % initialize
  for k = 1:N
    [Pxy(k),f,Pxx(k),Pyy(k),Perr(k)] = CrossSpectSignals(obj1(k),Ts1,obj2(k),Ts2,option);
    if N > 50 && fix(20*k/N) ~= fix(20*(k-1)/N)
      fprintf('%3.0f%% done.\n', 5*fix(20*k/N));
    end
  end

else
  Signals1 = obj1;
  Signals2 = obj2;

  % Check inputs
  [flag1,valid1,errmsg1] = IsSignalGroup(Signals1);
  [flag2,valid2,errmsg2] = IsSignalGroup(Signals2);
  if ~flag1 || ~flag2
    error('Both ''Signals1'' and ''Signals2'' must be signal groups or signal-group arrays.')
  elseif ~valid1
    fprintf('%s\n',errmsg1);
    error('Input ''Signals1'' is not a valid signal group.')
  elseif ~valid2
    fprintf('%s\n',errmsg2);
    error('Input ''Signals2'' is not a valid signal group.')
  elseif ~isnumeric(Ts1) || ~isnumeric(Ts2) || numel(Ts1)~=1 || numel(Ts2)~=1
    error('Inputs ''Ts1'' and ''Ts2'' must be scalar numeric values.')
  elseif Ts1 <= 0 || Ts2 <= 0
    error('Both ''Ts1'' and ''Ts2'' must be positive.')
  end

  % Ensure the two groups have matching signal order
  if ~isequal(GetNamesMatrix(Signals1),GetNamesMatrix(Signals2))
    error('Names in ''Signals1'' and ''Signals2'' do not match.')
  end

  % Sample time
  Ts = Ts1;

  % Number of signals per group
  nsignals = size(Signals1.Values,2);

  % Data lengths
  N1 = size(Signals1.Values,1);
  N2 = size(Signals2.Values,1);

  % Time vectors
  t1 = Ts1*(0:N1-1)';
  t2 = Ts2*(0:N2-1)';

  % Patch any isolated NaNs in the signals
  for k = 1:nsignals
    x1 = Signals1.Values(:,k);
    mask = isnan(x1);
    if ~all(mask) && any(mask)
      x1 = interp1(t1(~mask),x1(~mask),t1,'linear','extrap');
      Signals1.Values(:,k) = x1;
    end
    x2 = Signals2.Values(:,k);
    mask = isnan(x2);
    if ~all(mask) && any(mask)
      x2 = interp1(t2(~mask),x2(~mask),t2,'linear','extrap');
      Signals2.Values(:,k) = x2;
    end
  end

  % Re-sample onto a common time grid
  t = (0:Ts:min(t1(end),t2(end)))';
  Signals1.Values = interp1(t1,Signals1.Values,t);
  Signals2.Values = interp1(t2,Signals2.Values,t);

  % Signal data, and data length
  X = Signals1.Values;
  Y = Signals2.Values;
  npoints = size(X,1);

  % Determine number of frequency points
  % (Use this method since X(:,1) or Y(:,1) could be all NaNs.)
  [~,f] = ComputeCoh(zeros(npoints,1),zeros(npoints,1),1/Ts);
  Nf = length(f);

  % Initialize outputs to all NaNs
  Pxy  = Signals1;  Pxy.Values  = nan(Nf,nsignals);
  Pxx  = Signals1;  Pxx.Values  = nan(Nf,nsignals);
  Pyy  = Signals1;  Pyy.Values  = nan(Nf,nsignals);
  Perr = Signals1;  Perr.Values = nan(Nf,nsignals);

  % Note: Function "ComputeCoh" does not handle 
  % all-NaN signals.  To get results for 'pxx' if 
  % 'y' is all NaNs or vice-versa, we temporarily 
  % set the all-NaN signal to zeros, in order to 
  % get an answer for the remaining signal. 

  % Compute spectra
  for k = 1:nsignals
    x = X(:,k);  % from Signals1
    y = Y(:,k);  % from Signals2
    if all(isnan(x)) && all(isnan(y))
      pxy  = nan(Nf,1);
      pxx  = nan(Nf,1);
      pyy  = nan(Nf,1);
      perr = nan(Nf,1);
    elseif all(isnan(x)) && ~all(isnan(y))
      [~,~,~,pyy] = ComputeCoh(zeros(size(x)),y,1/Ts);
      pxy  = nan(Nf,1);
      pxx  = nan(Nf,1);
      perr = nan(Nf,1);
    elseif ~all(isnan(x)) && all(isnan(y))
      [~,~,pxx,~] = ComputeCoh(x,zeros(size(y)),1/Ts);
      pxy  = nan(Nf,1);
      pyy  = nan(Nf,1);
      perr = nan(Nf,1);
    else  % neither x nor y is all NaNs
      [pxy,f,pxx,pyy,perr] = ComputeCoh(x,y,1/Ts);
    end
    Pxy.Values(:,k)  = pxy;
    Pxx.Values(:,k)  = pxx;
    Pyy.Values(:,k)  = pyy;
    Perr.Values(:,k) = perr;
    units = PsdUnits(Signals1.Units{k});
    Pxy.Units{k}  = units;
    Pxx.Units{k}  = units;
    Pyy.Units{k}  = units;
    Perr.Units{k} = units;
  end

  % Convert to dB, if specified
  if strcmpi(option,'dB')
    Pxx.Values  = 10*log10(abs(Pxx.Values));
    Pyy.Values  = 10*log10(abs(Pyy.Values));
    Perr.Values = 10*log10(abs(Perr.Values));
    [Pxx.Units{:}]  = deal('dB');
    [Pyy.Units{:}]  = deal('dB');
    [Perr.Units{:}] = deal('dB');
  end
end
