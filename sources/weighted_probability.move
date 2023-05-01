module owner::weighted_probability {

    use std::signer;
    use std::string::{Self};
    use aptos_token::token::{TokenId};
    use owner::bone;
    use owner::shard;
    use owner::knife;
    use owner::pseudorandom::{rand_u64_range};

    friend owner::urn_to_earn;

    // error codes
    const EINVALID_MINT_TYPE: u64 = 1;

    // points of each part
    const ARM_1_P:     u8 = 1;
    const ARM_3_P:     u8 = 3;
    const LEG_6_P:     u8 = 6;
    const LEG_7_P:     u8 = 7;
    const HIP_13_P:    u8 = 13;
    const HIP_15_P:    u8 = 15;
    const CHEST_18_P:  u8 = 18;
    const SKULL_21_P:  u8 = 21;
    const SKULL_26_P:  u8 = 26;
    const G_ARM_2_P:   u8 = 2;
    const G_LEG_5_P:   u8 = 5;
    const G_LEG_7_P:   u8 = 7;
    const G_HIP_11_P:  u8 = 11;
    const G_HIP_14_P:  u8 = 14;
    const G_CHEST_17_P:u8 = 17;
    const G_SKULL_21_P:u8 = 21;
    
    // name: object name, value: weight
    const ARM_1_W:      u64 = 5;
    const ARM_3_W:      u64 = 100;
    const LEG_6_W:      u64 = 50;
    const LEG_7_W:      u64 = 60;
    const HIP_13_W:     u64 = 20;
    const HIP_15_W:     u64 = 40;
    const CHEST_18_W:   u64 = 55;
    const SKULL_21_W:   u64 = 10;
    const SKULL_26_W:   u64 = 25;
    const G_SHARD_W:    u64 = 180;
    const G_ARM_2_W:    u64 = 70;
    const G_LEG_5_W:    u64 = 20;
    const G_LEG_7_W:    u64 = 20;
    const G_HIP_11_W:   u64 = 10;
    const G_HIP_14_W:   u64 = 10;
    const G_CHEST_17_W: u64 = 10;
    const G_SKULL_21_W: u64 = 5;
    const KNIFE_W:      u64 = 130;
    const SUM_OF_W:     u64 = 820;

    // accumulate the weight
    struct AccumulateWeight has store, key {
        arm_1:      u64,
        arm_3:      u64,
        leg_6:      u64,
        leg_7:      u64,
        hip_13:     u64,
        hip_15:     u64,
        chest_18:   u64,
        skull_21:   u64,
        skull_26:   u64,
        g_shard:    u64,
        g_arm_2:    u64,
        g_leg_5:    u64,
        g_leg_7:    u64,
        g_hip_11:   u64,
        g_hip_14:   u64,
        g_chest_17: u64,
        g_skull_21: u64,
        knife:      u64,
    }

    public(friend) fun init_weighted_probability(sign: &signer) {
        init_accumulate_weight(sign);
    }

    fun init_accumulate_weight(sender: &signer) {
        // Don't run setup more than once
        if (exists<AccumulateWeight>(signer::address_of(sender))) {
            return
        };

        let aw = AccumulateWeight {
            arm_1: 0,
            arm_3: 0,
            leg_6: 0,
            leg_7: 0,
            hip_13: 0,
            hip_15: 0,
            chest_18: 0,
            skull_21: 0,
            skull_26: 0,
            g_shard: 0,
            g_arm_2: 0,
            g_leg_5: 0,
            g_leg_7: 0,
            g_hip_11: 0,
            g_hip_14: 0,
            g_chest_17: 0,
            g_skull_21: 0,
            knife: 0,
        };

        aw.arm_1 = ARM_1_W;
        aw.arm_3 = aw.arm_1 + ARM_3_W;
        aw.leg_6 = aw.arm_3 + LEG_6_W;
        aw.leg_7 = aw.leg_6 + LEG_7_W;
        aw.hip_13 = aw.leg_7 + HIP_13_W;
        aw.hip_15 = aw.hip_13 + HIP_15_W;
        aw.chest_18 = aw.hip_15 + CHEST_18_W;
        aw.skull_21 = aw.chest_18 + SKULL_21_W;
        aw.skull_26 = aw.skull_21 + SKULL_26_W;
        aw.g_shard = aw.skull_26 + G_SHARD_W;
        aw.g_arm_2 = aw.g_shard + G_ARM_2_W;
        aw.g_leg_5 = aw.g_arm_2 + G_LEG_5_W;
        aw.g_leg_7 = aw.g_leg_5 + G_LEG_7_W;
        aw.g_hip_11 = aw.g_leg_7 + G_HIP_11_W;
        aw.g_hip_14 = aw.g_hip_11 + G_HIP_14_W;
        aw.g_chest_17 = aw.g_hip_14 + G_CHEST_17_W;
        aw.g_skull_21 = aw.g_chest_17 + G_SKULL_21_W;
        aw.knife = aw.g_skull_21 + KNIFE_W;

        move_to(sender, aw);
    }

    
    public(friend) fun mint_by_weight(
        sign: &signer,
        resource: &signer,
    ): TokenId acquires AccumulateWeight {
        let aw = borrow_global<AccumulateWeight>(@owner);
        let rand_num = rand_u64_range(&signer::address_of(sign), 0, SUM_OF_W);

        if (rand_num < aw.arm_1) {
            bone::mint_bone(sign, resource, ARM_1_P, string::utf8(b"arm"))
        } else if (rand_num < aw.arm_3) {
            bone::mint_bone(sign, resource, ARM_3_P, string::utf8(b"arm"))
        } else if (rand_num < aw.leg_6) {
            bone::mint_bone(sign, resource, LEG_6_P, string::utf8(b"leg"))
        } else if (rand_num < aw.leg_7) {
            bone::mint_bone(sign, resource, LEG_7_P, string::utf8(b"leg"))
        } else if (rand_num < aw.hip_13) {
            bone::mint_bone(sign, resource, HIP_13_P, string::utf8(b"hip"))
        } else if (rand_num < aw.hip_15) {
            bone::mint_bone(sign, resource, HIP_15_P, string::utf8(b"hip"))
        } else if (rand_num < aw.chest_18) {
            bone::mint_bone(sign, resource, CHEST_18_P, string::utf8(b"chest"))
        } else if (rand_num < aw.skull_21) {
            bone::mint_bone(sign, resource, SKULL_21_P, string::utf8(b"skull"))
        } else if (rand_num < aw.skull_26) {
            bone::mint_bone(sign, resource, SKULL_26_P, string::utf8(b"skull"))
        } else if (rand_num < aw.g_shard) {
            shard::mint(sign, resource)
        } else if (rand_num < aw.g_arm_2) {
            bone::mint_bone(sign, resource, G_ARM_2_P, string::utf8(b"golden arm"))
        } else if (rand_num < aw.g_leg_5) {
            bone::mint_bone(sign, resource, G_LEG_5_P, string::utf8(b"golden leg"))
        } else if (rand_num < aw.g_leg_7) {
            bone::mint_bone(sign, resource, G_LEG_7_P, string::utf8(b"golden leg"))
        } else if (rand_num < aw.g_hip_11) {
            bone::mint_bone(sign, resource, G_HIP_11_P, string::utf8(b"golden hip"))
        } else if (rand_num < aw.g_hip_14) {
            bone::mint_bone(sign, resource, G_HIP_14_P, string::utf8(b"golden hip"))
        } else if (rand_num < aw.g_chest_17) {
            bone::mint_bone(sign, resource, G_CHEST_17_P, string::utf8(b"golden chest"))
        } else if (rand_num < aw.g_skull_21) {
            bone::mint_bone(sign, resource, G_SKULL_21_P, string::utf8(b"golden skull"))
        } else if (rand_num < aw.knife) {
            knife::mint(sign, resource)
        } else {
            abort EINVALID_MINT_TYPE
        }
    }
}