script {
    use std::string;
    use std::vector;
    
    fun add_to_whitelist(sender: &signer){
        let collection = string::utf8(b"Aptos Monkeys");
        let addrs = vector::empty<address>();
        // vector::push_back<address>(&mut addrs, @0x1);
        // vector::push_back<address>(&mut addrs, @0x2);
        // vector::push_back<address>(&mut addrs, @0x880f255dea4800fcea4b640cc6a9dfdb711f6d75a89719d7e06f936d3b8dbaea);
        // vector::push_back<address>(&mut addrs, @0x7b251d07fcd75d1a9ea04875d81717fd096d8edcb945a6fab60e5bb2496dea2b);
        // vector::push_back<address>(&mut addrs, @0x194a3968600fce6c6b0f9f83d4a60a44114d96dce0b4b37e88538d9ce1f2bdc1);
        // vector::push_back<address>(&mut addrs, @0x5766d4da8548b52cbcdd2b0377cfc3ecff61d5e4929c778cbd28606fe96e423d);
        // vector::push_back<address>(&mut addrs, @0x180678030b6848b0601683ab4e97ad651ff5880bdd938754f73afb09a7e46340);
        // vector::push_back<address>(&mut addrs, @0xb8ab31b4afab9827989f8eefcd8efc89de868af4ca386b70e79acdf7ced7b3ef);
        // vector::push_back<address>(&mut addrs, @0xc5838c5cb909055bd603f55d786e785a4feb8471dae6e69d977ec78ed2c83cbe);
        // vector::push_back<address>(&mut addrs, @0x4a49995a1557e830261d2240ecb58438cb726dfe6f5e5944c95a8b8923192447);
        // vector::push_back<address>(&mut addrs, @0x00fa702aad9a3e08a1668122de0718c0eec7d930c740a2164e534bed53de4911);
        // vector::push_back<address>(&mut addrs, @0x14bb3a81a6a92db55f4ef6f4f1abef445c418a33d5ddfd4bd672346c9db38add);
        // vector::push_back<address>(&mut addrs, @0xf5f8fa110109823bd52c4e9e807d3d1dddefddfb315fcd55ddb28e315c1615d3);

        // vector::push_back<address>(&mut addrs, @0xedee10d387fcc2f10d54d12dd69ce973dd8b4f0e7a59f0fbb57db64500d7ce5c);
        // vector::push_back<address>(&mut addrs, @0x946280a55720fd8665d927ee7c25b8eeeb323870619fcffb29c8115f1aedfe24);
        // vector::push_back<address>(&mut addrs, @0xdb0811ac77320edb8a76520cea79af8850d2e9ca56f6cbf81dbbfd1279abe99a);
        // vector::push_back<address>(&mut addrs, @0x46d60c35125f77f118da6be257c474136829c89ce4d95e51cb5eadf4da308a85);
        // vector::push_back<address>(&mut addrs, @0x495947c96cf56b18480d03603be8c53bfdc74b17221431debe0f4472672da99d);
        // vector::push_back<address>(&mut addrs, @0xaaca0be9a81bd6fbf0cf7204ccaf6cbf1c1798abd90ce2fa018588df1d59ae07);
        vector::push_back<address>(&mut addrs, @0xc21294798df7a0577552de536a249b1ad506140ae980c93a6feff9d2b962037a);
        owner::whitelist::add_to_whitelist(sender, collection, addrs);
    }
}