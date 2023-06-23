script {
    use std::string;
    use aptos_token::token::{Self};
    
    fun transfer_knife(sender: &signer){
        let collection = string::utf8(b"urn");
        let token_name = string::utf8(b"knife");
        let creator = @0xc8d6637a9adc7023cde6f50bc26171151c53ede0eacc4167b832e61ebfde2cff;

        // let to = @0xb34c0314d90b2597f2531119601f4ad7fe9db4eb7671265e93c905a46aa92860; // user
        let to = @0x0e138de41892cba07ad1be13880902c7b7a143b7e7fa044b52bb4c52b150d915; // user2
        let token_id = token::create_token_id_raw(creator, collection, token_name, 0);
        token::transfer(sender, token_id, to, 3);
    }
}