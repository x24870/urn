module owner::leaderboard {
    use std::signer;
    use std::vector;
    use aptos_token::token::{TokenId};
    // use owner::urn;

    const ECONFIG_INITIALIZED: u64 = 1;

    const LEADERBOARD_SIZE: u64 = 10;

    struct Leaderboard has key {
        ranks: vector<Rank>,
    }

    struct Rank has store, drop {
        addr: address,
        token: TokenId,
        exp: u64,
    }

    public fun init_leaderboard(owner: &signer) {
        assert!(!exists<Leaderboard>(signer::address_of(owner)), ECONFIG_INITIALIZED);
        move_to(owner, Leaderboard{ranks: vector::empty<Rank>()});
    }

    // the leaderboard is order by exp in ascending order
    public fun update_leaderboard(
        addr: address, token: TokenId, exp: u64
    ) acquires Leaderboard {
        let leaderboard = borrow_global_mut<Leaderboard>(@owner);
        let ranks = &mut leaderboard.ranks;

        // check if the token is already in the leaderboard
        // if in leaderboard, remove it
        let (in_leaderboard, idx) = in_leaderboard(ranks, token);
        if (in_leaderboard) {
            vector::remove(ranks, idx);
        };

        // insert the token into the leaderboard
        insert_leaderboard(ranks, addr, token, exp);
    }

    fun in_leaderboard(ranks: &vector<Rank>, token: TokenId): (bool, u64) {
        let len = vector::length(ranks);
        let i = 0;
        while (i < len) {
            let rank = vector::borrow(ranks, i);
            if (rank.token == token) {
                return (true, i)
            };
            i = i + 1;
        };
        return (false, 0)
    }

    fun insert_leaderboard(ranks: &mut vector<Rank>, addr: address, token: TokenId, exp: u64) {
        let i = 0;
        let len = vector::length(ranks);
        // let exp = urn::get_exp(urn_owner, urn);
        while (i < len) {
            let rank = vector::borrow(ranks, i);
            if (rank.exp > exp) {
                break
            };
            i = i + 1;
        };

        // this token is less than all the utokenrns in the leaderboard
        if (i == 0 && len >= LEADERBOARD_SIZE) {
            return
        };

        let rank = Rank{addr: addr, token: token, exp: exp};
        vector::insert(ranks, i, rank);

        // if length > 10, pop first(the lowest)
        if (len > LEADERBOARD_SIZE) {
            vector::remove(ranks, 0);
        };
    }
}