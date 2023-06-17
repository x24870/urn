module owner::urn {
    use aptos_framework::account::{Self};
    use aptos_std::table::{Self, Table, borrow, borrow_mut, contains, add};
    use std::signer;
    use std::string::{Self, String};
    use aptos_token::token::{Self, TokenId};
    use std::bcs;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_token::property_map::{Self};
    use owner::pseudorandom::{rand_u8_range_no_sender};

    const MAX_U64: u64 = 18446744073709551615;
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";

    friend owner::urn_to_earn;
    friend owner::knife;

    struct MintEvent has store, drop {
        minter: address,
    }

    struct BurnEvent has store, drop {
        burner: address,
    }

    struct BurnGoldenUrnEvent has store, drop {
        burner: address,
    }

    struct UrnMinter has store, key {
        res_acct_addr: address,
        urn_token_data_id: token::TokenDataId,
        golden_urn_token_data_id: token::TokenDataId,
        collection: string::String,
        mint_event: EventHandle<MintEvent>,
        burn_event: EventHandle<BurnEvent>,
        burn_golden_urn_event: EventHandle<BurnGoldenUrnEvent>,
        urn_burned: Table<address, u8>,
        golden_urn_burned: Table<address, u8>,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;
    const ENOT_OWN_THIS_TOKEN: u64 = 4;
    const ETOKEN_PROP_MISMATCH: u64 = 5;
    const EURN_OVERFLOW: u64 = 6;
    const EURN_NOT_FULL: u64 = 7;

    const URN_TOKEN_NAME: vector<u8> = b"urn";
    const GOLDEN_URN_TOKEN_NAME: vector<u8> = b"golden urn";
    const ASH_PROP_NAME: vector<u8> = b"ash";
    const URN_URL: vector<u8> = b"https://swtj5ht5rztldcg6ag5wzbvr5jpbwaj2pvb7ojiq4dzk6kop5knq.arweave.net/laaenn2OZrGI3gG7bIax6l4bATp9Q_clEODyrynP6ps";
    const GOLDEN_URN_URL: vector<u8> = b"https://35hkq3ikzvppn4nyqyfrw452mmxx7oxguslawh46g4cd3x4rclna.arweave.net/306obQrNXvbxuIYLG3O6Yy9_uuaklgsfnjcEPd-REto";


    public(friend) fun init_urn(
        sender: &signer, resource: &signer, collection_name: String
    ) {
        // Don't run setup more than once
        if (exists<UrnMinter>(signer::address_of(sender))) {
            return
        };

        // create urn token data
        let urn_token_data_id = create_urn_token_data(
            resource, 
            collection_name,
            string::utf8(URN_TOKEN_NAME),
            string::utf8(URN_URL)
            );
        let golden_urn_token_data_id = create_urn_token_data(
            resource, 
            collection_name,
            string::utf8(GOLDEN_URN_TOKEN_NAME),
            string::utf8(GOLDEN_URN_URL)
            );

        move_to(sender, UrnMinter {
            res_acct_addr: signer::address_of(resource),
            urn_token_data_id: urn_token_data_id,
            golden_urn_token_data_id: golden_urn_token_data_id,
            collection: collection_name,
            mint_event: account::new_event_handle<MintEvent>(resource),
            burn_event: account::new_event_handle<BurnEvent>(resource),
            burn_golden_urn_event: account::new_event_handle<BurnGoldenUrnEvent>(resource),
            urn_burned: table::new<address, u8>(),
            golden_urn_burned: table::new<address, u8>(),
        });
    }

    fun create_urn_token_data(
        resource: &signer, 
        collection_name: String,
        tokendata_name: String,
        token_uri: String,
    ): token::TokenDataId {
        let nft_maximum: u64 = 0; // unlimited
        let description = string::utf8(b"just an urn");
        let royalty_payee_address: address = @owner;
        let royalty_points_denominator: u64 = 100;
        let royalty_points_numerator: u64 = 5;
        let token_mutate_config = token::create_token_mutability_config(
            &vector<bool>[ true, true, true, true, true ]); // max, uri, royalty, description, property
        let default_keys = vector<String>[
            string::utf8(b"type"), string::utf8(ASH_PROP_NAME), string::utf8(BURNABLE_BY_OWNER)
        ];
        let default_vals = vector<vector<u8>>[
            bcs::to_bytes<string::String>(&tokendata_name), bcs::to_bytes<u8>(&0), bcs::to_bytes<bool>(&true)
        ];
        let default_types = vector<String>[
            string::utf8(b"0x1::string::String"), string::utf8(b"u8"), string::utf8(b"bool")
        ];

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
            default_keys,
            default_vals,
            default_types
        );

        return token_data_id
    }

    public(friend) fun mint(sign: &signer, resource: &signer):TokenId acquires UrnMinter {
        let urnMinter = borrow_global_mut<UrnMinter>(@owner);

        let amount = 1;
        let token_id = token::mint_token(resource, urnMinter.urn_token_data_id, amount);
        
        // emit mint urn event
        event::emit_event<MintEvent>(
            &mut urnMinter.mint_event,
            MintEvent {
                minter: signer::address_of(sign),
            }
        );

        token_id
    }

    public(friend) fun mint_golden_urn(sign: &signer, resource: &signer):TokenId acquires UrnMinter {
        let urnMinter = borrow_global_mut<UrnMinter>(@owner);
        let token_id = token::mint_token(resource, urnMinter.golden_urn_token_data_id, 1);
        
        // emit mint urn event
        event::emit_event<MintEvent>(
            &mut urnMinter.mint_event,
            MintEvent {
                minter: signer::address_of(sign),
            }
        );

        token_id
    }

    public fun get_ash_fullness(token_id: TokenId, token_owner: address): u8 {
        let balance = token::balance_of(token_owner, token_id);
        assert!(balance != 0, ENOT_OWN_THIS_TOKEN);
        let properties = token::get_property_map(token_owner, token_id);
        let fullness = property_map::read_u8(&properties, &string::utf8(ASH_PROP_NAME));
        fullness
    }

    public fun get_urn_type(token_id: TokenId): String {
        let (
            _creator_addr, 
            _collection, 
            name, 
            _prop_ver
            ) = token::get_token_id_fields(&token_id);
        name
    }

    public fun get_urn_token_name(): vector<u8> {
        URN_TOKEN_NAME
    }

    public(friend) fun fill(
        sign: &signer, resource: &signer, token_id: TokenId, amount: u8
    ): TokenId {
        let token_owner = signer::address_of(sign);
        let fillness = get_ash_fullness(token_id, token_owner);
        fillness = fillness + amount;
        assert!(fillness <= 100, EURN_OVERFLOW);

        let keys = vector<String>[string::utf8(ASH_PROP_NAME)];
        let vals = vector<vector<u8>>[bcs::to_bytes<u8>(&fillness)];
        let types = vector<String>[string::utf8(b"u8")];

        token::mutate_one_token(
            resource, 
            signer::address_of(sign),
            token_id,
            keys,
            vals,
            types
        )
    }

    public(friend) fun rand_drain(
        resource: &signer,
        victim: address,
        urn_been_robbed: TokenId,
    ): u8{
        let fillness = get_ash_fullness(urn_been_robbed, victim);
        // TODO make sure high > low, and low >= 0
        if (fillness == 0) {
            return 0 // workaround for that rand_u8_range_no_sender(0, 0) will abort
        };
        let robbed = rand_u8_range_no_sender(0, fillness); // TODO: how much ash to rob?
        fillness = fillness - robbed;

        let keys = vector<String>[string::utf8(ASH_PROP_NAME)];
        let vals = vector<vector<u8>>[bcs::to_bytes<u8>(&fillness)];
        let types = vector<String>[string::utf8(b"u8")];

        token::mutate_one_token(
            resource, 
            victim,
            urn_been_robbed,
            keys,
            vals,
            types
        );

        return robbed
    }

    public(friend) fun burn_filled_urn(
        sign: &signer, token_id: TokenId
    ) acquires UrnMinter {
        let sign_addr = signer::address_of(sign);
        // check the user owns the urn
        let balance = token::balance_of(sign_addr, token_id);
        assert!(balance != 0, ENOT_OWN_THIS_TOKEN);

        // check the is full
        let fullness = get_ash_fullness(token_id, sign_addr);
        assert!(fullness == 100, EURN_NOT_FULL);
        let (
            creator_addr, 
            collection, 
            name, 
            prop_ver
            ) = token::get_token_id_fields(&token_id);

        token::burn(
            sign,
            creator_addr,
            collection,
            name,
            prop_ver,
            1,
        );

        let urnMinter = borrow_global_mut<UrnMinter>(@owner);

        // emit event and record to map
        if (is_golden_urn(token_id)) {
            event::emit_event<BurnGoldenUrnEvent>(
                &mut urnMinter.burn_golden_urn_event,
                BurnGoldenUrnEvent {
                    burner: sign_addr,
                }
            );
            if (contains<address, u8>(
                &urnMinter.golden_urn_burned, sign_addr)) {
                    let v = *borrow(&urnMinter.golden_urn_burned, sign_addr);
                    *borrow_mut(&mut urnMinter.golden_urn_burned, sign_addr) = v + 1;
                } else {
                    add<address, u8>(&mut urnMinter.golden_urn_burned, sign_addr, 1);
                }
        } else {
            event::emit_event<BurnEvent>(
                &mut urnMinter.burn_event,
                BurnEvent {
                    burner: sign_addr,
                }
            );
            if (contains<address, u8>(
                &urnMinter.urn_burned, sign_addr)) {
                    let v = *borrow(&urnMinter.urn_burned, sign_addr);
                    *borrow_mut(&mut urnMinter.urn_burned, sign_addr) = v + 1;
                } else {
                    add<address, u8>(&mut urnMinter.urn_burned, sign_addr, 1);
                }
        }
    }

    public(friend) fun add_burned(
        sign: &signer, addr: address, is_golden: bool
    ) acquires UrnMinter {
        assert!(signer::address_of(sign)==@owner, ENOT_AUTHORIZED);
        let um = borrow_global_mut<UrnMinter>(@owner);

        // emit event and record to map
        if (is_golden) {
            if (contains<address, u8>(&um.golden_urn_burned, addr)) {
                    let v = *borrow(&um.golden_urn_burned, addr);
                    *borrow_mut(&mut um.golden_urn_burned, addr) = v + 1;
                } else {
                    add<address, u8>(&mut um.golden_urn_burned, addr, 1);
                }
        } else {
            if (contains<address, u8>(&um.urn_burned, addr)) {
                    let v = *borrow(&um.urn_burned, addr);
                    *borrow_mut(&mut um.urn_burned, addr) = v + 1;
                } else {
                    add<address, u8>(&mut um.urn_burned, addr, 1);
                }
        }
    }

    public fun is_full(token_id: TokenId, token_owner: address) {
        assert!(get_ash_fullness(token_id, token_owner) == 100, ETOKEN_PROP_MISMATCH);
    }

    public fun is_golden_urn(token_id: TokenId): bool {
        get_urn_type(token_id) == string::utf8(GOLDEN_URN_TOKEN_NAME)
    }

    #[view]
    public fun urn_burned(addr: address): u8 acquires UrnMinter {
        let um = borrow_global<UrnMinter>(@owner);
        if (contains<address, u8>(&um.urn_burned, addr)) {
                return *borrow(&um.urn_burned, addr)
        };

        return 0
    }
}