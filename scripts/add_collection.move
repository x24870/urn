script {
    use std::string;

    fun add_collection(sender: &signer){
        let collection = string::utf8(b"Aptos Monkeys");
        let f = 50;
        let d = 200;
        owner::whitelist::add_collection(sender, collection, f, d);

        let collection = string::utf8(b"Blocto");
        f = 4;
        d = 4;
        owner::whitelist::add_collection(sender, collection, f, d);
    }
}