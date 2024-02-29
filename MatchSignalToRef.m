function [out,delay,xdelay,xdelay0] = MatchSignalToRef(t,x,t0,x0,delay0)

% MATCHSIGNALTOREF - Match a signal to a reference signal.
% [q,delay] = MatchSignalToRef(t,x,t0,x0)
% [q,delay] = MatchSignalToRef(t,x,t0,x0,delay0)
% [q,delay] = MatchSignalToRef(t,x,t0,x0,dvec)
% [q,delay,xdelay,xdelay0] = MatchSignalToRef(...)
% MatchSignalToRef(...)
%
% Returns the correlation coefficient 'q' for the best match 
% between signal (t,x) and a delayed version of reference signal 
% (t0,x0), i.e., (t0+delay,x0).  Both the correlation coefficient 
% 'q' and the corresponding optimal 'delay' are returned.  (A 
% positive value for 'delay' implies that signal 'x' lags 'x0', 
% and a negative value implies that it leads.) 
%
% By default, an unconstrained minimization is performed, with 
% optional input 'delay0' specifying an initial guess for 'delay', 
% and a zero initial guess assumed otherwise.  If vector 'dvec' 
% of candidate delay values is provided in place of 'delay', a 
% brute-force search is performed instead. 
%
% Additional outputs 'xdelay' and 'xdelay0' represent the optimally 
% delayed version of 'x', sampled on time grids 't' and 't0', 
% respectively.  For efficiency, these outputs are not computed 
% if the corresponding output arguments are not supplied. 
%
% If called without output arguments, a plot is generated 
% showing the relationship of correlation coefficient to 
% the applied delay, with the computed optimal delay value 
% notated. 
%
% See also "CompareSignalToRef". 
%
% P.G. Bonanni
% 4/12/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 5
  delay0 = 0;
end

% Define the criterion function
fun = @(delay)1-CompareSignalToRef(delay,t,x,t0,x0);

% Compute optimal delay
if isscalar(delay0)
  delay = fminsearch(fun,delay0);
else  % if 'delay0' is a vector or array
  % Brute-force search
  dvec = delay0(:);
  vals = feval(fun,dvec);
  [~,i] = min(vals);
  delay = dvec(i);
end

% Correlation value
q = CompareSignalToRef(delay,t,x,t0,x0);

% If additional arguments supplied ...
if nargout > 2
  xdelay = interp1(t,x,t+delay,'linear','extrap');
end
if nargout > 3
  xdelay0 = interp1(t,x,t0+delay,'linear','extrap');
end


if nargout
  out = q;

else
  figure

  % Compute a suitable delay range
  T = (t0(end)-t0(1))/5;
  Drange = delay + [-T,T];

  % Plot correlation versus delay
  fun = @(delay)CompareSignalToRef(delay,t,x,t0,x0);
  fplot(fun,Drange)
  line(delay*[1;1],ylim,'Color','r')
  str1 = sprintf('q = %g', q);
  str2 = sprintf('delay = %g', delay);
  text(0.05,0.9,{str1;str2},'Color','r','Units','normalized')
  xlabel('delay')
  ylabel('correlation')
end
