function [DataOut,info] = RemoveRepeatedPoints(Data,method)

% REMOVEREPEATEDPOINTS - Remove repeated time points from a dataset.
% DataOut = RemoveRepeatedPoints(Data)
% DataOut = RemoveRepeatedPoints(Data,method)
% [DataOut,info] = RemoveRepeatedPoints(...)
%
% Detects repeated time values in input dataset 'Data' and 
% selects among, or aggregates, the associated data points 
% according to a specified 'method', where 'method' is one 
% of {'first','last','mean','median','min','max','sum'}. If 
% not specified, the default is 'first'. The resulting output 
% dataset 'DataOut' has the repetitions removed. 
%
% In addition to providing an output dataset, the function 
% reports statistics on the number of detected repetitions 
% in a message to the screen.  It also indicates if any 
% signal value differences are detected in the data rows 
% associated with repeated time values. 
%
% Optional output 'info' is a structure with the following 
% fields, representing information derived during the 
% removal/aggregation process: 
%   'Ni'      -  input data length
%   'No'      -  output data length
%   'nsets'   -  number of repetition sets
%   'nreps'   -  total repetition points detected and removed
%   'flagD'   -  flag set to 'true' if signal value differences detected
%   'index'   -  index vector of retained time points from the input dataset
%   'index1'  -  index vector of "first" points in each repeating sequence
%   'indexR'  -  index vector of removed points
%   'Members' -  cell array of length matching 'index1', each element 
%                an index vector identifying points that were aggregated 
%                to produce the corresponding final value. 
% If the 'info' output argument is provided, reporting of 
% statistics to the screen is suppressed. 
%
% P.G. Bonanni
% 7/8/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


if nargin < 2
  method = 'first';
end

% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Set selection/aggregation method
if strcmp(method,'first')
  fun = @(x)x(1,:);
elseif strcmp(method,'last')
  fun = @(x)x(end,:);
elseif strcmp(method,'mean')
  fun = @mean;
elseif strcmp(method,'median')
  fun = @median;
elseif strcmp(method,'min')
  fun = @min;
elseif strcmp(method,'max')
  fun = @max;
elseif strcmp(method,'sum')
  fun = @sum;
else
  error('Method must be one of (''first'',''last'',''mean'',''median'',''min'',''max'',''sum'').');
end

% Data length
N = GetDataLength(Data);

% Initialize output dataset
DataOut = Data;

% Initialize 'info' structure
info.Ni      = N;
info.No      = N;
info.nsets   = 0;
info.nreps   = 0;
info.flagD   = false;
info.index   = (1:N)';
info.index1  = (1:N)';
info.indexR  = [];
info.Members = {};

% Get time vector
t = Data.Time.Values;

% Check time vector
if any(diff(t) < 0)
  error('Time vector is invalid: reversals detected.')
end

% Return immediately if time is monotonic
if all(diff(t) > 0)
  if nargout < 2
    fprintf('Input data length:  %d\n', N);
    fprintf('Output data length: %d\n', N);
    fprintf('Number of non-unique time points: %d\n', 0);
    fprintf('Total detected repetitions:       %d\n', 0);
  end
  return
end

% ---------------------------------
% Find points to merge
% ---------------------------------

% Find index of points to remove
indexR = 1 + find(diff(t) == 0);

% Find index of points to keep
index = setdiff((1:N)',indexR);

% Associate each 'indexR' with a member of 'index'
membership = zeros(size(indexR));
for k = 1:length(indexR)
  i = find(index < indexR(k), 1, 'last');
  membership(k) = index(i);
end

% Get list of "first points", i.e., points 
% ... that are followed by repetitions
index1 = unique(membership);

% List the points associated with each member of 'index1'
Members = cell(size(index1));  % initialize
for k = 1:length(index1)
  mask = membership==index1(k);
  Members{k} = [index1(k); indexR(mask)];  % "repetition sets"
end

% Compute statistics
nsets = length(index1);  % number of repetition sets
nreps = length(indexR);  % total repetitions, excluding first

% ---------------------------------
% Build output dataset
% ---------------------------------

% Initialize "differences" flag
flagD = false;

% Data length for output
Nout = length(index);

% Set time vector
DataOut.Time.Values = Data.Time.Values(index);

% Get list of signal groups, excluding 'Time'
[~,groups] = GetSignalGroups(Data);
groups = setdiff(groups,'Time','stable');

% Loop over groups
for k = 1:length(groups)
  group = groups{k};

  % Remove extra data rows
  DataOut.(group).Values(Nout+1:end, :) = [];

  % Build 'Values' array
  row = 0;  % initialize
  for j = 1:N
    % Is point a "first point", a "repeated point", neither?
    [flag1,i] = ismember(j,index1);  % 'i' is index within 'index1'
    [flagR,~] = ismember(j,indexR);

    % If point is not associated with repetitions ...
    if ~flag1 && ~flagR
      row = row + 1;
      DataOut.(group).Values(row,:) = Data.(group).Values(j,:);
    elseif flag1  % else if a "first point" in a repetition set
      row = row + 1;
      ROWS = Members{i};  % list of rows to combine
      DataOut.(group).Values(row,:) = fun(Data.(group).Values(ROWS,:));

      % Check if any signal differences exist, treating repeated NaNs as equal
      X = Data.(group).Values(ROWS,:); n=size(X,1);
      if ~isequaln(X, repmat(X(1,:),n,1)), flagD=true; end
    end
  end
end

% ---------------------------------
% Build 'info' structure
% ---------------------------------

info.Ni      = N;
info.No      = Nout;
info.nsets   = nsets;
info.nreps   = nreps;
info.flagD   = flagD;
info.index   = index;
info.index1  = index1;
info.indexR  = indexR;
info.Members = Members;

% ---------------------------------
% Report statistics
% ---------------------------------

if nargout < 2
  fprintf('Input data length:  %d\n', N);
  fprintf('Output data length: %d\n', Nout);
  fprintf('Number of non-unique time points: %d\n', nsets);
  fprintf('Total detected repetitions:       %d\n', nreps);
  fprintf('Differences detected? ');
  if flagD
    fprintf('(x) YES  ( ) NO\n');
  else
    fprintf('( ) YES  (x) NO\n');
  end
end
