script {
    fun mint_shovel(sender: &signer){
        owner::shovel::mint(sender);
    }
}