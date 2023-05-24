

"""
saves optimizers, logs & counts observations,
prints stats based on verbose levels, plots performance
"""
struct MetadataManager

end

# Implement:
log_ask!(mm, xs)
log_tell!(mm, xs, ys)
log_eval!(mm, time)
# pritty printing based on verbose levels
# get optimizers, stats, plots at any time (e.g. while using ask-tell interface)
