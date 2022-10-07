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
    assert_le,
)
from starkware.cairo.common.math_cmp import is_not_zero

from openzeppelin.upgrades.library import Proxy

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
from contracts.settling_game.modules.mobs.game_structs import (
    SpawnConditions,
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

@event
func MobSpawnOffering(mob_id: felt, resource_id: felt, resource_quantity: felt) {
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

@storage_var
func mob_spawn_conditions(mob_id: felt) -> (conditions: SpawnConditions) {
}

@storage_var
func mob_sacrifice(mob_id: felt, resource_id: felt) -> (resource_quantity: felt) {
}


// -----------------------------------
// EXTERNAL
// -----------------------------------

// @notice deposit resources towards mob spawn requirements
@external
func sacrifice_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    mob_id: felt, resource_id: felt, resource_quantity: felt
) {
    alloc_locals;

    // TODO check requirements for mob for this resource so that
    // we can revert if they are depositing too much

    mob_sacrifice.write(mob_id, resource_id, resource_quantity);

    MobSpawnOffering.emit(mob_id, resource_id, resource_quantity);

    return ();
}

// @notice spawns mob at supplied coordinates
@external
func spawn_mob{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    mob_id: felt, x: felt, y: felt
) {
    alloc_locals;

    let (spawn_conditions) = mob_spawn_conditions.read(mob_id);

    with_attr error_message("Mobs: spawn conditions not met") {
        let has_required_resources = is_not_zero(spawn_conditions.resource_id);
        if (has_required_resources == TRUE) {
            let (sacrificed_resources) = mob_sacrifice.read(
                mob_id, spawn_conditions.resource_id
            );
            assert_le(spawn_conditions.resource_quantity, sacrificed_resources);

            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        } else {
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        }
    }

    // check spawn conditions
    with_attr error_message("Mobs: only one mob alive at a time") {
        let (army_data) = mob_data_by_id.read(mob_id);
        assert army_data.ArmyPacked = 0;
    }

    // TODO do something with sacrificed resources (split to treasury/module fee/burn/etc)

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
func get_spawn_conditions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    mob_id: felt
) -> (conditions: SpawnConditions) {
    let (conditions) = mob_spawn_conditions.read(mob_id);
    return (conditions=conditions);
}

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

// -----------------------------------
// Admin
// -----------------------------------

@external
func set_spawn_conditions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    mob_id: felt, conditions: SpawnConditions
) {
    Proxy.assert_only_admin();
    mob_spawn_conditions.write(mob_id, conditions);
    return ();
}