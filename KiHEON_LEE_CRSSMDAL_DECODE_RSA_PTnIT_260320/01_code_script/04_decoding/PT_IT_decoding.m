% ROI-based bidirectional cross-task decoding between PT and IT using TDT and SPM.
% This script computes ROI-wise cross-task decoding accuracy in two directions
% and reports the averaged pairwise-minus-chance accuracy across directions.
%
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
%
% Analysis settings:
%   - classifier: linear SVM (LIBSVM)
%   - outer evaluation metric: accuracy_pairwise_minus_chance
%   - inner parameter selection: leave-one-run-out CV over C values
%   - scaling: z-scoring estimated on training data and applied to test data
%
% Outer decoding directions:
%   1) PT (12 runs) -> IT (6 runs)
%   2) IT (6 runs) -> PT (12 runs)
%
% Final output:
%   ROI_results_pairwise.csv
%
% First-level input files:
%   beta_r##_<emotion>.nii
%   where <emotion> is one of: happy, angry, sad, neutral.
% ===================================================================
function PT_IT_decoding(subj, roi_spec)

%% Inputs
if nargin < 2
    roi_spec = [];
end

labelnames = {'happy', 'angry', 'sad', 'neutral'};

%% Paths and toolboxes
root = pwd();
script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir, 'utility_functions'));

ptDir = fullfile(root, subj, 'first_level_GLM_for_perception');
itDir = fullfile(root, subj, 'first_level_GLM_for_imagery');

assert(exist(ptDir, 'dir') == 7, 'PT directory not found: %s', ptDir);
assert(exist(itDir, 'dir') == 7, 'IT directory not found: %s', itDir);

resRoot = fullfile(ptDir, 'pairwise_accuracy_twofold_libsvm');
if ~exist(resRoot, 'dir')
    mkdir(resRoot);
end

% Temporary directories are used for ROI reslicing and internal TDT outputs.
tempRoot = fullfile(tempdir, sprintf('PT_IT_decoding_%s_%s', subj, datestr(now, 'yyyymmddTHHMMSSFFF')));
roiOutDir = fullfile(tempRoot, 'rois_resliced');
mkdir(roiOutDir);
cleanupObj = onCleanup(@() cleanup_tempdir(tempRoot)); %#ok<NASGU>

addpath(genpath('~/library/matlab/decoding_toolbox')); % TDT
addpath('~/library/matlab/spm12'); % SPM12
addpath('~/library/matlab/decoding_toolbox/decoding_software/libsvm3.17/matlab'); % libsvm

try
    spm('defaults', 'fmri');
catch
end

%% Locate run-level beta images
PT_all = cellstr(spm_select('FPList', ptDir, '^beta_r\d+_[a-z]+\.nii$')).';
IT_all = cellstr(spm_select('FPList', itDir, '^beta_r\d+_[a-z]+\.nii$')).';
assert(~isempty(PT_all) && ~isempty(IT_all), 'No PT or IT beta images were found.');

[emoPT, runPT] = parse_tokens_from_betas(PT_all);
[emoIT, runIT] = parse_tokens_from_betas(IT_all);

files_pt_all = PT_all;
emo_pt_all = emoPT;
run_pt_all = runPT;

keepIT = runIT >= 1 & runIT <= 6;
files_it = IT_all(keepIT);
emo_it = emoIT(keepIT);
run_it = runIT(keepIT);

check_class_balance('PT (all runs)', emo_pt_all, labelnames);
check_class_balance('IT', emo_it, labelnames);

% =============================================================================
%% Resolve and prepare ROI masks
roiList_raw = resolve_rois(roi_spec, root);
assert(~isempty(roiList_raw), 'No ROI masks were resolved.');

refImg = files_pt_all{1};
roiList = reslice_rois_force_to_ref_and_return_rpaths(roiList_raw, refImg, roiOutDir);

min_vox = 5;
roiList = roiList(arrayfun(@(i) count_mask_voxels(roiList{i}) >= min_vox, 1:numel(roiList)));
assert(~isempty(roiList), 'All ROI masks were below the minimum voxel threshold.');

[roiList, dropped] = verify_roi_grid_and_autofix(roiList, refImg, roiOutDir, root);
if ~isempty(dropped)
    warning('Dropped %d ROI mask(s) that failed grid verification.', numel(dropped));
end
assert(~isempty(roiList), 'All ROI masks failed grid verification.');

