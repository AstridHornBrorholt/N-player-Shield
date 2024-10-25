# Centralized Shield

A shield managing two cars at once, following a random car in front of them. Because of memory constraints on my machine, it was only possible to do two cars, and only if the maximum distance was 50m rather than 200m. Maybe I can bump it up to 75m with better memory usage.

Since the shield affects both cars at once, the cars are also trained using a centralized controller.

## Files

 - `3-car.so` is thie shield that manages the two cars, with an uncontrollable car in front.
 - `2-car.so` is thie shield that manages only one car. This is the normal shield except it enforces a maximum distance of 50m instead of the usual 200m.
 - `3-Car Centralized.xml` is the uppaal model of the two cars following the random car under a centralized shield. This and the next file have `_blueprint` variants.
 - `3-Car.xml` is the regular, distributed shield variant.
 - `3-Car Declared.xml` uses a "co-ordinating" shield between the second and third car.
 - `shield.c` doesn't seem to be in use. Looks like dangling copy-pasta.

## Co-ordinating Shield

Centralized shields require agents to coordinate in order to agree on joint actions. This coordination allows an agent to know which actions its peer will take in the following time-step, when deciding its own action.

This is a huge benefit, which leads to much better performance than the independent, distributed approach.
In order to investigate how much of this was due to the co-ordination between agents, a version of the distributed shield was created that takes the other agent's future action as part of the input. This allows for a similar kind of co-ordination as the centralized shield requires, but in a distributed setting.

We found that letting agents co-ordinate actions is also beneficial when using distributed shields, but that a centralized shield is still more permissive.