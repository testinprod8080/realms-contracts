![Mobs module header](/static/mobs_module.png)
_cave paintings of monsters that once roamed the Realms_

# Mobs Module
A module that expands the PvE experience by introducing NPC mobs to the Realms Settling Game. 

At its core, the Settling Game is a PvP game. Although [Goblin Towns](https://scroll.bibliothecadao.xyz/docs/game/goblin-towns) presents a taste of PvE gameplay, it has much more potential. This module sets up the infrastructure for designers and players to create rich PvE experiences.

This infrastructure includes mob spawning requirements as a token sink, mob mechanics customization beyond generative health and attack, and the beginnings of a reward system.

# Gameplay Overview
Let's go through the current user journey for this module.

First, mobs will need to be designed and registered in the module. This involves setting the spawn conditions, which includes setting a required amount of a [Resource](https://scroll.bibliothecadao.xyz/docs/game/resources) offering. There is also support for mob behavior customization. More on this in [Designing Mobs section](#designing-mobs).

Once a mob has been registered, it is up to players to offer up the required Resources in order to spawn the mob.

Once the mob has been spawn, players who have traveled their army to the mob's location can attack at will.

When the mob dies, players who attacked it can claim a reward (ERC1155).

# Features
## Designing Mobs
This version offers basic configuration of mobs. Currently, a mob is spawned as a very strong army with 23 Battalions for all 8 unit types. In the future, this will be either configurable or generative.

Mob designers can set the following values:
- **Resources Required** - a single resource type and quantity required to spawn the mob
- **Spawn Location** - x and y coordinates on the Atlas
- **Custom Logic Contract** - address of a contract containing custom logic for a mob

To register the mob, an admin will need to call `set_spawn_conditions()` with the above data.

### Custom Logic Contract
This offers designers creativity to build unique mechanics and behaviors in a mob.

The custom logic can trigger at the beginning and end of a player attacking a mob. Specifically, the custom logic takes in army data and modifies it as needed.

As an example, see `Sample_Custom_Mob_Logic.cairo`. There are two functions that need to be implemented by the designer. The `modify_army_data_after_combat()` function is called after an attack and is passed in army data that has been affected by the battle. In this example, there is no custom logic so it just passes the data through.

The `modify_army_data_before_combat()` function is where things get interesting. Based on an arbitrary timespan, this logic will restore a mob's army to full health before starting the battle. As you can imagine, this type of mob behavior introduces time criticality when trying to kill the mob.

There is a lot of room for creativity when using this pattern, but also opens up risks. Since any logic can be run, there needs to be a process to ensure nothing malicious or harmful is introduced.

## Spawning Mobs
As a requirement for spawning a mob, resources will need to be deposited into the module contract for the specified mob.

For example, if the mob spawn condition required 100 Wood resources, then players must call `sacrifice_resources()` to offer up Wood resources.

Once 100 Wood have been sacrificed, the `spawn_mob()` function can be invoked. The mob will be spawned at the x and y coordinates specified in the spawn conditions.

## Attacking Mobs
This module relies on most of the existing travel and combat systems. If you are familiar with those Settling Game mechanics, then not much is different.

A player must travel their Realm's attacking army to the mob's location before attacking. Since the mob does not have to be in a Realm or Crypt, a `travel_to_coordinates()` function has been created in the Travel module.

Combat is essentially the same as the core game except that rewards can only be claimed once the mob has been killed. An `attack_mob()` function has been added to the Combat module, which means fighting mobs will affect your army stats.

Currently, mobs do not actively attack an army in the same location (this might change in the future). Mobs passively damage an attacking army through their defense counter attack.

## Reaping Rewards
The rewards system is very basic at this point. All attackers can claim mob meat (ERC1155) once the mob is killed.

# Future Features
- [ ] Spawning: Generative stats
- [ ] Rewards: proportional to damage inflicted
- [ ] Rewards: support multiple reward types
- [ ] Rewards: 
- [ ] Spawn Conditions: multiple resource/token types for offering
- [ ] Mob Mechanics: mob can travel
- [ ] Mob Mechanics: mob actively attacks
