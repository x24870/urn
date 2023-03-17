script {
    use std::string;
    use std::vector;
    
    fun add_to_whitelist(sender: &signer){
        let collection = string::utf8(b"BAYC");
        let addrs = vector::empty<address>();
        // vector::push_back<address>(&mut addrs, @0x1);
        // vector::push_back<address>(&mut addrs, @0x2);
        vector::push_back<address>(&mut addrs, @0x567e5f9b66053c3d9eb65d38de538c9c52ca4e1b60220fdeec4c405a9dd0ee1c);
        vector::push_back<address>(&mut addrs, @0x5feb1aa98718058c86105af0904cf3b74ffeb70cc7072124962e23f609d0c47d);
        owner::whitelist::add_to_whitelist(sender, collection, addrs);
    }
}