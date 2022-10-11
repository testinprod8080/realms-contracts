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
    claim_rewards,
    set_mob_army_data_and_emit,
    get_mob_health,
    get_mob_army_combat_data,
    get_spawn_conditions,
    get_mob_sacrifice,
    mob_can_be_attacked,
    get_mob_attack_data,
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
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), 0));

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
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), 0));
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
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), 0));
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
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), 0));
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
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), 0));
    setup_mocks(MOCK_CONTRACT_ADDRESS);
    Module.initializer(MOCK_CONTRACT_ADDRESS);
    sacrifice_resources(mob_id, resource_id, resource_quantity);
    stop_mocks();

    // act
    spawn_mob(mob_id);

    // assert data stored
    let (health) = get_mob_health(mob_id);
    assert health = 800;

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
func test_fail_cannot_claim_rewards_if_mob_not_dead{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange
    let x = 100;
    let y = 100;
    let mob_id = 1;    
    let resource_id = Uint256(1, 0);
    let resource_quantity = Uint256(100, 0);
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), 0));
    setup_mocks(MOCK_CONTRACT_ADDRESS);
    Module.initializer(MOCK_CONTRACT_ADDRESS);
    sacrifice_resources(mob_id, resource_id, resource_quantity);
    stop_mocks();
    spawn_mob(mob_id);

    // act & assert
    %{ expect_revert(error_message="Mobs: cannot claim reward if mob is still alive") %}
    claim_rewards(mob_id);

    return();    
}

@external
func test_fail_did_not_attack_cannot_claim_rewards{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    let mob_id = 1;

    %{ expect_revert(error_message="Mobs: cannot claim reward if did not attack") %}
    claim_rewards(mob_id);

    return();    
}

@external
func test_claim_rewards{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange - spawn mob
    let x = 100;
    let y = 100;
    let mob_id = 1;    
    let resource_id = Uint256(1, 0);
    let resource_quantity = Uint256(100, 0);
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), 0));
    setup_mocks(MOCK_CONTRACT_ADDRESS);
    Module.initializer(MOCK_CONTRACT_ADDRESS);
    sacrifice_resources(mob_id, resource_id, resource_quantity);
    spawn_mob(mob_id);

    // arrange - set damage inflicted
    let army_data = ArmyData(1, 0, 0, 0, 0);
    let caller = MOCK_CONTRACT_ADDRESS;
    let damage_inflicted  = 10;
    let timestamp = 1;
    set_mob_army_data_and_emit(
        mob_id, army_data, caller, damage_inflicted, timestamp
    );

    %{ 
        stop_prank_callable = start_prank(ids.MOCK_CONTRACT_ADDRESS) 
        stop_mock_IERC115 = mock_call(
            ids.MOCK_CONTRACT_ADDRESS, 
            "mint", 
            []
        ) 
    %}  

    // act
    claim_rewards(mob_id);

    %{ 
        stop_prank_callable()
        stop_mock_IERC115()
    %}
    stop_mocks();

    return();    
}

@external
func test_set_mob_army_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange
    let mob_id = 1;
    let army_data = ArmyData(1, 0, 0, 0, 0);
    let caller = MOCK_CONTRACT_ADDRESS;
    let damage_inflicted  = 10;
    let timestamp = 1;

    // act
    set_mob_army_data_and_emit(
        mob_id, army_data, caller, damage_inflicted, timestamp
    );

    // assert
    let (result_army_data) = get_mob_army_combat_data(mob_id);
    assert result_army_data.ArmyPacked = 1;

    let (attack_data) = get_mob_attack_data(mob_id, caller);
    assert attack_data.total_damage_inflicted = damage_inflicted;
    assert attack_data.last_attack_timestamp = timestamp;

    return ();
}

