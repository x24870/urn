module owner::shovel {
    use aptos_framework::account;
    // use aptos_std::table;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use std::bcs;
    use aptos_token::token::{Self};
    // use owner::urn_utils;
    // use aptos_framework::event::{Self};

    const MAX_U64: u64 = 18446744073709551615;
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";

    friend owner::urn;

    struct ShovelMinter has store, key {
        signer_cap: account::SignerCapability,
        res_acct_addr: address,
        token_data_id: token::TokenDataId,
        collection: string::String,
        name: string::String,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;

    const COLLECTION_NAME: vector<u8> = b"URN";
    const TOKEN_NAME: vector<u8> = b"SHOVEL";

    const TOKEN_URL: vector<u8> = b"https://shovel.jpg";

    public(friend) fun init(sender: &signer) {
        // Don't run setup more than once
        if (exists<ShovelMinter>(signer::address_of(sender))) {
            return
        };

        // Create the resource account, so we can get ourselves as signer later
        let (resource, signer_cap) = account::create_resource_account(sender, vector::empty());

        // Set up NFT collection
        let collection_name = string::utf8(COLLECTION_NAME);
        let description = string::utf8(b"Dig your grandma and put to the urn");
        let collection_uri = string::utf8(b"https://urn.jpg");
        let maximum_supply = MAX_U64;
        let mutate_setting = vector<bool>[ false, true, false ]; // desc, max, uri
        token::create_collection(&resource, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        // create shovel token data
        let token_data_id = create_shovel_token_data(&resource);

        move_to(sender, ShovelMinter {
            signer_cap: signer_cap,
            res_acct_addr: signer::address_of(&resource),
            token_data_id: token_data_id,
            collection: collection_name,
            name: string::utf8(TOKEN_NAME),
        });
    }

    fun create_shovel_token_data(resource: &signer): token::TokenDataId {
        let collection_name = string::utf8(COLLECTION_NAME);
        let tokendata_name = string::utf8(TOKEN_NAME);
        let nft_maximum: u64 = 0; // unlimited shovel
        let description = string::utf8(b"just a shovel");
        let token_uri: string::String = string::utf8(TOKEN_URL);
        let royalty_payee_address: address = @owner;
        let royalty_points_denominator: u64 = 100;
        let royalty_points_numerator: u64 = 5;
        let token_mutate_config = token::create_token_mutability_config(
            &vector<bool>[ false, true, false, false, true ]); // max, uri, royalty, description, property
        // let property_keys: vector<string::String> = vector::singleton(string::utf8(b"iron")); // iron
        // let property_values: vector<vector<u8>> = vector::singleton(*string::bytes(
        //     &urn_utils::u64_to_hex_string(1))
        //     );
        // let property_types: vector<string::String> = vector::singleton(string::utf8(b"material")); // material
        let property_keys = vector<String>[string::utf8(BURNABLE_BY_OWNER)];
        let property_values = vector<vector<u8>>[bcs::to_bytes<bool>(&true)];
        let property_types = vector<String>[string::utf8(b"bool")];

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

    public(friend) fun get_resource_signer(): signer acquires ShovelMinter {
        account::create_signer_with_capability(&borrow_global<ShovelMinter>(@owner).signer_cap)
    }

    public fun destroy_shovel(sender: &signer) acquires ShovelMinter {
        // let token_data_id = shovel::get_token_data_id();
        // let resource = get_resource_signer();
        let shovel_minter = borrow_global<ShovelMinter>(@owner);
        // let sender_addr = signer::address_of(sender);
        // burn 1 shovel
        // token::burn_by_creator(
        //     &resource,
        //     sender_addr,
        //     shovel_minter.collection,
        //     shovel_minter.name,
        //     0, //property version
        //     1 , //amount
        //     );

        token::burn(
            sender,
            shovel_minter.res_acct_addr,
            shovel_minter.collection,
            shovel_minter.name,
            0,
            1,
        );
    }

    const HEX_SYMBOLS: vector<u8> = b"0123456789abcdef";

    public entry fun mint(sign: &signer) acquires ShovelMinter {
        let sender = signer::address_of(sign);
        let resource = get_resource_signer();

        let sm = borrow_global_mut<ShovelMinter>(@owner);

        let amount = 5;
        let token_id = token::mint_token(&resource, sm.token_data_id, amount); // TODO random shovel bundle

        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        token::transfer(&resource, token_id, sender, amount);
    }
}