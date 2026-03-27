function outpath = multi_reg_from_confounds(run_dir, varargin)
% Create an SPM multi_reg text file from fMRIPrep confounds.
%
% This function extracts the six rigid-body motion parameters and
% framewise displacement (FD) from the fMRIPrep confounds table and writes
% them to a tab-delimited text file for use as an SPM multi_reg regressor.
%
% Output columns:
%   1) trans_x
%   2) trans_y
%   3) trans_z
%   4) rot_x
%   5) rot_y
%   6) rot_z
%   7) framewise_displacement
%
% Notes:
%   - If the first FD entry is represented as 'n/a' or NaN, it is replaced
%     with 0.
%   - The output file is written to run_dir as:
%         rp_fd_<bold_basename>.txt
%
% Required input:
%   run_dir : directory containing the fMRIPrep confounds TSV and the
%             preprocessed BOLD file for a single run.
%
% Optional name-value arguments:
%   'demean'      : logical, default false
%                   If true, subtract the column-wise mean from all output
%                   regressors.
%   'check_nvols' : logical, default true
%                   If true, compare the number of confound rows with the
%                   number of BOLD volumes and apply the original off-by-one
%                   handling when needed.
%
% Returns:
%   outpath : full path to the written multi_reg text file.
%
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================

%% Parse inputs
p = inputParser;
addParameter(p, 'demean', false, @islogical);
addParameter(p, 'check_nvols', true, @islogical);
parse(p, varargin{:});
opt = p.Results;

%% Locate the confounds TSV file
d = dir(fullfile(run_dir, '*desc-confounds_timeseries.tsv'));
assert(~isempty(d), 'confounds TSV not found in %s', run_dir);
tsv = fullfile(run_dir, d(1).name);

%% Read confounds and convert common missing-value strings to NaN
opts = detectImportOptions(tsv, 'FileType', 'text', 'Delimiter', '\t');
opts = setvaropts(opts, opts.VariableNames, 'TreatAsMissing', {'n/a', 'NA', 'NaN'});
T = readtable(tsv, opts);

%% Extract motion parameters and framewise displacement
need6 = {'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z'};
missing = setdiff(need6, T.Properties.VariableNames);
assert(isempty(missing), 'Missing columns in %s: %s', tsv, strjoin(missing, ', '));

X6 = table2array(T(:, need6));

if ismember('framewise_displacement', T.Properties.VariableNames)
    FD = T.framewise_displacement;
    if iscell(FD)
        FD = str2double(FD);
    end
    FD(isnan(FD)) = 0;
else
    FD = zeros(height(T), 1);
end

X = [X6, FD];

%% Optional column-wise de-meaning
if opt.demean
    mu = mean(X, 1, 'omitnan');
    X = X - mu;
    X(isnan(X)) = 0;
end

%% Optional volume-count check against the BOLD file
bold = '';
pat = { ...
    '*desc-preproc_bold.nii', ...
    '*desc-preproc_bold.nii.gz', ...
    'w3rf*.nii' ...
};

for k = 1:numel(pat)
    dd = dir(fullfile(run_dir, pat{k}));
    if ~isempty(dd)
        bold = fullfile(run_dir, dd(1).name);
        break;
    end
end

if opt.check_nvols && ~isempty(bold)
    if endsWith(bold, '.gz')
        try
            gunzip(bold);
            bold = erase(bold, '.gz');
        catch
            warning('gunzip failed for %s (SPM may still read gz)', bold);
        end
    end

    try
        V = spm_vol(bold);
        nvol = numel(V);
        nrow = size(X, 1);

        if nrow ~= nvol
            warning('Row mismatch in %s: confounds=%d, volumes=%d', run_dir, nrow, nvol);

            % Preserve the original off-by-one handling.
            if nrow == nvol - 1
                X = [zeros(1, size(X, 2)); X];
            elseif nrow == nvol + 1
                X = X(1:nvol, :);
            end
        end
    catch ME
        warning('Could not read NIfTI for volume check: %s', ME.message);
    end
end

%% Write the output file
if isempty(bold)
    base = 'confounds';
else
    [~, base, ~] = fileparts(bold);
end

outpath = fullfile(run_dir, sprintf('rp_fd_%s.txt', base));
writematrix(X, outpath, 'Delimiter', '\t');
fprintf('[OK] %s (rows=%d, cols=%d)\n', outpath, size(X, 1), size(X, 2));
end
