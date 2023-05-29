

"""
saves optimizers, logs & counts observations,
prints stats based on verbose levels, plots performance
"""
struct MetadataManager

end

# Implement:
function log_ask!(mm, xs) end
function log_tell!(mm, xs, ys) end
function log_eval!(mm, time) end
# pritty printing based on verbose levels
# get optimizers, stats, plots at any time (e.g. while using ask-tell interface)
