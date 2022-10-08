%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, sqrt
from starkware.cairo.common.pow import pow
from starkware.cairo.common.uint256 import Uint256

from contracts.settling_game.modules.travel.library import Travel, PRECISION
from contracts.settling_game.modules.travel.Travel import (
    travel_to_coordinates,
    initializer,
    get_travel_information,
)

from contracts.settling_game.utils.constants import SECONDS_PER_KM
from contracts.settling_game.utils.game_structs import Point

const offset = 1800000;

const TEST_X1 = (307471) + offset;

const TEST_Y1 = (-96200) + offset;

const TEST_X2 = (685471) + offset;

const TEST_Y2 = (419800) + offset;

@external
func test_calculate_distance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (distance) = Travel.calculate_distance(Point(TEST_X1, TEST_Y1), Point(TEST_X2, TEST_Y2));

    let (x) = pow(TEST_X2 - TEST_X1, 2);
    let (y) = pow(TEST_Y2 - TEST_Y1, 2);

    let sqr_distance = sqrt(x + y);

    let (d, _) = unsigned_div_rem(sqr_distance, PRECISION);

    assert d = distance;
    %{ print('Distance:', ids.distance) %}
    return ();
}

@external
func test_time{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (distance) = Travel.calculate_distance(Point(TEST_X1, TEST_Y1), Point(TEST_X2, TEST_Y2));

    let (time) = Travel.calculate_time(distance);

    assert time = distance * SECONDS_PER_KM;
    %{ print('Time:', ids.time) %}
    return ();
}

@external
func test_travel_to_coordinates{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // arrange inputs
    let traveller_contract_id = 1;
    let traveller_token_id = Uint256(1, 0);
    let traveller_nested_id = 1;
    let x = 10000;
    let y = 10000;


    // mocks
    local external_contract_address = 0x3fe90a1958bb8468fb1b62970747d8a00c435ef96cda708ae8de3d07f1bb56b;
    initializer(external_contract_address, external_contract_address);
    %{ 
        stop_prank_callable = start_prank(ids.external_contract_address)
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

    // act
    travel_to_coordinates(
        traveller_contract_id, 
        traveller_token_id, 
        traveller_nested_id, 
        x, 
        y
    );
    
    %{ 
        stop_prank_callable()
        stop_mock_get_external_contract_address() 
        stop_mock_ownerOf()
    %}

    // assert
    let (travel_information) = get_travel_information(
        traveller_contract_id,
        traveller_token_id,
        traveller_nested_id
    );
    assert travel_information.travel_time = 30;

    return ();    
}