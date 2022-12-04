module owner::urn {
    use aptos_framework::account;
    use std::signer;
    use std::string::{Self, String};
    // use std::vector;
    use aptos_token::token::{Self, TokenId};
    use std::bcs;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_token::property_map::{Self};
    use owner::shovel;
    use owner::bone;

    const MAX_U64: u64 = 18446744073709551615;
    const COLLECTION_NAME: vector<u8> = b"URN";

    struct MintEvent has store, drop {
        minter: address,
    }

    struct UrnMinter has store, key {
        // signer_cap: account::SignerCapability,
        res_acct_addr: address,
        mint_event: EventHandle<MintEvent>,
        token_data_id: token::TokenDataId,
        collection: string::String,
        name: string::String,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;

    const TOKEN_NAME: vector<u8> = b"URN";

    const TOKEN_URL: vector<u8> = b"https://gateway.pinata.cloud/ipfs/QmSioUrHchtStNHXCHSzS8M6HVHDV8dPojgwF4EqpFBtf5/urn.jpg";

    fun init_module(sender: &signer) {
        // let (resource, signer_cap) = account::create_resource_account(sender, vector::singleton(1));
        shovel::init(sender);
        bone::init(sender);
        let resource = shovel::get_resource_signer();
        // let signer_cap = shovel::get_signer_cap();

        let token_data_id = create_urn_token_data(&resource);
        let res_acct_addr = signer::address_of(&resource);

        move_to(sender, UrnMinter {
            // signer_cap,
            res_acct_addr,
            mint_event: account::new_event_handle<MintEvent>(&resource),
            token_data_id: token_data_id,
            collection: string::utf8(COLLECTION_NAME),
            name: string::utf8(TOKEN_NAME),
        });
    }

    // fun get_resource_signer(): signer acquires UrnMinter {
    //     account::create_signer_with_capability(&borrow_global<UrnMinter>(@owner).signer_cap)
    // }

    const HEX_SYMBOLS: vector<u8> = b"0123456789abcdef";

    fun create_urn_token_data(resource: &signer): token::TokenDataId {
        // Set up the NFT
        let collection_name = string::utf8(COLLECTION_NAME);
        let tokendata_name = string::utf8(TOKEN_NAME);
        let nft_maximum: u64 = 0;
        let description = string::utf8(b"just a urn");
        let token_uri: string::String = string::utf8(TOKEN_URL);
        let royalty_payee_address: address = @owner;
        let royalty_points_denominator: u64 = 100;
        let royalty_points_numerator: u64 = 5;
        let token_mutate_config = token::create_token_mutability_config(
            &vector<bool>[ false, true, false, false, true ]); // max, uri, royalty, description, property
        // let default_keys: vector<string::String> = vector::singleton(string::utf8(b"material"));
        // let default_vals: vector<vector<u8>> = vector::singleton(bcs::to_bytes<string::String>(&string::utf8(b"ceramic")));
        // let default_types: vector<string::String> = vector::singleton(string::utf8(b"vector<u8>"));

        let default_keys = vector<String>[
            string::utf8(b"material"), string::utf8(b"ash")
        ];
        let default_vals = vector<vector<u8>>[
            bcs::to_bytes<string::String>(&string::utf8(b"ceramic")), bcs::to_bytes<u8>(&0)
        ];
        let default_types = vector<String>[
            string::utf8(b"vector<u8>"), string::utf8(b"u8")
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
            default_types,
        );

        return token_data_id
    }

    public fun mint(sign: &signer) acquires UrnMinter {
        // Mints 1 NFT to the signer
        let sender = signer::address_of(sign);

        let resource = shovel::get_resource_signer();

        let um = borrow_global_mut<UrnMinter>(@owner);

        let token_id = token::mint_token(&resource, um.token_data_id, 1);

        token::initialize_token_store(sign);
        token::opt_in_direct_transfer(sign, true);
        token::transfer(&resource, token_id, sender, 1);

        event::emit_event<MintEvent>(
            &mut um.mint_event,
            MintEvent {
                minter: signer::address_of(sign),
            }
        );
    }

    // public fun fill(sign: &signer, token_id: TokenId, amount: u8) {
        
    //     token::mutate_one_token(
    //         sign, 
    //         signer::address_of(sign),
    //         token_id,

    //         )
    // }

    public fun destroy_urn(sign: &signer) acquires UrnMinter {
        let um = borrow_global<UrnMinter>(@owner);

        token::burn(
            sign,
            um.res_acct_addr,
            um.collection,
            um.name,
            0,
            1,
        );
    }

    public fun is_full(sign: &signer, token_id: TokenId): bool {
        let pm = token::get_property_map(
            signer::address_of(sign),
            token_id,
        );

        if (property_map::read_u64(&pm, &string::utf8(b"ash")) == 100) {
            true
        } else {
            false
        }
        
    }

    #[test(user = @0xa11ce, owner = @owner)]
    fun test_destroy_urn(owner: &signer, user: &signer) {
        account::create_account_for_test(signer::address_of(user));
        account::create_account_for_test(signer::address_of(owner));

        init_module(owner);
    }
}