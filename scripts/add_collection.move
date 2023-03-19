script {
    use std::string;

    fun add_collection(sender: &signer){
        let collection = string::utf8(b"BAYC");
        let f = 0;
        let d = 1;
        owner::whitelist::add_collection(sender, collection, f, d);
    }
}