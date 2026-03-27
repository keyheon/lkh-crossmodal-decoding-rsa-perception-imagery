%% PT & IT 'emotional_face' shared activation (conjunction-null, minimum-T)
% This script estimates a flexible-factorial second-level model for the PT and
% IT 'emotional_face' contrasts, defines task-specific positive t-contrasts,
% and computes a conjunction-null map.
%
% Steps:
%   1) flexible factorial design (Subject × Task [PT, IT])
%   2) classical model estimation
%   3) task-specific t-contrast creation
%   4) conjunction-null inference and filtered-map export
%
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================

%% Initialize SPM
clearvars;
clc;
close all;

spm('Defaults', 'fMRI');
spm_jobman('initcfg');

%% Paths and helper functions
script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir, 'utility_functions'));

%% Analysis settings
root_first = '~/analysis'; % where participant folders are located; modify if needed
outDir     = '~/analysis/group'; % modify if needed

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

subj_vec  = 101:120;   % P101-P120
pt_subdir = 'first_level_GLM_for_perception';
it_subdir = 'first_level_GLM_for_imagery';
pt_con    = 6;         % con_0006 = emotional_face
it_con    = 6;

%% Build and save the flexible-factorial design
matlabbatch = build_pt_it_ff_design_batch( ...
    outDir, root_first, subj_vec, pt_subdir, it_subdir, pt_con, it_con);

spm_jobman('run', matlabbatch);

%% Estimate the second-level model
matlabbatch_est = build_classical_estimation_batch(fullfile(outDir, 'SPM.mat'));
spm_jobman('run', matlabbatch_est);

%% Create task-specific positive t-contrasts
SP = load(fullfile(outDir, 'SPM.mat'));
SPM = SP.SPM;

[c_pt, c_it] = get_task_main_effect_contrasts(SPM);

contrast_names = {'PT_emotional_face>0', 'IT_emotional_face>0'};
contrast_vectors = {c_pt, c_it};

matlabbatch_con = build_named_tcontrast_batch( ...
    fullfile(outDir, 'SPM.mat'), contrast_names, contrast_vectors);

spm_jobman('run', matlabbatch_con);

%% Run conjunction-null inference and save the filtered map
Ic = find_contrast_indices_by_name( ...
    fullfile(outDir, 'SPM.mat'), {'PT_emotional_face>0', 'IT_emotional_face>0'});

run_conjunction_null_and_save( ...
    outDir, Ic, 0.05, 10, 'FDR', 'ConjNull_PT_IT_emotional_face_FDR05.nii');
