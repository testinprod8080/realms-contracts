// -----------------------------------
// Mobs game structs
//
// MIT License
// -----------------------------------

%lang starknet

from contracts.settling_game.utils.game_structs import (
    Point,
)
from starkware.cairo.common.uint256 import Uint256

struct SpawnConditions {
    resource_id: Uint256,
    resource_quantity: Uint256,
    coordinates: Point,
}

struct AttackData {
    total_damage_inflicted: felt,
    last_attack_timestamp: felt,
}