%% Utility function
% ===================================================================
% Author of this script:
%   Ki Heon Lee
% Contact:
%   kiheon97@gmail.com
% ===================================================================
function cleanup_tempdir(tempRoot)
if exist(tempRoot, 'dir') == 7
    try
        rmdir(tempRoot, 's');
    catch
    end
end
end
