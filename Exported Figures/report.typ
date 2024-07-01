#import calc : round

= Cruise Control

All experiments were repeated 10 times and the mean is reported.

== Shield Synthesis Times

Making the decentralized shield took #round(0.44 + 4.7 + 1.6) seconds. This is with a max safe distance of 200m. If it is decreased to 50m, the time becomes #round(0.1 + 1.3 + 0.28). Looks like there's a lot of overhead computing reachability. 

The decentralized shield with co-ordinated actions took #round(0.8 + 16.9 + 14.2) to compute.  And then #round(0.2 + 3.9 + 2.2) to compute for 50m safety distance. This sort of tracks with the fact that the grid is $3 times$ as large.

The centralized shield by comparison, takes #round(30 + 3566 + 1097) seconds for 3 cars. At 4 cars, it runs out of memory. Reminder to myself to try and support `StaticArrays` for this stuff.

I tried to make a plot of this in @CC-Synthesis-Times. I had to add an axis break because the difference is so enormous.

== Decentralized Shield & Decentralized, Cascading Learning

Episodes in all experiments are 100 seconds. Reward is reported as the negative total average distance to the car in front. That is, if during those 100 seconds all 9 controlled cars had an average distance of 40m to the car in front of it, the total reward would be -360.

In @CC-Learned-Performance, the green line shows the outcomes of cascading (decentralized) training with different learning budgets. That is, the first controlled car was trained to follow the random car in front of the fleet. Then the learned policy is made part of the environment, and the next car in the row is trained afterwards. Since 9 cars are trained separately, they are each given $1/9$th of the total training budget.

== More Cars

I actually have results for 30 cars trained for 2500 episodes each. This took 48 hors to complete. There is also an optimization waiting in a new release of UPPAAL which should take it beyond that.

== Random baseline

It is interesting to know what the baseline performance is, to see if learning even occurs. Each agent samples a safe action according to the shield, according to a uniformly random distribution. The avergae performance#footnote[Measured as $sum -D[i]/100$] for a fleet of 10 cars was -1204.
However, it was safe.

== Decentralized Shield & Decentralized Learning

It is interesting to see whether training specific agents for each car in the fleet actually results in better performance, or if using the same policy for all cars gives a similar result. In fact it is better to train a specialized policy for each position in the fleet.

In  @CC-Learned-Performance,  the blue lines represent the results from @CC-Learned-Performance. The teal(?) line is the corresponding setup evaluated using only the strategy of car1. 

#grid(columns:(1fr, 1fr),

    [#figure(
        image("./CC/CC.svg", width:100%),
        caption: "Learned Performance"
    ) <CC-Learned-Performance>],
    [#figure(
        image("./CC/Synthesis times - edited.svg", width:100%),
        caption: "Shield synthesis times"
    ) <CC-Synthesis-Times>],
)

== Decentralized Shield & Centralized Learning

It would be interesting to see if a centralized learning approach can help the cars to achieve a better coherent performance, compared to the default setup. Though the challenge is a much bigger state space has to be learned.

The purple line in @CC-Learned-Performance shows the learning outcomes for different training budgets.

#grid(columns:(1fr, 1fr),
    [#figure(
    image("./CC/Centralized shield.svg", width:70%),
    caption: "Respectively, centralized shield where actions are co-ordinated, decentralized shield, and decentralized shield where actions are co-ordinated."
) <centralized-shield>],
) 

== Centralized Shield & Centralized Learning

I was not actually able to synthesize a centralized shield for even two cars. This seems strange to me since the worst-case memory consumption is much less than the RAM I have available. Must be some significant inefficiency in a data strcutre of mine. 

But what I was able to do, was create a shield for two cars whose max distance was only 50m. Synthesizing this shield took #round((30 + 3566 + 1097)/60) minutes. In comparison, synthesizing the distributed shield takes 3 seconds.

It did not leave much room for learning a more optimal strategy, but it was working. So to match, I made a decentralized sheild with the same max distance. The comparison of training outcomes for the two cars are shown in @centralized-shield.

The front car has similar performance for both configuratoins, but the second car performs much better in the centralized shielding setup. I speculate this is because centralized shielding makes the additional assumption, that cars communicate their actions between each other, allowing  them to match speed perfectly. 

This assumption is not present in the default decentralized configuration, but I'll try to include it, to see if it is the centralized shield, or the additional information, that makes the difference.



== Shield Transfer

Transferring a shield from one agent to the other doesn't have to be as simple as "renaming the variables." In this experiment, we showed how a safety strategy can be transferred to an agent with completely different mechanics (under certain circumstances). 

A shield of 10 cars all acting randomly was created with the default mechanics: 

`(t_act = 1, distance_min = 0, distance_max = 200, acceleration = 2, v_min = -10, v_max = 20)`

These cars were observed to be safe for 1000 traces. Then the mechanics were altered: 

`(t_act = 0.8, distance_min = 10.0, distance_max = 90.0, acceleration = 1.0, v_ego_min = 0.0, v_ego_max = 12.0, v_front_min = 0.0, v_front_max = 12.0)`

And a projection was worked out: $p vec(v_1, v_2, d) =  vec((v_1 + 10)*0.4, (v_2 + 10)*0.4, (d + 25)*0.4)$
Applying the projection, the cars were safe under the new mechanics for another 1000 traces.

#let act = "act"

TODO: Probably shouldn't alter $t_act$ since this adds cofusion without really proving anything else


= Chemical Production

Safety is defined as the volume contained in each tank staying between 2L and 50L. The shield was able to avoid safety violations in all cases. @Layout shows the layout of the system used. Lines represent pipes that can pump material into tanks in the next layer. A numbered square indicates a production unit with an internal tank. A number without a border indicates a provider which can provide infinite material, but at a cost that varies according to periodic time. $D_1$ and $D_2$ indicate consumers which pull material out of units 9 and 10 at a periodically varying rate. 

All experiments were repeated 10 times and the mean outcome is reported.


== Decentralized Shielding & Cascading Learning

In the default setup, all production units are shielded at all times, to avoid having either inadequate supply or overflow. 
Units which have not been optimized yet pick which inflow pipes are enabled, according to a uniformly random distribution.
One productoin unit is trained at a time, with a set number of episodes. The reward signal for each unit is $-1 times "cost"$. Recall that "cost" is the price of taking material from providers, as opposed to other units. The immediate cost of relying on providers varies periodically. When training has finished, the resulting policy is made part of the environment, and training of the next unit begins. 
Training happens sequentially according to the numbers on the production units (squares) of @Layout. Note that the training budget for each unit is $1/10$th of the total budget.

@CP-Learned-Performance shows the global rewards, i.e. the sum of each unit's individual rewards. Distributed training is the blue line; cascading is the green.

The baseline performance, where all production units pick actions randomly, is a reward of -2336. The average reward achieved after training each production unit for 20000 episodes is -183.

#grid(columns:(1fr, 1fr),

    [#figure(
        image("./CP/CP.svg", width:100%),
        caption: "Chemical production learning results."
    ) <CP-Learned-Performance>],
    [#figure(
        image("./CP/Layout.png", height:170pt),
        caption: "Layout of the system"
    ) <Layout>]
)


== Decentralized Shielding & Centralized Learning

Turns out a centralized controller is much more effective in this context, perhaps due to the slightly lower dimensionality. The performance for the entire plant under one centralized controller is shown in the purple line of @CP-Learned-Performance. The best performance achieved is a mean reward of -398.

