module owner::shard {
    use std::signer;
    use std::string::{Self, String};
    use std::bcs;
    use aptos_token::token::{Self};

    const MAX_U64: u64 = 18446744073709551615;
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";

    friend owner::urn_to_earn;

    struct ShardMinter has store, key {
        res_acct_addr: address,
        token_data_id: token::TokenDataId,
        collection: string::String,
        name: string::String,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;
    const EINSUFFICIENT_BALANCE: u64 = 4;

    const TOKEN_NAME: vector<u8> = b"SHARD";
    const TOKEN_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/shard.jpg";

    public(friend) fun init_shard(sender: &signer, resource: &signer, collection_name: String) {
        // Don't run setup more than once
        if (exists<ShardMinter>(signer::address_of(sender))) {
            return
        };

        // create shard token data
        let token_data_id = create_shard_token_data(resource, collection_name);

        move_to(sender, ShardMinter {
            res_acct_addr: signer::address_of(resource),
            token_data_id: token_data_id,
            collection: collection_name,
            name: string::utf8(TOKEN_NAME),
        });
    }

    fun create_shard_token_data(resource: &signer, collection_name: String): token::TokenDataId {
        let collection_name = collection_name;
        let tokendata_name = string::utf8(TOKEN_NAME);
        let nft_maximum: u64 = 0; // unlimited shard
        let description = string::utf8(b"just a shard");
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


    public fun destroy_ten_shards(sign: &signer) acquires ShardMinter {
        let shard_minter = borrow_global<ShardMinter>(@owner);
        
        // check user has enough shards
        let shard_token_id = token::create_token_id_raw(
            shard_minter.res_acct_addr,
            shard_minter.collection,
            shard_minter.name,
            0, // property version
        );
        assert!(token::balance_of(signer::address_of(sign), shard_token_id) >= 1, EINSUFFICIENT_BALANCE);

        // burn 10 shards
        token::burn(
            sign,
            shard_minter.res_acct_addr,
            shard_minter.collection,
            shard_minter.name,
            0, // property version
            10, // amount
        );
    }

    public(friend) fun mint(_sign: &signer, resource: &signer): token::TokenId acquires ShardMinter {
        let shardMinter = borrow_global_mut<ShardMinter>(@owner);

        let amount = 1;
        let token_id = token::mint_token(resource, shardMinter.token_data_id, amount);
        token_id
    }
}