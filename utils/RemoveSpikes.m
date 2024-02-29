function obj = RemoveSpikes(obj,name,filt,minval,maxval,duration,method)

% REMOVESPIKES - Remove spikes from a named signal in a dataset or signal group.
% Data = RemoveSpikes(Data,name,filt,minval,maxval,duration,method)
% Signals = RemoveSpikes(...)
%
% Removes spikes from the signal specified by 'name' in signal group 
% 'Signals', in accordance with the 'method' parameter, as follows: 
%  1  -  Signal is assumed to be integer-valued. Inputs 'minval' 
%        and 'maxval' define the valid signal range (with +inf 
%        and -inf values permitted), and 'duration' the maximum 
%        spike duration (in samples). A given spike is removed 
%        if the signal has the same value before and after the 
%        spike and the spike does not exceed the specified 
%        'duration'. The 'filt' input is not used. 
%  2  -  Signal is assumed to be real-valued and continuous. 
%        Inputs 'minval' and 'maxval' define the valid signal range 
%        (with +inf and -inf values permitted), and 'duration' the 
%        maximum spike duration (in samples). The spike is removed 
%        by linear interpolation across the surrounding points 
%        unless it exceeds the specified 'duration'. The 'filt' 
%        input is not used. 
%  3  -  Signal is assumed to be real-valued and continuous. 
%        The spike is identified by referencing the signal to 
%        a median-filtered version of itself, using filter 
%        order 'filt' (must be odd). Inputs 'minval' and 'maxval' 
%        define the valid signal range with respect to the 
%        reference (with +inf and -inf values permitted), and 
%        'duration' the maximum spike duration (in samples) 
%        after accounting for the filter width. The spike is 
%        removed by linear interpolation across the surrounding 
%        points unless the 'duration' requirement is exceeded. 
%  4  -  Signal is assumed to be real-valued and continuous. 
%        The signal is median filtered using filter order 'filt' 
%        (must be odd). Inputs 'minval', 'maxval', and 'duration' 
%        are not used. 
%
% Warning(s) are issued if one or more spikes do not meet the 
% criteria for repair. 
%
% P.G. Bonanni
% 3/30/22, revised 4/1/22

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Retrieve the signal
x = GetSignal(name,obj);

% Get data length
npoints = GetDataLength(obj);

% Apply the method
switch method
  case 1
    % Find and remove spikes on an integer signal
    mask = x < minval | x > maxval;  % detect out-of-range portion
    vr = [0; mask(1:end-1)];         % shift right
    vl = [mask(2:end); 0];           % shift left
    istart = find(mask~=0 & vr==0);  % start of spike
    iend   = find(mask~=0 & vl==0);  % end of spike
    for k = 1:length(istart)
      if iend(k)-istart(k)+1 <= duration
        if istart(k)==1 && iend(k)<npoints
          x(istart(k):iend(k)) = x(iend(k)+1);
        elseif istart(k)>1 && (iend(k)==npoints || iend(k)<npoints && x(istart(k)-1)==x(iend(k)+1))
          x(istart(k):iend(k)) = x(istart(k)-1);
        elseif istart(k)>1
          fprintf('Warning: Spike at index %d not removed because of left/right value mismatch.\n',istart(k));
        end
      else
        fprintf('Warning: Spike at index %d not removed because it has a duration of %d samples.\n', ...
                istart(k), iend(k)-istart(k)+1);
      end
    end

  case 2
    % Find and remove spikes on a continuous signal
    mask = x < minval | x > maxval;  % detect out-of-range portion
    index = reshape(1:length(x),size(x));
    x1=x; x1(mask)=interp1(index(~mask),x(~mask),index(mask),'linear','extrap');
    vr = [0; mask(1:end-1)];         % shift right
    vl = [mask(2:end); 0];           % shift left
    istart = find(mask~=0 & vr==0);  % start of spike
    iend   = find(mask~=0 & vl==0);  % end of spike
    for k = 1:length(istart)
      if iend(k)-istart(k)+1 <= duration
        x(istart(k):iend(k)) = x1(istart(k):iend(k));
      else
        fprintf('Warning: Spike at index %d not removed because it has a duration of %d samples.\n', ...
                istart(k), iend(k)-istart(k)+1);
      end
    end

  case 3
    % Find and remove spikes on a continuous signal, using median-filter reference
    xm = medfilt1(x,filt);  y=x-xm;  % deviation from local median
    mask = y < minval | y > maxval;  % detect out-of-range portion
    index = reshape(1:length(x),size(x));
    x1=x; x1(mask)=interp1(index(~mask),x(~mask),index(mask),'linear','extrap');
    vr = [0; mask(1:end-1)];         % shift right
    vl = [mask(2:end); 0];           % shift left
    istart = find(mask~=0 & vr==0);  % start of spike
    iend   = find(mask~=0 & vl==0);  % end of spike
    filt2 = (filt-1)/2;
    istart = max(istart-filt2,1);    % expand by 1/2 filter range
    iend   = min(iend+filt2,npoints);
    for k = 1:length(istart)
      if iend(k)-istart(k)+1 <= duration
        x(istart(k):iend(k)) = xm(istart(k):iend(k));
      else
        fprintf('Warning: Spike at index %d not removed because it has a duration of %d samples.\n', ...
                istart(k), iend(k)-istart(k)+1);
      end
    end

  case 4
    % Median filter
    x = medfilt1(x,filt);

  otherwise
    error('Invalid ''method''.')
end

% Replace the signal
if IsDataset(obj)
  obj = ReplaceSignalInDataset(obj,name,x);
else
  obj = ReplaceSignalInGroup(obj,name,x);
end
