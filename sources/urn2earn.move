module owner::urn {
    use aptos_framework::account;
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use aptos_token::token::{Self, TokenId};
    use std::bcs;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_token::property_map::{Self};
    // use owner::shovel;
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

        move_to(sender, UrnToEarnConfig {
            description: description,
            name: name,
            uri: uri,
            maximum: maximum,
            mutate_config: mutate_setting,
            cap: signer_cap
        });
    }

    const HEX_SYMBOLS: vector<u8> = b"0123456789abcdef";

}