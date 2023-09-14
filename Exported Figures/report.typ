= Learned Performance -- Default Setup

@Learned-Performance shows results which have been trained for a set amount of runs. 
Performance is accumulated distance over 100 seconds. #footnote[It might be better to report this as average distance over these 100 seconds.] The x-axis represents the performance of each car, so that the data-point at "car1" represents the accumulated distance between car1 and car0. Note that car0 is a random agent.

The learned performance of car1 is compiled into the model when training and evaluating car2 and so on.


It is interesting to note that performance drops with the number of cars added to the chain. This could be due to the real fenomenon of congestion forming even without obstacles. (https://www.youtube.com/watch?v=7wm-pZp_mi0)

= Comparison to non-specialized model

It is interesting to see whether training specific agents for each car in the fleet actually results in better performance, or if using the same policy for all cars gives a similar result. In fact it is better to train a specialized policy for each position in the fleet.

In @non-specialized-5k, @non-specialized-10k and @non-specialized-20k,  the blue lines represent the results from @Learned-Performance. The teal(?) line is the corresponding setup evaluated using only the strategy of car1. 

#grid(columns:(1fr, 1fr),

    [#figure(
        image("./Learned Performance.svg", width:100%),
        caption: "Learned Performance"
    ) <Learned-Performance>],
    [#figure(
        image("./Compared to non-specialized 5k.svg", width:100%),
        caption: "Compared to non-specialized 5k"
    ) <non-specialized-5k>],
    [#figure(
        image("./Compared to non-specialized 10k.svg", width:100%),
        caption: "Compared to non-specialized 10k"
    ) <non-specialized-10k>],
    [#figure(
        image("./Compared to non-specialized 20k.svg", width:100%),
        caption: "Compared to non-specialized 20k"
    ) <non-specialized-20k>]
)

= Centralized strategy

It would be interesting to see if a centralized strategy can help the cars to achieve a better coherent performance, compared to the default setup. Though the challenge is a much bigger state space has to be learned.

@centralized-controller shows the learning outcomes on a per-car basis for different fleet sizes. Every centralized controller was trained for 20000 runs.

It can be seen that when the fleet size is 2 (only car1 being controlled by the learner) this car has the same performance as is observed in previous figures. Already when two cars are under the learner's control (fleet size 3) it seems that the first car is performing slightly worse.

And then of course there is a dramatic shift when it has to manage three cars or more. 

There seems to be a slight trend of the backmost cars performing better in each case, but overall the performance is far worse than the non-centralized agents.

@centralized-controller-mean-performance shows instead just the mean performance of each centralized agents, taken over all the cars in its control. This illustrates perhaps better how much of a performance hike occurs before it levels out. I ask myself if 8000 isn't the performance of a random agent. Or maybe that was 12000.

#grid(columns:(1fr, 1fr),
    [#figure(
        image("./Centralized controller.svg", width:100%),
        caption: "Centralized controller"
    ) <centralized-controller>],
    [#figure(
        image("./Centralized controller mean performance.svg", width:60%),
        caption: "Centralized controller mean performance"
    ) <centralized-controller-mean-performance>],
)