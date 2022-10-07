// -----------------------------------
// Mobs game structs
//
// MIT License
// -----------------------------------

%lang starknet

from contracts.settling_game.utils.game_structs import (
    Point,
)

struct SpawnConditions {
    resource_id: felt,
    resource_quantity: felt,
    coordinates: Point,
}