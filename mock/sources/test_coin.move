module mock::test_coin {
    use aptos_framework::coin::{Self, Coin, BurnCapability, FreezeCapability, MintCapability};
    use aptos_std::type_info::{Self, type_of};
    use std::signer::{address_of};
    use std::string::{utf8};

    struct BTC {}
    struct ETH {}
    struct BNB {}
    struct SOL {}
    struct USDT {}
    struct USDC {}

    struct CapStore<phantom CoinType> has key {
        mint_cap: MintCapability<CoinType>,
        burn_cap: BurnCapability<CoinType>,
        freeze_cap: FreezeCapability<CoinType>,
    }

    fun init_coin<CoinType>(account: &signer, decimals: u8) {
        let coin_type = type_of<CoinType>();
        let name = type_info::struct_name(&coin_type);

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<CoinType>(
            account,
            utf8(name),
            utf8(name),
            decimals,
            false,
        );

        move_to(account, CapStore { burn_cap, freeze_cap, mint_cap });
    }

    fun init_module(mock: &signer) {
        init_coin<BTC>(mock, 9);
        init_coin<ETH>(mock, 9);
        init_coin<BNB>(mock, 9);
        init_coin<SOL>(mock, 9);
        init_coin<USDT>(mock, 9);
        init_coin<USDC>(mock, 9);
    }

    public fun mint<CoinType>(amount: u64): Coin<CoinType>
        acquires CapStore
    {
        let pool = borrow_global<CapStore<CoinType>>(@mock);
        coin::mint<CoinType>(amount, &pool.mint_cap)
    }

    public entry fun fund<CoinType>(user: &signer, amount: u64)
        acquires CapStore
    {
        let pool = borrow_global<CapStore<CoinType>>(@mock);
        let coins = coin::mint<CoinType>(amount, &pool.mint_cap);
        coin::deposit(address_of(user), coins);
    }

    #[test_only]
    public fun init_test(mock: &signer) {
        init_module(mock);
    }
}
