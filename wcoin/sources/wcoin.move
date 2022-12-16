module wcoin::wcoin {
    use std::string::{utf8, append};
    use aptos_std::signer::{address_of};
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability};
    use aptos_framework::resource_account;

    struct W<phantom CoinType> {}

    struct WCoinCapability has key { signer_cap: SignerCapability }

    fun init_module(wcoin: &signer) {
        let signer_cap = resource_account::retrieve_resource_account_cap(wcoin, @bank);
        move_to(wcoin, WCoinCapability { signer_cap });
    }

    public fun retrieve_signer_cap(bank: &signer): SignerCapability
        acquires WCoinCapability
    {
        assert!(address_of(bank) == @bank, 0);
        let WCoinCapability { signer_cap } = move_from<WCoinCapability>(@wcoin);
        signer_cap
    }

    public fun create<CoinType>(wcoin_signer_cap: &SignerCapability):
        (BurnCapability<W<CoinType>>, FreezeCapability<W<CoinType>>, MintCapability<W<CoinType>>)
    {
        let wcoin_signer = account::create_signer_with_capability(wcoin_signer_cap);

        let name = utf8(b"Wrapped ");
        append(&mut name, coin::name<CoinType>());

        let symbol = utf8(b"W_");
        append(&mut symbol, coin::symbol<CoinType>());

        coin::initialize<W<CoinType>>(
            &wcoin_signer,
            name,
            symbol,
            coin::decimals<CoinType>(),
            true,
        )
    }


    #[test_only]
    public fun init_test(wcoin: &signer) {
        init_module(wcoin);
    }
}
