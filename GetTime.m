function t = GetTime(Data)

% GETTIME - Extract the time vector from a dataset.
% t = GetTime(Data)
%
% Extracts the time vector from dataset 'Data' and 
% returns the result as column vector 't'. 
%
% See also "GetSignal". 
%
% P.G. Bonanni
% 7/13/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Data' argument
if numel(Data) > 1
  error('Works for scalar datasets only.')
end
[flag,valid] = IsDataset(Data);
if ~flag || ~valid
  error('Input ''Data'' is not a valid dataset.  See "IsDataset".')
end

% Get time vector
t = Data.Time.Values;
