function [out1,out2] = GetNamesMatrix(obj)

% GETNAMESMATRIX - Get names matrix for a signal group or dataset.
% [NAMES,Layers] = GetNamesMatrix(Signals)
% [NAMES,Layers] = GetNamesMatrix(Data)
%
% Returns the 'NAMES' matrix for signal group 'Signals'. 
% Rows of the matrix correspond to signals in the group, 
% and columns correspond to name layers.  Also returns 
% the list of layers as cell array 'Layers'.  If called 
% without output arguments, the results are printed to 
% the screen as a chart. 
%
% If dataset 'Data' is provided as an input argument, 
% a concatenated 'NAMES' matrix, representing a composite 
% of all signal groups, is returned. 
%
% See also "GetNames", "GetDefaultNames". 
%
% P.G. Bonanni
% 2/15/18

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Check input
[~,valid1] = IsDataset(obj);
[~,valid2] = IsSignalGroup(obj);
if ~valid1 && ~valid2
  error('Works for datasets or signal groups only.')
end

% If input is a dataset ...
if IsDataset(obj)
  Data = obj;
  Signals = CollectSignals(Data);
  if nargout  % return results
    [out1,out2] = GetNamesMatrix(Signals);
  else  % print results
    GetNamesMatrix(Signals);
  end
  return
else  % if input is a signal group ...
  Signals = obj;
end

% Identify name layers
Layers = GetLayers(Signals);

% Build NAMES matrix
s = rmfield(Signals, setdiff(fieldnames(Signals),Layers));
C = struct2cell(s);  NAMES = cat(2,C{:});

% Replace any [] entries with ''
mask = cellfun(@(x)isnumeric(x)&&isempty(x),NAMES);
[NAMES{mask}] = deal('');


if nargout
  out1 = NAMES;
  out2 = Layers;

else
  fprintf('\n');

  % Print results to screen as a chart
  C = num2cell([Layers';NAMES],1);  % add header row, and separate array columns
  [nrows,ncols] = size(NAMES);  nrows=nrows+1;  % total size
  C1 = cellfun(@char,C,'Uniform',false);        % make character arrays
  for k = 1:length(C1)
    Str = C1{k};
    n = size(Str,2);  % insert framing lines of length n
    Str = [repmat('-',1,n); Str(1,:); repmat('-',1,n); Str(2:end,:)];
    C1{k} = Str;
  end
  nrows = nrows+2;
  Delim = repmat('  ',nrows,1);
  C2 = [C1; repmat({Delim},1,ncols)];
  C2 = C2(:);  C2(end)=[];
  Str = cat(2,C2{:});  % add separation
  C3 = cellstr(Str);
  fprintf('%s\n',C3{:})
end
