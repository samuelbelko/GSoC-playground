# Some very adaptive policy, probing various acquistion functions,
# sticking with those that work well (e.g. like in dragonfly that implements
# a similar strategy for being robust wrt prior)
mutable struct Adaptive_plc
    # maintain state and settings regarding acquisition functions
end

function (ada_plc::Adaptive_plc)(dsm::Basic_GP_dsm)

end