@external
func test_set_mob_army_data_with_custom_logic{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange
    let mob_id = 1;
    let army_data = ArmyData(1, 0, 0, 0, 0);
    let caller = MOCK_CONTRACT_ADDRESS;
    let damage_inflicted  = 10;
    let timestamp = 1;

    let x = 100;
    let y = 100; 
    let resource_id = Uint256(1, 0);
    let resource_quantity = Uint256(100, 0);
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), MOCK_CONTRACT_ADDRESS));
    setup_mocks(MOCK_CONTRACT_ADDRESS);

    // act
    set_mob_army_data_and_emit(
        mob_id, army_data, caller, damage_inflicted, timestamp
    );

    stop_mocks();

    // assert
    // set custom logic address to 0 to get actual values when calling get_mob_army_combat_data for assertion
    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), 0));
    let (result_army_data) = get_mob_army_combat_data(mob_id);
    assert result_army_data.ArmyPacked = 10; // set as expected value in setup_mocks()

    let (attack_data) = get_mob_attack_data(mob_id, caller);
    assert attack_data.total_damage_inflicted = damage_inflicted;
    assert attack_data.last_attack_timestamp = timestamp;

    return ();
}

@external
func test_dead_mob_cannot_be_attacked{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // act
    let (can_attack) = mob_can_be_attacked(0, 0);

    // assert
    assert can_attack = FALSE;

    return ();
}

@external
func test_mob_cannot_be_attacked_before_cooldown{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange
    let x = 100;
    let y = 100;
    let mob_id = 1;
    let resource_id = Uint256(1, 0);
    let resource_quantity = Uint256(100, 0);

    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), 0));
    setup_mocks(MOCK_CONTRACT_ADDRESS);
    Module.initializer(MOCK_CONTRACT_ADDRESS);
    sacrifice_resources(mob_id, resource_id, resource_quantity);
    stop_mocks();

    spawn_mob(mob_id);

    // act
    let (can_attack) = mob_can_be_attacked(mob_id, MOCK_CONTRACT_ADDRESS);

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

    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), 0));
    setup_mocks(MOCK_CONTRACT_ADDRESS);
    Module.initializer(MOCK_CONTRACT_ADDRESS);
    sacrifice_resources(mob_id, resource_id, resource_quantity);
    stop_mocks();

    spawn_mob(mob_id);
    %{ stop_warp = warp(1000000) %}

    // act
    let (can_attack) = mob_can_be_attacked(mob_id, MOCK_CONTRACT_ADDRESS);

    %{ stop_warp() %}

    // assert
    assert can_attack = TRUE;

    return ();
}

@external
func test_get_mob_army_data_with_custom_logic{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;
    
    // arrange
    let x = 100;
    let y = 100;
    let mob_id = 1;    
    let resource_id = Uint256(1, 0);
    let resource_quantity = Uint256(100, 0);

    set_spawn_conditions(mob_id, SpawnConditions(resource_id, resource_quantity, Point(x, y), MOCK_CONTRACT_ADDRESS));
    setup_mocks(MOCK_CONTRACT_ADDRESS);
    Module.initializer(MOCK_CONTRACT_ADDRESS);
    sacrifice_resources(mob_id, resource_id, resource_quantity);

    spawn_mob(mob_id);

    // act
    let (army_data) = get_mob_army_combat_data(mob_id);

    stop_mocks();

    // assert
    assert army_data.ArmyPacked = 2; // set as expected value in setup_mocks()

    return ();
}

// -----------------------------------
// HELPERS
// -----------------------------------

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
        stop_mock_ICustomMob_modify_army_data_before_combat = mock_call(
            ids.external_contract_address, 
            "modify_army_data_before_combat", 
            [2, 0, 0, 0, 0]
        ) 
        stop_mock_ICustomMob_modify_army_data_after_combat = mock_call(
            ids.external_contract_address, 
            "modify_army_data_after_combat", 
            [10, 0, 0, 0, 0]
        ) 
    %}

    return ();
}

func stop_mocks() {
    %{ 
        stop_mock_get_external_contract_address() 
        stop_mock_safeTransferFrom()
        stop_mock_ICustomMob_modify_army_data_before_combat()
        stop_mock_ICustomMob_modify_army_data_after_combat()
    %}

    return ();
}