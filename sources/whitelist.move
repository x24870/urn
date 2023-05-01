module owner::whitelist {
    use std::signer;
    use std::error;
    use std::vector;
    use std::string::{String};
    use aptos_std::table::{Self, Table, contains, borrow, borrow_mut, add};
    // use aptos_framework::timestamp;

    const ENOT_AUTHORIZED:         u64 = 1;
    const ECONFIG_NOT_INITIALIZED: u64 = 2;
    const ECONFIG_INITIALIZED:     u64 = 3;
    const EACCOUNT_DOES_NOT_EXIST: u64 = 4;
    const ENOT_WHITELISTED:        u64 = 5;
    const EALREADY_MINTED:         u64 = 6;
    const EINVALID_COLLECTION:     u64 = 7;
    const EINVALID_ADDRESS:        u64 = 8;
    const EDUPLIDATED_WL_ADDR:     u64 = 9;

    // mint type
    const FREE_MINT:       u8 = 0;
    const DISCOUNTED_MINT: u8 = 1;
    const MINT:            u8 = 2;

    struct WhitelistConfig has key {
        // key: collection name, val: Whitelist
        whitelists: Table<String, Whitelist>,
    }

    struct Whitelist has store {
        // key: whitelisted address, val: minted
        wl_addrs: Table<address, bool>,
        free_quota: u64,
        discount_quota: u64,
    }

    public fun init_whitelist_config(owner: &signer) {
        let owner_addr = signer::address_of(owner);
        assert!(!exists<WhitelistConfig>(owner_addr), ECONFIG_INITIALIZED);
        move_to(owner, WhitelistConfig{
            whitelists: table::new<String, Whitelist>(),
        });
    }

    public fun is_whitelisted(wl: &Whitelist, addr: address) {
        // let wl_config = borrow_global<WhitelistConfig>(@owner);
        // let wl = borrow<String, Whitelist>(&wl_config.whitelists, collection);
        assert!(contains<address, bool>(&wl.wl_addrs, addr), ENOT_WHITELISTED);
        assert!(*borrow(&wl.wl_addrs, addr), EALREADY_MINTED); // true is mintable
    }

    // add a collection by name to the whitelist
    public entry fun add_collection(
        owner: &signer, collection: String, free_quota: u64, discount_quota: u64
    ) acquires WhitelistConfig {
        assert!(signer::address_of(owner) == @owner, error::permission_denied(ENOT_AUTHORIZED));
        let wl_config = borrow_global_mut<WhitelistConfig>(@owner);
        assert!(!contains<String, Whitelist>(&wl_config.whitelists, collection), EINVALID_COLLECTION);
        add<String, Whitelist>(
            &mut wl_config.whitelists, 
            collection,
            Whitelist{
                wl_addrs: table::new<address, bool>(),
                free_quota: free_quota, 
                discount_quota: discount_quota,
            }
        );
    }

    // add a list of addresses by collection name to the whitelist
    public entry fun add_to_whitelist(
        owner: &signer,
        collection: String,
        wl_addresses: vector<address>,
    ) acquires WhitelistConfig {
        assert!(signer::address_of(owner) == @owner, error::permission_denied(ENOT_AUTHORIZED));
        assert!(exists<WhitelistConfig>(@owner), error::permission_denied(ECONFIG_NOT_INITIALIZED));
        let wl_config = borrow_global_mut<WhitelistConfig>(@owner);
        let wl = borrow_mut(&mut wl_config.whitelists, collection);

        let i = 0;
        while (i < vector::length(&wl_addresses)) {
            let addr = *vector::borrow(&wl_addresses, i);
            assert!(!contains<address, bool>(&wl.wl_addrs, addr), EDUPLIDATED_WL_ADDR);
            add(&mut wl.wl_addrs, addr, true);

            i = i + 1;
        };
    }

    public fun label_minted(
        collection: String, addr: address
    ):u8 acquires WhitelistConfig {
        let wl_config = borrow_global_mut<WhitelistConfig>(@owner);
        let wl = borrow_mut<String, Whitelist>(&mut wl_config.whitelists, collection);
        // check if the address is whitelisted
        is_whitelisted(wl, addr);

        // label the account has minted
        *borrow_mut<address, bool>(&mut wl.wl_addrs, addr) = false;

        // decrese
        if (wl.free_quota != 0) {
            wl.free_quota = wl.free_quota - 1;
            return FREE_MINT
        } else if (wl.discount_quota != 0) {
            wl.discount_quota = wl.discount_quota - 1;
            return DISCOUNTED_MINT
        };
        return MINT
    }

    #[view]
    public fun get_collection_left_quota(
        collection: String
    ):(u64, u64) acquires WhitelistConfig {
        let wl_config = borrow_global<WhitelistConfig>(@owner);
        let wl = borrow<String, Whitelist>(&wl_config.whitelists, collection);
        return (wl.free_quota, wl.discount_quota)
    }

    #[view]
    public fun view_is_whitelisted(
        collection: String,
        addr: address
    ):(bool) acquires WhitelistConfig {
        let wl_config = borrow_global<WhitelistConfig>(@owner);
        let wl = borrow<String, Whitelist>(&wl_config.whitelists, collection);
        return contains<address, bool>(&wl.wl_addrs, addr)
    }

    #[view]
    public fun sum(nums: vector<u64>): u64 {
        let i = 0;
        let s = 0;
        while(i < vector::length<u64>(&nums)) {
            s = s + *vector::borrow(&nums, i);
            i = i + 1;
        };
        return s
    }

    public entry fun sum2(nums: vector<u64>) {
        let i = 0;
        let s = 0;
        while(i < vector::length<u64>(&nums)) {
            s = s + *vector::borrow(&nums, i);
            i = i + 1;
        };
    }

}