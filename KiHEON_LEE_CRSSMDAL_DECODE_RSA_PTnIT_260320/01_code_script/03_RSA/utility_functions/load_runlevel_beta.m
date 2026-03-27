%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function [X, labels, ok] = load_runlevel_beta(sub_path, runs, cond_labels, mask_fn, label_mode)
    rows = {};
    labels = {};

    for r = runs
        if strcmp(label_mode, 'map_to_1_6') && r > 6
            r_label = r - 6;
        else
            r_label = r;
        end

        for e = 1:numel(cond_labels)
            emo = cond_labels{e};
            beta_fn = fullfile(sub_path, sprintf('beta_r%02d_%s.nii', r, emo));

            if ~exist(beta_fn, 'file')
                continue;
            end

            try
                ds = cosmo_fmri_dataset(beta_fn, 'mask', mask_fn);
                rows{end + 1} = ds.samples; %#ok<AGROW>
                labels{end + 1} = sprintf('r%02d_%s', r_label, emo); %#ok<AGROW>
            catch
                continue;
            end
        end
    end

    if isempty(rows)
        X = [];
        ok = false;
        return;
    end

    X = cat(1, rows{:});
    ok = (numel(labels) == numel(runs) * numel(cond_labels));
end