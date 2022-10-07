// -----------------------------------
// GoblinTown Library
//
// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.lang.compiler.lib.registers import get_fp_and_pc

from contracts.settling_game.utils.constants import SHIFT_8_9
from contracts.settling_game.utils.game_structs import RealmData, ResourceIds

namespace Mobs {
    func pack{range_check_ptr}(strength: felt, spawn_ts: felt) -> (packed: felt) {
        let packed = strength + spawn_ts * SHIFT_8_9;
        return (packed,);
    }

    func unpack{range_check_ptr}(packed: felt) -> (strength: felt, spawn_ts: felt) {
        let (spawn_ts, strength) = unsigned_div_rem(packed, SHIFT_8_9);
        return (strength, spawn_ts);
    }

    func calculate_strength{range_check_ptr}(rnd: felt) -> (strength: felt) {
        alloc_locals;
        let (__fp__, _) = get_fp_and_pc();

        // add a random element to the calculated strength
        let strength = 9 + rnd;

        // cap it
        let is_within_bounds = is_le(strength, 9);
        if (is_within_bounds == TRUE) {
            return (strength,);
        }

        return (9,);
    }
}
