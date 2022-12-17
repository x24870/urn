module owner::bone {
    use aptos_framework::account;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use std::bcs;
    use aptos_token::token::{Self};
    // use owner::urn_utils;
    use owner::pseudorandom;

    const MAX_U64: u64 = 18446744073709551615;
    friend owner::urn;

    struct BoneMinter has store, key {
        signer_cap: account::SignerCapability,
        skull_token_data_id: token::TokenDataId,
        chest_token_data_id: token::TokenDataId,
        hip_token_data_id: token::TokenDataId,
        leg_token_data_id: token::TokenDataId,
        arm_token_data_id: token::TokenDataId,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;

    const COLLECTION_NAME: vector<u8> = b"URN";
    // const TOKEN_NAME: vector<u8> = b"BONE";


    // const TOKEN_URL: vector<u8> = b"https://bone.jpg";
    const SKULL_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/skull.jpg";
    const CHEST_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/bone.jpg";
    const HIP_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/hip.jpg";
    const LEG_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/leg.jpg";
    const ARM_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/hand.jpg";


    public(friend) fun init(sender: &signer) {
        // Don't run setup more than once
        if (exists<BoneMinter>(signer::address_of(sender))) {
            return
        };

        // Create the resource account, so we can get ourselves as signer later
        // let (resource, signer_cap) = account::create_resource_account(sender, vector::empty());
        let (resource, signer_cap) = account::create_resource_account(sender, vector::singleton(1));

        // Set up NFT collection
        let collection_name = string::utf8(COLLECTION_NAME);
        let description = string::utf8(b"Dig your grandma and put to the urn");
        let collection_uri = string::utf8(b"https://urn.jpg");
        let maximum_supply = MAX_U64;
        let mutate_setting = vector<bool>[ false, true, false ]; // desc, max, uri
        token::create_collection(&resource, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        // create shovel token data
        let skull_token_data_id = create_bone_token_data(&resource, string::utf8(b"skull"), string::utf8(SKULL_URL));
        let chest_token_data_id = create_bone_token_data(&resource, string::utf8(b"chest"), string::utf8(CHEST_URL));
        let hip_token_data_id = create_bone_token_data(&resource, string::utf8(b"hip"), string::utf8(HIP_URL));
        let leg_token_data_id = create_bone_token_data(&resource, string::utf8(b"leg"), string::utf8(LEG_URL));
        let arm_token_data_id = create_bone_token_data(&resource, string::utf8(b"arm"), string::utf8(ARM_URL));

        move_to(sender, BoneMinter {
            signer_cap,
            skull_token_data_id,
            chest_token_data_id,
            hip_token_data_id,
            leg_token_data_id,
            arm_token_data_id,
        });
    }

    fun create_bone_token_data(resource: &signer, token_name: String, token_uri: String): token::TokenDataId {
        let collection_name = string::utf8(COLLECTION_NAME);
        // let tokendata_name = string::utf8(TOKEN_NAME);
        let nft_maximum: u64 = 0;
        let description = string::utf8(b"Your grandpa or grandma");
        // let token_uri: string::String = string::utf8(TOKEN_URL);
        let royalty_payee_address: address = @owner;
        let royalty_points_denominator: u64 = 100;
        let royalty_points_numerator: u64 = 5;
        let token_mutate_config = token::create_token_mutability_config(
            &vector<bool>[ false, true, false, false, true ]); // max, uri, royalty, description, property
        // let property_keys: vector<string::String> = vector::singleton(string::utf8(b"skull"));
        // let property_values: vector<vector<u8>> = vector::singleton(*string::bytes(
        //     &urn_utils::u64_to_hex_string(1))
        //     );
        // let property_types: vector<string::String> = vector::singleton(string::utf8(b"part"));
        let default_keys: vector<string::String> = vector::singleton(string::utf8(b"part"));
        let default_vals: vector<vector<u8>> = vector::singleton(bcs::to_bytes<string::String>(&string::utf8(b"arm")));
        let default_types: vector<string::String> = vector::singleton(string::utf8(b"vector<u8>"));

        let token_data_id = token::create_tokendata(
            resource,
            collection_name,
            // tokendata_name,
            token_name,
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
            // property_keys,
            // property_values,
            // property_types
        );

        return token_data_id
    }

    fun get_resource_signer(): signer acquires BoneMinter {
        account::create_signer_with_capability(&borrow_global<BoneMinter>(@owner).signer_cap)
    }

    public fun batch_mint(sign: &signer, num: u8) acquires BoneMinter {
        while (num > 0) {
            mint(sign);
            num = num - 1;
        }
    }

    public fun mint(sign: &signer) acquires BoneMinter { // TODO should only allows friend
        let sender = signer::address_of(sign);
        let resource = get_resource_signer();

        let minter = borrow_global_mut<BoneMinter>(@owner);

        let amount = 1;

        // mint
        let num = pseudorandom::rand_u64_range(&sender, 0, 100);
        let token_id: token::TokenId;
        if(num > 95) { // 5%
            token_id = token::mint_token(&resource, minter.skull_token_data_id, amount);
        } else if(num > 85) { // 10%
            token_id = token::mint_token(&resource, minter.chest_token_data_id, amount);
        } else if(num > 70) { // 15%
            token_id = token::mint_token(&resource, minter.hip_token_data_id, amount);
        } else if(num > 40) { // 30%
            token_id = token::mint_token(&resource, minter.leg_token_data_id, amount);
        }else { // 40%
            token_id = token::mint_token(&resource, minter.arm_token_data_id, amount);
        };
        
        token::opt_in_direct_transfer(sign, true);
        token::transfer(&resource, token_id, sender, amount);

        // let new_keys: vector<string::String> = vector::singleton(string::utf8(b"part"));
        // let new_types: vector<string::String> = vector::singleton(string::utf8(b"vector<u8>"));
        // let new_vals: vector<vector<u8>> = vector::singleton(bcs::to_bytes<string::String>(&string::utf8(b"skull")));
        // parts
        // let skull_vals: vector<vector<u8>> = vector::singleton(bcs::to_bytes<string::String>(&string::utf8(b"skull")));
        // let leg_vals: vector<vector<u8>> = vector::singleton(bcs::to_bytes<string::String>(&string::utf8(b"leg")));

        // let (creator_address, collection, name) = token::get_token_data_id_fields(&minter.bone_token_data_id);
        // let num = pseudorandom::rand_u64_range(&sender, 0, 100);        
        // if(num > 50 && num < 80) { // 30%
        //     token::mutate_token_properties(
        //     &resource, //creator
        //     // signer::address_of(&resource), //owner
        //     sender,
        //     creator_address, //creator
        //     collection, //collection
        //     name, //name
        //     0, // prop version
        //     1, // amount
        //     new_keys,
        //     leg_vals,
        //     new_types,
        // );
        // } else if(num >= 80 && num < 100) { // 20%
        //     token::mutate_token_properties(
        //     &resource, //creator
        //     // signer::address_of(&resource), //owner
        //     sender,
        //     creator_address, //creator
        //     collection, //collection
        //     name, //name
        //     0, // prop version
        //     1, // amount
        //     new_keys,
        //     skull_vals,
        //     new_types,
        // );
        // };

        // token::direct_transfer(&resource, sign, token_id, 1);
        // token::initialize_token_store(sign);
 
    }

    fun get_mutate_prop(part_num: u8): (vector<string::String>, vector<vector<u8>>, vector<string::String>){
        let new_keys: vector<string::String> = vector::empty<string::String>();
        let new_vals: vector<vector<u8>> = vector::empty<vector<u8>>();
        let new_types: vector<string::String> = vector::empty<string::String>();
        if (part_num == 1) {
            vector::push_back(&mut new_keys, string::utf8(b"part"));
            vector::push_back(&mut new_vals, bcs::to_bytes<string::String>(&string::utf8(b"leg")));
            vector::push_back(&mut new_types, string::utf8(b"vector<u8>"));
        };
        (new_keys, new_vals, new_types)
    }
}