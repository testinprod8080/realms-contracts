# Matchbox x Realms Hackathon 

## TODO

- [x] boss spawn
    - [x] location
    - [x] health
    - [x] attack strength
- [x] player travel to boss location
- [x] player attack boss
- [x] boss defend, health, and death
- [ ] pay resources to spawn boss
- [ ] pay to travel to boss location/fight boss?
- [ ] claim reward (could be NFT)
    - idea: claim resources
    - idea: biome specific trophy
    - idea: first blood, final blow, most damage
- [ ] boss travel
- [ ] player attack cooldown
- [ ] boss attack
- [ ] player defend against boss

- [ ] generative boss stats

- [ ] spawn minion(s)
    - [ ] current location
    - [ ] health
    - [ ] attack strength
- [ ] minion travel
- [ ] minion attack
- [ ] minion defend, health, and death

- [ ] look at respawning boss with higher difficulty (higher health and attack strength, num of minions spawned)
  - [ ] track level

## Sacrifice to spawn boss

### Ideas
- Deposit resources into contract
    - 100 wood for level 1 boss
    - x2 required for next level 2 and so on
    - partial deposits allowed, no withdrawals
- Some bosses require multiple resources
    - 100 wood, 5 dragonhide, etc
    - resources could be related to their type
- Boss spawned in same call by the last depositor to fulfill requirement
- Start with arbitrary list of bosses and requirements
    - a requirement could be that the caller has traveled to a specific coordinate
    - require 5 total invocations of the spawn call
    - foster creativity from the community to come up with requirements
- spawn location could be random
- boss types, traits, abilities

### Considerations
- if using the Combat module, what is the army composition of bosses based on type, traits, etc?
- boss generation algo for new and leveling up

### Data Structure

Boss spawn requirements lookup
- mob_id
- resource_ids[]
- resource_quantity[]
- x_coordinate
- y_coordinate
- (future) requirements_contract_address - for custom requirements