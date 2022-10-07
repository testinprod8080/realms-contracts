%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from contracts.settling_game.utils.game_structs import (
    Point,
    ArmyData,
)
from contracts.settling_game.modules.mobs.Mobs import (
    spawn_mob,
    get_mob_coordinates,
    get_mob_health,
    get_mob_army_combat_data,
    set_mob_army_data_and_emit,
    mob_can_be_attacked,
    set_spawn_conditions,
    get_spawn_conditions,
    sacrifice_resources,
)
from contracts.settling_game.modules.mobs.game_structs import (
    SpawnConditions,
)

@external
func test_set_spawn_conditions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // arrange
    let x = 100;
    let y = 100;
    let mob_id = 1;
    let resource_id = 1;
    let resource_quantity = 100;

    // act
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y)));

    // assert
    let (conditions) = get_spawn_conditions(mob_id);
    assert conditions.resource_id = resource_id;
    assert conditions.resource_quantity = resource_quantity;
    assert conditions.coordinates.x = x;
    assert conditions.coordinates.y = y;

    return ();    
}

@external
func test_fail_spawn_mob_if_not_enough_resources{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange
    let x = 100;
    let y = 100;
    let mob_id = 1;
    let resource_id = 1;
    let resource_quantity = 100;
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y)));
    sacrifice_resources(mob_id, resource_id, resource_quantity - 1);

    // act
    %{ expect_revert(error_message="Mobs: spawn conditions not met") %}
    spawn_mob(mob_id, x, y);

    return ();
}

@external
func test_fail_spawn_mob_without_spawn_conditions{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange
    let x = 100;
    let y = 100;
    let mob_id = 1;

    // act
    %{ expect_revert(error_message="Mobs: no spawn condition found") %}
    spawn_mob(mob_id, x, y);

    return ();    
}

@external
func test_fail_spawn_mob_if_exists{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange
    let x = 100;
    let y = 100;
    let mob_id = 1;
    let resource_id = 1;
    let resource_quantity = 100;
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y)));
    sacrifice_resources(mob_id, resource_id, resource_quantity);
    spawn_mob(mob_id, x, y);

    // act
    %{ expect_revert(error_message="Mobs: only one mob alive at a time") %}
    spawn_mob(mob_id, x, y);

    return ();
}

@external
func test_spawn_mob{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange
    let x = 100;
    let y = 100;
    let mob_id = 1;    
    let resource_id = 1;
    let resource_quantity = 100;
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y)));
    sacrifice_resources(mob_id, resource_id, resource_quantity);

    // act
    spawn_mob(mob_id, x, y);

    // assert spawned at expected location
    let (coordinates) = get_mob_coordinates(mob_id);
    assert coordinates.x = x;
    assert coordinates.y = y;

    // assert data stored
    let (health) = get_mob_health(mob_id);
    assert health = 18400;

    let (army_data) = get_mob_army_combat_data(mob_id);
    assert army_data.ArmyPacked = 249537519729966414970199203575; // max army

    // assert events
    %{
        expect_events(
            {
                "name": "MobSpawn", 
                "data": {
                    "mob_id": ids.mob_id, 
                    "x": ids.x,
                    "y": ids.y,
                    "time_stamp": 0
                }
            }
        ) 
    %}

    return ();
}

@external
func test_set_mob_army_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange
    let mob_id = 1;
    let army_data = ArmyData(1, 0, 0, 0, 0);

    // act
    set_mob_army_data_and_emit(mob_id, army_data);

    // assert
    let (result_army_data) = get_mob_army_combat_data(mob_id);
    assert result_army_data.ArmyPacked = 1;

    return ();
}

@external
func test_fail_dead_mob_cannot_be_attacked{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // act
    let (can_attack) = mob_can_be_attacked(0);

    // assert
    assert can_attack = FALSE;

    return ();
}

@external
func test_mob_can_be_attacked{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange
    let x = 100;
    let y = 100;
    let mob_id = 1;
    let resource_id = 1;
    let resource_quantity = 100;
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y)));
    sacrifice_resources(mob_id, resource_id, resource_quantity);
    spawn_mob(mob_id, x, y);

    // act
    let (can_attack) = mob_can_be_attacked(mob_id);

    // assert
    assert can_attack = TRUE;

    return ();
}
