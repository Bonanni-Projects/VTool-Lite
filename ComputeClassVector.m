function [out1,out2] = ComputeClassVector(SIGNALS,name,choice,edges,option)

% COMPUTECLASSVECTOR - Compute classification vector for a signal group array.
% [iclass,BinResults] = ComputeClassVector(SIGNALS,name,choice,edges)
% [iclass,BinResults] = ComputeClassVector(SIGNALS,name,['mean','std','median','max','min','mode'],edges)
% [iclass,BinResults] = ComputeClassVector(...,'report')
% ComputeClassVector(...)
%
% Computes the binning index vector for signal group array 'SIGNALS', 
% given selection of a signal 'name', a statistical function 'choice', 
% and specification of bin boundaries.  Input 'choice' specifies 
% either a statistical function ('mean','std','median','max','min',
% 'mode') or a scalar value signifying a percentile value between 
% 0 and 100. Vector 'edges' defines monotonically increasing bin 
% boundaries, where edge(i) specifies the left edge, and edge(i+1) 
% the right edge of the ith bin (with '-inf' and 'inf' values at the 
% ends permitted). 
%
% Output 'iclass' is a vector equal in length to 'SIGNALS' returning 
% the bin index value for each element of 'SIGNALS'.  A value iclass=0 
% marks cases falling outside the specified binning range.  Output 
% 'BinResults' is a structure array equal in length to the number of 
% bins, containing the fields: 
%   'index'   -  bin index
%   'center'  -  bin center value
%   'cases'   -  number of cases
%   'title'   -  title string for the bin
%
% If called without an output argument, the function reports results 
% of the classification to the screen, but returns no outputs.  However, 
% the 'report' option may be specified if both outputs and reporting 
% are desired. 
%
% P.G. Bonanni
% 8/12/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 5
  option = '';
end

% Check 'SIGNALS' input
[flag,valid,errmsg] = IsSignalGroupArray(SIGNALS);
if ~flag
  error('Input ''SIGNALS'' is not a signal group array: %s',errmsg)
elseif ~valid
  error('Input ''SIGNALS'' is not a valid signal group array: %s  See "IsSignalGroupArray".',errmsg)
end

% Check other inputs
if ~ischar(name) || size(name,1)~=1
  error('Input ''name'' must be a scalar string.')
elseif isnumeric(choice) && (~isscalar(choice) || choice < 0 || choice > 100)
  error('Percentile values must be scalar, from 0 to 100.')
elseif ischar(choice) && ~any(strcmp(choice,{'mean','std','median','max','min','mode'}))
  error('Invalid choice of statistic.')
elseif ~isnumeric(edges) || ~isvector(edges) || length(edges) < 2 || ~all(diff(edges) > 0)
  error('Invalid ''edges'' input.')
end

% Find the named signal
iC = FindName(name,SIGNALS(1));
if isempty(iC)
  error('Selected signal name not found.')
end

% Extract data for the named signal
if numel(iC)>1, iC=iC(1); end  % first instance only
C = arrayfun(@(x)x.Values(:,iC),SIGNALS,'Uniform',false);
X = cat(2,C{:});

% If 'X' is a single row, modify it to ensure columnwise behavior below
if size(X,1)==1, X = [X; X]; end

% Build statistical function
if ischar(choice)
  fun = str2func(choice);
else
  pct = choice;
  fun = @(x)prctile(x,pct);
end

% Compute the statistic
x = fun(X)';

% Compute bin vector
[~,~,iclass] = histcounts(x,edges);

% Compute bin centers
centers = (edges(1:end-1)'+edges(2:end)')/2;

% Generate bin title strings
units = SIGNALS(1).Units{iC};
BinTitles = arrayfun(@(x1,x2)sprintf('%g - %g %s',x1,x2,units), ...
                      edges(1:end-1)',edges(2:end)','Uniform',false);

% Initialize 'BinResults'
nbins = length(centers);
BinResults = struct('index',  cell(nbins,1), ...
                    'center', cell(nbins,1), ...
                    'cases',  cell(nbins,1), ...
                    'title',  cell(nbins,1));

% Record binning results
for k = 1:length(centers)
  BinResults(k).index = k;
  BinResults(k).cases = sum(iclass==k);
  BinResults(k).center = centers(k);
  BinResults(k).title = BinTitles{k};
end

% If output argument(s) provided
if nargout
  out1 = iclass;
  out2 = BinResults;
end

% If no output arguments, or if 'report' option specified
if ~nargout || strcmp(option,'report')
  
  % Display binning results
  fprintf('Number of cases by bin (%d total):\n',length(iclass));
  C = struct2cell(BinResults)';  C = C(:,[1,3,4])';
  fprintf('  %2d  %4d    %s\n', C{:});
  fprintf('      %4d    rejected',sum(iclass==0));
  if any(isnan(x)), fprintf(' (%d cases contained NaNs)\n',sum(isnan(x))); else fprintf('\n'); end
  fprintf('\n');

  % If all cases rejected
  if all(iclass == 0)
    fprintf('All cases fall outside binning range.\n')
    fprintf('\n');
  end
end
