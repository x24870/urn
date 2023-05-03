script {
    use std::string;
    use std::vector;
    
    fun add_to_whitelist(sender: &signer){
        let collection = string::utf8(b"Blocto");
        let addrs = vector::empty<address>();
        // vector::push_back<address>(&mut addrs, @0x1);
        // vector::push_back<address>(&mut addrs, @0x2);
        // vector::push_back<address>(&mut addrs, @0x880f255dea4800fcea4b640cc6a9dfdb711f6d75a89719d7e06f936d3b8dbaea);
        vector::push_back<address>(&mut addrs, @0x7b251d07fcd75d1a9ea04875d81717fd096d8edcb945a6fab60e5bb2496dea2b);
        vector::push_back<address>(&mut addrs, @0x194a3968600fce6c6b0f9f83d4a60a44114d96dce0b4b37e88538d9ce1f2bdc1);
        vector::push_back<address>(&mut addrs, @0x5766d4da8548b52cbcdd2b0377cfc3ecff61d5e4929c778cbd28606fe96e423d);
        vector::push_back<address>(&mut addrs, @0x180678030b6848b0601683ab4e97ad651ff5880bdd938754f73afb09a7e46340);
        vector::push_back<address>(&mut addrs, @0xb8ab31b4afab9827989f8eefcd8efc89de868af4ca386b70e79acdf7ced7b3ef);
        vector::push_back<address>(&mut addrs, @0xc5838c5cb909055bd603f55d786e785a4feb8471dae6e69d977ec78ed2c83cbe);
        vector::push_back<address>(&mut addrs, @0x4a49995a1557e830261d2240ecb58438cb726dfe6f5e5944c95a8b8923192447);
        vector::push_back<address>(&mut addrs, @0x00fa702aad9a3e08a1668122de0718c0eec7d930c740a2164e534bed53de4911);
        vector::push_back<address>(&mut addrs, @0x14bb3a81a6a92db55f4ef6f4f1abef445c418a33d5ddfd4bd672346c9db38add);
        owner::whitelist::add_to_whitelist(sender, collection, addrs);
    }
}