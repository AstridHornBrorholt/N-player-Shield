= First batch of results

@Learned-Performance are results which have been trained for a set amount of runs. 
Performance is accumulated distance over 100 seconds. The x-axis represents the performance of each car, so that the data-point at "car1" represents the accumulated distance between car1 and car0. Note that car0 is a random agent.

The learned performance of car1 is compiled into the model when training and evaluating car2 and so on.

#figure(
    image("./Learned Performance.svg"),
    caption: "Learned Performance"
) <Learned-Performance>

It is interesting to note that performance drops with the number of cars added to the chain. This could be due to the real fenomonon of congestion forming even without obstacles. (https://www.youtube.com/watch?v=7wm-pZp_mi0)

= Comparison to non-specialized model

It is interesting to see whether training specific agents for each car in the fleet actually results in better performance, or if using the same policy for all cars gives a similar result. In fact it is better to train a specialized policy for each position in the fleet.

In @non-specialized-5k, @non-specialized-10k and @non-specialized-20k,  the blue lines represent the results from @Learned-Performance. The teal(?) line is the corresponding setup evaluated using only the strategy of car1. 

#figure(
    image("./Compared to non-specialized 5k.svg"),
    caption: "Compared to non-specialized 5k"
) <non-specialized-5k>
#figure(
    image("./Compared to non-specialized 10k.svg"),
    caption: "Compared to non-specialized 10k"
) <non-specialized-10k>
#figure(
    image("./Compared to non-specialized 20k.svg"),
    caption: "Compared to non-specialized 20k"
) <non-specialized-20k>

= Centralized strategy

It would be interesting to see if a centralized strategy can help the cars to achieve a better coherent performance, compared to the default setup. 

This does not seem to be the case at least for the same amount of training time. Using just 1000 episodes, training a fleet of 3 cars with a centralized strategy for both car1 and car2 (car0 being random), the strategy learned a performance of *3724* for car1 and *4822* for car2. In comparison, the default training method achieved an accumulated distance of *2721* for car1, and *3028* for car2. See @Centralized-Strategy-1k.

#figure(
    image("./Centralized Strategy 1k.png"),
    caption: "UPPAAL Query result for Centralized Strategy 1k"
) <Centralized-Strategy-1k>

For 5000 training runs, this was *3093* and *3186* for cars 1 and 2, compared to *2722* and *2730* in the default setup. See @Centralized-Strategy-5k.

#figure(
    image("./Centralized Strategy 5k.png"),
    caption: "UPPAAL Query result for Centralized Strategy 5k"
) <Centralized-Strategy-5k>