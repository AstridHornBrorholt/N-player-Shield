= Cruise Control

All experiments were repeated 10 times and the mean is reported.

== Learned Performance -- Default Setup

@CC-Learned-Performance shows results which have been trained for a set amount of runs. 
Performance is accumulated distance over 100 seconds. #footnote[It might be better to report this as average distance over these 100 seconds.] The x-axis represents the performance of each car, so that the data-point at "car1" represents the accumulated distance between car1 and car0. Note that car0 is a random agent.

The learned performance of car1 is compiled into the model when training and evaluating car2 and so on.


It is interesting to note that performance drops with the number of cars added to the chain. This could be due to the real fenomenon of congestion forming even without obstacles. (https://www.youtube.com/watch?v=7wm-pZp_mi0)

== Comparison to non-specialized model

It is interesting to see whether training specific agents for each car in the fleet actually results in better performance, or if using the same policy for all cars gives a similar result. In fact it is better to train a specialized policy for each position in the fleet.

In  @non-specialized-20k,  the blue lines represent the results from @CC-Learned-Performance. The teal(?) line is the corresponding setup evaluated using only the strategy of car1. 

#grid(columns:(1fr, 1fr),

    [#figure(
        image("./CC/Learned Performance.svg", width:100%),
        caption: "Learned Performance"
    ) <CC-Learned-Performance>],
    [#figure(
        image("./CC/Compared to non-specialized 20k.svg", width:100%),
        caption: "Non-specialized 20k and (regular) specialized 20k"
    ) <non-specialized-20k>]
)

== Centralized Controller

It would be interesting to see if a Centralized Controller can help the cars to achieve a better coherent performance, compared to the default setup. Though the challenge is a much bigger state space has to be learned.

@centralized-controller shows the learning outcomes on a per-car basis for different fleet sizes. Every centralized controller was trained for 20000 runs.

It can be seen that when the fleet size is 2 (only car1 being controlled by the learner) this car has the same performance as is observed in previous figures. Already when two cars are under the learner's control (fleet size 3) it seems that the first car is performing slightly worse.

And then of course there is a dramatic shift when it has to manage three cars or more. 

There seems to be a slight trend of the backmost cars performing better in each case, but overall the performance is far worse than the non-centralized agents.

@centralized-controller-mean-performance shows instead just the mean performance of each centralized agents, taken over all the cars in its control. This illustrates perhaps better how much of a performance hike occurs before it levels out. I ask myself if 8000 isn't the performance of a random agent. Or maybe that was 12000.

#grid(columns:(1fr, 1fr),
    [#figure(
        image("./CC/Centralized controller.svg", width:100%),
        caption: "Centralized controller"
    ) <centralized-controller>],
    [#figure(
        image("./CC/Centralized controller mean performance.svg", width:60%),
        caption: "Centralized controller mean performance"
    ) <centralized-controller-mean-performance>],
)

#pagebreak()

= Chemical Production

The shield was able to avoid safety violations in all cases, defined as every tank in the system staying within certain bounds. @Layout shows the layout of the system used. Lines represent pipes that can pump material into tanks in the next layer. A numbered square indicates a production unit with an internal tank. A number without a border indicates a provider which can provide infinite material, but at a cost that varies according to periodic time. $D_1$ and $D_2$ indicate consumers which pull material out of units 9 and 10 at a periodically varying rate. 

All experiments were repeated 10 times and the mean is reported.


= Learned Performance - Default Setup

In the default setup, all production units are shielded at all times, to avoid having either inadequate supply or overflow. 
Units which have not been optimized yet pick which inflow pipes are enabled, according to a uniformly random distribution.
One productoin unit is trained at a time, to minimize overall cost of the system. When training has finished, the resulting policy is made part of the environment, and training of the next unit begins. 
Training happens sequentially according to the numbers on the production units (squares) of @Layout.

@CP-Learned-Performance shows the gradual improvement of the reward (negative cost) resulting from this training. 
Unsurprisingly, the reward is improved with each unit trained.
The baseline performance, where all production units pick actions randomly, is a reward of -2336. The average reward achieved after training each production unit for 20000 episodes is -1360.

#grid(columns:(1fr, 1fr),

    [#figure(
        image("./CP/Learned Performance.svg", width:100%),
        caption: "Learned Performance"
    ) <CP-Learned-Performance>],
    [#figure(
        image("./CP/Layout.png", height:170pt),
        caption: "Layout of the system"
    ) <Layout>]
)

Note that @CP-Learned-Performance cannot be compared to @CC-Learned-Performance even though the two look similar. In the chemical production example, the reward reported is that of the entire system. In the cruise control example, each agent has its own individual reward, which is what is shown.