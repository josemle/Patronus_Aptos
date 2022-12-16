module oracle::oracle_test {
    use aptos_std::type_info::{type_of};
    use aptos_framework::account;
    use aptos_framework::aptos_coin;

    use switchboard::aggregator::{Self as switchboard_aggregator};

    use oracle::oracle;

    use mock::test_coin;

    const C1E9: u64 = 1000000000;

    public fun setup_feed<CoinType>(oracle: &signer, feed: address, price: u64, adapter: u8) {
        if (adapter == oracle::switchboard_adapter()) {
            let feed_signer = account::create_account_for_test(feed);
            switchboard_aggregator::new_test(&feed_signer, (price as u128), 9, false);
        } else {
            abort 0
        };

        oracle::update_oracle<CoinType>(oracle, feed, adapter);
    }

    public fun setup_oracle() {
        let oracle = account::create_account_for_test(@oracle);
        let adapter = oracle::switchboard_adapter();

        oracle::init_test(&oracle);
        setup_feed<test_coin::BTC>(&oracle, @0x100A, C1E9 * 20123, adapter);
        setup_feed<test_coin::ETH>(&oracle, @0x100B, C1E9 * 1567, adapter);
        setup_feed<test_coin::BNB>(&oracle, @0x100C, C1E9 * 345, adapter);
        setup_feed<test_coin::SOL>(&oracle, @0x100D, C1E9 * 34, adapter);
        setup_feed<test_coin::USDT>(&oracle, @0x100E, C1E9, adapter);
        setup_feed<test_coin::USDC>(&oracle, @0x100F, C1E9, adapter);
        setup_feed<aptos_coin::AptosCoin>(&oracle, @0x1010, C1E9 * 4, adapter);
    }

    public fun update_price<CoinType>(price: u64) {
        let (feed, adapter) = oracle::lookup(type_of<CoinType>());
        let feed_signer_cap = account::create_test_signer_cap(feed);
        let feed_signer = account::create_signer_with_capability(&feed_signer_cap);

        if (adapter == oracle::switchboard_adapter()) {
            switchboard_set_price<CoinType>(&feed_signer, price);
        } else {
            abort 0
        }
    }

    fun switchboard_set_price<CoinType>(feed_signer: &signer, price: u64) {
        switchboard_aggregator::update_value(feed_signer, (price as u128), 9, false);
    }
}
