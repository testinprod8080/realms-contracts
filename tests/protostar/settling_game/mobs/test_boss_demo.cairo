%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.settling_game.utils.game_structs import (
    Point,
    Army,
    ArmyData,
    Battalion,
    ExternalContractIds,
)
from contracts.settling_game.utils.constants import (
    COMBAT_OUTCOME_ATTACKER_WINS,
    COMBAT_OUTCOME_DEFENDER_WINS,
)
from contracts.settling_game.modules.mobs.Mobs import (
    spawn_mob,
    get_mob_coordinates,
    get_mob_health,
    get_mob_army_combat_data,
    set_mob_army_data_and_emit,
)
from contracts.settling_game.modules.travel.Travel import (
    travel_to_coordinates,
    initializer,
    get_travel_information,
    assert_traveller_is_at_coordinates,
)
from contracts.settling_game.modules.combat.Combat import (
    attack_mob,
    set_xoroshiro,
    build_army_from_battalions,
    get_realm_army_combat_data,
)
from contracts.settling_game.modules.combat.library import Combat

const BOSS_X_COORD = 10000;
const BOSS_Y_COORD = 10000;
const MOCK_CONTRACT_ADDRESS = 0x3fe90a1958bb8468fb1b62970747d8a00c435ef96cda708ae8de3d07f1bb56b;

@external
func test_full_demo{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}() {
    alloc_locals;

    // arrange
    %{ stop_prank_callable = start_prank(ids.MOCK_CONTRACT_ADDRESS) %}    
    initializer(MOCK_CONTRACT_ADDRESS, MOCK_CONTRACT_ADDRESS);
    let packed_boss_army = 439804651110402; // 2 LightCavalry battalions
    %{
        print("Created boss army: " + str(ids.packed_boss_army))
    %}

    // idea: sacrifice resources into escrow contract to spawn boss

    // spawn boss
    let x_coordinate = BOSS_X_COORD;
    let y_coordinate = BOSS_Y_COORD;
    let mob_id = 1;
    test_spawn_mob(mob_id, x_coordinate, y_coordinate);

    // travel to boss location
    let traveller_contract_id = ExternalContractIds.S_Realms;
    let traveller_token_id = Uint256(low=1, high=1);
    let traveller_nested_id = 1;
    test_travel_to_boss_location(
        traveller_contract_id, 
        traveller_token_id, 
        traveller_nested_id, 
        x_coordinate, 
        y_coordinate
    );

    // build weak army
    let attacking_weak_army_id = 1;
    let attacking_realm_id = Uint256(low=1, high=1);

    let (weak_battalion_ids: felt*) = alloc();
    assert weak_battalion_ids[0] = 1;

    let (weak_battalion_quantity: felt*) = alloc();
    assert weak_battalion_quantity[0] = 1;

    let (weak_army) = build_army(
        attacking_realm_id, 
        attacking_weak_army_id, 
        1, weak_battalion_ids, 
        1, weak_battalion_quantity
    );
    %{
        print("Created weak army: " + str(ids.weak_army.ArmyPacked))
    %}

    // attack with weak army
    let attacker_won = FALSE;
    let (win) = test_attack_boss(
        attacking_weak_army_id,
        attacking_realm_id,
        mob_id,
        packed_boss_army,
    );
    %{
        print("Attack successful? " + str(bool(ids.win)))
    %}

    // assert combat results via events
    let (starting_weak_army) = Combat.unpack_army(weak_army.ArmyPacked);
    let ending_weak_army = Army(Battalion(1, 25), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0));
    let (starting_boss_army) = Combat.unpack_army(packed_boss_army);
    let ending_boss_army = Army(Battalion(2, 33), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0));
    assert_attack_boss_events(
        attacking_weak_army_id, 
        attacking_realm_id, 
        mob_id, 
        attacker_won,
        starting_weak_army,
        starting_boss_army,
        ending_weak_army,
        ending_boss_army,
    );

    // build strong army
    let attacking_strong_army_id = 2;

    let (strong_battalion_ids: felt*) = alloc();
    assert strong_battalion_ids[0] = 8;

    let (strong_battalion_quantity: felt*) = alloc();
    assert strong_battalion_quantity[0] = 30;
    
    let (strong_army) = build_army(
        attacking_realm_id, 
        attacking_strong_army_id, 
        1, strong_battalion_ids, 
        1, strong_battalion_quantity
    );
    %{
        print("Created strong army: " + str(ids.strong_army.ArmyPacked))
    %}

    // attack with strong army
    let attacker_won = TRUE;
    let (win) = test_attack_boss(
        attacking_strong_army_id,
        attacking_realm_id,
        mob_id,
        packed_boss_army,
    );
    %{
        print("Attack successful? " + str(bool(ids.win)))
    %}

    // assert combat results via events
    let (starting_strong_army) = Combat.unpack_army(strong_army.ArmyPacked);
    let ending_strong_army = Army(Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(0, 0), Battalion(30, 24));
    let (starting_boss_army) = Combat.unpack_army(packed_boss_army);
    let (ending_boss_army) = Combat.unpack_army(0);
    assert_attack_boss_events(
        attacking_strong_army_id, 
        attacking_realm_id, 
        mob_id, 
        attacker_won,
        starting_strong_army,
        starting_boss_army,
        ending_strong_army,
        ending_boss_army,
    );

    // idea: mint nft trophy

    %{ stop_prank_callable() %}

    return ();    
}

