// Module Interfaces
// MIT License

%lang starknet

from contracts.settling_game.utils.game_structs import (
    Point,
    ArmyData,
)
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IMob {
    func get_mob_coordinates(mob_id: felt) -> (coordinates: Point) {
    }

    func mob_can_be_attacked(mob_id: felt) -> (yesno: felt) {
    }

    func get_mob_army_combat_data(mob_id: felt) -> (mob_army_data: ArmyData) {
    }

    func set_mob_army_data_and_emit(
        mob_id: felt, 
        army_data: ArmyData, 
        caller: felt, 
        damage_inflicted: felt, 
        timestamp: felt,
    ) {
    }
}
