// -----------------------------------
// Custom logic for self healing mob

// MIT License
// -----------------------------------

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.bool import TRUE
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.math_cmp import is_le

from contracts.settling_game.modules.combat.library import Combat
from contracts.settling_game.utils.game_structs import (
    Army,
    Battalion,
    ArmyData,
)
from contracts.settling_game.utils.constants import DAY

const TIME_UNTIL_HEALTH_RESTORE = DAY / 10; // 1 day unit

// @notice restores army health based on last attack timestamp
@external
func modify_army_data_before_combat{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*
} (army_data: ArmyData) -> (modified_army_data: ArmyData) {
    alloc_locals;

    let (now) = get_block_timestamp();
    let diff = now - army_data.LastAttacked;
    let can_restore_health = is_le(TIME_UNTIL_HEALTH_RESTORE, diff);

    if (can_restore_health == TRUE) {
        let (unpacked_army) = Combat.unpack_army(army_data.ArmyPacked);
        let modified_unpacked_army = Army(
            Battalion(unpacked_army.LightCavalry.Quantity, 100),
            Battalion(unpacked_army.HeavyCavalry.Quantity, 100),
            Battalion(unpacked_army.Archer.Quantity, 100),
            Battalion(unpacked_army.Longbow.Quantity, 100),
            Battalion(unpacked_army.Mage.Quantity, 100),
            Battalion(unpacked_army.Arcanist.Quantity, 100),
            Battalion(unpacked_army.LightInfantry.Quantity, 100),
            Battalion(unpacked_army.HeavyInfantry.Quantity, 100)
        );
        let (modified_packed_army) = Combat.pack_army(modified_unpacked_army);

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;

        tempvar modified_army_data = ArmyData(
            modified_packed_army,
            army_data.LastAttacked,
            army_data.XP,
            army_data.Level,
            army_data.CallSign
        );
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        tempvar bitwise_ptr = bitwise_ptr;

        tempvar modified_army_data = army_data;
    }

    return (modified_army_data,);
}

// @notice no custom logic
// @dev interface needs to be implemented
@external
func modify_army_data_after_combat(army_data: ArmyData
) -> (modified_army_data: ArmyData) {
    return (army_data,);
}