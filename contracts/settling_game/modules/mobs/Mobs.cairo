// -----------------------------------
//   Module.Mobs
//   Logic of Mobs module

// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.math import (
    assert_not_zero,
)

from contracts.settling_game.library.library_module import Module
from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.utils.game_structs import (
    Point,
    Army,
    Battalion,
    ArmyData,
)
from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.modules.combat.constants import (
    BattalionIds,
)

// -----------------------------------
// Events
// -----------------------------------

@event
func MobSpawn(mob_id: felt, x: felt, y: felt, time_stamp: felt) {
}

@event
func MobArmyMetadata(mob_id: felt, army_data: ArmyData) {
}

// -----------------------------------
// Storage
// -----------------------------------x

@storage_var
func mob_data_by_id(mob_id: felt) -> (army_data: ArmyData) {
}

@storage_var
func mob_coordinates(mob_id: felt) -> (point: Point) {
}

// -----------------------------------
// EXTERNAL
// -----------------------------------

// @notice spawns mob at supplied coordinates
// @dev only callable by whitelisted
@external
func spawn_mob{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    mob_id: felt, x: felt, y: felt
) {
    alloc_locals;

    // TODO: whitelisted only

    // check spawn conditions
    with_attr error_message("Mobs: only one mob alive at a time") {
        let (army_data) = mob_data_by_id.read(mob_id);
        assert army_data.ArmyPacked = 0;
    }

    // store spawn coordinates
    mob_coordinates.write(mob_id, Point(x=x, y=y));

    // store army stats
    let unpacked_army = Army(
        LightCavalry=Battalion(Quantity=23, Health=100),
        HeavyCavalry=Battalion(Quantity=23, Health=100),
        Archer=Battalion(Quantity=23, Health=100),
        Longbow=Battalion(Quantity=23, Health=100),
        Mage=Battalion(Quantity=23, Health=100),
        Arcanist=Battalion(Quantity=23, Health=100),
        LightInfantry=Battalion(Quantity=23, Health=100),
        HeavyInfantry=Battalion(Quantity=23, Health=100),
    );
    let (packed_army) = Combat.pack_army(unpacked_army);
    mob_data_by_id.write(mob_id, ArmyData(packed_army, 0, 0, 0, 0));

    // emit mob spawn
    let (ts) = get_block_timestamp();
    MobSpawn.emit(mob_id, x, y, ts);

    return ();
}

@external
func set_mob_army_data_and_emit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    mob_id: felt, army_data: ArmyData
) {
    mob_data_by_id.write(mob_id, army_data);

    // emit data
    MobArmyMetadata.emit(mob_id, army_data);

    return ();
}

// -----------------------------------
// INTERNAL
// -----------------------------------

// -----------------------------------
// GETTERS
// -----------------------------------

@view
func get_mob_coordinates{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    mob_id: felt
) -> (coordinates: Point) {
    let (point) = mob_coordinates.read(mob_id);
    return (coordinates=point);
}

@view
func get_mob_health{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    mob_id: felt
) -> (health: felt) {
    let (army_data) = mob_data_by_id.read(mob_id);
    let (unpacked_army_data) = Combat.unpack_army(army_data.ArmyPacked);
    let health = unpacked_army_data.LightCavalry.Health * unpacked_army_data.LightCavalry.Quantity +
        unpacked_army_data.HeavyCavalry.Health * unpacked_army_data.HeavyCavalry.Quantity +
        unpacked_army_data.Archer.Health * unpacked_army_data.Archer.Quantity +
        unpacked_army_data.Longbow.Health * unpacked_army_data.Longbow.Quantity +
        unpacked_army_data.Mage.Health * unpacked_army_data.Mage.Quantity +
        unpacked_army_data.Arcanist.Health * unpacked_army_data.Arcanist.Quantity +
        unpacked_army_data.LightInfantry.Health * unpacked_army_data.LightInfantry.Quantity +
        unpacked_army_data.HeavyInfantry.Health * unpacked_army_data.HeavyInfantry.Quantity;
    return (health=health);
}

@view
func mob_can_be_attacked{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    mob_id: felt
) -> (yesno: felt) {
    alloc_locals;

    // TODO is spawned/alive
    let (mob_health) = get_mob_health(mob_id);
    if (mob_health == 0) {
        return (FALSE,);
    }

    // TODO attack cooldown?
    // let (mob_army_data: ArmyData) = get_mob_army_combat_data(mob_id);

    // let (now) = get_block_timestamp();
    // let diff = now - mob_army_data.LastAttacked;
    // let was_attacked_recently = is_le(diff, ATTACK_COOLDOWN_PERIOD);

    // if (was_attacked_recently == 1) {
    //     return (FALSE);
    // }

    return (TRUE,);
}

@view
func get_mob_army_combat_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    mob_id: felt
) -> (mob_army_data: ArmyData) {
    let (army_data) = mob_data_by_id.read(mob_id);
    return (mob_army_data=army_data);
}