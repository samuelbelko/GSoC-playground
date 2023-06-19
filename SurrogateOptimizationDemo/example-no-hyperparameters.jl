function create_surrogate(xs, ys, hh::VoidHyperparameterHandler)
    dimension = 2
    # SecondOrderPolynomialSurrogate(xs, ys, zeros(dimension), ones(dimension))
    RandomForestSurrogate(xs, ys ,zeros(dimension),  ones(dimension), num_round = 2)
end

function create_hyperparameter_handler(dimension)
    VoidHyperparameterHandler(ones(dimension), false)
end
