module owner::knife {
    use std::signer;
    use std::string::{Self, String};
    use std::bcs;
    use std::option;
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_token::token::{Self, TokenId};
    use owner::iterable_table::{Self, borrow_iter, head_key, length};
    use owner::pseudorandom::{rand_u64_range_no_sender};
    use owner::urn;

    const ETABLE_EMPTY: u64 = 0;
    const ENO_VICTIM:   u64 = 1;

    const MAX_U64: u64 = 18446744073709551615;
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";

    friend owner::urn_to_earn;
    friend owner::weighted_probability;

    struct KnifeMinter has store, key {
        res_acct_addr: address,
        token_data_id: token::TokenDataId,
        collection: string::String,
        name: string::String,
        table: iterable_table::IterableTable<address, TokenId>,
    }

    struct RobHistory has store, key {
        been_robbed_events: EventHandle<BeenRobbedEvent>,
    }

    struct BeenRobbedEvent has drop, store {
        robber: address,
        success: bool,
        token_id: TokenId,
        amount: u8,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;

    const TOKEN_NAME: vector<u8> = b"knife";
    const TOKEN_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmbQuPgdA29Mf34Pqf2gJjqC63qYQX4KZF9e8xVffCZCqw/knife.jpg";

    public(friend) fun init_knife(sender: &signer, resource: &signer, collection_name: String) {
        // Don't run setup more than once
        if (exists<KnifeMinter>(signer::address_of(sender))) {
            return
        };

        // create knife token data
        let token_data_id = create_knife_token_data(resource, collection_name);

        move_to(sender, KnifeMinter {
            res_acct_addr: signer::address_of(resource),
            token_data_id: token_data_id,
            collection: collection_name,
            name: string::utf8(TOKEN_NAME),
            table: iterable_table::new(),
        });
    }

    fun create_knife_token_data(resource: &signer, collection_name: String): token::TokenDataId {
        let collection_name = collection_name;
        let tokendata_name = string::utf8(TOKEN_NAME);
        let nft_maximum: u64 = 0; // unlimited knife
        let description = string::utf8(b"just a knife");
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

    public entry fun create_rob_history_manually(sign: &signer) {
        create_rob_history(sign);
    }

    // TODO: when to call this function?
    // create RobHistory resource to enable showing the history of been robbed
    public fun create_rob_history(sign: &signer) {
        if (!exists<RobHistory>(signer::address_of(sign))) {
            move_to(sign, RobHistory {
                been_robbed_events: account::new_event_handle<BeenRobbedEvent>(sign),
            });
        }
    }

    public fun destroy_knife(sender: &signer) acquires KnifeMinter {
        let knife_minter = borrow_global<KnifeMinter>(@owner);
        token::burn(
            sender,
            knife_minter.res_acct_addr,
            knife_minter.collection,
            knife_minter.name,
            0, // property version
            1, // amount
        );
    }

    public(friend) fun mint(_sign: &signer, resource: &signer): TokenId acquires KnifeMinter {
        let knifeMinter = borrow_global_mut<KnifeMinter>(@owner);
        let amount = 1;
        let token_id = token::mint_token(resource, knifeMinter.token_data_id, amount);
        token_id
    }

    public(friend) fun add_victim(sender: &signer, urn: TokenId) acquires KnifeMinter {
        let km = borrow_global_mut<KnifeMinter>(@owner);
        let addr = signer::address_of(sender);

        
        if (!iterable_table::contains(&km.table, addr)) {
            // victim table length 10, TODO: determine the length
            if (iterable_table::length(&km.table) >= 10) {
                // remove 1 victim from head
                let head = iterable_table::head_key(&km.table);
                iterable_table::remove(&mut km.table, *option::borrow(&head));
            };

            iterable_table::add(&mut km.table, addr, urn);
        }
    }

    // public(friend) fun remove_victim(addr: address) acquires KnifeMinter {
    //     let km = borrow_global_mut<KnifeMinter>(@owner);
    //     // assert!(iterable_table::contains(&km.table, addr) ,ENO_VICTIM);
    //     iterable_table::remove(&mut km.table, addr);
    // }

    public(friend) fun contains_victim(addr: address): bool acquires KnifeMinter {
        let km = borrow_global<KnifeMinter>(@owner);
        return iterable_table::contains(&km.table, addr)
    }

    public(friend) fun random_rob(
        sender: &signer, 
        urn: TokenId,
        resource: &signer
    ):(TokenId, u8) acquires KnifeMinter, RobHistory {
        
        // burn knife token
        destroy_knife(sender);
        let km = borrow_global_mut<KnifeMinter>(@owner);
        let len = length<address, TokenId>(&km.table);
        assert!(len != 0, ETABLE_EMPTY);

        // get random index num
        let rand_num = rand_u64_range_no_sender(0, len);
        let key = head_key<address, TokenId>(&km.table);
        assert!(option::is_some(&key), 0);

        let i = 1;
        while (i < rand_num) {
            let (_, _, next) = borrow_iter<address, TokenId>(&km.table, *option::borrow(&key));
            key = next;
        };

        // key is the address been robbed, value is the urn token_id been robbed
        let val = iterable_table::remove<address, TokenId>(&mut km.table, *option::borrow(&key));
        let amount = urn::rand_drain(resource, *option::borrow(&key), val);
        urn = urn::fill(sender, resource, urn, amount);

        // emit been robbed event
        if (exists<RobHistory>(*option::borrow(&key))) {
            let brh = borrow_global_mut<RobHistory>(*option::borrow(&key));
            event::emit_event<BeenRobbedEvent>(
                &mut brh.been_robbed_events,
                BeenRobbedEvent { 
                    robber: signer::address_of(sender),
                    success: true, // TODO: implement rob failed
                    token_id: val,
                    amount: amount,
                },
            );
        };

        return (urn, amount)
    }

    public(friend) fun rob(
        sender: &signer, 
        urn: TokenId,
        victim_addr: address,
        vimtim_urn: TokenId,
        resource: &signer
    ):(TokenId, u8) acquires KnifeMinter, RobHistory {
        // burn knife token
        destroy_knife(sender);
        let km = borrow_global_mut<KnifeMinter>(@owner);
        let len = length<address, TokenId>(&km.table);
        assert!(len != 0, ETABLE_EMPTY);

        // rob
        let amount = urn::rand_drain(resource, victim_addr, vimtim_urn);
        urn = urn::fill(sender, resource, urn, amount);

        // emit been robbed event
        if (exists<RobHistory>(victim_addr)) {
            let brh = borrow_global_mut<RobHistory>(victim_addr);
            event::emit_event<BeenRobbedEvent>(
                &mut brh.been_robbed_events,
                BeenRobbedEvent { 
                    robber: signer::address_of(sender),
                    success: true, // TODO: implement rob failed
                    token_id: vimtim_urn,
                    amount: amount,
                },
            );
        };

        // TODO: add robber to victim table
        return (urn, amount)
    }

    #[test_only]
    public fun is_victim(addr: address): bool acquires KnifeMinter {
        let km = borrow_global<KnifeMinter>(@owner);
        return iterable_table::contains(&km.table, addr)
    }
}