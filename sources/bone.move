module owner::bone {
    use aptos_framework::account;
    use std::signer;
    use std::string::{Self};
    use std::vector;
    use aptos_token::token::{Self};
    use owner::urn_utils;

    const MAX_U64: u64 = 18446744073709551615;


    struct BoneMinter has store, key {
        signer_cap: account::SignerCapability,
        bone_token_data_id: token::TokenDataId,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;

    const COLLECTION_NAME: vector<u8> = b"URN";
    const TOKEN_NAME: vector<u8> = b"BONE";

    const TOKEN_URL: vector<u8> = b"https://bone.jpg";

    fun init_module(sender: &signer) {
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
        let bone_token_data_id = create_bone_token_data(&resource);

        move_to(sender, BoneMinter {
            signer_cap,
            bone_token_data_id,
        });
    }

    fun create_bone_token_data(resource: &signer): token::TokenDataId {
        let collection_name = string::utf8(COLLECTION_NAME);
        let tokendata_name = string::utf8(TOKEN_NAME);
        let nft_maximum: u64 = 0;
        let description = string::utf8(b"Your grandpa or grandma");
        let token_uri: string::String = string::utf8(TOKEN_URL);
        let royalty_payee_address: address = @owner;
        let royalty_points_denominator: u64 = 100;
        let royalty_points_numerator: u64 = 5;
        let token_mutate_config = token::create_token_mutability_config(
            &vector<bool>[ false, true, false, false, true ]); // max, uri, royalty, description, property
        let property_keys: vector<string::String> = vector::singleton(string::utf8(b"skull"));
        let property_values: vector<vector<u8>> = vector::singleton(*string::bytes(
            &urn_utils::u64_to_hex_string(1))
            );
        let property_types: vector<string::String> = vector::singleton(string::utf8(b"part"));

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
            property_keys,
            property_values,
            property_types
        );

        return token_data_id
    }

    fun get_resource_signer(): signer acquires BoneMinter {
        account::create_signer_with_capability(&borrow_global<BoneMinter>(@owner).signer_cap)
    }

    public fun mint(sign: &signer) acquires BoneMinter { // TODO should only allows friend
        let sender = signer::address_of(sign);
        let resource = get_resource_signer();

        let minter = borrow_global_mut<BoneMinter>(@owner);

        let amount = 1;
        let token_id = token::mint_token(&resource, minter.bone_token_data_id, amount);

        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        token::transfer(&resource, token_id, sender, amount);
    }

}