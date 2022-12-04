script {
    fun mint_urn(sender: &signer){
        owner::urn::mint(sender);
    }
}