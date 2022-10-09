%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.utils.game_structs import (
    Army,
    Battalion,
)
from contracts.settling_game.modules.mobs.game_structs import (
    AttackData,
)
from contracts.settling_game.modules.mobs.library import Mobs
from contracts.settling_game.modules.mobs.constants import RewardIds

@external
func test_get_health_from_unpacked_army{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // arrange
    let army = Army(
        Battalion(1, 100),
        Battalion(1, 100),
        Battalion(1, 100),
        Battalion(1, 100),
        Battalion(0, 0),
        Battalion(0, 0),
        Battalion(0, 0),
        Battalion(0, 0),
    );

    // act
    let (health) = Mobs.get_health_from_unpacked_army(army);

    // assert
    assert health = 400;

    return ();    
}

@external
func test_check_mob_alive{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // arrange
    let army = Army(
        Battalion(1, 100),
        Battalion(1, 100),
        Battalion(1, 100),
        Battalion(1, 100),
        Battalion(0, 0),
        Battalion(0, 0),
        Battalion(0, 0),
        Battalion(0, 0),
    );

    // act
    let (dead) = Mobs.check_mob_dead(army);

    // assert
    assert dead = FALSE;

    return ();    
}

@external
func test_check_mob_dead{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // arrange
    let army = Army(
        Battalion(0, 0),
        Battalion(0, 0),
        Battalion(0, 0),
        Battalion(0, 0),
        Battalion(0, 0),
        Battalion(0, 0),
        Battalion(0, 0),
        Battalion(0, 0),
    );

    // act
    let (dead) = Mobs.check_mob_dead(army);

    // assert
    assert dead = TRUE;

    return ();    
}

@external
func test_did_not_claim_mob_meat{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (len, _) = Mobs.get_claimable_reward_ids(AttackData(0, 0));

    assert len = 0;

    return ();
}

@external
func test_get_claimable_reward_ids{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let total_damage_inflicted = 1;

    let (len, ids) = Mobs.get_claimable_reward_ids(AttackData(total_damage_inflicted, 0));

    assert len = 1;
    assert ids[0] = Uint256(RewardIds.MobMeat, 0);

    return ();
}

// @external
// func test_get_claimable_reward_amounts{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;
//     let total_damage_inflicted = 1;

//     let (ids) = Mobs.get_claimable_reward_amounts(AttackData(total_damage_inflicted, 0));

//     assert ids[0] = Uint256(RewardIds.MobMeat, 0);

//     return ();
// }