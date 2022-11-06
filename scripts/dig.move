script {
    fun dig(sender: &signer){
        owner::graveyard::dig(sender);
    }
}