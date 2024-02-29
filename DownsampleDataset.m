function Data = DownsampleDataset(Data,factor)

% DOWNSAMPLEDATASET - Downsample a dataset.
% Data = DownsampleDataset(Data,factor)
%
% Downsamples 'Time' and all signal groups in 'Data' by positive 
% integer 'factor'.  In contrast to "ResampleDataset", any time 
% gaps in the dataset are preserved.  If factor=1 or [], the 
% input dataset is returned unmodified. 
%
% P.G. Bonanni
% 3/27/18

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

% Return immediately if no downsampling required or requested
if isempty(factor) || factor == 1, return, end

% Check 'factor' argument
if rem(factor,1)~=0 || factor < 1
  error('Input ''factor'' must be a positive integer.')
end

% No change required if factor == 1
if factor==1, return, end

% Identify signal-group fields
[~,fields] = GetSignalGroups(Data);

% Downsample all groups, including 'Time'
for k = 1:length(fields)
  field = fields{k};
  Data.(field).Values = Data.(field).Values(1:factor:end,:);
end
