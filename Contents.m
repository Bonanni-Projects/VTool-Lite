% VTOOL             VALIDATION TOOLBOX               Pierino G. Bonanni 7/20/19
%
% Dataset Construction and Modification
%   BuildDataset              - Build a signal evaluation dataset based on NameTables.
%   BuildDatasetFromData      - Build a dataset from raw time and signal data.
%   BuildDatasetFromModel     - Build a supplementary dataset from a model.
%   RebuildDataset            - Rebuild a dataset based on NameTables.
%   RebuildDatasetFromModel   - Rebuild a dataset based on a model.
%   NullDataset               - Build a null dataset from a model.
%   RenameField               - Rename signal groups, name layers, or fields.
%   CopySignals               - Copy signals between datasets or signal groups.
%   ChangeSignalUnits         - Change signal units in a dataset or signal group.
%   ChangeTimeUnits           - Change the time units in a dataset.
%   ReconcileUnits            - Reconcile units across datasets or signal groups.
%   ReplaceSignalInDataset    - Replace a signal in a dataset.
%   ReplaceUnits              - Replace a units string in a dataset or signal group.
%   ReplaceDescription        - Replace a description string in a dataset or signal group.
%   RemoveGroupsExcept        - Remove extra signal groups.
%   LimitTimeRange            - Limit time range of a dataset.
%   ResampleDataset           - Resample a dataset.
%   DownsampleDataset         - Downsample a dataset.
%   SampleAndHold             - Sample and hold signals in a dataset or signal group.
%   RemoveRepeatedPoints      - Remove repeated time points from a dataset.
%   Decimate                  - Decimate signals or groups in a dataset.
%   ApplyMask                 - Mask signals or groups at selected locations.
%   ApplyIndex                - Apply integer or binary index to signals or groups.
%   ApplyFunction             - Apply a function to data in datasets or signal groups.
%   BufferDataset             - Buffer a dataset into a dataset array.
%   ConcatDatasets            - Concatenate datasets into a single dataset.
%   NanFillDataset            - Fill sampling holes in a dataset.
%   PadDataToLength           - Pad a dataset or dataset array to length.
%   SequenceDatasets          - Sequence datasets contiguously in time.
%   MergeDatasets             - Merge two or more datasets into one.
%   ConvertToDouble           - Convert data to 'double'.
%   ConvertToAbsoluteTime     - Convert to absolute time.
%   ConvertToElapsedTime      - Convert to elapsed time.
%   SelectFromDataset         - Reduce a dataset to a set of selected signals.
%   RegroupByDimension        - Regroup a dataset by signal dimension.
%
% Signal Group Manipulation
%   BuildTimeGroup            - Build a time signal group.
%   BuildTimeArray            - Build a time signal group array.
%   DefineSignalGroup         - Define a new signal group on a dataset.
%   CollectSignals            - Collect signals from a dataset into a master group.
%   AddSignalToGroup          - Add a signal to a new or existing signal group.
%   MergeSignalGroups         - Merge two or more signal groups into one.
%   SelectFromGroup           - Reduce a signal group to a set of selected signals.
%   RemoveFromGroup           - Remove one or more signals from a signal group.
%   ReplaceSignalInGroup      - Replace a signal in a signal group.
%   BufferSignalGroup         - Buffer a signal group into a signal group array.
%   ConcatSignalGroups        - Concatenate signal groups or signal group arrays.
%   PadSignalsToLength        - Pad a signal group or signal-group array to length.
%   ConvertSignalsToDB        - Convert signal group to dB units.
%   SequenceTime              - Generate a sequenced time array.
%
% Name Management
%   FindName                  - Find a signal name in a signal group or dataset.
%   NameTables                - Open the active NameTables.xlsx file.
%   AddNameLayer              - Add a new name layer to a dataset or signal group.
%   AddMissingLayers          - Coordinate name layers among two or more datasets.
%   CopyNamesFromModel        - Copy all names from a model dataset or signal group.
%   ReplaceNameOnLayer        - Replace a signal name in a dataset or signal group.
%   RemoveNameLayer           - Remove one or more name layers.
%   RemoveLayersExcept        - Remove extra name layers.
%   PrintNameTables           - Print NameTables.xlsx to a text file.
%
% Checking
%   Check                     - Identify input type and check for validity.
%   CheckNames                - Check for repeated names in a dataset or signal group.
%   CheckNameTables           - Check NameTables.xlsx file for errors.
%   IsFileType                - Flag filenames belonging to a specified file type.
%   IsDataset                 - Identify and check a dataset for validity.
%   IsDatasetArray            - Identify and check a dataset array for validity.
%   IsSignalGroup             - Identify and check a signal group for validity.
%   IsSignalGroupArray        - Identify and check a signal group array for validity.
%   IsSarray                  - Identify and check an S-array for validity.
%
% Retrieval
%   GetParam                  - Return a VTool configuration parameter.
%   GetNames                  - Get names from a name layer or signal channel.
%   GetLayers                 - List of name layers in a dataset or signal group.
%   GetDefaultNames           - Get default signal names from a signal group or dataset.
%   GetNamesMatrix            - Get names matrix for a signal group or dataset.
%   GetTime                   - Extract the time vector from a dataset.
%   GetSignal                 - Extract a signal from a signal group or dataset.
%   GetSampleTime             - Get sample time from a dataset or a Time group.
%   GetDataLength             - Get data length(s) in a dataset, signal group, etc.
%   GetNumSignals             - Get number of signals in a signal group, dataset, etc.
%   GetSignalGroups           - Get signal groups and group names.
%   ListSourceTypes           - List the source types in "NameTables.xlsx".
%   DissolveGroup             - Convert a signal group to variables.
%   ReadMasterLookup          - Read MASTER lookup table.
%   ReadSourceTab             - Read a "source tab" from "NameTables.xlsx".
%
% Comparison
%   Compare                   - Compare two datasets or signal groups.
%   CompareDatasets           - Compare two datasets.
%   CompareSignalGroups       - Compare two signal groups.
%   CompareNames              - Compare names in two datasets or signal groups.
%   CompareDisplays           - Compare display info for two datasets or signal groups.
%
% Display and Plotting
%   Display                   - Display a dataset or a signal group.
%   DisplayDataset            - Display contents of a dataset.
%   DisplaySampleTime         - Display sample time statistics.
%   DisplaySignalGroup        - Display contents of a signal group.
%   PlotDataset               - Plot and analyze signals from one or more datasets.
%   PlotSignalsInDataset      - Plot dataset signals with user-definable grouping.
%   PlotSignalGroup           - Plot a signal group or signal group array.
%   PlotConcatenatedArrays    - Plot concatenated signal group arrays.
%   PlotBinnedSequences       - Plot raw sequences, segregated by bin.
%   FiguresToPPT              - Save current figures to PowerPoint.
%   FiguresToFile             - Save current figures to a .fig file.
%   FiguresToPNG              - Save current figures to .png files.
%   LinkAxes                  - Link axes after plotting.
%   UnlinkAxes                - Un-link axes after plotting.
%   PlotMeanStats             - Plot mean-value stats.
%   PlotLtStats               - Plot long-time (min-max-mean) stats.
%   PlotStStats               - Plot short-time stats.
%   PlotPsdStats              - Plot power-spectral-density stats.
%
% Statistical Analysis
%   ComputeStat               - Compute a statistic for a named signal in a signal group or array.
%   ComputeStat2              - Compute a statistic for a named signal in two signal groups or arrays.
%   ComputeDEL                - Compute DEL for a named signal in a signal group or array.
%   ComputeFunStatsByBin      - Compute generalized signal-group array statistics by bin.
%   ComputeLtStatsByBin       - Compute LT signal-group array statistics by bin.
%   ComputeStStatsByBin       - Compute ST signal-group array statistics by bin.
%   ComputeDelStatsByBin      - Compute DEL signal-group array statistics by bin.
%   ComputePsdByBin           - Compute PSD spectra by bin.
%   ComputeErrPsdByBin        - Compute Error-PSD spectra by bin.
%   ComputeRelPsdByBin        - Compute relative PSD spectra by bin.
%   ComputeFilterMask         - Compute a filter mask from a signal group array.
%   ComputeClassVector        - Compute classification vector for a signal group array.
%   ComputeStatsArray         - Compute comparison statistics from signal group arrays.
%   CombineStatsFiles         - Combine multiple "computed_stats" files into one.
%
% File I/O
%   formats                   - VTool file formats.
%   ExtractData               - Extract data from a file (PRIMARY USER INTERFACE FUNCTION).
%   ReadSarrayFile            - Read signal data from an S-array file.
%   ReadXlsFile               - Read signal data from a spreadsheet file.
%   MakeVtlFile               - Make a .vtl file from time-synchronized data.
%   MakeSarrayFile            - Make an S-array .mat file from signal data.
%   ConvertToSarray           - Convert files to S-array .mat files.
%   ConvertToVtl              - Convert files to VTool .vtl format.
%   WriteDataToCSV            - Write dataset signals to a CSV file.
%
% Batch Processing
%   RunBatchFunction          - Run a batch function on one or more data files.
%   FindFilesOfType           - Find files of a given type in a folder and its subfolders.
%   FindFilesOfPattern        - Find files matching a name pattern in a folder and subfolders.
%   FindResultsPathnames      - Find result files in a folder and its subfolders.
%   CollectSignalsFromFiles   - Collect signals from data files in a folder.
%   CollectDataFromFiles      - Collect datasets from data files in a folder.
%   CollectSignalsFromResults - Collect signals from result files in a folder.
%   CollectDataFromResults    - Collect datasets from result files in a folder.
%   ConcatSignalsFromFiles    - Concatenate signals from data files in a folder.
%   ConcatDataFromFiles       - Concatenate datasets from data files in a folder.
%   ConcatSignalsFromResults  - Concatenate signals from result files in a folder.
%   ConcatDataFromResults     - Concatenate datasets from result files in a folder.
%
% Utility Functions
%   Select                    - Select pathnames using a file browser.
%   MakeSarray                - Make an S-array from signal data.
%   DataToSarray              - Convert a dataset to S-array form.
%   DataToTimetable           - Convert a dataset to timetable form.
%   CollapseSarray            - Collapse an S-array into dataset form.
%   Layer2Source              - Source string corresponding to a name layer.
%   Source2Layer              - Name layer corresponding to a source string.
%   ReorderFields             - Re-order fields to standard order.
%   ComputePSD                - Compute PSD of a signal.
%   ComputeCoh                - Compute coherence and PSD spectra.
%   SpectSignals              - Compute power spectral density for a signal group.
%   CrossSpectSignals         - Cross power spectral density for signal groups.
%   CompareSignalToRef        - Compare two signals, given a delay.
%   MatchSignalToRef          - Match a signal to a reference signal.
%   DamageEquivLoad           - Damage equivalent load for a time series.
%   WeightedHistogram         - Weighted histogram calculation.
%   ActivateEvents            - Toggle event activation for Timeseries axes.
%
% For more information, see HELP.html or type "<a href="matlab:HELP vtool">HELP vtool</a>".
