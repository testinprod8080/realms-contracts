%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.library.library_module import Module
from contracts.settling_game.utils.game_structs import (
    Point,
    ArmyData,
)

from contracts.settling_game.modules.mobs.Mobs import (
    set_spawn_conditions,
    sacrifice_resources,
    spawn_mob,
    set_mob_army_data_and_emit,
    get_mob_health,
    get_mob_army_combat_data,
    get_spawn_conditions,
    get_mob_sacrifice,
    mob_can_be_attacked,
)
from contracts.settling_game.modules.mobs.game_structs import (
    SpawnConditions,
)

const MOCK_CONTRACT_ADDRESS = 0x3fe90a1958bb8468fb1b62970747d8a00c435ef96cda708ae8de3d07f1bb56b;

@external
func test_set_spawn_conditions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // arrange
    let x = 100;
    let y = 100;
    let mob_id = 1;
    let resource_id = Uint256(1, 0);
    let resource_quantity = Uint256(100, 0);

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
func test_sacrifice_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // arrange
    let x = 100;
    let y = 100;
    let mob_id = 1;
    let resource_id = Uint256(1, 0);
    let resource_quantity = Uint256(100, 0);
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y)));
    setup_mocks(MOCK_CONTRACT_ADDRESS);
    Module.initializer(MOCK_CONTRACT_ADDRESS);

    // act
    sacrifice_resources(mob_id, resource_id, resource_quantity);
    stop_mocks();

    // assert
    let (quantity) = get_mob_sacrifice(mob_id, resource_id);
    assert quantity = resource_quantity;

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
    let resource_id = Uint256(1, 0);
    let resource_quantity = Uint256(100, 0);
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y)));
    setup_mocks(MOCK_CONTRACT_ADDRESS);
    Module.initializer(MOCK_CONTRACT_ADDRESS);
    sacrifice_resources(mob_id, resource_id, Uint256(99, 0));
    stop_mocks();

    // act
    %{ expect_revert(error_message="Mobs: spawn conditions not met") %}
    spawn_mob(mob_id);

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
    spawn_mob(mob_id);

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
    let resource_id = Uint256(1, 0);
    let resource_quantity = Uint256(100, 0);
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y)));
    setup_mocks(MOCK_CONTRACT_ADDRESS);
    Module.initializer(MOCK_CONTRACT_ADDRESS);
    sacrifice_resources(mob_id, resource_id, resource_quantity);
    stop_mocks();
    spawn_mob(mob_id);

    // act
    %{ expect_revert(error_message="Mobs: only one mob alive at a time") %}
    spawn_mob(mob_id);

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
    let resource_id = Uint256(1, 0);
    let resource_quantity = Uint256(100, 0);
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y)));
    setup_mocks(MOCK_CONTRACT_ADDRESS);
    Module.initializer(MOCK_CONTRACT_ADDRESS);
    sacrifice_resources(mob_id, resource_id, resource_quantity);
    stop_mocks();

    // act
    spawn_mob(mob_id);

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
                    "coordinates": {
                        "x": ids.x,
                        "y": ids.y
                    },
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
    let resource_id = Uint256(1, 0);
    let resource_quantity = Uint256(100, 0);
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y)));
    setup_mocks(MOCK_CONTRACT_ADDRESS);
    Module.initializer(MOCK_CONTRACT_ADDRESS);
    sacrifice_resources(mob_id, resource_id, resource_quantity);
    stop_mocks();
    spawn_mob(mob_id);

    // act
    let (can_attack) = mob_can_be_attacked(mob_id);

    // assert
    assert can_attack = TRUE;

    return ();
}

func setup_mocks(    
    external_contract_address: felt,
) {
    %{
        stop_mock_get_external_contract_address = mock_call(
            ids.external_contract_address, 
            "get_external_contract_address", 
            [ids.external_contract_address]
        ) 
        stop_mock_safeTransferFrom = mock_call(
            ids.external_contract_address, 
            "safeTransferFrom", 
            []
        ) 
    %}

    return ();
}

func stop_mocks() {
    %{ 
        stop_mock_get_external_contract_address() 
        stop_mock_safeTransferFrom()
    %}

    return ();
}