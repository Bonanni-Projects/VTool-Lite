function varargout = AddMissingLayers(varargin)

% ADDMISSINGLAYERS - Coordinate name layers among two or more datasets.
% [Data1,Data2,Data3,...] = AddMissingLayers(Data1,Data2,Data3,...)
%
% Adds missing name layers as required to coordinate the 
% name layers among two or more provided datasets 'Data1', 
% 'Data2', 'Data3', etc.  The resulting datasets are returned 
% in the same order, and contain all name layers present in 
% the input datasets. 
%
% See also "AddNameLayer", "CopyNamesFromModel". 
%
% P.G. Bonanni
% 7/3/19

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check 'Data' arguments
for k = 1:nargin
  Data = varargin{k};
  if numel(Data) > 1
    error('Input dataset #%d is not scalar.  Works for scalar datasets only.',k)
  end
  [flag,valid] = IsDataset(Data);
  if ~flag || ~valid
    error('Input dataset #%d is not a valid dataset.  See "IsDataset".',k)
  end
end

% Check number of outputs
if nargout > nargin
  error('Too many output arguments.')
end

% Get full set of name layers
C = cellfun(@GetLayers,varargin,'Uniform',false);
Layers = unique(cat(1,C{:}));

% Process the datasets
for k = 1:nargout
  fprintf('Processing dataset #%d ...\n',k);
  varargout{k} = AddNameLayer(varargin{k},Layers);
end
fprintf('Done.\n');
