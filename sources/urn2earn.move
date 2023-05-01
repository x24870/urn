module owner::urn_to_earn {
    use aptos_framework::account::{Self, create_signer_with_capability};
    use aptos_framework::coin::{Self, transfer};
    use aptos_framework::aptos_coin::{Self, AptosCoin};
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
    // use owner::weighted_probability;

    struct UrnToEarnConfig has key {
        description: String,
        name: String,
        uri: String,
        maximum: u64,
        mutate_config: vector<bool>,
        cap: account::SignerCapability,
    }

    const ENOT_AUTHORIZED:           u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED:      u64 = 3;
    const EINSUFFICIENT_BALANCE:     u64 = 4;
    const ETOKEN_PROP_MISMATCH:      u64 = 5;
    const ETEST_ERROR:               u64 = 6;
    const EWL_QUOTA_OUT:             u64 = 7;

    const MAX_U64: u64 = 18446744073709551615;

    const COLLECTION_NAME: vector<u8> = b"URN";

    const SHOEVEL_PRICE: u64 = 100000; // 0.001 APT
    const URN_PRICE: u64 = 1000000; // 0.01 APT

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
        knife::init_knife(sender, &resource, name);
        // setup whitelist module
        whitelist::init_whitelist_config(sender);

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
        mint_shovel_internal(sign, SHOEVEL_PRICE);
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
        mint_shovel_internal(sign, shovel_price);
    }

    fun mint_shovel_internal(sign: &signer, price: u64): TokenId acquires UrnToEarnConfig {
        transfer<AptosCoin>(sign, @owner, price);
        let resource = get_resource_account();
        let token_id = shovel::mint(sign, &resource);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        let sender = signer::address_of(sign);
        token::transfer(&resource, token_id, sender, 1);
        token_id
    }

    public entry fun mint_urn(sign: &signer) acquires UrnToEarnConfig {
        mint_urn_internal(sign);
    }

    fun mint_urn_internal(sign: &signer): TokenId acquires UrnToEarnConfig {
        transfer<AptosCoin>(sign, @owner, URN_PRICE);
        let resource = get_resource_account();
        let token_id = urn::mint(sign, &resource);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        let sender = signer::address_of(sign);
        token::transfer(&resource, token_id, sender, 1);
        token_id
    }

    // public entry fun mint_bone(sign: &signer) acquires UrnToEarnConfig {
    //     let resource = get_resource_account();
    //     let token_id = bone::mint(sign, &resource);
    //     token::initialize_token_store(sign);
    //     token::opt_in_direct_transfer(sign, true);
    //     let sender = signer::address_of(sign);
    //     token::transfer(&resource, token_id, sender, 1);
    // }

    // public entry fun mint_golden_bone(sign: &signer) acquires UrnToEarnConfig {
    //     let resource = get_resource_account();
    //     let token_id = bone::mint_golden_bone(sign, &resource);
    //     token::initialize_token_store(sign);
    //     token::opt_in_direct_transfer(sign, true);
    //     let sender = signer::address_of(sign);
    //     token::transfer(&resource, token_id, sender, 1);
    // }

    public fun burn_and_fill(
        sign: &signer, bone_token_id: TokenId, urn_token_id: TokenId
    ) acquires UrnToEarnConfig {
        burn_and_fill_internal(sign, urn_token_id, bone_token_id);
    }

    fun burn_and_fill_internal(
        sign: &signer, urn_token_id: TokenId, bone_token_id: TokenId
    ): TokenId acquires UrnToEarnConfig {
        let sign_addr = signer::address_of(sign);
        // check user owns the token
        assert!(token::balance_of(sign_addr, urn_token_id) == 1, EINSUFFICIENT_BALANCE);
        assert!(token::balance_of(sign_addr, bone_token_id) == 1, EINSUFFICIENT_BALANCE);

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
        let resource = get_resource_account();

        let filled_urn = urn::fill(sign, &resource, urn_token_id, point);
        knife::add_victim(sign, filled_urn);

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
        // TODO: check shovel balance > 0
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
        // TODO: check shard balance >= 10
        shard::destroy_ten_shards(sign);

        let resource = get_resource_account();
        let token_id = urn::mint_golden_urn(sign, &resource);
        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        let sender = signer::address_of(sign);
        token::transfer(&resource, token_id, sender, 1);
        token_id
    }

    public fun reincarnate(sign: &signer, urn_token_id: TokenId) {
        // check user owns the token
        assert!(token::balance_of(signer::address_of(sign), urn_token_id) == 1, EINSUFFICIENT_BALANCE);
        urn::burn_filled_urn(sign, urn_token_id);
    }

    #[test_only]
    use owner::pseudorandom;
    #[test_only]
    use aptos_framework::genesis;
    // #[test_only]
    // use aptos_framework::debug;
    #[test_only]
    use aptos_framework::option;
    #[test_only]
    const INIT_APT: u64 = 1000000000;

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

        assert!(coin::balance<AptosCoin>(owner_addr)==INIT_APT, 0);
        assert!(coin::balance<AptosCoin>(user_addr)==INIT_APT, 0);
        assert!(coin::balance<AptosCoin>(robber_addr)==INIT_APT, 0);
        assert!(*option::borrow(&coin::supply<AptosCoin>()) == (INIT_APT*3 as u128), 0);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_shovel(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        // test mint shovel
        let token_id = mint_shovel_internal(user, SHOEVEL_PRICE);
        assert!(token::balance_of(user_addr, token_id) == 1, EINSUFFICIENT_BALANCE);
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
        let bone_token_id = bone::mint(user, &resource);
        token::transfer(&resource, bone_token_id, user_addr, 1);
        assert!(token::balance_of(user_addr, bone_token_id) == 1, EINSUFFICIENT_BALANCE);

        let point = bone::get_bone_point(bone_token_id, user_addr);
        // debug::print(&point);

        // test burn bone and fill urn
        urn_token_id = burn_and_fill_internal(user, urn_token_id, bone_token_id);
        assert!(token::balance_of(user_addr, bone_token_id) == 0, EINSUFFICIENT_BALANCE);
        let fullness = urn::get_ash_fullness(urn_token_id, user_addr);
        assert!(fullness == point, EINSUFFICIENT_BALANCE);

        // test mint golden bone
        let golden_bone_token_id = bone::mint_golden_bone(user, &resource);
        token::transfer(&resource, golden_bone_token_id, user_addr, 1);
        assert!(token::balance_of(user_addr, golden_bone_token_id) == 1, EINSUFFICIENT_BALANCE);
        // let point = bone::get_bone_point(golden_bone_token_id, user_addr);
        // debug::print(&point);
        bone::is_golden_bone(golden_bone_token_id, user_addr);
    }

    #[test(aptos_framework=@aptos_framework, owner=@owner, user=@0xb0b, robber=@0x0bb3)]
    public fun test_shard(
        aptos_framework: &signer, owner: &signer, user: &signer, robber: &signer
    ) acquires UrnToEarnConfig {
        init_for_test(aptos_framework, owner, user, robber);
        let user_addr = signer::address_of(user);
        let resource = get_resource_account();
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

        // test mint golden bone
        let bone_token_id = bone::mint(user, &resource);
        token::transfer(&resource, bone_token_id, user_addr, 1);
        assert!(token::balance_of(user_addr, bone_token_id) == 1, EINSUFFICIENT_BALANCE);
        bone::is_golden_bone(bone_token_id, user_addr);

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

        reincarnate(user, urn_token_id);
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

        reincarnate(user, urn_token_id);
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

        // mint knife for robber
        let knife_token_id = knife::mint(user, &resource);
        token::transfer(&resource, knife_token_id, robber_addr, 1);

        let (robber_urn, amount) = knife::rob(robber, robber_urn, &resource);
        assert!(token::balance_of(robber_addr, knife_token_id) == 0, EINSUFFICIENT_BALANCE);
        assert!(urn::get_ash_fullness(user_urn, user_addr)+amount==50, ETOKEN_PROP_MISMATCH);
        assert!(urn::get_ash_fullness(robber_urn, robber_addr)==amount, ETOKEN_PROP_MISMATCH);
        assert!(!knife::contains_victim(user_addr), ETEST_ERROR);
        // debug::print(&amount);
    }
}