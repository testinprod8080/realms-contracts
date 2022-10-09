// -----------------------------------
// GoblinTown Library
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from contracts.settling_game.utils.game_structs import (
    Army,
)
from contracts.settling_game.modules.mobs.game_structs import (
    AttackData,
)
from contracts.settling_game.modules.mobs.constants import RewardIds

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

    func get_claimable_reward_ids{range_check_ptr}(attack_data: AttackData
    ) -> (reward_ids_len: felt, reward_ids: Uint256*) {
        alloc_locals;

        let (local reward_ids: Uint256*) = alloc();
        let reward_ids_len = 0;

        if (attack_data.total_damage_inflicted != 0) {
            assert reward_ids[0] = Uint256(RewardIds.MobMeat, 0);
            tempvar reward_ids_len = reward_ids_len + 1;
        } else {
            tempvar reward_ids_len = reward_ids_len;
        }

        // TODO first blood, most damage, final blow
        
        return (reward_ids_len, reward_ids,);
    }
}
