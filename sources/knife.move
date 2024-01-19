module owner::knife {
    use std::signer;
    use std::string::{Self, String};
    use std::bcs;
    use std::option;
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_token::token::{Self, TokenId};
    use owner::iterable_table::{Self, borrow_iter, head_key, length};
    use owner::pseudorandom::{rand_u64_range_no_sender, rand_u8_range_no_sender};
    use owner::urn;

    const ETABLE_EMPTY:  u64 = 0;
    const ENO_VICTIM:    u64 = 1;
    const EMSG_TOO_LONG: u64 = 2;

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
        msg: string::String,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;

    const TOKEN_NAME: vector<u8> = b"knife";
    const TOKEN_URL: vector<u8> = b"https://5diky5ui3jeatqn2e22ymjr3h6m6uzso6exwk4oimb4rjbblxqba.arweave.net/6NCsdojaSAnBuia1hiY7P5nqZk7xL2VxyGB5FIQrvAI";

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
            // victim table length 1000, TODO: determine the length
            if (iterable_table::length(&km.table) >= 1000) {
                // remove 1 victim from head
                let head = iterable_table::head_key(&km.table);
                iterable_table::remove(&mut km.table, *option::borrow(&head));
            };

            iterable_table::add(&mut km.table, addr, urn);
        }
    }

    public(friend) fun remove_victim(addr: address) acquires KnifeMinter {
        let km = borrow_global_mut<KnifeMinter>(@owner);
        // assert!(iterable_table::contains(&km.table, addr) ,ENO_VICTIM);
        if (!iterable_table::contains(&km.table, addr)) {
            return
        };
        iterable_table::remove(&mut km.table, addr);
    }

    public(friend) fun contains_victim(addr: address): bool acquires KnifeMinter {
        let km = borrow_global<KnifeMinter>(@owner);
        return iterable_table::contains(&km.table, addr)
    }

    public(friend) fun random_rob(
        sender: &signer, 
        urn: TokenId,
        resource: &signer,
        msg: String
    ):(TokenId, u8, address, TokenId) acquires KnifeMinter, RobHistory {
        // check msg length
        assert!(string::length(&msg) < 256, EMSG_TOO_LONG);
        
        // burn knife token
        destroy_knife(sender);
        let km = borrow_global_mut<KnifeMinter>(@owner);
        let len = length<address, TokenId>(&km.table);
        assert!(len != 0, ETABLE_EMPTY);

        // get random index num
        let rand_num = rand_u64_range_no_sender(0, len);
        let key = head_key<address, TokenId>(&km.table);
        assert!(option::is_some(&key), 0);

        let i = 0;
        while (i < rand_num) {
            let (_, _, next) = borrow_iter<address, TokenId>(&km.table, *option::borrow(&key));
            key = next;
            i = i + 1;
        };

        // determine if the rob will success
        // let successed = rand_u8_range_no_sender(0, 100) > 10; // TODO: determine the success rate
        let successed = true;
        let victim_urn = token::create_token_id(
            km.token_data_id,
            0, // property version
        );

        // key is the address been robbed, value is the urn token_id been robbed
        let victim_addr = *option::borrow(&key);
        if (!iterable_table::contains(&km.table, victim_addr)) {
            successed = false;
        } else {
            victim_urn = iterable_table::remove<address, TokenId>(&mut km.table, victim_addr);
            // check if the victim owns the urn
            if (token::balance_of(victim_addr, victim_urn) == 0) {
                successed = false;
            };
        };

        let amount: u8;
        if (successed) {
            // success
            amount = urn::rand_drain(resource, victim_addr, victim_urn);

            let fillness = urn::get_ash_fullness(victim_urn, victim_addr);
            if (fillness + amount > 100) {
                amount = 100 - fillness;
            };
            urn = urn::fill(sender, resource, urn, amount);
        } else {
            // failed, robber will lose random amount of ash in the urn
            // amount = urn::rand_drain(resource, signer::address_of(sender), urn);
            amount = 0;
        };

        // emit been robbed event
        if (exists<RobHistory>(victim_addr)) {
            let brh = borrow_global_mut<RobHistory>(victim_addr);
            event::emit_event<BeenRobbedEvent>(
                &mut brh.been_robbed_events,
                BeenRobbedEvent { 
                    robber: signer::address_of(sender),
                    success: successed, // TODO: implement rob failed
                    token_id: victim_urn,
                    amount: amount,
                    msg: msg,
                },
            );
        };

        add_victim(sender, urn);

        return (urn, amount, victim_addr, victim_urn)
    }

    public(friend) fun rob(
        sender: &signer, 
        urn: TokenId,
        victim_addr: address,
        vimtim_urn: TokenId,
        resource: &signer,
        msg: String
    ):(TokenId, u8) acquires KnifeMinter, RobHistory {
        // check msg length
        assert!(string::length(&msg) < 256, EMSG_TOO_LONG);

        // burn knife token
        destroy_knife(sender);
        let km = borrow_global_mut<KnifeMinter>(@owner);
        let len = length<address, TokenId>(&km.table);
        assert!(len != 0, ETABLE_EMPTY);

        // determine if the rob will success
        // let successed = rand_u8_range_no_sender(0, 100) > 10; // TODO: determine the success rate
        let successed = true;
        let amount: u8;
        if (successed) {
            // success
            amount = urn::rand_drain(resource, victim_addr, vimtim_urn);
            urn = urn::fill(sender, resource, urn, amount);
        } else {
            // failed, robber will lose random amount of ash in the urn
            amount = urn::rand_drain(resource, signer::address_of(sender), urn);
        };

        // emit been robbed event
        if (exists<RobHistory>(victim_addr)) {
            let brh = borrow_global_mut<RobHistory>(victim_addr);
            event::emit_event<BeenRobbedEvent>(
                &mut brh.been_robbed_events,
                BeenRobbedEvent { 
                    robber: signer::address_of(sender),
                    success: successed, // TODO: implement rob failed
                    token_id: vimtim_urn,
                    amount: amount,
                    msg: msg,
                },
            );
        };

        add_victim(sender, urn);
        
        return (urn, amount)
    }

    #[view]
    public fun get_victims():(u64, vector<address>, vector<u64>) acquires KnifeMinter {
        let km = borrow_global<KnifeMinter>(@owner);
        let len = length<address, TokenId>(&km.table);
        let addrs = vector::empty<address>();
        let urn_prop_nums = vector::empty<u64>();

        let key = head_key<address, TokenId>(&km.table);
        let i = 0;
        while (i < len) {
            let (urn, _, next) = borrow_iter<address, TokenId>(&km.table, *option::borrow(&key));
            vector::push_back(&mut addrs, *option::borrow(&key));
           let (_, _, _, prop_ver) = token::get_token_id_fields(urn);
            vector::push_back(&mut urn_prop_nums, prop_ver);
            // let (_, _, next) = borrow_iter<address, TokenId>(&km.table, *option::borrow(&key));
            key = next;
            i = i + 1;
        };
        return (len, addrs, urn_prop_nums)
    }

    #[test_only]
    public fun is_victim(addr: address): bool acquires KnifeMinter {
        let km = borrow_global<KnifeMinter>(@owner);
        return iterable_table::contains(&km.table, addr)
    }
}