module owner::urn {
    use aptos_framework::account::{Self};
    use std::signer;
    use std::string::{Self, String};
    use aptos_token::token::{Self, TokenId};
    use std::bcs;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_token::property_map::{Self};

    const MAX_U64: u64 = 18446744073709551615;
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";

    friend owner::urn_to_earn;

    struct MintEvent has store, drop {
        minter: address,
    }

    struct UrnMinter has store, key {
        res_acct_addr: address,
        token_data_id: token::TokenDataId,
        collection: string::String,
        name: string::String,
        mint_event: EventHandle<MintEvent>,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;
    const ENOT_OWN_THIS_TOKEN: u64 = 4;

    const TOKEN_NAME: vector<u8> = b"URN";
    const TOKEN_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/urn.jpg";

    public(friend) fun init_urn(
        sender: &signer, resource: &signer, collection_name: String
    ) {
        // Don't run setup more than once
        if (exists<UrnMinter>(signer::address_of(sender))) {
            return
        };

        // create urn token data
        let token_data_id = create_urn_token_data(resource, collection_name);

        move_to(sender, UrnMinter {
            res_acct_addr: signer::address_of(resource),
            token_data_id: token_data_id,
            collection: collection_name,
            name: string::utf8(TOKEN_NAME),
            mint_event: account::new_event_handle<MintEvent>(resource),
        });
    }

    fun create_urn_token_data(resource: &signer, collection_name: String): token::TokenDataId {
        let collection_name = collection_name;
        let tokendata_name = string::utf8(TOKEN_NAME);
        let nft_maximum: u64 = 0; // unlimited urn
        let description = string::utf8(b"just an urn");
        let token_uri: string::String = string::utf8(TOKEN_URL);
        let royalty_payee_address: address = @owner;
        let royalty_points_denominator: u64 = 100;
        let royalty_points_numerator: u64 = 5;
        let token_mutate_config = token::create_token_mutability_config(
            &vector<bool>[ true, true, true, true, true ]); // max, uri, royalty, description, property
        let default_keys = vector<String>[
            string::utf8(b"MATERIAL"), string::utf8(b"ASH"), string::utf8(BURNABLE_BY_OWNER)
        ];
        let default_vals = vector<vector<u8>>[
            bcs::to_bytes<string::String>(&string::utf8(b"ceramic")), bcs::to_bytes<u8>(&0), bcs::to_bytes<bool>(&true)
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
        let token_id = token::mint_token(resource, urnMinter.token_data_id, amount);
        
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
        let token_id = token::mint_token(resource, urnMinter.token_data_id, 1);
        
        // emit mint urn event
        event::emit_event<MintEvent>(
            &mut urnMinter.mint_event,
            MintEvent {
                minter: signer::address_of(sign),
            }
        );

        let keys = vector<String>[string::utf8(b"MATERIAL")];
        let vals = vector<vector<u8>>[bcs::to_bytes<string::String>(&string::utf8(b"gold"))];
        let types = vector<String>[string::utf8(b"0x1::string::String")];
        
        token_id = token::mutate_one_token(
            resource, 
            signer::address_of(resource), // token haven't transfered
            token_id,
            keys,
            vals,
            types
        );

        token_id
    }

    public fun get_ash_fullness(token_id: TokenId, token_owner: address): u8 {
        let balance = token::balance_of(token_owner, token_id);
        assert!(balance != 0, ENOT_OWN_THIS_TOKEN);
        let properties = token::get_property_map(token_owner, token_id);
        let fullness = property_map::read_u8(&properties, &string::utf8(b"ASH"));
        fullness
    }

    public fun get_urn_material(token_id: TokenId, token_owner: address): String {
        let balance = token::balance_of(token_owner, token_id);
        assert!(balance != 0, ENOT_OWN_THIS_TOKEN);
        let properties = token::get_property_map(token_owner, token_id);
        let material = property_map::read_string(&properties, &string::utf8(b"MATERIAL"));
        material
    }

    public fun fill(
        sign: &signer, resource: &signer, token_id: TokenId, amount: u8
    ): TokenId {
        let token_owner = signer::address_of(sign);
        let fillness = get_ash_fullness(token_id, token_owner);
        fillness = fillness + amount;

        let keys = vector<String>[string::utf8(b"ASH")];
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


    // public fun is_full(sign: &signer, token_id: TokenId): bool {
    //     let pm = token::get_property_map(
    //         signer::address_of(sign),
    //         token_id,
    //     );

    //     if (property_map::read_u64(&pm, &string::utf8(b"ash")) == 100) {
    //         true
    //     } else {
    //         false
    //     }
    // }

    // #[test(user = @0xa11ce, owner = @owner)]
    // fun test_destroy_urn(
    //     owner: &signer, user: &signer
    //     ) acquires UrnMinter {
    //     account::create_account_for_test(signer::address_of(user));
    //     account::create_account_for_test(signer::address_of(owner));

    //     init_module(owner);
    //     mint(user);
    //     destroy_urn(user);
    // }
}