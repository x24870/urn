script {
    fun mint_shovel(sender: &signer){
        owner::shovel::claim_mint(sender);
    }
}