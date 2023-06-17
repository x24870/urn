script {
    use std::string;
    use aptos_token::token::{Self};
    
    fun transfer_knife(sender: &signer){
        let collection = string::utf8(b"urn");
        let token_name = string::utf8(b"knife");
        let creator = @0xa9186f2d8c237d16f9cbf4a1fc0f7e87d80e6d3d002c3b7a05a3b4e46a6b9e92;

        let to = @0xc4bee3d265c6d7129657953584f33943e970aca91bc864d9ca25dada3da90916;
        let token_id = token::create_token_id_raw(creator, collection, token_name, 0);
        token::transfer(sender, token_id, to, 3);
    }
}