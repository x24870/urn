script {
    use std::string;
    use std::vector;
    
    fun add_to_whitelist(sender: &signer){
        let collection = string::utf8(b"BAYC");
        let addrs = vector::empty<address>();
        // vector::push_back<address>(&mut addrs, @0x1);
        // vector::push_back<address>(&mut addrs, @0x2);
        vector::push_back<address>(&mut addrs, @0x880f255dea4800fcea4b640cc6a9dfdb711f6d75a89719d7e06f936d3b8dbaea);
        // vector::push_back<address>(&mut addrs, @0x5feb1aa98718058c86105af0904cf3b74ffeb70cc7072124962e23f609d0c47d);
        owner::whitelist::add_to_whitelist(sender, collection, addrs);
    }
}