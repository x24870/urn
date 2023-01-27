module owner::urn_to_earn {
    use aptos_framework::account::{Self, create_signer_with_capability};
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use aptos_token::token::{Self, TokenId};
    use owner::shovel;
    use owner::urn;
    use owner::bone;
    use owner::shard;

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
        shovel::init_shovel(sender, &resource, name);
        urn::init_urn(sender, &resource, name);
        bone::init_bone(sender, &resource, name);
        shard::init_shard(sender, &resource, name);

        move_to(sender, UrnToEarnConfig {
            description: description,
            name: name,
            uri: uri,
            maximum: maximum,
            mutate_config: mutate_setting,
            cap: signer_cap,
        });
    }

    fun get_resource_account(): signer acquires UrnToEarnConfig {
        let cfg = borrow_global_mut<UrnToEarnConfig>(@owner);
        let resource = create_signer_with_capability(&cfg.cap);
        resource
    }

    public entry fun mint_shovel(sign: &signer) acquires UrnToEarnConfig {
        let resource = get_resource_account();
        let token_id = shovel::mint(sign, &resource);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        let sender = signer::address_of(sign);
        token::transfer(&resource, token_id, sender, 1);
    }

    public entry fun mint_urn(sign: &signer) acquires UrnToEarnConfig {
        let resource = get_resource_account();
        let token_id = urn::mint(sign, &resource);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        let sender = signer::address_of(sign);
        token::transfer(&resource, token_id, sender, 1);
    }

    public entry fun mint_bone(sign: &signer) acquires UrnToEarnConfig {
        let resource = get_resource_account();
        let token_id = bone::mint(sign, &resource);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        let sender = signer::address_of(sign);
        token::transfer(&resource, token_id, sender, 1);
    }

    public entry fun burn_and_fill(
        sign: &signer, bone_token_id: TokenId, urn_token_id: TokenId
    ) acquires UrnToEarnConfig {
        burn_and_fill_internal(sign, bone_token_id, urn_token_id);
    }

    fun burn_and_fill_internal(
        sign: &signer, bone_token_id: TokenId, urn_token_id: TokenId
    ): TokenId acquires UrnToEarnConfig {
        let point = bone::burn_bone(sign, bone_token_id);
        let resource = get_resource_account();
        urn::fill(sign, &resource, urn_token_id, point)
    }

    public entry fun dig(
        sign: &signer
    ) acquires UrnToEarnConfig {
        dig_internal(sign);
    }

    fun dig_internal(
        sign: &signer
    ): TokenId acquires UrnToEarnConfig {
        shovel::destroy_shovel(sign);
        let resource = get_resource_account();
        let bone_token_id = bone::mint(sign, &resource);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        token::transfer(
            &resource, bone_token_id, signer::address_of(sign), 1
            );

        bone_token_id
    }

    public entry fun forge(sign: &signer) acquires UrnToEarnConfig {
        forge_internal(sign);
    }

    fun forge_internal(sign: &signer): TokenId acquires UrnToEarnConfig {
        shard::destroy_ten_shards(sign);

        let resource = get_resource_account();
        let token_id = urn::mint_golden_urn(sign, &resource);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        let sender = signer::address_of(sign);
        token::transfer(&resource, token_id, sender, 1);
        token_id
    }

    #[test_only]
    use owner::pseudorandom;
     #[test_only]
    use aptos_framework::genesis;
     #[test_only]
    use aptos_framework::debug;

    #[test_only]
    fun init_for_test(
        owner: &signer, user: &signer
    ) {
        let owner_addr = signer::address_of(owner);
        let user_addr = signer::address_of(user);
        aptos_framework::account::create_account_for_test(owner_addr);
        aptos_framework::account::create_account_for_test(user_addr);

        init_module(owner);
        assert!(exists<UrnToEarnConfig>(owner_addr), 0);

        // init pseudorandom pre-requirements 
        genesis::setup();
        pseudorandom::init_for_test(owner);

    }

    #[test(owner=@owner, user=@0xb0b)]
    public fun test_shovel(
        owner: &signer, user: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(owner, user);
        let user_addr = signer::address_of(user);
        // test mint shovel
        let resource = get_resource_account();
        let token_id = shovel::mint(user, &resource);

        token::initialize_token_store(user);
        token::opt_in_direct_transfer(user, true);
        token::transfer(&resource, token_id, user_addr, 1);

        assert!(token::balance_of(user_addr, token_id) == 1, EINSUFFICIENT_BALANCE);

        let bone_token_id = dig_internal(user);
        assert!(token::balance_of(user_addr, token_id) == 0, EINSUFFICIENT_BALANCE);
        assert!(token::balance_of(user_addr, bone_token_id) == 1, EINSUFFICIENT_BALANCE);
    }

    #[test(owner=@owner, user=@0xb0b)]
    public fun test_urn(
        owner: &signer, user: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(owner, user);
        let user_addr = signer::address_of(user);
        // test mint urn
        let resource = get_resource_account();
        let token_id = urn::mint(user, &resource);

        token::initialize_token_store(user);
        token::opt_in_direct_transfer(user, true);
        token::transfer(&resource, token_id, user_addr, 1);

        assert!(token::balance_of(user_addr, token_id) == 1, EINSUFFICIENT_BALANCE);

        // test fill
        let fullness = urn::get_ash_fullness(token_id, user_addr);
        assert!(fullness == 0, EINSUFFICIENT_BALANCE);

        token_id = urn::fill(user, &resource, token_id, 5);
        fullness = urn::get_ash_fullness(token_id, user_addr);
        assert!(fullness == 5, EINSUFFICIENT_BALANCE);

        token_id = urn::fill(user, &resource, token_id, 5);
        fullness = urn::get_ash_fullness(token_id, user_addr);
        assert!(fullness == 10, EINSUFFICIENT_BALANCE);

        // make sure urn material still exists
        let material = urn::get_urn_material(token_id, user_addr);
        assert!(material == string::utf8(b"ceramic"), EINSUFFICIENT_BALANCE);
    }

    #[test(owner=@owner, user=@0xb0b)]
    public fun test_bone(
        owner: &signer, user: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(owner, user);
        let user_addr = signer::address_of(user);

        // prepare
        token::initialize_token_store(user);
        token::opt_in_direct_transfer(user, true);
        let resource = get_resource_account();

        // test mint urn
        let urn_token_id = urn::mint(user, &resource);
        token::transfer(&resource, urn_token_id, user_addr, 1);

        // test mint bone
        let bone_token_id = bone::mint(user, &resource);
        token::transfer(&resource, bone_token_id, user_addr, 1);
        assert!(token::balance_of(user_addr, bone_token_id) == 1, EINSUFFICIENT_BALANCE);

        let point = bone::get_bone_point(bone_token_id, user_addr);
        debug::print(&point);


        // test burn bone
        urn_token_id = burn_and_fill_internal(user, bone_token_id, urn_token_id);
        assert!(token::balance_of(user_addr, bone_token_id) == 0, EINSUFFICIENT_BALANCE);
        let fullness = urn::get_ash_fullness(urn_token_id, user_addr);
        assert!(fullness == point, EINSUFFICIENT_BALANCE);
    }

    #[test(owner=@owner, user=@0xb0b)]
    public fun test_shard(
        owner: &signer, user: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(owner, user);
        let user_addr = signer::address_of(user);
        let resource = get_resource_account();
        // enable opt in
        token::initialize_token_store(user);
        token::opt_in_direct_transfer(user, true);
        // test mint shard
        let token_id = shard::mint(user, &resource); // 1
        shard::mint(user, &resource); // 2
        shard::mint(user, &resource); // 3
        shard::mint(user, &resource); // 4
        shard::mint(user, &resource); // 5
        shard::mint(user, &resource); // 6
        shard::mint(user, &resource); // 7
        shard::mint(user, &resource); // 8
        shard::mint(user, &resource); // 9
        shard::mint(user, &resource); // 10
        token::transfer(&resource, token_id, user_addr, 10);

        assert!(token::balance_of(user_addr, token_id) == 10, EINSUFFICIENT_BALANCE);

        let golden_urn_token_id = forge_internal(user);
        assert!(token::balance_of(user_addr, token_id) == 0, EINSUFFICIENT_BALANCE);
        assert!(token::balance_of(user_addr, golden_urn_token_id) == 1, EINSUFFICIENT_BALANCE);
    }
}