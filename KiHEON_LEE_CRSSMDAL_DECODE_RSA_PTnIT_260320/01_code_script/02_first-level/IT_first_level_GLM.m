%% IT first-level GLM specification, estimation, beta export, and contrast generation
% This script specifies and estimates the imagery-task first-level GLM,
% exports run-level beta images for MVPA, and creates the first-level
% contrast used in the univariate analysis.
%
% ===================================================================
% Author of this script:
%   Ki Heon Lee, Heungsik Yoon
% Contact:
%   kiheon97@gmail.com
% ===================================================================
%
% Input BOLD series:
%   By default, the script selects the unsmoothed preprocessed BOLD file
%   (appropriate for MVPA). The same model can be estimated on a smoothed
%   BOLD series for univariate analysis by updating the input search
%   location and filename pattern to match the desired image in the
%   corresponding 'smooth6mm' subdirectory. If the selected input basename
%   changes, update the nuisance-regressor filename rule accordingly.
%
% By default, temporal high-pass filtering (128 s) is handled within SPM
% during the first-level model specification.

%% Initialize SPM
clearvars;
clc;
close all;

spm('Defaults', 'fMRI');
spm_jobman('initcfg');

%% Analysis settings
script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir, 'utility_functions'));

data_path = pwd(); % Each participant folder (e.g., P101)
analysis_path = 'first_level_GLM_for_imagery';
outdir = fullfile(data_path, analysis_path);

if ~exist(outdir, 'dir')
    mkdir(outdir);
    fprintf('Created analysis directory: %s\n', analysis_path);
else
    fprintf('Using existing analysis directory: %s\n', analysis_path);
end

n_runs = 6;
run_dirs = arrayfun(@(x) sprintf('02_IT_RUN%02d', x), 1:n_runs, 'UniformOutput', false);
conditions = {'happy', 'angry', 'sad', 'neutral'};

% Default: unsmoothed preprocessed BOLD input used for MVPA.
% Replace this with the corresponding smoothed filename pattern when
% estimating the same model on smoothed data for univariate analysis.
% If the selected BOLD basename changes, update the multi_reg filename rule
% below so that it points to the correct nuisance-regressor text file.
bold_pattern = '^sub-.*_desc-preproc_bold\.nii$';

%% Load firm-time table used for rating durations
firm_file = fullfile(data_path, 'onset', 'visit3_data_firmtime.csv');
firm_ms = importdata(firm_file);
firm_ms(firm_ms == -1000) = 5000;
firm_sec_all = firm_ms / 1000;

%% Load event onsets and valid trial assignments
onset_all = struct();
run_all = struct();

for e = 1:numel(conditions)
    onset_all.(conditions{e}) = [];
    run_all.(conditions{e}) = [];
end

for ni = 1:n_runs
    run_num = ni;

    for e = 1:numel(conditions)
        cond_name = conditions{e};
        onset_file = fullfile(data_path, 'onset', sprintf('visit3_output_onset_face_%s.csv', cond_name));
        block_file = fullfile(data_path, 'onset', sprintf('visit3_output_onset_face_%s_block.csv', cond_name));
        intensity_file = fullfile(data_path, 'onset', sprintf('visit3_output_onset_face_%s_intensity.csv', cond_name));

        temp_onset = importdata(onset_file);
        temp_block = importdata(block_file);
        temp_intensity = importdata(intensity_file);

        % Retain trials assigned to the current run with non-missing ratings.
        idx = (temp_block == run_num) & ~isnan(temp_intensity);

        onset_all.(cond_name) = [onset_all.(cond_name); temp_onset(idx)]; %#ok<AGROW>
        run_all.(cond_name) = [run_all.(cond_name); repmat(ni, sum(idx), 1)]; %#ok<AGROW>
    end
end

%% Assemble run-wise condition assignments
final_assign = struct();
for e = 1:numel(conditions)
    cond_name = conditions{e};
    final_assign.(cond_name).onsets = onset_all.(cond_name);
    final_assign.(cond_name).runs = run_all.(cond_name);
end

%% Specify and estimate the first-level model
clear jobs
jobs{1}.stats{1}.fmri_spec.dir = {outdir};
jobs{1}.stats{1}.fmri_spec.timing.units = 'secs';
jobs{1}.stats{1}.fmri_spec.timing.RT = 2;

rating_ptr = 1;

