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
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;
    const ENOT_OWN_THIS_TOKEN: u64 = 4;
    const ETOKEN_PROP_MISMATCH: u64 = 5;

    const TOKEN_NAME: vector<u8> = b"BONE";
    const TOKEN_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/urn.jpg";

    // const TOKEN_URL: vector<u8> = b"https://bone.jpg";
    const SKULL_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/skull.jpg";
    const CHEST_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/bone.jpg";
    const HIP_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/hip.jpg";
    const LEG_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/leg.jpg";
    const ARM_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/hand.jpg";


    public(friend) fun init_bone(
        sender: &signer,
        resource: &signer,
        collection_name: String
    ) {
        // Don't run setup more than once
        if (exists<BoneMinter>(signer::address_of(sender))) {
            return
        };

        // create shovel token data
        let skull_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(b"skull"), string::utf8(SKULL_URL));
        let chest_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(b"chest"), string::utf8(CHEST_URL));
        let hip_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(b"hip"), string::utf8(HIP_URL));
        let leg_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(b"leg"), string::utf8(LEG_URL));
        let arm_token_data_id = create_bone_token_data(
            resource, collection_name, string::utf8(b"arm"), string::utf8(ARM_URL));

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
        });
    }

    fun create_bone_token_data(
        resource: &signer, 
        collection_name: String, 
        tokendata_name: String,
        token_uri: String
    ): token::TokenDataId {
        let nft_maximum: u64 = 0;
        let description = string::utf8(b"just a bone");
        let royalty_payee_address: address = @owner;
        let royalty_points_denominator: u64 = 100;
        let royalty_points_numerator: u64 = 5;
        let token_mutate_config = token::create_token_mutability_config(
            &vector<bool>[ true, true, true, true, true ]); // max, uri, royalty, description, property
        let default_keys = vector<String>[
            string::utf8(b"PART"), 
            string::utf8(b"MATERIAL"), 
            string::utf8(b"POINT"), 
            string::utf8(BURNABLE_BY_OWNER)
        ];
        let default_vals = vector<vector<u8>>[
            bcs::to_bytes<string::String>(&string::utf8(b"arm")), 
            bcs::to_bytes<string::String>(&string::utf8(b"calcium")), 
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

    // public fun batch_mint(sign: &signer, num: u8) acquires BoneMinter {
    //     while (num > 0) {
    //         mint(sign);
    //         num = num - 1;
    //     }
    // }

    public(friend) fun mint(
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
        let keys = vector<String>[string::utf8(b"POINT")];
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

    public(friend) fun mint_golden_bone(
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
        let keys = vector<String>[
            string::utf8(b"POINT"), 
            string::utf8(b"MATERIAL")
            ];
        let vals = vector<vector<u8>>[
            bcs::to_bytes<u8>(&point), 
            bcs::to_bytes<string::String>(&string::utf8(b"gold"))
            ];
        let types = vector<String>[
            string::utf8(b"u8"), 
            string::utf8(b"0x1::string::String")
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

    fun rand_bone(addr: &address, bm: &mut BoneMinter): token::TokenDataId {
        // TODO adjust rate of each part
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

    public fun get_bone_point(token_id: TokenId, token_owner: address): u8 {
        let balance = token::balance_of(token_owner, token_id);
        assert!(balance != 0, ENOT_OWN_THIS_TOKEN);
        let properties = token::get_property_map(token_owner, token_id);
        let point = property_map::read_u8(&properties, &string::utf8(b"POINT"));
        point
    }

    public fun get_bone_material(token_id: TokenId, token_owner: address): String {
        let balance = token::balance_of(token_owner, token_id);
        assert!(balance != 0, ENOT_OWN_THIS_TOKEN);
        let properties = token::get_property_map(token_owner, token_id);
        let material = property_map::read_string(&properties, &string::utf8(b"MATERIAL"));
        material
    }

    public fun is_golden_bone(token_id: TokenId, token_owner: address) {
        assert!(get_bone_material(token_id, token_owner) == string::utf8(b"gold"), ETOKEN_PROP_MISMATCH);
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
}