// Constants utility contract
//   A set of constants used by mobs module
//
// MIT License

%lang starknet

from contracts.settling_game.utils.constants import (
    DAY,
)

// a min delay between attacks on a mob; it can't
// be attacked again during cooldown
const MOB_PLAYER_ATTACK_COOLDOWN_PERIOD = DAY / 10;  // 1 day unit

// TODO consider moving to Resources
namespace RewardIds {
    const MobMeat = 1; // participation trophy for anyone that attacked
    const FirstBloodBadge = 2;
    const MostDamageBadge = 3;
    const FinalBlowBadge = 4;
}