module owner::urn_to_earn {
    use aptos_framework::account::{Self, create_signer_with_capability};
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use aptos_token::token::{Self};
    // use std::bcs;
    // use aptos_framework::event::{Self, EventHandle};
    // use aptos_token::property_map::{Self};
    use owner::shovel;
    // use owner::bone;

    struct UrnToEarnConfig has key {
        description: String,
        name: String,
        uri: String,
        maximum: u64,
        mutate_config: vector<bool>,
        cap: account::SignerCapability,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;
    const EINSUFFICIENT_BALANCE: u64 = 4;

    const MAX_U64: u64 = 18446744073709551615;

    const COLLECTION_NAME: vector<u8> = b"URN";

    fun init_module(sender: &signer) {
        // Don't run setup more than once
        if (exists<UrnToEarnConfig>(signer::address_of(sender))) {
            return
        };

        // Create the resource account, so we can get ourselves as signer later
        let (resource, signer_cap) = account::create_resource_account(sender, vector::empty());

        // Set up NFT collection
        let name = string::utf8(COLLECTION_NAME);
        let description = string::utf8(b"Dig your grandma and put to the urn");
        let uri = string::utf8(b"https://urn.jpg");
        let maximum = MAX_U64;
        let mutate_setting = vector<bool>[ false, true, false ]; // desc, max, uri
        token::create_collection(&resource, name, description, uri, maximum, mutate_setting);

        // setup NFTs
        shovel::init_shovel(sender, name, &signer_cap);

        move_to(sender, UrnToEarnConfig {
            description: description,
            name: name,
            uri: uri,
            maximum: maximum,
            mutate_config: mutate_setting,
            cap: signer_cap,
        });
    }

    public entry fun mint_shovel(sign: &signer) acquires UrnToEarnConfig {
        let cfg = borrow_global_mut<UrnToEarnConfig>(@owner);
        let token_id = shovel::mint(sign, &cfg.cap);
        let resource = create_signer_with_capability(&cfg.cap);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        let sender = signer::address_of(sign);
        token::transfer(&resource, token_id, sender, 1);
    }

    #[test(owner=@owner, user=@0xb0b)]
    public fun test_init_module(owner: &signer, user: &signer) acquires UrnToEarnConfig {
        let owner_addr = signer::address_of(owner);
        let user_addr = signer::address_of(user);
        aptos_framework::account::create_account_for_test(owner_addr);
        aptos_framework::account::create_account_for_test(user_addr);

        init_module(owner);
        assert!(exists<UrnToEarnConfig>(owner_addr), 0);

        // test mint shovel
        let cfg = borrow_global_mut<UrnToEarnConfig>(@owner);
        let resource = create_signer_with_capability(&cfg.cap);
        let token_id = shovel::mint(user, &cfg.cap);

        token::initialize_token_store(user);
        token::opt_in_direct_transfer(user, true);
        token::transfer(&resource, token_id, user_addr, 1);

        assert!(token::balance_of(user_addr, token_id) == 1, EINSUFFICIENT_BALANCE);
    }
}