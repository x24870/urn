module owner::graveyard {
    // use aptos_framework::account;
    // use aptos_std::table;
    // use std::signer;
    // use std::string::{Self};
    // use std::vector;
    // use aptos_token::token::{Self};
    use owner::bone;
    use owner::shovel::{Self};


    struct Graveyard has store, key {}


    fun init_module(sender: &signer) {
        move_to(sender, Graveyard {});
    }

    public entry fun dig(sender: &signer) {
        // burn 1 shovel
        shovel::destroy_shovel(sender);

        // bone::mint(sender);
        bone::batch_mint(sender, 100)
    }
}