// -----------------------------------
// Helpers
// -----------------------------------

func test_spawn_mob{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    x: felt,
    y: felt,
    mob_id: felt,
) {
    alloc_locals;

    // act
    spawn_mob(mob_id, x, y);

    // assert
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

func test_travel_to_boss_location{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(
    traveller_contract_id: felt,
    traveller_token_id: Uint256,
    traveller_nested_id: felt,
    x: felt, 
    y: felt,
) {
    alloc_locals;

    // arrange
    let expected_travel_time = 30;
    mock_IModuleController(MOCK_CONTRACT_ADDRESS);

    // act
    travel_to_coordinates(
        traveller_contract_id, 
        traveller_token_id, 
        traveller_nested_id, 
        x, 
        y
    );

    stop_mock_IModuleController();

    // assert
    let (travel_information) = get_travel_information(
        traveller_contract_id,
        traveller_token_id,
        traveller_nested_id
    );
    assert travel_information.travel_time = expected_travel_time;
    assert travel_information.x = x;
    assert travel_information.y = y;

    return ();    
}

func build_army{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    attacking_realm_id: Uint256,
    attacking_army_id: felt,
    battalion_ids_len: felt,
    battalion_ids: felt*,
    battalions_len: felt,
    battalion_quantity: felt*,
) -> (army_data: ArmyData) {
    alloc_locals;

    mock_IModuleController(MOCK_CONTRACT_ADDRESS);
    mock_build_army_calls(MOCK_CONTRACT_ADDRESS);

    build_army_from_battalions(
        attacking_realm_id, 
        attacking_army_id,
        battalion_ids_len,
        battalion_ids,
        battalions_len,
        battalion_quantity,
    );

    stop_mock_IModuleController();
    stop_mock_build_army_calls();

    let (army_data) = get_realm_army_combat_data(attacking_army_id, attacking_realm_id);

    return (army_data=army_data);
}

func test_attack_boss{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    mob_id: felt,
    packed_mob_army: felt,
) -> (win: felt) {
    alloc_locals;

    // arrange
    local external_contract_address = MOCK_CONTRACT_ADDRESS;
    set_xoroshiro(external_contract_address);
    mock_IModuleController(external_contract_address);
    mock_attack_boss(
        BOSS_X_COORD, 
        BOSS_Y_COORD, 
        external_contract_address, 
        packed_mob_army,
    );

    // act - attack
    let (attacker_won) = attack_mob(attacking_army_id, attacking_realm_id, mob_id);

    stop_mock_IModuleController();
    stop_mock_attack_boss();

    return (win=attacker_won);
}

// -----------------------------------
// Mocks
// -----------------------------------

func mock_IModuleController(    
    external_contract_address: felt,
) {
    // mocks - IModuleController
    %{
        stop_mock_get_module_address = mock_call(
            ids.external_contract_address, 
            "get_module_address", 
            [ids.external_contract_address]
        )
        stop_mock_get_external_contract_address = mock_call(
            ids.external_contract_address, 
            "get_external_contract_address", 
            [ids.external_contract_address]
        ) 
        stop_mock_ownerOf = mock_call(
            ids.external_contract_address, 
            "ownerOf", 
            [ids.external_contract_address]
        ) 
    %}

    return ();
}

func mock_build_army_calls(    
    external_contract_address: felt,
) {
    // mocks - IBuildings
    %{
        stop_mock_get_effective_buildings = mock_call(
            ids.external_contract_address, 
            "get_effective_buildings", 
            [100, 100, 100, 100, 100, 100, 100, 100, 100]
        )
    %}

    // mocks - IERC1155
    %{
        stop_mock_IERC1155_burnBatch = mock_call(
            ids.external_contract_address, 
            "burnBatch", 
            [100, 100, 100, 100, 100, 100, 100, 100, 100]
        )
    %}

    return ();
}

func mock_attack_boss(
    x: felt,
    y: felt,
    external_contract_address: felt,
    packed_mob_army: felt,
) {
    // mocks - ITravel
    %{
        stop_mock_get_mob_coordinates = mock_call(
            ids.external_contract_address, 
            "get_mob_coordinates", 
            [ids.x, ids.y]
        ) 
        stop_mock_assert_traveller_is_at_coordinates = mock_call(
            ids.external_contract_address, 
            "assert_traveller_is_at_coordinates", 
            []
        ) 
    %}

    // mocks - IMob
    %{
        stop_mock_mob_can_be_attacked = mock_call(
            ids.external_contract_address, 
            "mob_can_be_attacked", 
            [ids.TRUE]
        ) 
        stop_mock_get_mob_army_combat_data = mock_call(
            ids.external_contract_address, 
            "get_mob_army_combat_data", 
            [ids.packed_mob_army, 0, 0, 0, 0]
            #[249537519729966414970199203575, 0, 0, 0, 0]
        ) 
        stop_mock_set_mob_army_data_and_emit = mock_call(
            ids.external_contract_address, 
            "set_mob_army_data_and_emit", 
            []
        ) 
    %}

    // mocks - IXoroshiro
    %{
        stop_mock_xoroshiro_next = mock_call(
            ids.external_contract_address, 
            "next", 
            [50]
        ) 
    %}

    return ();
}

func stop_mock_IModuleController() {
    %{ 
        stop_mock_get_module_address()
        stop_mock_get_external_contract_address() 
        stop_mock_ownerOf()
    %}

    return ();
}

func stop_mock_build_army_calls() {
    %{
        stop_mock_get_effective_buildings()
        stop_mock_IERC1155_burnBatch()
    %}

    return ();
}

func stop_mock_attack_boss() {
    %{ 
        stop_mock_get_mob_coordinates()
        stop_mock_assert_traveller_is_at_coordinates()
        stop_mock_mob_can_be_attacked()
        stop_mock_get_mob_army_combat_data()
        stop_mock_set_mob_army_data_and_emit()
        stop_mock_xoroshiro_next()
    %}

    return ();
}

// -----------------------------------
// Expect Events
// -----------------------------------

func assert_attack_boss_events(
    attacking_army_id: felt,
    attacking_realm_id: Uint256,
    mob_id: felt,
    combat_outcome: felt,
    starting_attacking_army: Army,
    starting_mob_army: Army,
    ending_attacking_army: Army,
    ending_mob_army: Army,
) {
    %{ 
        import copy
        army_id = ids.attacking_army_id
        realm_id = {
            "low": ids.attacking_realm_id.low, 
            "high": ids.attacking_realm_id.high
        }
        empty_army = {
            "LightCavalry": {
                "Health": 0,
                "Quantity": 0
            },
            "HeavyCavalry": {
                "Health": 0,
                "Quantity": 0
            },
            "Archer": {
                "Health": 0,
                "Quantity": 0
            },
            "Longbow": {
                "Health": 0,
                "Quantity": 0
            },
            "Mage": {
                "Health": 0,
                "Quantity": 0
            },
            "Arcanist": {
                "Health": 0,
                "Quantity": 0
            },
            "LightInfantry": {
                "Health": 0,
                "Quantity": 0
            },
            "HeavyInfantry": {
                "Health": 0,
                "Quantity": 0
            }
        }

        starting_attacking_army = copy.deepcopy(empty_army)
        starting_attacking_army["LightCavalry"]["Quantity"] = ids.starting_attacking_army.LightCavalry.Quantity
        starting_attacking_army["LightCavalry"]["Health"] = ids.starting_attacking_army.LightCavalry.Health
        starting_attacking_army["HeavyInfantry"]["Quantity"] = ids.starting_attacking_army.HeavyInfantry.Quantity
        starting_attacking_army["HeavyInfantry"]["Health"] = ids.starting_attacking_army.HeavyInfantry.Health

        starting_mob_army = copy.deepcopy(empty_army)
        starting_mob_army["LightCavalry"]["Quantity"] = ids.starting_mob_army.LightCavalry.Quantity
        starting_mob_army["LightCavalry"]["Health"]  = ids.starting_mob_army.LightCavalry.Health

        ending_attacking_army = copy.deepcopy(empty_army)
        ending_attacking_army["LightCavalry"]["Quantity"] = ids.ending_attacking_army.LightCavalry.Quantity
        ending_attacking_army["LightCavalry"]["Health"] = ids.ending_attacking_army.LightCavalry.Health
        ending_attacking_army["HeavyInfantry"]["Quantity"] = ids.ending_attacking_army.HeavyInfantry.Quantity
        ending_attacking_army["HeavyInfantry"]["Health"] = ids.ending_attacking_army.HeavyInfantry.Health

        ending_mob_army = copy.deepcopy(empty_army)
        ending_mob_army["LightCavalry"]["Quantity"] = ids.ending_mob_army.LightCavalry.Quantity
        ending_mob_army["LightCavalry"]["Health"]  = ids.ending_mob_army.LightCavalry.Health

        expect_events(
            {
                "name": "CombatMobStart", 
                "data": {
                    "attacking_army_id": army_id, 
                    "attacking_realm_id": realm_id,
                    "attacking_army": starting_attacking_army,
                    "mob_id": ids.mob_id,
                    "mob_army": starting_mob_army
                }
            },
            {
                "name": "CombatMobEnd", 
                "data": {
                    "combat_outcome": ids.combat_outcome,
                    "attacking_army_id": army_id, 
                    "attacking_realm_id": realm_id,
                    "attacking_army": ending_attacking_army,
                    "mob_id": ids.mob_id,
                    "mob_army": ending_mob_army
                }
            }
        ) 
    %}

    return ();
}