roiList = dedup_by_basename_prefer_r_in_dir(roiList, roiOutDir);

roiList_preQC = roiList;
try
    roiList = filter_rois_by_overlap(roiList, files_pt_all, files_it, 1);
catch ME
    warning('ROI overlap filtering failed (%s). Reverting to the pre-filter ROI list.', ME.message);
    roiList = roiList_preQC;
end
if isempty(roiList)
    warning('All ROI masks were removed by overlap filtering. Reverting to the pre-filter ROI list.');
    roiList = roiList_preQC;
end

[~, roiNames, roiExt] = cellfun(@fileparts, roiList, 'UniformOutput', false);
roiBaseNames = strcat(roiNames, roiExt);
% =============================================================================

%% Run bidirectional cross-modal decoding
pt2it_dir = fullfile(tempRoot, 'res_PT2IT');
it2pt_dir = fullfile(tempRoot, 'res_IT2PT');
mkdir(pt2it_dir);
mkdir(it2pt_dir);

pt2it_acc = run_one_direction_ncv(files_pt_all, emo_pt_all, run_pt_all, ...
                                  files_it,     emo_it,     run_it, ...
                                  roiList, pt2it_dir, labelnames);

it2pt_acc = run_one_direction_ncv(files_it,     emo_it,     run_it, ...
                                  files_pt_all, emo_pt_all, run_pt_all, ...
                                  roiList, it2pt_dir, labelnames);

overall_acc = mean([pt2it_acc, it2pt_acc], 2, 'omitnan');

%% Export the final ROI-wise decoding table
T = table(roiBaseNames(:), overall_acc(:), ...
    'VariableNames', {'ROI', 'OverallAccuracy_pairwise_minus_chance_percent'});

out_csv = fullfile(resRoot, 'ROI_results_pairwise.csv');
writetable(T, out_csv);

fprintf('[%s] Saved decoding results: %s\n', datestr(now, 'yy-mm-dd HH:MM'), out_csv);
end

% =============================================================================
%% Inner function
function acc_vec = run_one_direction_ncv(fTrain, emoTrain, runTrain, fTest, emoTest, runTest, ...
                                         roiList, resultsDir, labelnames)
labTr = map_labels(emoTrain, labelnames);
labTe = map_labels(emoTest, labelnames);

cfg = decoding_defaults;
cfg.software = 'spm12';
cfg.analysis = 'ROI';
cfg.decoding.method = 'classification';

cfg.scale.method = 'z';
cfg.scale.estimation = 'across';

cfg.decoding.software = 'libsvm';
cfg.decoding.train.classification.model_parameters = '-s 0 -t 0 -c 1 -q';
cfg.decoding.test.classification.model_parameters = '-q';

cfg.feature_selection.method = 'none';

cfg.results.dir = resultsDir;
cfg.results.overwrite = 1;
cfg.results.write = 0;
cfg.results.output = {'accuracy_pairwise_minus_chance'};

cfg.files.name = [fTrain(:); fTest(:)];
cfg.files.label = [labTr(:); labTe(:)];
cfg.files.chunk = [runTrain(:); 100 + runTest(:)];
cfg.files.set = [ones(numel(fTrain), 1); 2 * ones(numel(fTest), 1)];
cfg.files.mask = roiList;

train_mask = cfg.files.set == 1;
test_mask = cfg.files.set == 2;
cfg.design.train = train_mask;
cfg.design.test = test_mask;
cfg.nfolds = 1;
cfg.design.label = cfg.files.label;
cfg.design.set = 1;
cfg.design.unbalanced_data = 'ok';
cfg.plot_design = 0;

cfg.parameter_selection.method = 'grid';
cfg.parameter_selection.parameters = {'-c'};
cfg.parameter_selection.parameter_range = {logspace(-6, 3, 10)};
cfg.parameter_selection.design.function.name = 'make_design_cv';
cfg.parameter_selection.results.output = {'accuracy_minus_chance'};
cfg.parameter_selection.decoding = cfg.decoding;

results = decoding(cfg);

acc_vec = nan(numel(roiList), 1);
if isfield(results, 'accuracy_pairwise_minus_chance') && ...
        isfield(results.accuracy_pairwise_minus_chance, 'output')
    out_acc = results.accuracy_pairwise_minus_chance.output(:);
    acc_vec(1:min(end, numel(out_acc))) = out_acc(1:min(end, numel(out_acc)));
end
end