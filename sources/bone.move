module owner::bone {
    use aptos_framework::account::{Self};
    use std::signer;
    use std::string::{Self, String};
    use aptos_token::token::{Self, TokenId};
    use aptos_framework::event::{Self, EventHandle};
    use std::bcs;
    use owner::pseudorandom::{rand_u8_range};
    use aptos_token::property_map::{Self};

    const MAX_U64: u64 = 18446744073709551615;
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";

    friend owner::urn_to_earn;
    friend owner::weighted_probability;

    struct MintEvent has store, drop {
        minter: address,
    }

    struct BoneMinter has store, key {
        res_acct_addr: address,
        collection: string::String,
        name: string::String,
        mint_event: EventHandle<MintEvent>,
        skull_token_data_id: token::TokenDataId,
        chest_token_data_id: token::TokenDataId,
        hip_token_data_id: token::TokenDataId,
        leg_token_data_id: token::TokenDataId,
        arm_token_data_id: token::TokenDataId,
        golden_skull_token_data_id: token::TokenDataId,
        golden_chest_token_data_id: token::TokenDataId,
        golden_hip_token_data_id: token::TokenDataId,
        golden_leg_token_data_id: token::TokenDataId,
        golden_arm_token_data_id: token::TokenDataId,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;
    const ENOT_OWN_THIS_TOKEN: u64 = 4;
    const ETOKEN_PROP_MISMATCH: u64 = 5;
    const EINVALID_BONE_PART: u64 = 6;

    const TOKEN_NAME: vector<u8> = b"bone";

    const SKULL_URL: vector<u8> = b"https://v4xxyxp44dli3zvkzpunkfu3fndxih3fhpwwpalhfwg4syjgagra.arweave.net/ry98Xfzg1o3mqsvo1RabK0d0H2U77WeBZy2NyWEmAaI";
    const CHEST_URL: vector<u8> = b"https://7tokwurasnk25hjwrvxlxzzg4n3toumofxwumpfnimucyavax3ea.arweave.net/_NyrUiCTVa6dNo1uu-cm43c3UY4t7UY8rUMoLAKgvsg";
    const HIP_URL: vector<u8> = b"https://fhmmvnetsu3plemyuwuz6vvwzf6g3kfom6d7mq5zet5bxlnipvpq.arweave.net/KdjKtJOVNvWRmKWpn1a2yXxtqK5nh_ZDuST6G62ofV8";
    const LEG_URL: vector<u8> = b"https://cdalk6xvuva5ga6fsqn5xlxluo3myizh46f5tajotjtt3olmmm2q.arweave.net/EMC1evWlQdMDxZQb267ro7bMIyfni9mBLppnPblsYzU";
    const ARM_URL: vector<u8> = b"https://llwl6rue3cqcl7umhelxlnhzyzd6zrppvxoy33p63tqhcd2zmzoq.arweave.net/Wuy_RoTYoCX-jDkXdbT5xkfsxe-t3Y3t_tzgcQ9ZZl0";
    const GOLDEN_SKULL_URL: vector<u8> = b"https://55muo5a3stnrim4obh3xg32fclcemzmemijpueuj4iksy5zf52ea.arweave.net/71lHdBuU2xQzjgn3c29FEsRGZYRiEvoSieIVLHcl7og";
    const GOLDEN_CHEST_URL: vector<u8> = b"https://lowky5ptxozjvh2nakz4w5cvhhgu225kmd6exb2icfxbcgu6pvja.arweave.net/W6ysdfO7spqfTQKzy3RVOc1Na6pg_EuHSBFuERqefVI"; 
    const GOLDEN_HIP_URL: vector<u8> = b"https://fm63sjau7yuyh7uvpplqv7cutx34gjcv74lhj4ga4ozdnpih7k6q.arweave.net/Kz25JBT-KYP-lXvXCvxUnffDJFX_FnTwwOOyNr0H-r0";
    const GOLDEN_LEG_URL: vector<u8> = b"https://skeg7acy54lxdloupzbeakocuzbkajyepcty4w4rwzc7jv2hindq.arweave.net/kohvgFjvF3Gt1H5CQCnCpkKgJwR4p45bkbZF9NdHQ0c";
    const GOLDEN_ARM_URL: vector<u8> = b"https://u3bllzquqmt4maxmbbhe2tisqusxqwu4kb7l6e7yrtzlcoaxc3na.arweave.net/psK15hSDJ8YC7AhOTU0ShSV4WpxQfr8T-IzysTgXFto";

    const POINT_PROP_NAME: vector<u8> = b"point";
    const MATERIAL_PROP_NAME: vector<u8> = b"material";
    const PART_PROP_NAME: vector<u8> = b"part";

    const SKULL: vector<u8> =   b"skull";
    const CHEST: vector<u8> =   b"chest";
    const HIP: vector<u8> =     b"hip";
    const LEG: vector<u8> =     b"leg";
    const ARM: vector<u8> =     b"arm";
    const G_SKULL: vector<u8> = b"golden skull";
    const G_CHEST: vector<u8> = b"golden chest";
    const G_HIP: vector<u8> =   b"golden hip";
    const G_LEG: vector<u8> =   b"golden leg";
    const G_ARM: vector<u8> =   b"golden arm";

    public(friend) fun init_bone(
        sender: &signer,
        resource: &signer,
        collection_name: String
    ) {
        // Don't run setup more than once
        if (exists<BoneMinter>(signer::address_of(sender))) {
            return
        };

        let is_golden = true;

        // create bone token data
        let skull_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(SKULL), string::utf8(SKULL_URL), !is_golden);
        let chest_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(CHEST), string::utf8(CHEST_URL), !is_golden);
        let hip_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(HIP), string::utf8(HIP_URL), !is_golden);
        let leg_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(LEG), string::utf8(LEG_URL), !is_golden);
        let arm_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(ARM), string::utf8(ARM_URL), !is_golden);
        // create golden bone token data
        let golden_skull_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(G_SKULL), string::utf8(GOLDEN_SKULL_URL), is_golden);
        let golden_chest_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(G_CHEST), string::utf8(GOLDEN_CHEST_URL), is_golden);
        let golden_hip_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(G_HIP), string::utf8(GOLDEN_HIP_URL), is_golden);
        let golden_leg_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(G_LEG), string::utf8(GOLDEN_LEG_URL), is_golden);
        let golden_arm_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(G_ARM), string::utf8(GOLDEN_ARM_URL), is_golden);

        move_to(sender, BoneMinter {
            res_acct_addr: signer::address_of(resource),
            collection: collection_name,
            name: string::utf8(b"bone"),
            mint_event: account::new_event_handle<MintEvent>(resource),
            skull_token_data_id: skull_token_data_id,
            chest_token_data_id: chest_token_data_id,
            hip_token_data_id: hip_token_data_id,
            leg_token_data_id: leg_token_data_id,
            arm_token_data_id: arm_token_data_id,
            golden_skull_token_data_id: golden_skull_token_data_id,
            golden_chest_token_data_id: golden_chest_token_data_id,
            golden_hip_token_data_id: golden_hip_token_data_id,
            golden_leg_token_data_id: golden_leg_token_data_id,
            golden_arm_token_data_id: golden_arm_token_data_id,
        });
    }

    fun create_bone_token_data(
        resource: &signer, 
        collection_name: String, 
        tokendata_name: String,
        token_uri: String,
        is_golden: bool,
    ): token::TokenDataId {
        let nft_maximum: u64 = 0;
        let description = string::utf8(b"just a bone");
        let royalty_payee_address: address = @owner;
        let royalty_points_denominator: u64 = 100;
        let royalty_points_numerator: u64 = 5;
        let token_mutate_config = token::create_token_mutability_config(
            &vector<bool>[ true, true, true, true, true ]); // max, uri, royalty, description, property
        let material: String;
        if (is_golden) {
            material = string::utf8(b"gold");
        } else {
            material = string::utf8(b"calcium");
        };

        let default_keys = vector<String>[
            string::utf8(PART_PROP_NAME), 
            string::utf8(MATERIAL_PROP_NAME), 
            string::utf8(POINT_PROP_NAME), 
            string::utf8(BURNABLE_BY_OWNER)
        ];
        let default_vals = vector<vector<u8>>[
            bcs::to_bytes<string::String>(&tokendata_name), 
            bcs::to_bytes<string::String>(&material), 
            bcs::to_bytes<u8>(&0), 
            bcs::to_bytes<bool>(&true)
        ];
        let default_types = vector<String>[
            string::utf8(b"0x1::string::String"),
            string::utf8(b"0x1::string::String"),
            string::utf8(b"u8"), 
            string::utf8(b"bool")
        ];
        let token_data_id = token::create_tokendata(
            resource,
            collection_name,
            tokendata_name,
            description,
            nft_maximum,
            token_uri,
            royalty_payee_address,
            royalty_points_denominator,
            royalty_points_numerator,
            token_mutate_config,
            default_keys,
            default_vals,
            default_types,
        );

        return token_data_id
    }

    // mint bone or golden bone
    public(friend) fun mint(
        sign: &signer,
        resource: &signer,
        point: u8,
        part: String,
    ): TokenId acquires BoneMinter {
        let boneMinter = borrow_global_mut<BoneMinter>(@owner);
        let amount = 1;
        let signer_addr = signer::address_of(sign);

        let token_data_id = get_bone_token_data_id(part, boneMinter);
        let token_id = token::mint_token(resource, token_data_id, amount);
    
        // emit mint bone event
        event::emit_event<MintEvent>(
            &mut boneMinter.mint_event,
            MintEvent {
                minter: signer_addr,
            }
        );

        // rand point
        let keys = vector<String>[string::utf8(POINT_PROP_NAME)];
        let vals = vector<vector<u8>>[bcs::to_bytes<u8>(&point)];
        let types = vector<String>[string::utf8(b"u8")];
        
        token_id = token::mutate_one_token(
            resource, 
            signer::address_of(resource), // token haven't transfered
            token_id,
            keys,
            vals,
            types
        );

        token_id
    }

    fun get_bone_token_data_id(part: String, bm: &mut BoneMinter): token::TokenDataId {
        if (part == string::utf8(ARM)) {
            return bm.arm_token_data_id
        } else if (part == string::utf8(LEG)) {
            return bm.leg_token_data_id
        } else if (part == string::utf8(HIP)) {
            return bm.hip_token_data_id
        } else if (part == string::utf8(CHEST)) {
            return bm.chest_token_data_id
        } else if (part == string::utf8(SKULL)) {
            return bm.skull_token_data_id
        } else if (part == string::utf8(G_ARM)) {
            return bm.golden_arm_token_data_id
        } else if (part == string::utf8(G_LEG)) {
            return bm.golden_leg_token_data_id
        } else if (part == string::utf8(G_HIP)) {
            return bm.golden_hip_token_data_id
        } else if (part == string::utf8(G_CHEST)) {
            return bm.golden_chest_token_data_id
        } else if (part == string::utf8(G_SKULL)) {
            return bm.golden_skull_token_data_id
        } else {
            abort EINVALID_BONE_PART
        }
    }

    public fun get_bone_point(token_id: TokenId, token_owner: address): u8 {
        let balance = token::balance_of(token_owner, token_id);
        assert!(balance != 0, ENOT_OWN_THIS_TOKEN);
        let properties = token::get_property_map(token_owner, token_id);
        let point = property_map::read_u8(&properties, &string::utf8(POINT_PROP_NAME));
        point
    }

    public fun get_bone_material(token_id: TokenId, token_owner: address): String {
        let balance = token::balance_of(token_owner, token_id);
        assert!(balance != 0, ENOT_OWN_THIS_TOKEN);
        let properties = token::get_property_map(token_owner, token_id);
        let material = property_map::read_string(&properties, &string::utf8(MATERIAL_PROP_NAME));
        material
    }

    public fun is_golden_bone(token_id: TokenId, token_owner: address): bool {
        get_bone_material(token_id, token_owner) == string::utf8(b"gold")
    }

    public(friend) fun burn_bone(
        sign: &signer, token_id: TokenId
    ): u8 {
        let point = get_bone_point(token_id, signer::address_of(sign));
        let (
            creator_addr, 
            collection, 
            name, 
            prop_ver
            ) = token::get_token_id_fields(&token_id);

        token::burn(
            sign,
            creator_addr,
            collection,
            name,
            prop_ver,
            1,
        );
        point
    }

    #[test_only]
    public(friend) fun mint_50point_skull(
        sign: &signer, resource: &signer
    ): TokenId acquires BoneMinter {
        assert!(signer::address_of(sign)==@owner, ENOT_AUTHORIZED);

        let boneMinter = borrow_global_mut<BoneMinter>(@owner);
        let token_id = token::mint_token(resource, boneMinter.skull_token_data_id, 1);
    
        // rand point
        let keys = vector<String>[string::utf8(POINT_PROP_NAME)];
        let vals = vector<vector<u8>>[bcs::to_bytes<u8>(&50)];
        let types = vector<String>[string::utf8(b"u8")];
        
        token_id = token::mutate_one_token(
            resource, 
            signer::address_of(resource), // token haven't transfered
            token_id,
            keys,
            vals,
            types
        );

        token_id
    }

    #[test_only]
    public(friend) fun mint_bone(
        sign: &signer,
        resource: &signer,
    ): TokenId acquires BoneMinter {
        let boneMinter = borrow_global_mut<BoneMinter>(@owner);
        let amount = 1;
        let signer_addr = signer::address_of(sign);

        let token_data_id = rand_bone(&signer_addr, boneMinter);
        let token_id = token::mint_token(resource, token_data_id, amount);
    
        // emit mint bone event
        event::emit_event<MintEvent>(
            &mut boneMinter.mint_event,
            MintEvent {
                minter: signer_addr,
            }
        );

        // rand point
        let point = rand_u8_range(&signer_addr, 0, 100);
        let keys = vector<String>[string::utf8(POINT_PROP_NAME)];
        let vals = vector<vector<u8>>[bcs::to_bytes<u8>(&point)];
        let types = vector<String>[string::utf8(b"u8")];
        
        token_id = token::mutate_one_token(
            resource, 
            signer::address_of(resource), // token haven't transfered
            token_id,
            keys,
            vals,
            types
        );

        token_id
    }

    #[test_only]
        public(friend) fun mint_golden_bone(
        sign: &signer,
        resource: &signer,
    ): TokenId acquires BoneMinter {
        let boneMinter = borrow_global_mut<BoneMinter>(@owner);
        let amount = 1;
        let signer_addr = signer::address_of(sign);

        let token_data_id = rand_golden_bone(&signer_addr, boneMinter);
        let token_id = token::mint_token(resource, token_data_id, amount);
    
        // emit mint bone event
        event::emit_event<MintEvent>(
            &mut boneMinter.mint_event,
            MintEvent {
                minter: signer_addr,
            }
        );

        // rand point
        let point = rand_u8_range(&signer_addr, 0, 100);
        let keys = vector<String>[
            string::utf8(POINT_PROP_NAME), 
            ];
        let vals = vector<vector<u8>>[
            bcs::to_bytes<u8>(&point), 
            ];
        let types = vector<String>[
            string::utf8(b"u8"), 
            ];
        
        token_id = token::mutate_one_token(
            resource, 
            signer::address_of(resource), // token haven't transfered
            token_id,
            keys,
            vals,
            types
        );

        token_id
    }

    #[test_only]
    fun rand_bone(addr: &address, bm: &mut BoneMinter): token::TokenDataId {
        let r = rand_u8_range(addr, 0, 100);
        if (r < 20) {
            return bm.arm_token_data_id
        } else if (r < 40) {
            return bm.leg_token_data_id
        } else if (r < 60) {
            return bm.hip_token_data_id
        } else if (r < 80) {
            return bm.chest_token_data_id
        } else {
            return bm.skull_token_data_id
        }
    }

    #[test_only]
    fun rand_golden_bone(addr: &address, bm: &mut BoneMinter): token::TokenDataId {
        let r = rand_u8_range(addr, 0, 100);
        if (r < 20) {
            return bm.golden_arm_token_data_id
        } else if (r < 40) {
            return bm.golden_leg_token_data_id
        } else if (r < 60) {
            return bm.golden_hip_token_data_id
        } else if (r < 80) {
            return bm.golden_chest_token_data_id
        } else {
            return bm.golden_skull_token_data_id
        }
    }

}