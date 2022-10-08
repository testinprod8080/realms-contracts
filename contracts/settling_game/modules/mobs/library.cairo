// -----------------------------------
// GoblinTown Library
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.math_cmp import is_le

from contracts.settling_game.utils.game_structs import (
    Army,
)

namespace Mobs {
    func get_health_from_unpacked_army{range_check_ptr}(unpacked_army_data: Army) -> (health: felt) {
        let health = unpacked_army_data.LightCavalry.Health +
        unpacked_army_data.HeavyCavalry.Health +
        unpacked_army_data.Archer.Health +
        unpacked_army_data.Longbow.Health +
        unpacked_army_data.Mage.Health +
        unpacked_army_data.Arcanist.Health +
        unpacked_army_data.LightInfantry.Health +
        unpacked_army_data.HeavyInfantry.Health;
        
        return (health,);
    }

    func check_mob_dead{range_check_ptr}(unpacked_army_data: Army) -> (dead: felt) {
        let (health) = get_health_from_unpacked_army(unpacked_army_data);
        let dead = is_le(health, 0);
        return (dead,);
    }
}
