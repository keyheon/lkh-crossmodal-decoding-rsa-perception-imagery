%% ROI-based RSA between Avg-PT and IT using run-level beta images
% This script computes ROI-wise representational similarity between the
% element-wise averaged perception-task RSM (Avg-PT) and the imagery-task RSM
% (IT) using run-level beta images.
%
% ===================================================================
% Author of this script:
%   Ki Heon Lee, Heungsik Yoon
% Contact:
%   kiheon97@gmail.com
% ===================================================================
%
% For each ROI and participant, the script:
%   1) loads run-level beta images for PT session 1 (runs 1-6), PT session 2
%      (runs 7-12), and IT (runs 1-6);
%   2) reorders patterns to a standard 24-item run-major order;
%   3) retains voxels that are finite across PT session 1, PT session 2,
%      and IT, and removes constant voxels across the concatenated data;
%   4) computes 24 x 24 RSMs using Pearson correlation across patterns;
%   5) computes the Avg-PT RSM by Fisher z-transforming and averaging the
%      PT session 1 and PT session 2 RSMs cell-wise, and the resulting
%      averaged values are inverse transformed;
%   6) computes the Spearman correlation between the vectorized upper
%      triangles of the Avg-PT and IT RSMs.
%
% Expected first-level input files:
%   beta_r##_<emotion>.nii
% where <emotion> is one of: happy, angry, sad, neutral.
%
% Output:
%   SubjectRS_runbeta_24x24_<yymmdd>.csv
% ===================================================================

clearvars;
clc;

%% Paths and participants
script_dir = fileparts(mfilename('fullpath'));
pwd_path = script_dir;
base_path = fullfile(script_dir, '..', '..');

addpath(fullfile(script_dir, 'utility_functions'));
addpath(genpath('/library/MATLAB/CoSMoMVPA')); % CoSMoMVPA

subjects = {'P101','P102','P103','P104','P105','P106','P107','P108','P109','P110', ...
            'P111','P112','P113','P114','P115','P116','P117','P118','P119','P120'};
n_subjects = numel(subjects);

% First-level analysis directories containing the beta images.
pt_analysis_path = 'first_level_GLM_for_perception';
it_analysis_path = 'first_level_GLM_for_imagery';

%% ROI definitions
roi_path = fullfile(base_path, 'ROIs');
roi_files = dir(fullfile(roi_path, 'rstr*.nii'));
mask_list = fullfile({roi_files.folder}, {roi_files.name});
n_masks = numel(mask_list);

assert(n_masks > 0, 'No ROI masks were found in %s', roi_path);

%% Constants
cond_labels = {'happy', 'angry', 'sad', 'neutral'};
runs_per_session = 6;
n_conditions = numel(cond_labels);
n_items = runs_per_session * n_conditions;
standard_item_labels = make_item_labels(runs_per_session, cond_labels);

%% Result matrix: Avg-PT vs IT Spearman correlation
RS_AvgPT_IT_S = nan(n_masks, n_subjects);

% =============================================================================
%% ROI loop
for m = 1:n_masks
    mask_fn = mask_list{m};
    [~, roi_name, ~] = fileparts(mask_fn);
    fprintf('\n== ROI %d/%d: %s ==\n', m, n_masks, roi_name);

    % Skipping very large masks.
    mask_data = cosmo_fmri_dataset(mask_fn);
    if sum(mask_data.samples(:) > 0) > 10000
        fprintf('Skipping large mask (>10,000 voxels): %s\n', roi_name);
        continue;
    end

    %% Participant loop
    for s = 1:n_subjects
        sub = subjects{s};
        fprintf('--- Subject %s ---\n', sub);

        pt_path = fullfile(base_path, sub, pt_analysis_path);
        it_path = fullfile(base_path, sub, it_analysis_path);

        % Load run-level beta images.
        [X_pt1, labels_pt1, ok_pt1] = load_runlevel_beta(pt_path, 1:6, cond_labels, mask_fn, 'map_to_1_6');
        [X_pt2, labels_pt2, ok_pt2] = load_runlevel_beta(pt_path, 7:12, cond_labels, mask_fn, 'map_to_1_6');
        [X_it,  labels_it,  ok_it ] = load_runlevel_beta(it_path, 1:6, cond_labels, mask_fn, 'map_to_1_6');

        if ~(ok_pt1 && ok_pt2 && ok_it)
            fprintf('   -> Incomplete beta set. Skipping subject for this ROI.\n');
            continue;
        end

        % Reorder to the standard 24-item run-major label order.
        [X_pt1, ok1] = reorder_to_standard(X_pt1, labels_pt1, standard_item_labels);
        [X_pt2, ok2] = reorder_to_standard(X_pt2, labels_pt2, standard_item_labels);
        [X_it,  ok3] = reorder_to_standard(X_it,  labels_it,  standard_item_labels);

        if ~(ok1 && ok2 && ok3)
            fprintf('   -> Label alignment failed. Skipping subject for this ROI.\n');
            continue;
        end

        % Compute PT session 1, PT session 2, and IT RSMs using the analysis
        % policy that was used in the manuscript.
        [rsm_pt1, rsm_pt2, rsm_it] = make_rsms_default(X_pt1, X_pt2, X_it);

        % Compute the Avg-PT RSM using Fisher z-transformed cell-wise averaging.
        rsm_avg = average_pt_rsms(rsm_pt1, rsm_pt2);

        % Compute the final ROI-wise RSA metric: Spearman correlation between
        % the Avg-PT and IT upper-triangle vectors.
        RS_AvgPT_IT_S(m, s) = spearman_corr_vectors(vec_ut(rsm_avg), vec_ut(rsm_it));
    end
end
% =============================================================================

%% Export the subject-level RSA table
roi_column = cell(n_masks * n_subjects, 1);
subject_column = cell(n_masks * n_subjects, 1);
rs_column = nan(n_masks * n_subjects, 1);

row_idx = 1;
for m = 1:n_masks
    [~, roi_name, ~] = fileparts(mask_list{m});
    for s = 1:n_subjects
        roi_column{row_idx} = roi_name;
        subject_column{row_idx} = subjects{s};
        rs_column(row_idx) = RS_AvgPT_IT_S(m, s);
        row_idx = row_idx + 1;
    end
end

T_SubjectRS = table(roi_column, subject_column, rs_column, ...
    'VariableNames', {'ROI', 'Subject', 'RS_AvgPT_IT_S'});

out_csv = fullfile(pwd_path, sprintf('SubjectRS_runbeta_24x24_%s.csv', datestr(now, 'yymmdd')));
writetable(T_SubjectRS, out_csv);

fprintf('\nSaved subject-level RSA results: %s\n', out_csv);
disp('=== ROI-based Avg-PT vs IT RSA completed ===');
