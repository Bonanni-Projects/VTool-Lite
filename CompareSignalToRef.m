function q = CompareSignalToRef(delay,t,x,t0,x0)

% COMPARESIGNALTOREF - Compare two signals, given a delay.
% q = CompareSignalToRef(delay,t,x,t0,x0)
%
% Compute correlation coefficient between (t0,x0) and (t,x), 
% after delaying signal (t0,x0) by the amount 'delay'.  
% Correlation is based on a comparison between signal 
% (t0+delay,x0) and signal (t,x) interpolated at the 
% values in time vector 't0+delay'. 
%
% The function is "vectorized" with respect to the 'delay' 
% input.  If 'delay' is a vector, matrix, or multidimensional 
% array, 'q' is returned with the corresponding size and 
% shape. 
%
% See also "MatchSignalToRef". 
%
% P.G. Bonanni
% 4/15/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% If scalar 'delay' specified
if isscalar(delay)

  % Apply delay
  to = t0 + delay;

  % Trim 'to' and 'x0' to include only overlapping time
  mask = (to < min(t)) | (to > max(t));
  to(mask) = [];
  x0(mask)  = [];

  % Interpolate signal #1 at 't0+delay'
  xx = interp1(t,x,to);

  % Correlation coefficient between resulting signals
  Q = corrcoef(xx,x0);  q=Q(1,2);

else  % if non-scalar 'delay'
  q = nan(size(delay));
  for k = 1:numel(delay)
    q(k) = CompareSignalToRef(delay(k),t,x,t0,x0);
  end
end
