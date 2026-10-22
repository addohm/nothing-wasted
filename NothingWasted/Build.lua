-- Nothing Wasted: the build stamp. tools\install_forever.cmd overwrites this file in the installed copy
-- with the git commit, so /nw help shows which build is running. Releases leave it empty.
local _, ns = ...
ns.build = nil
