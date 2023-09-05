module owner::shovel {
    use std::signer;
    use std::string::{Self, String};
    use std::bcs;
    use aptos_token::token::{Self};

    const MAX_U64: u64 = 18446744073709551615;
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";

    friend owner::urn_to_earn;

    struct ShovelMinter has store, key {
        res_acct_addr: address,
        token_data_id: token::TokenDataId,
        collection: string::String,
        name: string::String,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;

    const TOKEN_NAME: vector<u8> = b"shovel";
    const TOKEN_URL: vector<u8> = b"https://6a42ouwg4jcg35owuyyupll6awryvbhg56oxwmmf3lnxyxqpsrma.arweave.net/8DmnUsbiRG311qYxR61-BaOKhObvnXsxhdrbfF4PlFg";

    public(friend) fun init_shovel(sender: &signer, resource: &signer, collection_name: String) {
        // Don't run setup more than once
        if (exists<ShovelMinter>(signer::address_of(sender))) {
            return
        };

        // create shovel token data
        let token_data_id = create_shovel_token_data(resource, collection_name);

        move_to(sender, ShovelMinter {
            res_acct_addr: signer::address_of(resource),
            token_data_id: token_data_id,
            collection: collection_name,
            name: string::utf8(TOKEN_NAME),
        });
    }

    fun create_shovel_token_data(resource: &signer, collection_name: String): token::TokenDataId {
        let collection_name = collection_name;
        let tokendata_name = string::utf8(TOKEN_NAME);
        let nft_maximum: u64 = 0; // unlimited shovel
        let description = string::utf8(b"just a shovel");
        let token_uri: string::String = string::utf8(TOKEN_URL);
        let royalty_payee_address: address = @owner;
        let royalty_points_denominator: u64 = 100;
        let royalty_points_numerator: u64 = 5;
        let token_mutate_config = token::create_token_mutability_config(
            &vector<bool>[ true, true, true, true, true ]); // max, uri, royalty, description, property
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


    public fun destroy_shovel(sender: &signer) acquires ShovelMinter {
        let shovel_minter = borrow_global<ShovelMinter>(@owner);
        token::burn(
            sender,
            shovel_minter.res_acct_addr,
            shovel_minter.collection,
            shovel_minter.name,
            0, // property version
            1, // amount
        );
    }

    public(friend) fun mint(_sign: &signer, resource: &signer, amount: u64): token::TokenId acquires ShovelMinter {
        let shovelMinter = borrow_global_mut<ShovelMinter>(@owner);
        // let resource = create_signer_with_capability(cap);

        let token_id = token::mint_token(resource, shovelMinter.token_data_id, amount);
        token_id
    }
}