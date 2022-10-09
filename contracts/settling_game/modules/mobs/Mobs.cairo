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
from starkware.starknet.common.syscalls import (
    get_block_timestamp, 
    get_caller_address,
    get_contract_address,
)
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_le,
)
from starkware.cairo.common.math_cmp import is_not_zero, is_le

from openzeppelin.upgrades.library import Proxy

from contracts.settling_game.library.library_module import Module
from contracts.settling_game.interfaces.imodules import IModuleController
from contracts.settling_game.interfaces.IERC1155 import IERC1155
from contracts.settling_game.utils.game_structs import (
    Point,
    Army,
    Battalion,
    ArmyData,
    ExternalContractIds,
)

from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.modules.combat.constants import (
    BattalionIds,
)
from contracts.settling_game.modules.mobs.game_structs import (
    SpawnConditions,
    AttackData,
)
from contracts.settling_game.modules.mobs.library import Mobs
from contracts.settling_game.modules.mobs.constants import (
    MOB_PLAYER_ATTACK_COOLDOWN_PERIOD,
)

// -----------------------------------
// Events
// -----------------------------------

@event
func MobSpawn(mob_id: felt, coordinates: Point, time_stamp: felt) {
}

@event
func MobArmyMetadata(mob_id: felt, army_data: ArmyData) {
}

@event
func MobSpawnOffering(caller: felt, mob_id: felt, resource_id: Uint256, resource_quantity: Uint256, time_stamp: felt) {
}

// -----------------------------------
// Storage
// -----------------------------------x

@storage_var
func mob_data_by_id(mob_id: felt) -> (army_data: ArmyData) {
}


@storage_var
func mob_spawn_conditions(mob_id: felt) -> (conditions: SpawnConditions) {
}

@storage_var
func mob_sacrifice(mob_id: felt, resource_id: Uint256) -> (resource_quantity: Uint256) {
}

@storage_var
func mob_attack_data(mob_id: felt, caller: felt) -> (attack_data: AttackData) {
}


// -----------------------------------
// EXTERNAL
// -----------------------------------

// @notice deposit resources towards mob spawn requirements
@external
func sacrifice_resources{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    mob_id: felt, resource_id: Uint256, resource_quantity: Uint256
) {
    alloc_locals;

    // TODO check requirements for mob for this resource so that
    // we can revert if they are depositing too much

    let (resources_address) = Module.get_external_contract_address(ExternalContractIds.Resources);
    let (caller) = get_caller_address();
    let (contract_address) = get_contract_address();

    let (local data: felt*) = alloc();
    assert data[0] = 0;

    IERC1155.safeTransferFrom(
        resources_address,
        caller,
        contract_address,
        resource_id,
        resource_quantity,
        1,
        data,
    );

    mob_sacrifice.write(mob_id, resource_id, resource_quantity);

    let (ts) = get_block_timestamp();
    MobSpawnOffering.emit(caller, mob_id, resource_id, resource_quantity, ts);

    return ();
}

// @notice spawns mob at supplied coordinates
@external
func spawn_mob{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    mob_id: felt
) {
    alloc_locals;

    let (spawn_conditions) = mob_spawn_conditions.read(mob_id);
    let has_required_resources = is_not_zero(spawn_conditions.resource_id.low + spawn_conditions.resource_id.high);

    with_attr error_message("Mobs: no spawn condition found") {
        assert_not_zero(has_required_resources);
    }

    with_attr error_message("Mobs: spawn conditions not met") {
        let (sacrificed_resources) = mob_sacrifice.read(
            mob_id, spawn_conditions.resource_id
        );
        assert_le(spawn_conditions.resource_quantity.low, sacrificed_resources.low);
    }

    // check spawn conditions
    with_attr error_message("Mobs: only one mob alive at a time") {
        let (army_data) = mob_data_by_id.read(mob_id);
        assert army_data.ArmyPacked = 0;
    }

    // TODO do something with sacrificed resources (split to treasury/module fee/burn/etc)

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
    MobSpawn.emit(mob_id, spawn_conditions.coordinates, ts);

    return ();
}

@external
func set_mob_army_data_and_emit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    mob_id: felt, 
    army_data: ArmyData, 
    caller: felt, 
    damage_inflicted: felt, 
    timestamp: felt,
) {
    // TODO restrict caller
    
    let (attack_data) = mob_attack_data.read(mob_id, caller);
    mob_attack_data.write(
        mob_id, 
        caller, 
        AttackData(
            attack_data.total_damage_inflicted + damage_inflicted, 
            timestamp,
        ),
    );

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
    return (conditions,);
}

@view
func get_mob_sacrifice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    mob_id: felt, resource_id: Uint256,
) -> (resource_quantity: Uint256) {
    let (resource_quantity) = mob_sacrifice.read(mob_id, resource_id);
    return (resource_quantity,);
}

@view
func get_mob_coordinates{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    mob_id: felt
) -> (coordinates: Point) {
    let (conditions) = mob_spawn_conditions.read(mob_id);
    return (conditions.coordinates,);
}

@view
func get_mob_health{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    mob_id: felt
) -> (health: felt) {
    let (army_data) = mob_data_by_id.read(mob_id);
    let (unpacked_army_data) = Combat.unpack_army(army_data.ArmyPacked);
    let (health) = Mobs.get_health_from_unpacked_army(unpacked_army_data);
    return (health,);
}

@view
func mob_can_be_attacked{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    mob_id: felt, caller: felt
) -> (yesno: felt) {
    alloc_locals;

    // TODO is spawned/alive
    let (mob_health) = get_mob_health(mob_id);
    if (mob_health == 0) {
        return (FALSE,);
    }

    // TODO attack cooldown?
    let (attack_data) = get_mob_attack_data(mob_id, caller);
    let (now) = get_block_timestamp();
    let diff = now - attack_data.last_attack_timestamp;
    let was_attacked_recently = is_le(diff, MOB_PLAYER_ATTACK_COOLDOWN_PERIOD);
    if (was_attacked_recently == TRUE) {
        return (FALSE,);
    }

    return (TRUE,);
}

@view
func get_mob_army_combat_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    mob_id: felt
) -> (mob_army_data: ArmyData) {
    let (army_data) = mob_data_by_id.read(mob_id);
    return (army_data,);
}

@view
func get_mob_attack_data{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
}(
    mob_id: felt, caller: felt
) -> (attack_data: AttackData) {
    let (attack_data) = mob_attack_data.read(mob_id, caller);
    return (attack_data,);
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