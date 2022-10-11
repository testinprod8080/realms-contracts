%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.settling_game.utils.game_structs import (
    ArmyData,
)
from contracts.settling_game.utils.constants import DAY

from contracts.settling_game.modules.mobs.Sample_Custom_Mob_Logic import (
    modify_army_data_before_combat,
    modify_army_data_after_combat,
    TIME_UNTIL_HEALTH_RESTORE,
)

@external
func test_before_combat_not_enough_time_elapsed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;

    // arrange
    let army_data = ArmyData(1, 0, 0, 0, 0);
    %{ stop_warp = warp(int(ids.TIME_UNTIL_HEALTH_RESTORE - 1)) %}

    // act
    let (new_army_data) = modify_army_data_before_combat(army_data);

    %{ stop_warp() %}

    // assert
    assert new_army_data = army_data;

    return ();
}
@external
func test_before_combat_health_restored{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}() {
    alloc_locals;

    // arrange
    let army_data = ArmyData(1, 0, 0, 0, 0);
    let expected_army_data = ArmyData(249537519729966414154432512001, 0, 0, 0, 0);
    %{ stop_warp = warp(ids.TIME_UNTIL_HEALTH_RESTORE) %}

    // act
    let (new_army_data) = modify_army_data_before_combat(army_data);

    %{ stop_warp() %}

    // assert
    assert new_army_data = expected_army_data;

    return ();
}

@external
func test_after_combat{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    
    // arrange
    let army_data = ArmyData(1, 0, 0, 0, 0);

    // act
    let (new_army_data) = modify_army_data_after_combat(army_data);

    // assert
    assert new_army_data = army_data;

    return ();
}