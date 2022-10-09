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