for ni = 1:n_runs
    run_path = fullfile(data_path, run_dirs{ni});

    % Select the 4D preprocessed BOLD series for this run.
    f4d = spm_select('FPList', run_path, bold_pattern);
    assert(~isempty(f4d), '4D BOLD not found in %s', run_path);
    f4d = deblank(f4d(1, :));
    [~, base] = fileparts(f4d);

    % Expand the selected 4D file into a list of 3D frames.
    pat_exact = ['^' regexptranslate('escape', [base '.nii']) '$'];
    run_scans = spm_select('ExtFPList', run_path, pat_exact, Inf);
    assert(~isempty(run_scans), 'ExtFPList failed for %s', base);

    % Use the motion/FD nuisance regressor file corresponding to the same run.
    run_mot = fullfile(run_path, ['rp_fd_' base '.txt']);
    assert(exist(run_mot, 'file') == 2, 'multi_reg not found: %s', run_mot);

    jobs{1}.stats{1}.fmri_spec.sess(ni).scans = cellstr(run_scans);
    jobs{1}.stats{1}.fmri_spec.sess(ni).multi_reg = {run_mot};

    cond_counter = 0;
    for c = 1:numel(conditions)
        cond_name = conditions{c};
        idx_run = (final_assign.(cond_name).runs == ni);
        onsets_this = final_assign.(cond_name).onsets(idx_run);

        if isempty(onsets_this)
            continue;
        end

        cond_counter = cond_counter + 1;
        jobs{1}.stats{1}.fmri_spec.sess(ni).cond(cond_counter).name = cond_name;
        jobs{1}.stats{1}.fmri_spec.sess(ni).cond(cond_counter).onset = onsets_this(:);
        jobs{1}.stats{1}.fmri_spec.sess(ni).cond(cond_counter).duration = 0;
    end

    % Rating period regressor: onset is 6.5 s after cue onset.
    rating_onsets = [];
    for emo = {'happy', 'angry', 'sad', 'neutral'}
        idx = final_assign.(emo{1}).runs == ni;
        rating_onsets = [rating_onsets; final_assign.(emo{1}).onsets(idx)]; %#ok<AGROW>
    end

    if ~isempty(rating_onsets)
        [rating_onsets, ~] = sort(rating_onsets);
        n_trial = numel(rating_onsets);
        rating_durs = firm_sec_all(rating_ptr : rating_ptr + n_trial - 1);
        rating_ptr = rating_ptr + n_trial;

        cond_counter = cond_counter + 1;
        jobs{1}.stats{1}.fmri_spec.sess(ni).cond(cond_counter).name = 'rating';
        jobs{1}.stats{1}.fmri_spec.sess(ni).cond(cond_counter).onset = rating_onsets + 6.5;
        jobs{1}.stats{1}.fmri_spec.sess(ni).cond(cond_counter).duration = rating_durs(:);
    end
end

jobs{1}.stats{2}.fmri_est.spmmat = {fullfile(outdir, 'SPM.mat')};
spm_jobman('run', jobs);
disp('=== Model specification and estimation completed ===');

%% Export run-level beta images for MVPA
SP = load(fullfile(outdir, 'SPM.mat'));
SPM = SP.SPM;
all_reg_names = SPM.xX.name;

for c = 1:numel(conditions)
    cond_name = conditions{c};

    % Export first-HRF beta images for each run.
    beta_indices = find(contains(all_reg_names, cond_name) & contains(all_reg_names, '*bf(1)'));
    if isempty(beta_indices)
        fprintf('Warning: no beta images found for %s\n', cond_name);
        continue;
    end

    for bi = 1:numel(beta_indices)
        idx = beta_indices(bi);
        src_path = fullfile(SPM.swd, SPM.Vbeta(idx).fname);
        Vb = spm_vol(src_path);
        vol = spm_read_vols(Vb);

        regname = all_reg_names{idx};
        tok = regexp(regname, 'Sn\((\d+)\)', 'tokens');
        if ~isempty(tok)
            run_id = str2double(tok{1}{1});
        else
            run_id = bi;
        end

        Vout = Vb;
        Vout.fname = fullfile(outdir, sprintf('beta_r%02d_%s.nii', run_id, cond_name));
        spm_write_vol(Vout, vol);
        fprintf('Saved run-level beta: %s (run %02d, %s)\n', Vout.fname, run_id, cond_name);
    end
end

disp('=== Run-level beta export completed ===');

%% Create the first-level contrast for the univariate analysis
clear jobs
SP = load(fullfile(outdir, 'SPM.mat'));
SPM = SP.SPM;

jobs{1}.stats{1}.con.spmmat = {fullfile(outdir, 'SPM.mat')};
jobs{1}.stats{1}.con.consess{1}.tcon.name = 'emotional_face';
jobs{1}.stats{1}.con.consess{1}.tcon.convec = make_contrast_by_names(SPM, {'happy', 'angry', 'sad'}, {});
jobs{1}.stats{1}.con.consess{1}.tcon.sessrep = 'none';

spm_jobman('run', jobs);
disp('=== Contrast creation completed ===');