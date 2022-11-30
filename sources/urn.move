module owner::urn {
    use aptos_framework::account;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use aptos_token::token;
    use std::bcs;
    use aptos_framework::event::{Self, EventHandle};

    const MAX_U64: u64 = 18446744073709551615;
    const COLLECTION_NAME: vector<u8> = b"URN";

    struct MintEvent has store, drop {
        minter: address,
    }

    struct UrnMinter has store, key {
        signer_cap: account::SignerCapability,
        mint_event: EventHandle<MintEvent>,
    }

    const ENOT_AUTHORIZED: u64 = 1;
    const EHAS_ALREADY_CLAIMED_MINT: u64 = 2;
    const EMINTING_NOT_ENABLED: u64 = 3;

    const TOKEN_NAME: vector<u8> = b"URN";

    const TOKEN_URL: vector<u8> = b"https://urn.jpg";

    fun init_module(sender: &signer) {
        let (resource, signer_cap) = account::create_resource_account(sender, vector::singleton(1));


        move_to(sender, UrnMinter {
            signer_cap,
            mint_event: account::new_event_handle<MintEvent>(&resource),
        });
    }

    fun get_resource_signer(): signer acquires UrnMinter {
        account::create_signer_with_capability(&borrow_global<UrnMinter>(@owner).signer_cap)
    }

    const HEX_SYMBOLS: vector<u8> = b"0123456789abcdef";

    public fun mint(sign: &signer) acquires UrnMinter {
        // Mints 1 NFT to the signer
        let sender = signer::address_of(sign);

        let resource = get_resource_signer();

        let um = borrow_global_mut<UrnMinter>(@owner);

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
            &resource,
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

        let token_id = token::mint_token(&resource, token_data_id, 1);

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


}