%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.settling_game.utils.game_structs import (
    Army,
    Battalion,
)
from contracts.settling_game.modules.mobs.library import Mobs

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