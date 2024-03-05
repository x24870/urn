module owner::urn_to_earn {
    use aptos_framework::account::{Self, create_signer_with_capability};
    use aptos_framework::coin::{Self, transfer};
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    use aptos_framework::randomness;
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use aptos_token::token::{Self, TokenId};
    use owner::shovel;
    use owner::urn;
    use owner::bone;
    use owner::shard;
    use owner::knife;
    use owner::whitelist;
    use owner::weighted_probability;
    use owner::pseudorandom;
    use owner::leaderboard;
    // use owner::counter;

    struct UrnToEarnConfig has key {
        description: String,
        name: String,
        uri: String,
        maximum: u64,
        mutate_config: vector<bool>,
        cap: account::SignerCapability,
        seed: u64,
    }

    const ENOT_AUTHORIZED:               u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT:     u64 = 2;
    const EMINTING_NOT_ENABLED:          u64 = 3;
    const EINSUFFICIENT_BALANCE:         u64 = 4;
    const ETOKEN_PROP_MISMATCH:          u64 = 5;
    const ETEST_ERROR:                   u64 = 6;
    const EWL_QUOTA_OUT:                 u64 = 7;
    const EAPT_BALANCE_INCONSISTENT:     u64 = 8;
    const EINSUFFICIENT_EXP:             u64 = 9;

    const MAX_U64: u64 = 18446744073709551615;

    const COLLECTION_NAME: vector<u8> = b"urn";

    const SHOEVEL_PRICE: u64 = 100000; // 0.001 APT
    const URN_PRICE: u64 = 1000000; // 0.01 APT

    const EXP_FILL: u64 = 3;
    const EXP_ROB: u64 = 5;
    const EXP_RAND_ROB: u64 = 8;
    const EXP_BEEN_ROB: u64 = 5;
    const EXP_BEEN_RAND_ROB: u64 = 10;

    const REQUIRED_SHARDS: u64 = 69;

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
        let uri = string::utf8(b"https://urn.jpg"); // TODO update collection image
        let maximum = MAX_U64;
        let mutate_setting = vector<bool>[ false, true, false ]; // desc, max, uri
        token::create_collection(&resource, name, description, uri, maximum, mutate_setting);

        // setup NFTs
        shovel::init_shovel(sender, &resource, name);
        urn::init_urn(sender, &resource, name);
        bone::init_bone(sender, &resource, name);
        shard::init_shard(sender, &resource, name);
        knife::init_knife(sender, &resource, name);
        // setup bridge
        // counter::init_counter(sender, &resource);
        // setup helper modules
        whitelist::init_whitelist_config(sender);
        weighted_probability::init_weighted_probability(sender);
        leaderboard::init_leaderboard(sender);

        move_to(sender, UrnToEarnConfig {
            description: description,
            name: name,
            uri: uri,
            maximum: maximum,
            mutate_config: mutate_setting,
            cap: signer_cap,
            seed: 0,
        });
    }

    fun get_resource_account(): signer acquires UrnToEarnConfig {
        let cfg = borrow_global_mut<UrnToEarnConfig>(@owner);
        let resource = create_signer_with_capability(&cfg.cap);
        resource
    }

    public entry fun mint_shovel(sign: &signer, amount: u64) acquires UrnToEarnConfig {
        mint_shovel_internal(sign, amount, SHOEVEL_PRICE);
    }

    public entry fun wl_mint_shovel(sign: &signer, collection_name: String) acquires UrnToEarnConfig {
        let mint_type = whitelist::label_minted(collection_name, signer::address_of(sign));
        // FREE_MINT:0, DISCOUNTED_MINT:1, MINT:2
        let shovel_price = SHOEVEL_PRICE;
        if (mint_type == 0) {
            shovel_price = 0
        } else if (mint_type == 1) {
            shovel_price = shovel_price / 2
        } else {
            assert!(false, EWL_QUOTA_OUT);
        };
        mint_shovel_internal(sign, 1, shovel_price);
    }

    public entry fun bayc_wl_mint_shovel(sign: &signer) acquires UrnToEarnConfig {
        let mint_type = whitelist::label_minted(string::utf8(b"BAYC"), signer::address_of(sign));
        // FREE_MINT:0, DISCOUNTED_MINT:1, MINT:2
        let shovel_price = SHOEVEL_PRICE;
        if (mint_type == 0) {
            shovel_price = 0
        } else if (mint_type == 1) {
            shovel_price = shovel_price / 2
        } else {
            assert!(false, EWL_QUOTA_OUT);
        };
        mint_shovel_internal(sign, 1, shovel_price);
    }

    fun mint_shovel_internal(sign: &signer, amount: u64, price: u64): TokenId acquires UrnToEarnConfig {
        transfer<AptosCoin>(sign, @owner, amount*price);
        let resource = get_resource_account();
        let token_id = shovel::mint(sign, &resource, amount);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        let sender = signer::address_of(sign);
        token::transfer(&resource, token_id, sender, amount);
        token_id
    }

    public entry fun mint_urn(sign: &signer) acquires UrnToEarnConfig {
        mint_urn_internal(sign);
    }

    fun mint_urn_internal(sign: &signer): TokenId acquires UrnToEarnConfig {
        // create a resource to record the history of beeen robbed
        // if user got the urn not by minting, they need to create this resource by themselves
        knife::create_rob_history(sign);

        transfer<AptosCoin>(sign, @owner, URN_PRICE);
        let resource = get_resource_account();
        let token_id = urn::mint(sign, &resource);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        let sender = signer::address_of(sign);
        token::transfer(&resource, token_id, sender, 1);
        token_id
    }

    public entry fun burn_and_fill(
        sign: &signer, urn_prop_ver: u64, bone_prop_ver: u64, part: String, 
    ) acquires UrnToEarnConfig {
        let resource = get_resource_account();
        let creator = signer::address_of(&resource);
        let collection = string::utf8(COLLECTION_NAME);
        let urn_token_name = string::utf8(urn::get_urn_token_name());

        let urn_token_id = token::create_token_id_raw(creator, collection, urn_token_name, urn_prop_ver);
        let bone_token_id = token::create_token_id_raw(creator, collection, part, bone_prop_ver);
        burn_and_fill_internal(sign, urn_token_id, bone_token_id);
    }

    public entry fun burn_and_fill_golden(
        sign: &signer, urn_prop_ver: u64, bone_prop_ver: u64, part: String, 
    ) acquires UrnToEarnConfig {
        let resource = get_resource_account();
        let creator = signer::address_of(&resource);
        let collection = string::utf8(COLLECTION_NAME);
        let urn_token_name = string::utf8(urn::get_golden_urn_token_name());

        let urn_token_id = token::create_token_id_raw(creator, collection, urn_token_name, urn_prop_ver);
        let bone_token_id = token::create_token_id_raw(creator, collection, part, bone_prop_ver);
        burn_and_fill_internal(sign, urn_token_id, bone_token_id);
    }

    fun burn_and_fill_internal(
        sign: &signer, urn_token_id: TokenId, bone_token_id: TokenId
    ): TokenId acquires UrnToEarnConfig {
        let sign_addr = signer::address_of(sign);
        let resource = get_resource_account();
        // check user owns the token
        assert!(token::balance_of(sign_addr, urn_token_id) >= 1, EINSUFFICIENT_BALANCE);
        assert!(token::balance_of(sign_addr, bone_token_id) >= 1, EINSUFFICIENT_BALANCE);

        // add exp
        let urn_token_id = urn::add_exp(&resource, sign_addr, urn_token_id, EXP_FILL);

        // burn
        if (urn::is_golden_urn(urn_token_id)) {
            assert!(
                bone::is_golden_bone(bone_token_id, sign_addr) == true,
                ETOKEN_PROP_MISMATCH);
        } else {
            assert!(
                bone::is_golden_bone(bone_token_id, sign_addr) == false,
                ETOKEN_PROP_MISMATCH);
        };
        let point = bone::burn_bone(sign, bone_token_id);
        

        let filled_urn = urn::fill(sign, &resource, urn_token_id, point);
        if (!urn::is_golden_urn(filled_urn)) {
            knife::add_victim(sign, filled_urn);
        };
        
        return filled_urn
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
        let (token_id, amount) = weighted_probability::mint_by_weight(sign, &resource);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        token::transfer(&resource, token_id, signer::address_of(sign), amount);

        token_id
    }

    public entry fun forge(sign: &signer) acquires UrnToEarnConfig {
        forge_internal(sign);
    }

    fun forge_internal(sign: &signer): TokenId acquires UrnToEarnConfig {
        shard::destroy_69_shards(sign);

        let resource = get_resource_account();
        let token_id = urn::mint_golden_urn(sign, &resource);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        let sender = signer::address_of(sign);
        token::transfer(&resource, token_id, sender, 1);
        token_id
    }

    // TODO: write test
    public entry fun random_rob(robber: &signer, prop_ver: u64, msg: String) acquires UrnToEarnConfig {
        let resource = get_resource_account();
        let creator = signer::address_of(&resource);
        let collection = string::utf8(COLLECTION_NAME);
        let urn_token_name = string::utf8(urn::get_urn_token_name());

        // random rob
        let robber_urn = token::create_token_id_raw(creator, collection, urn_token_name, prop_ver);
        random_rob_internal(robber, &resource, robber_urn, msg);
    }

    fun random_rob_internal(
        robber: &signer, resource: &signer, robber_urn: TokenId, msg: String
    ):(TokenId, u8, address, TokenId) {
        let (robber_urn, amount, victim_addr, victim_urn) = knife::random_rob(robber, robber_urn, resource, msg);

        // add exp
        _ = urn::add_exp(resource, signer::address_of(robber), robber_urn, EXP_RAND_ROB);
        _ = urn::add_exp(resource, victim_addr, victim_urn, EXP_BEEN_RAND_ROB);

        return (robber_urn, amount, victim_addr, victim_urn)
    }

    // TODO: write test
    public entry fun rob(
        robber: &signer, 
        robber_prop_ver: u64, 
        victim_addr: address, 
        victim_prop_ver: u64,
        msg: String
    ) acquires UrnToEarnConfig {
        let resource = get_resource_account();
        let creator = signer::address_of(&resource);
        let collection = string::utf8(COLLECTION_NAME);
        let urn_token_name = string::utf8(urn::get_urn_token_name());

        // rob
        let robber_urn = token::create_token_id_raw(creator, collection, urn_token_name, robber_prop_ver);
        let victim_urn = token::create_token_id_raw(creator, collection, urn_token_name, victim_prop_ver);
        // let (_, _) = knife::rob(robber, robber_urn, victim_addr, victim_urn, &resource, msg);
        rob_internal(robber, &resource, robber_urn, victim_addr, victim_urn, msg);
    }

    fun rob_internal(
        robber: &signer, resource: &signer, robber_urn: TokenId, victim_addr: address, victim_urn: TokenId, msg: String
    ):(TokenId, u8, address, TokenId) {
        let (robber_urn, amount) = knife::rob(robber, robber_urn, victim_addr, victim_urn, resource, msg);

        // add exp
        _ = urn::add_exp(resource, signer::address_of(robber), robber_urn, EXP_ROB);
        _ = urn::add_exp(resource, victim_addr, victim_urn, EXP_BEEN_ROB);

        return (robber_urn, amount, victim_addr, victim_urn)
    }

    public entry fun reincarnate(
        sign: &signer, urn_prop_ver: u64, fee: u64, payload: vector<u8>
    ) acquires UrnToEarnConfig {
        let resource = get_resource_account();
        let creator = signer::address_of(&resource);
        let collection = string::utf8(COLLECTION_NAME);
        let urn_token_name = string::utf8(urn::get_urn_token_name());

        let urn_token_id = token::create_token_id_raw(creator, collection, urn_token_name, urn_prop_ver);
        reincarnate_internal(sign, urn_token_id, fee, payload);
    }

    public fun reincarnate_internal(sign: &signer, urn_token_id: TokenId, fee: u64, payload: vector<u8>) {
        // check user owns the token
        assert!(token::balance_of(signer::address_of(sign), urn_token_id) == 1, EINSUFFICIENT_BALANCE);
        urn::burn_filled_urn(sign, urn_token_id);
        knife::remove_victim(signer::address_of(sign));
        // counter::send_to_remote(sign, 10121, fee, payload);
    }

    // just for temporary test
    public entry fun high_cost_func(sign: &signer) {
        let i = 0;
        while (i < 1000) {
            pseudorandom::rand_u128_range(&signer::address_of(sign), 0, 10000000000000);
            i = i + 1;
        };
    }

    // TODO remove this function
    entry fun set_seed(sign: &signer) acquires UrnToEarnConfig {
        // assert!(signer::address_of(sign) == @owner, ENOT_AUTHORIZED);
        // let cfg = borrow_global_mut<UrnToEarnConfig>(@owner);
        // cfg.seed = randomness::u64_integer();
        set_seed_internal();
    }

    fun set_seed_internal() acquires UrnToEarnConfig {
        let cfg = borrow_global_mut<UrnToEarnConfig>(@owner);
        cfg.seed = randomness::u64_integer();
    }

    #[view]
    public fun view_seed():u64 acquires UrnToEarnConfig {
        let cfg = borrow_global<UrnToEarnConfig>(@owner);
        cfg.seed
    }

    #[test_only]
    use aptos_framework::genesis;
    #[test_only]
    use aptos_framework::debug;
    #[test_only]
    use aptos_framework::option;
    #[test_only]
    use aptos_token::property_map;
    #[test_only]
    use owner::iterable_table::{Self};
    #[test_only]
    const INIT_APT: u64 = 1000000000; // 10 APT

    #[test_only]
    fun init_for_test(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) {
        let owner_addr = signer::address_of(owner);
        let user_addr = signer::address_of(user);
        let robber_addr = signer::address_of(robber);
        aptos_framework::account::create_account_for_test(owner_addr);
        aptos_framework::account::create_account_for_test(user_addr);
        aptos_framework::account::create_account_for_test(robber_addr);

        init_module(owner);
        assert!(exists<UrnToEarnConfig>(owner_addr), 0);

        // enable token opt-in
        token::initialize_token_store(user);
        token::opt_in_direct_transfer(user, true);
        token::initialize_token_store(robber);
        token::opt_in_direct_transfer(robber, true);

        // init pseudorandom pre-requirements 
        genesis::setup();
        pseudorandom::init_for_test(owner);

        // mint 10 APTs for owner & user
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test_without_aggregator_factory(aptos_framework);
        coin::destroy_burn_cap<AptosCoin>(burn_cap);
        
        let apt_for_owner = coin::mint<AptosCoin>(INIT_APT, &mint_cap);
        let apt_for_user = coin::mint<AptosCoin>(INIT_APT, &mint_cap);
        let apt_for_robber = coin::mint<AptosCoin>(INIT_APT, &mint_cap);
        coin::register<AptosCoin>(owner);
        coin::register<AptosCoin>(user);
        coin::register<AptosCoin>(robber);
        coin::deposit<AptosCoin>(owner_addr, apt_for_owner);
        coin::deposit<AptosCoin>(user_addr, apt_for_user);
        coin::deposit<AptosCoin>(robber_addr, apt_for_robber);

        coin::destroy_mint_cap<AptosCoin>(mint_cap);

        assert!(coin::balance<AptosCoin>(owner_addr)==INIT_APT, EAPT_BALANCE_INCONSISTENT);
        assert!(coin::balance<AptosCoin>(user_addr)==INIT_APT, EAPT_BALANCE_INCONSISTENT);
        assert!(coin::balance<AptosCoin>(robber_addr)==INIT_APT, EAPT_BALANCE_INCONSISTENT);
        assert!(*option::borrow(&coin::supply<AptosCoin>()) == (INIT_APT*3 as u128), 0);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_shovel(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        // test mint shovel
        let amount: u64 = 1;
        let token_id = mint_shovel_internal(user, amount, SHOEVEL_PRICE);
        assert!(token::balance_of(user_addr, token_id) == amount, EINSUFFICIENT_BALANCE);
        assert!(coin::balance<AptosCoin>(signer::address_of(owner))==INIT_APT+SHOEVEL_PRICE, 0);
        assert!(coin::balance<AptosCoin>(signer::address_of(user))==INIT_APT-SHOEVEL_PRICE, 0);

        let bone_token_id = dig_internal(user);
        assert!(token::balance_of(user_addr, token_id) == 0, EINSUFFICIENT_BALANCE);
        assert!(token::balance_of(user_addr, bone_token_id) == 1, EINSUFFICIENT_BALANCE);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_urn(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        // test mint urn
        let token_id = mint_urn_internal(user);
        assert!(token::balance_of(user_addr, token_id) == 1, EINSUFFICIENT_BALANCE);
        assert!(coin::balance<AptosCoin>(signer::address_of(owner))==INIT_APT+URN_PRICE, 0);
        assert!(coin::balance<AptosCoin>(signer::address_of(user))==INIT_APT-URN_PRICE, 0);

        // test fill
        let resource = get_resource_account();
        let fullness = urn::get_ash_fullness(token_id, user_addr);
        assert!(fullness == 0, ETOKEN_PROP_MISMATCH);

        token_id = urn::fill(user, &resource, token_id, 5);
        fullness = urn::get_ash_fullness(token_id, user_addr);
        assert!(fullness == 5, ETOKEN_PROP_MISMATCH);

        token_id = urn::fill(user, &resource, token_id, 5);
        fullness = urn::get_ash_fullness(token_id, user_addr);
        assert!(fullness == 10, ETOKEN_PROP_MISMATCH);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_bone(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let resource = get_resource_account();

        // test mint urn
        let urn_token_id = urn::mint(user, &resource);
        token::transfer(&resource, urn_token_id, user_addr, 1);

        // test mint bone
        let bone_token_id = bone::mint_bone(user, &resource);
        token::transfer(&resource, bone_token_id, user_addr, 1);
        assert!(token::balance_of(user_addr, bone_token_id) == 1, EINSUFFICIENT_BALANCE);

        let point = bone::get_bone_point(bone_token_id, user_addr);
        // debug::print(&point);

        // test burn bone and fill urn
        urn_token_id = burn_and_fill_internal(user, urn_token_id, bone_token_id);
        assert!(token::balance_of(user_addr, bone_token_id) == 0, EINSUFFICIENT_BALANCE);
        let fullness = urn::get_ash_fullness(urn_token_id, user_addr);
        assert!(fullness == point, EINSUFFICIENT_BALANCE);
        let exp = urn::get_exp(user_addr, urn_token_id);
        assert!(exp == EXP_FILL, EINSUFFICIENT_EXP);

        // test mint golden urn
        let golden_urn_token_id = urn::mint_golden_urn(user, &resource);
        token::transfer(&resource, golden_urn_token_id, user_addr, 1);

        // test mint golden bone
        let golden_bone_token_id = bone::mint_golden_bone(user, &resource);
        token::transfer(&resource, golden_bone_token_id, user_addr, 1);
        assert!(token::balance_of(user_addr, golden_bone_token_id) == 1, EINSUFFICIENT_BALANCE);
        let point = bone::get_bone_point(golden_bone_token_id, user_addr);
        debug::print(&point);
        bone::is_golden_bone(golden_bone_token_id, user_addr);

        // test burn golden bone and fill golden urn
        urn_token_id = burn_and_fill_internal(user, golden_urn_token_id, golden_bone_token_id);
        assert!(token::balance_of(user_addr, golden_bone_token_id) == 0, EINSUFFICIENT_BALANCE);
        let fullness = urn::get_ash_fullness(urn_token_id, user_addr);
        assert!(fullness == point, EINSUFFICIENT_BALANCE);
        let exp = urn::get_exp(user_addr, urn_token_id);
        assert!(exp == EXP_FILL, EINSUFFICIENT_EXP);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_entry_func(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let resource = get_resource_account();

        // test mint urn
        let urn_token_id = urn::mint(user, &resource);
        token::transfer(&resource, urn_token_id, user_addr, 1);

        // test mint bone
        let bone_token_id = bone::mint_bone(user, &resource);
        token::transfer(&resource, bone_token_id, user_addr, 1);
        assert!(token::balance_of(user_addr, bone_token_id) == 1, EINSUFFICIENT_BALANCE);

        let point = bone::get_bone_point(bone_token_id, user_addr);
        // debug::print(&point);

        // test burn bone and fill urn
        urn_token_id = burn_and_fill_internal(user, urn_token_id, bone_token_id);
        assert!(token::balance_of(user_addr, bone_token_id) == 0, EINSUFFICIENT_BALANCE);
        let fullness = urn::get_ash_fullness(urn_token_id, user_addr);
        assert!(fullness == point, EINSUFFICIENT_BALANCE);

        // urn property version is fixed, put bone to it again
        let bone_token_id = bone::mint_bone(user, &resource);
        token::transfer(&resource, bone_token_id, user_addr, 1);
        assert!(token::balance_of(user_addr, bone_token_id) == 1, EINSUFFICIENT_BALANCE);

        let (_, _, _, urn_prop_ver) = token::get_token_id_fields(&bone_token_id);
        let (_, _, _, bone_prop_ver) = token::get_token_id_fields(&bone_token_id);
        let bone_pm = token::get_property_map(user_addr, bone_token_id);
        let part = property_map::read_string(&bone_pm, &string::utf8(b"part"));
        burn_and_fill(user, urn_prop_ver, bone_prop_ver, part);
    }

    #[test_only]
    // mint 69 shards
    fun mint_enough_shards(sign: &signer, resource: &signer): TokenId {
        let (token_id, _amount) = shard::mint(sign, resource);
        while (true) {
            (token_id, _amount) = shard::mint(sign, resource);
            token::transfer(resource, token_id, signer::address_of(sign), _amount);
            if (token::balance_of(signer::address_of(sign), token_id) >= REQUIRED_SHARDS) {
                break
            };
        };
        return token_id
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_shard(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let resource = get_resource_account();
        // test mint shard
        let token_id = mint_enough_shards(user, &resource);
        let balance = token::balance_of(user_addr, token_id);
        assert!(balance >= REQUIRED_SHARDS, EINSUFFICIENT_BALANCE);

        let golden_urn_token_id = forge_internal(user);
        assert!(token::balance_of(user_addr, token_id) == balance - REQUIRED_SHARDS, EINSUFFICIENT_BALANCE);
        assert!(token::balance_of(user_addr, golden_urn_token_id) == 1, EINSUFFICIENT_BALANCE);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    #[expected_failure(abort_code = ETOKEN_PROP_MISMATCH)]
    public fun test_urn_and_golden_bone(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let resource = get_resource_account();

        // test mint urn
        let urn_token_id = urn::mint(user, &resource);
        token::transfer(&resource, urn_token_id, user_addr, 1);

        // test mint golden bone
        let golden_bone_token_id = bone::mint_golden_bone(user, &resource);
        token::transfer(&resource, golden_bone_token_id, user_addr, 1);
        assert!(token::balance_of(user_addr, golden_bone_token_id) == 1, EINSUFFICIENT_BALANCE);
        bone::is_golden_bone(golden_bone_token_id, user_addr);

        _ = burn_and_fill_internal(user, urn_token_id, golden_bone_token_id);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    #[expected_failure(abort_code = ETOKEN_PROP_MISMATCH)]
    public fun test_golden_urn_and_bone(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let resource = get_resource_account();

        // forge golden urn
        let shard_token_id = mint_enough_shards(user, &resource);
        let shard_balance = token::balance_of(user_addr, shard_token_id);
        assert!(shard_balance >= REQUIRED_SHARDS, EINSUFFICIENT_BALANCE);

        let golden_urn_token_id = forge_internal(user);
        assert!(token::balance_of(user_addr, shard_token_id) == shard_balance - REQUIRED_SHARDS, EINSUFFICIENT_BALANCE);
        assert!(token::balance_of(user_addr, golden_urn_token_id) == 1, EINSUFFICIENT_BALANCE);

        // mint bone
        let bone_token_id = bone::mint_bone(user, &resource);
        token::transfer(&resource, bone_token_id, user_addr, 1);
        assert!(token::balance_of(user_addr, bone_token_id) == 1, EINSUFFICIENT_BALANCE);

        // try to put bone into golden urn
        _ = burn_and_fill_internal(user, golden_urn_token_id, bone_token_id);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    #[expected_failure(abort_code = urn::EURN_OVERFLOW)]
    public fun test_urn_overflow(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let resource = get_resource_account();
        
        // mint urn 
        let urn_token_id = urn::mint(user, &resource);
        token::transfer(&resource, urn_token_id, user_addr, 1);

        // mint test skulls
        let bone_token_id_1 = bone::mint_50point_skull(owner, &resource);
        token::transfer(&resource, bone_token_id_1, user_addr, 1);
        let bone_token_id_2 = bone::mint_50point_skull(owner, &resource);
        token::transfer(&resource, bone_token_id_2, user_addr, 1);
        let bone_token_id_3 = bone::mint_50point_skull(owner, &resource);
        token::transfer(&resource, bone_token_id_3, user_addr, 1);

        urn_token_id = burn_and_fill_internal(user, urn_token_id, bone_token_id_1);
        assert!(urn::get_ash_fullness(urn_token_id, user_addr) == 50, ETOKEN_PROP_MISMATCH);
        burn_and_fill_internal(user, urn_token_id, bone_token_id_2);
        assert!(urn::get_ash_fullness(urn_token_id, user_addr) == 100, ETOKEN_PROP_MISMATCH);
        burn_and_fill_internal(user, urn_token_id, bone_token_id_3);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    #[expected_failure(abort_code = urn::EURN_NOT_FULL)]
    public fun test_urn_not_full(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let resource = get_resource_account();
        
        // mint urn 
        let urn_token_id = urn::mint(user, &resource);
        token::transfer(&resource, urn_token_id, user_addr, 1);

        // mint test skulls
        let bone_token_id_1 = bone::mint_50point_skull(owner, &resource);
        token::transfer(&resource, bone_token_id_1, user_addr, 1);

        urn_token_id = burn_and_fill_internal(user, urn_token_id, bone_token_id_1);
        assert!(urn::get_ash_fullness(urn_token_id, user_addr) == 50, ETOKEN_PROP_MISMATCH);

        reincarnate_internal(user, urn_token_id, 0, vector::empty());
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_reincarnate(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let resource = get_resource_account();
        
        // mint urn 
        let urn_token_id = urn::mint(user, &resource);
        token::transfer(&resource, urn_token_id, user_addr, 1);

        // mint test skulls
        let bone_token_id_1 = bone::mint_50point_skull(owner, &resource);
        token::transfer(&resource, bone_token_id_1, user_addr, 1);
        let bone_token_id_2 = bone::mint_50point_skull(owner, &resource);
        token::transfer(&resource, bone_token_id_2, user_addr, 1);

        urn_token_id = burn_and_fill_internal(user, urn_token_id, bone_token_id_1);
        assert!(urn::get_ash_fullness(urn_token_id, user_addr) == 50, ETOKEN_PROP_MISMATCH);
        assert!(token::balance_of(user_addr, bone_token_id_1) == 0, EINSUFFICIENT_BALANCE);
        urn_token_id = burn_and_fill_internal(user, urn_token_id, bone_token_id_2);
        assert!(urn::get_ash_fullness(urn_token_id, user_addr) == 100, ETOKEN_PROP_MISMATCH);
        assert!(token::balance_of(user_addr, bone_token_id_2) == 0, EINSUFFICIENT_BALANCE);

        reincarnate_internal(user, urn_token_id, 0, vector::empty());
        assert!(token::balance_of(user_addr, urn_token_id) == 0, EINSUFFICIENT_BALANCE);

        // TODO: check if urn_burned map is updates
        // TODO: test reincarnate multiple times
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_rob(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let robber_addr = signer::address_of(robber);
        let resource = get_resource_account();
        
        // mint urn for user and robber 
        let user_urn = urn::mint(user, &resource);
        token::transfer(&resource, user_urn, user_addr, 1);
        let robber_urn = urn::mint(robber, &resource);
        token::transfer(&resource, robber_urn, robber_addr, 1);

        // mint test skulls
        let bone_token_id_1 = bone::mint_50point_skull(owner, &resource);
        token::transfer(&resource, bone_token_id_1, user_addr, 1);

        user_urn = burn_and_fill_internal(user, user_urn, bone_token_id_1);
        assert!(urn::get_ash_fullness(user_urn, user_addr) == 50, ETOKEN_PROP_MISMATCH);
        assert!(token::balance_of(user_addr, bone_token_id_1) == 0, EINSUFFICIENT_BALANCE);
        assert!(knife::contains_victim(user_addr), ETEST_ERROR);

        // mint 2 knifes for robber
        let knife_token_id = knife::mint(user, &resource);
        token::transfer(&resource, knife_token_id, robber_addr, 1);

        let msg = string::utf8(b"test");
        let (robber_urn, amount, victim_addr, victim_urn) = random_rob_internal(robber, &resource, robber_urn, msg);
        assert!(token::balance_of(robber_addr, knife_token_id) == 0, EINSUFFICIENT_BALANCE);
        assert!(urn::get_ash_fullness(user_urn, user_addr)+amount==50, ETOKEN_PROP_MISMATCH);
        assert!(urn::get_ash_fullness(robber_urn, robber_addr) == amount, ETOKEN_PROP_MISMATCH);
        assert!(!knife::contains_victim(user_addr), ETEST_ERROR);
        assert!(urn::get_exp(robber_addr, robber_urn) == EXP_RAND_ROB, EINSUFFICIENT_EXP);
        assert!(urn::get_exp(victim_addr, victim_urn) == EXP_BEEN_RAND_ROB+EXP_FILL, EINSUFFICIENT_EXP);
        debug::print(&urn::get_exp(robber_addr, robber_urn));
        debug::print(&urn::get_exp(victim_addr, victim_urn));

        //// test rob by address
        let knife_token_id = knife::mint(user, &resource);
        token::transfer(&resource, knife_token_id, robber_addr, 1);
        let rob_fullness_before = urn::get_ash_fullness(robber_urn, robber_addr);
        let user_fullness_before = urn::get_ash_fullness(user_urn, user_addr);

        let bone_token_id_1 = bone::mint_50point_skull(owner, &resource);
        token::transfer(&resource, bone_token_id_1, user_addr, 1);

        user_urn = burn_and_fill_internal(user, user_urn, bone_token_id_1);
        assert!(urn::get_ash_fullness(user_urn, user_addr) == user_fullness_before+50, ETOKEN_PROP_MISMATCH);
        assert!(token::balance_of(user_addr, bone_token_id_1) == 0, EINSUFFICIENT_BALANCE);
        assert!(knife::contains_victim(user_addr), ETEST_ERROR);

        user_fullness_before = urn::get_ash_fullness(user_urn, user_addr);
        let msg = string::utf8(b"test");
        let (robber_urn, amount, _, _) = rob_internal(robber, &resource, robber_urn, victim_addr, victim_urn, msg);
        assert!(token::balance_of(robber_addr, knife_token_id) == 0, EINSUFFICIENT_BALANCE);
        debug::print(&amount);
        assert!(urn::get_ash_fullness(user_urn, user_addr)+amount==user_fullness_before, ETOKEN_PROP_MISMATCH);
        assert!(urn::get_ash_fullness(robber_urn, robber_addr)-amount==rob_fullness_before, ETOKEN_PROP_MISMATCH);
        assert!(urn::get_exp(robber_addr, robber_urn) == EXP_RAND_ROB+EXP_ROB, EINSUFFICIENT_EXP);
        assert!(urn::get_exp(victim_addr, victim_urn) == EXP_BEEN_RAND_ROB+EXP_FILL*2+EXP_BEEN_ROB, EINSUFFICIENT_EXP);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    #[expected_failure(abort_code = knife::EMSG_TOO_LONG)]
    public fun test_rob_msg_too_long(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let robber_addr = signer::address_of(robber);
        let resource = get_resource_account();
        
        // mint urn for user and robber 
        let user_urn = urn::mint(user, &resource);
        token::transfer(&resource, user_urn, user_addr, 1);
        let robber_urn = urn::mint(robber, &resource);
        token::transfer(&resource, robber_urn, robber_addr, 1);

        // mint test skulls
        let bone_token_id_1 = bone::mint_50point_skull(owner, &resource);
        token::transfer(&resource, bone_token_id_1, user_addr, 1);

        user_urn = burn_and_fill_internal(user, user_urn, bone_token_id_1);
        assert!(urn::get_ash_fullness(user_urn, user_addr) == 50, ETOKEN_PROP_MISMATCH);
        assert!(token::balance_of(user_addr, bone_token_id_1) == 0, EINSUFFICIENT_BALANCE);
        assert!(knife::contains_victim(user_addr), ETEST_ERROR);

        // mint knife for robber
        let knife_token_id = knife::mint(user, &resource);
        token::transfer(&resource, knife_token_id, robber_addr, 1);

        let msg = string::utf8(b"e9aff5bffdb5839f4e8fd7d9e846143806dd24559205228275138eae5a7348e3e9aff5bffdb5839f4e8fd7d9e846143806dd24559205228275138eae5a7348e3e9aff5bffdb5839f4e8fd7d9e846143806dd24559205228275138eae5a7348e3e9aff5bffdb5839f4e8fd7d9e846143806dd24559205228275138eae5a7348e3");
        let (_, _, _, _) = knife::random_rob(robber, robber_urn, &resource, msg);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_mint_by_weight(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let resource = get_resource_account();

        // test mint by weight
        let i = 0;
        while (i < 100) { // Iterate until first cutoff:
            let (token_id, amount) = weighted_probability::mint_by_weight(user, &resource);
            token::transfer(&resource, token_id, user_addr, amount);
            i = i + 1;
        };

        let knife_token_id = knife::mint(user, &resource);
        let (shard_token_id, _) = shard::mint(user, &resource);

        assert!(token::balance_of(user_addr, knife_token_id) > 15, EINSUFFICIENT_BALANCE);
        assert!(token::balance_of(user_addr, shard_token_id) > 50, EINSUFFICIENT_BALANCE);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_whitelist_mint(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let owner_addr = signer::address_of(owner);
        let robber_addr = signer::address_of(robber);

        // test mint by weight
        let collection = string::utf8(b"BAYC");
        let free_quota = 1;
        let discounted_quota = 1;
        whitelist::add_collection(owner, collection, free_quota, discounted_quota);

        // add whitelisted addresses
        let wl_addrs = vector::empty<address>();
        vector::push_back<address>(&mut wl_addrs, owner_addr);
        vector::push_back<address>(&mut wl_addrs, user_addr);
        vector::push_back<address>(&mut wl_addrs, robber_addr);
        whitelist::add_to_whitelist(owner, collection, wl_addrs);

        // get shovel token id
        let shovel_token_id = mint_shovel_internal(owner, 1, SHOEVEL_PRICE);
        let owner_balance = INIT_APT - SHOEVEL_PRICE;
        let owner_balance = owner_balance + SHOEVEL_PRICE;
        let owner_shovel = 1;

        // first should be free
        bayc_wl_mint_shovel(owner);
        owner_shovel = owner_shovel + 1;
        assert!(token::balance_of(owner_addr, shovel_token_id) == owner_shovel, EINSUFFICIENT_BALANCE);
        assert!(coin::balance<AptosCoin>(owner_addr)==owner_balance, EAPT_BALANCE_INCONSISTENT);

        // second should be discounted
        bayc_wl_mint_shovel(user);
        assert!(token::balance_of(user_addr, shovel_token_id) == 1, EINSUFFICIENT_BALANCE);
        let user_balance = INIT_APT - SHOEVEL_PRICE/2;
        owner_balance = owner_balance + SHOEVEL_PRICE/2;
        assert!(coin::balance<AptosCoin>(user_addr) == user_balance, EAPT_BALANCE_INCONSISTENT);
        assert!(coin::balance<AptosCoin>(owner_addr) == owner_balance, EAPT_BALANCE_INCONSISTENT);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    #[expected_failure(abort_code = EWL_QUOTA_OUT)]
    public fun test_whitelist_quota_out(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let owner_addr = signer::address_of(owner);
        let robber_addr = signer::address_of(robber);

        // test mint by weight
        let collection = string::utf8(b"BAYC");
        let free_quota = 1;
        let discounted_quota = 0;
        whitelist::add_collection(owner, collection, free_quota, discounted_quota);

        // add whitelisted addresses
        let wl_addrs = vector::empty<address>();
        vector::push_back<address>(&mut wl_addrs, owner_addr);
        vector::push_back<address>(&mut wl_addrs, user_addr);
        vector::push_back<address>(&mut wl_addrs, robber_addr);
        whitelist::add_to_whitelist(owner, collection, wl_addrs);

        // get shovel token id
        let shovel_token_id = mint_shovel_internal(owner, 1, SHOEVEL_PRICE);
        let owner_balance = INIT_APT - SHOEVEL_PRICE;
        let owner_balance = owner_balance + SHOEVEL_PRICE;
        let owner_shovel = 1;

        // first should be free
        bayc_wl_mint_shovel(owner);
        owner_shovel = owner_shovel + 1;
        assert!(token::balance_of(owner_addr, shovel_token_id) == owner_shovel, EINSUFFICIENT_BALANCE);
        assert!(coin::balance<AptosCoin>(owner_addr)==owner_balance, EAPT_BALANCE_INCONSISTENT);

        // second should fail, because run out of quota
        bayc_wl_mint_shovel(user);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_mint_probability(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        // let owner_addr = signer::address_of(owner);
        // let robber_addr = signer::address_of(robber);

        let resource = get_resource_account();
        let creator = signer::address_of(&resource);
        let collection = string::utf8(COLLECTION_NAME);

        let total_mint = 1000;
        let shovel_token_id = token::create_token_id_raw(creator, collection, string::utf8(b"shovel"), 0);

        // mint shovels
        mint_shovel_internal(user, total_mint, SHOEVEL_PRICE);
        assert!(token::balance_of(user_addr, shovel_token_id) == total_mint, EINSUFFICIENT_BALANCE);

        // dig many times
        let i = 0;
        let t = iterable_table::new<String, u64>();
        while(i < total_mint) {
            let token_id = dig_internal(user);
            i = i + 1;
            let (_,_,name,_) = token::get_token_id_fields(&token_id);
            
            if (!iterable_table::contains(&t, name)) {
                iterable_table::add(&mut t, name, 0)
            } ;
            let count = *iterable_table::borrow<String, u64>(&t, name);
            *iterable_table::borrow_mut<String, u64>(&mut t, name) = count + 1;
        };

        // print all minted tokens
        let key = iterable_table::head_key(&t);
        while (option::is_some(&key)) {
            let (val, _, next) = iterable_table::remove_iter(&mut t, *option::borrow(&key));
            debug::print(option::borrow<String>(&key));
            debug::print(&val);
            key = next;
        };


        // destroy the table
        key = iterable_table::head_key(&t);
        while (option::is_some(&key)) {
            let (_, _, next) = iterable_table::remove_iter(&mut t, *option::borrow(&key));
            key = next;
        };
        iterable_table::destroy_empty(t);
    }
}