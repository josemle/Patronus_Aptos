module switchboard::aggregator {
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::timestamp;
    use aptos_framework::block;
    use switchboard::math::{Self, SwitchboardDecimal};
    use switchboard::errors;
    use std::option::{Self, Option};
    use std::signer;
    use std::vector;
    use std::coin::{Self, Coin};

    // Aggregator Round Data
    struct LatestConfirmedRound {}
    struct CurrentRound {}
    struct AggregatorRound<phantom T> has key, store, copy, drop {
        // Maintains the current update count
        id: u128,
        // Maintains the time that the round was opened at.
        round_open_timestamp: u64,
        // Maintain the blockheight at the time that the round was opened
        round_open_block_height: u64,
        // Maintains the current median of all successful round responses.
        result: SwitchboardDecimal,
        // Standard deviation of the accepted results in the round.
        std_deviation: SwitchboardDecimal,
        // Maintains the minimum node response this round.
        min_response: SwitchboardDecimal,
        // Maintains the maximum node response this round.
        max_response: SwitchboardDecimal,
        // Pubkeys of the oracles fulfilling this round.
        oracle_keys: vector<address>,
        // Represents all successful node responses this round. `NaN` if empty.
        medians: vector<Option<SwitchboardDecimal>>,
        // Payouts so far in a given round
        current_payout: vector<SwitchboardDecimal>,
        // could do specific error codes
        errors_fulfilled: vector<bool>,
        // Maintains the number of successful responses received from nodes.
        // Nodes can submit one successful response per round.
        num_success: u64,
        num_error: u64,
        // Maintains whether or not the round is closed
        is_closed: bool,
        // Maintains the round close timestamp
        round_confirmed_timestamp: u64,
    }

    fun default_round<T>(): AggregatorRound<T> {

        AggregatorRound<T> {
            id: 0,
            round_open_timestamp: 0,
            round_open_block_height: block::get_current_block_height(),
            result: math::zero(),
            std_deviation: math::zero(),
            min_response: math::zero(),
            max_response: math::zero(),
            oracle_keys: vector::empty(),
            medians: vector::empty(),
            errors_fulfilled: vector::empty(),
            num_error: 0,
            num_success: 0,
            is_closed: false,
            round_confirmed_timestamp: 0,
            current_payout: vector::empty(),
        }
    }

    struct Aggregator has key, store, drop {

        // Aggregator account signer cap
        signer_cap: SignerCapability,

        // Configs
        authority: address,
        name: vector<u8>,
        metadata: vector<u8>,

        // Aggregator data that's fairly fixed
        created_at: u64,
        is_locked: bool,
        _ebuf: vector<u8>,
        features: vector<bool>,
    }

    // Frequently used configs
    struct AggregatorConfig has key {
        queue_addr: address,
        batch_size: u64,
        min_oracle_results: u64,
        min_update_delay_seconds: u64,
        history_limit: u64,
        variance_threshold: SwitchboardDecimal,
        force_report_period: u64,
        min_job_results: u64,
        expiration: u64,
        crank_addr: address,
        crank_disabled: bool,
        crank_row_count: u64,
        next_allowed_update_time: u64,
        consecutive_failure_count: u64,
        start_after: u64,
    }

    // Configuation items that are only used on the Oracle side
    struct AggregatorResultsConfig has key {
        variance_threshold: SwitchboardDecimal,
        force_report_period: u64,
        min_job_results: u64,
        expiration: u64,
    }

    struct AggregatorReadConfig has key {
        read_charge: u64,
        reward_escrow: address,
        read_whitelist: vector<address>,
        limit_reads_to_whitelist: bool,
    }

    struct AggregatorJobData has key {
        job_keys: vector<address>,
        job_weights: vector<u8>,
        jobs_checksum: vector<u8>,
    }

    struct AggregatorHistoryData has key {
        history: vector<AggregatorHistoryRow>,
        history_write_idx: u64,
    }

    struct AggregatorHistoryRow has drop, copy, store {
        value: SwitchboardDecimal,
        timestamp: u64,
        round_id: u128,
    }

    struct AggregatorConfigParams has drop, copy {
        addr: address,
        name: vector<u8>,
        metadata: vector<u8>,
        queue_addr: address,
        crank_addr: address,
        batch_size: u64,
        min_oracle_results: u64,
        min_job_results: u64,
        min_update_delay_seconds: u64,
        start_after: u64,
        variance_threshold: SwitchboardDecimal,
        force_report_period: u64,
        expiration: u64,
        disable_crank: bool,
        history_limit: u64,
        read_charge: u64,
        reward_escrow: address,
        read_whitelist: vector<address>,
        limit_reads_to_whitelist: bool,
        authority: address,
    }

    public fun addr_from_conf(conf: &AggregatorConfigParams): address {
        conf.addr
    }

    public fun queue_from_conf(conf: &AggregatorConfigParams): address {
        conf.queue_addr
    }

    public fun authority_from_conf(conf: &AggregatorConfigParams): address {
        conf.authority
    }

    public fun history_limit_from_conf(conf: &AggregatorConfigParams): u64 {
        conf.history_limit
    }

    public fun batch_size_from_conf(conf: &AggregatorConfigParams): u64 {
        conf.batch_size
    }

    public fun min_oracle_results_from_conf(conf: &AggregatorConfigParams): u64 {
        conf.min_oracle_results
    }

    public fun min_update_delay_seconds_from_conf(conf: &AggregatorConfigParams): u64 {
        conf.min_update_delay_seconds
    }

    public(friend) fun new_config(
        addr: address,
        name: vector<u8>,
        metadata: vector<u8>,
        queue_addr: address,
        crank_addr: address,
        batch_size: u64,
        min_oracle_results: u64,
        min_job_results: u64,
        min_update_delay_seconds: u64,
        start_after: u64,
        variance_threshold: SwitchboardDecimal,
        force_report_period: u64,
        expiration: u64,
        disable_crank: bool,
        history_limit: u64,
        read_charge: u64,
        reward_escrow: address,
        read_whitelist: vector<address>,
        limit_reads_to_whitelist: bool,
        authority: address,
    ): AggregatorConfigParams {
        AggregatorConfigParams {
            addr,
            name,
            metadata,
            queue_addr,
            crank_addr,
            batch_size,
            min_oracle_results,
            min_job_results,
            min_update_delay_seconds,
            start_after,
            variance_threshold,
            force_report_period,
            expiration,
            disable_crank,
            history_limit,
            read_charge,
            reward_escrow,
            read_whitelist,
            limit_reads_to_whitelist,
            authority,
        }
    }

    public fun exist(addr: address): bool {
        exists<Aggregator>(addr)
    }

    public fun has_authority(addr: address, account: &signer): bool acquires Aggregator {
        let ref = borrow_global<Aggregator>(addr);
        ref.authority == signer::address_of(account)
    }

    public fun buy_latest_value<CoinType>(
        account: &signer,
        addr: address,
        fee: Coin<CoinType>
    ): SwitchboardDecimal acquires AggregatorConfig, AggregatorReadConfig, AggregatorRound {
        let _aggregator_config = borrow_global_mut<AggregatorConfig>(addr);
        let aggregator_read_config = borrow_global_mut<AggregatorReadConfig>(addr);

        if (aggregator_read_config.limit_reads_to_whitelist) {
            assert!(vector::contains(&aggregator_read_config.read_whitelist, &signer::address_of(account)), errors::PermissionDenied());
        } else {
            assert!(
                coin::value(&fee) == aggregator_read_config.read_charge ||
                vector::contains(&aggregator_read_config.read_whitelist, &signer::address_of(account)),
                errors::InvalidArgument()
            );
        };
        coin::deposit(aggregator_read_config.reward_escrow, fee);
        borrow_global<AggregatorRound<LatestConfirmedRound>>(addr).result
    }

    public fun buy_latest_round<CoinType>(account: &signer, addr: address, fee: Coin<CoinType>): (
        SwitchboardDecimal, /* Result */
        u64,                /* Round Confirmed Timestamp */
        SwitchboardDecimal, /* Standard Deviation of Oracle Responses */
        SwitchboardDecimal, /* Min Oracle Response */
        SwitchboardDecimal, /* Max Oracle Response */
    ) acquires AggregatorConfig, AggregatorReadConfig, AggregatorRound {
        let _aggregator_config = borrow_global_mut<AggregatorConfig>(addr);
        let aggregator_read_config = borrow_global_mut<AggregatorReadConfig>(addr);
        if (aggregator_read_config.limit_reads_to_whitelist) {
            assert!(vector::contains(&aggregator_read_config.read_whitelist, &signer::address_of(account)), errors::PermissionDenied());
        } else {
            assert!(
                coin::value(&fee) == aggregator_read_config.read_charge ||
                vector::contains(&aggregator_read_config.read_whitelist, &signer::address_of(account)),
                errors::InvalidArgument()
            );
        };
        coin::deposit(aggregator_read_config.reward_escrow, fee);
        let latest_confirmed_round = borrow_global<AggregatorRound<LatestConfirmedRound>>(addr);
        (
            latest_confirmed_round.result,
            latest_confirmed_round.round_confirmed_timestamp,
            latest_confirmed_round.std_deviation,
            latest_confirmed_round.min_response,
            latest_confirmed_round.max_response,
        )
    }

    public fun latest_value(addr: address): SwitchboardDecimal acquires AggregatorRound, AggregatorReadConfig {
        let aggregator_read_config = borrow_global_mut<AggregatorReadConfig>(addr);
        assert!(aggregator_read_config.read_charge == 0 && !aggregator_read_config.limit_reads_to_whitelist, errors::PermissionDenied());
        borrow_global<AggregatorRound<LatestConfirmedRound>>(addr).result
    }


    public fun latest_round(addr: address): (
        SwitchboardDecimal, /* Result */
        u64,                /* Round Confirmed Timestamp */
        SwitchboardDecimal, /* Standard Deviation of Oracle Responses */
        SwitchboardDecimal, /* Min Oracle Response */
        SwitchboardDecimal, /* Max Oracle Response */
    ) acquires AggregatorRound, AggregatorReadConfig {
        let aggregator = borrow_global_mut<AggregatorReadConfig>(addr);
        assert!(aggregator.read_charge == 0, errors::PermissionDenied());
        let latest_confirmed_round = borrow_global<AggregatorRound<LatestConfirmedRound>>(addr);
        (
            latest_confirmed_round.result,
            latest_confirmed_round.round_confirmed_timestamp,
            latest_confirmed_round.std_deviation,
            latest_confirmed_round.min_response,
            latest_confirmed_round.max_response,
        )
    }

    // GETTERS

    public fun latest_round_timestamp(addr: address): u64 acquires AggregatorRound {
        let latest_confirmed_round = borrow_global<AggregatorRound<LatestConfirmedRound>>(addr);
        latest_confirmed_round.round_confirmed_timestamp
    }

    public fun latest_round_open_timestamp(addr: address): u64 acquires AggregatorRound {
        let latest_confirmed_round = borrow_global<AggregatorRound<LatestConfirmedRound>>(addr);
        latest_confirmed_round.round_open_timestamp
    }

    public fun lastest_round_min_response(addr: address): SwitchboardDecimal acquires AggregatorRound {
        let latest_confirmed_round = borrow_global<AggregatorRound<LatestConfirmedRound>>(addr);
        latest_confirmed_round.min_response
    }

    public fun lastest_round_max_response(addr: address): SwitchboardDecimal acquires AggregatorRound {
        let latest_confirmed_round = borrow_global<AggregatorRound<LatestConfirmedRound>>(addr);
        latest_confirmed_round.max_response
    }

    public fun authority(addr: address): address acquires Aggregator {
        let aggregator = borrow_global<Aggregator>(addr);
        aggregator.authority
    }

    public fun is_locked(addr: address): bool acquires Aggregator {
        let aggregator = borrow_global<Aggregator>(addr);
        aggregator.is_locked
    }

    public fun read_charge(addr: address): u64 acquires AggregatorReadConfig {
        let aggregator = borrow_global<AggregatorReadConfig>(addr);
        aggregator.read_charge
    }

    public fun next_allowed_timestamp(addr: address): u64 acquires AggregatorConfig {
        let aggregator = borrow_global<AggregatorConfig>(addr);
        aggregator.next_allowed_update_time
    }

    public fun job_keys(addr: address): vector<address> acquires AggregatorJobData {
        borrow_global<AggregatorJobData>(addr).job_keys
    }

    public fun min_oracle_results(addr: address): u64 acquires AggregatorConfig {
        borrow_global<AggregatorConfig>(addr).min_oracle_results
    }

    public fun crank_addr(addr: address): address acquires AggregatorConfig {
        borrow_global<AggregatorConfig>(addr).crank_addr
    }

    public fun crank_disabled(addr: address): bool acquires AggregatorConfig {
        borrow_global<AggregatorConfig>(addr).crank_disabled
    }

    public(friend) fun crank_row_count(self: address): u64 acquires AggregatorConfig {
        borrow_global<AggregatorConfig>(self).crank_row_count
    }

    public fun current_round_num_success(addr: address): u64 acquires AggregatorRound {
        let current_round = borrow_global<AggregatorRound<CurrentRound>>(addr);
        current_round.num_success
    }

    public fun current_round_open_timestamp(addr: address): u64 acquires AggregatorRound {
        let current_round = borrow_global<AggregatorRound<CurrentRound>>(addr);
        current_round.round_open_timestamp
    }

    public fun current_round_num_error(addr: address): u64 acquires AggregatorRound {
        let current_round = borrow_global<AggregatorRound<CurrentRound>>(addr);
        current_round.num_error
    }

    public fun curent_round_oracle_key_at_idx(addr: address, idx: u64): address acquires AggregatorRound {
        let current_round = borrow_global<AggregatorRound<CurrentRound>>(addr);
        *vector::borrow(&current_round.oracle_keys, idx)
    }

    public fun curent_round_median_at_idx(addr: address, idx: u64): SwitchboardDecimal acquires AggregatorRound {
        let current_round = borrow_global<AggregatorRound<CurrentRound>>(addr);
        let median = vector::borrow(&current_round.medians, idx);
        *option::borrow<SwitchboardDecimal>(median)
    }

    public fun current_round_std_dev(addr: address): SwitchboardDecimal acquires AggregatorRound {
        let current_round = borrow_global<AggregatorRound<CurrentRound>>(addr);
        current_round.std_deviation
    }

    public fun current_round_result(addr: address): SwitchboardDecimal acquires AggregatorRound {
        let current_round = borrow_global<AggregatorRound<CurrentRound>>(addr);
        current_round.result
    }

    public fun is_median_fulfilled(addr: address, idx: u64): bool acquires AggregatorRound {
        let current_round = borrow_global<AggregatorRound<CurrentRound>>(addr);
        let val = vector::borrow(&current_round.medians, idx);
        option::is_some(val)
    }

    public fun is_error_fulfilled(addr: address, idx: u64): bool acquires AggregatorRound {
        let current_round = borrow_global<AggregatorRound<CurrentRound>>(addr);
        *vector::borrow(&current_round.errors_fulfilled, idx)
    }

    public fun configs(self: address): (
        address, // Queue Address
        u64,     // Batch Size
        u64,     // Min Oracle Results
    ) acquires AggregatorConfig {
        let aggregator = borrow_global<AggregatorConfig>(self);
        (
            aggregator.queue_addr,
            aggregator.batch_size,
            aggregator.min_oracle_results,
        )
    }

    public fun batch_size(self: address): u64 acquires AggregatorConfig {
        borrow_global<AggregatorConfig>(self).batch_size
    }

    public fun queue_addr(addr: address): address acquires AggregatorConfig {
        borrow_global<AggregatorConfig>(addr).queue_addr
    }

    public fun history_limit(self: address): u64 acquires AggregatorConfig {
        borrow_global<AggregatorConfig>(self).history_limit
    }

    public fun can_open_round(addr: address): bool acquires AggregatorConfig {
        let ref = borrow_global<AggregatorConfig>(addr);
        timestamp::now_seconds() >= ref.start_after &&
        timestamp::now_seconds() >= ref.next_allowed_update_time
    }

    public fun is_jobs_checksum_equal(addr: address, vec: &vector<u8>): bool acquires AggregatorJobData {
        let checksum = borrow_global<AggregatorJobData>(addr).jobs_checksum; // copy
        &checksum == vec
    }

    #[test_only]
    public entry fun new_test(account: &signer, value: u128, dec: u8, neg: bool) {
        let cap = account::create_test_signer_cap(signer::address_of(account));
        move_to(
            account,
            Aggregator {
                signer_cap: cap,

                // Configs
                authority: signer::address_of(account),
                name: b"Switchboard Aggregator",
                metadata: b"",

                // Aggregator data that's fairly fixed
                created_at: timestamp::now_seconds(),
                is_locked: false,
                _ebuf: vector::empty(),
                features: vector::empty(),
            }
        );

        move_to(
            account,
            AggregatorConfig {
                queue_addr: @0x51,
                batch_size: 1,
                min_oracle_results: 1,
                min_update_delay_seconds: 5,
                history_limit: 0,
                crank_addr: @0x5,
                crank_disabled: false,
                crank_row_count: 0,
                next_allowed_update_time: 0,
                consecutive_failure_count: 0,
                start_after: 0,
                variance_threshold: math::zero(),
                force_report_period: 0,
                min_job_results: 1,
                expiration: 0,
            }
        );
        move_to(
            account,
            AggregatorReadConfig {
                read_charge: 0,
                reward_escrow: @0x55,
                read_whitelist: vector::empty(),
                limit_reads_to_whitelist: false,
            }
        );
        move_to(
            account,
            AggregatorJobData {
                job_keys: vector::empty(),
                job_weights: vector::empty(),
                jobs_checksum: vector::empty(),
            }
        );
        move_to(
            account,
            AggregatorHistoryData {
                history: vector::empty(),
                history_write_idx: 0,
            }
        );
        move_to(account, AggregatorRound<LatestConfirmedRound> {
            id: 0,
            round_open_timestamp: 0,
            round_open_block_height: block::get_current_block_height(),
            result: math::new(value, dec, neg),
            std_deviation: math::zero(),
            min_response: math::zero(),
            max_response: math::zero(),
            oracle_keys: vector::empty(),
            medians: vector::empty(),
            errors_fulfilled: vector::empty(),
            num_error: 0,
            num_success: 0,
            is_closed: false,
            round_confirmed_timestamp: 0,
            current_payout: vector::empty(),
        });
        move_to(
            account,
            AggregatorResultsConfig {
                variance_threshold: math::zero(),
                force_report_period: 0,
                min_job_results: 1,
                expiration: 0,
            }
        );
        move_to(account, default_round<CurrentRound>());
    }

    #[test_only]
    public entry fun update_value(account: &signer, value: u128, dec: u8, neg: bool) acquires AggregatorRound {
        let latest_confirmed_round = borrow_global_mut<AggregatorRound<LatestConfirmedRound>>(signer::address_of(account));
        latest_confirmed_round.result = math::new(value, dec, neg);
    }

    #[test_only]
    public entry fun update_open_timestamp(account: &signer, timestamp: u64) acquires AggregatorRound {
        let latest_confirmed_round = borrow_global_mut<AggregatorRound<LatestConfirmedRound>>(signer::address_of(account));
        latest_confirmed_round.round_open_timestamp = timestamp;
    }

    #[test_only]
    public entry fun update_confirmed_timestamp(account: &signer, timestamp: u64) acquires AggregatorRound {
        let latest_confirmed_round = borrow_global_mut<AggregatorRound<LatestConfirmedRound>>(signer::address_of(account));
        latest_confirmed_round.round_confirmed_timestamp = timestamp;
    }


    // For local test
    use std::string;
    use aptos_std::type_info;


    public entry fun update_price<CoinType>(user: &signer, value: u64)
        acquires AggregatorRound, Aggregator
    {
        let user_addr = signer::address_of(user);
        let seed = *string::bytes(&type_info::type_name<CoinType>());
        vector::append(&mut seed, b"FEED");
        let feed_addr = account::create_resource_address(&user_addr, seed);

        if (!exists<AggregatorRound<LatestConfirmedRound>>(feed_addr)) {
            let (agg_signer, signer_cap) = account::create_resource_account(user, seed);
            move_to(&agg_signer, default_round<LatestConfirmedRound>());
            move_to(&agg_signer, AggregatorReadConfig {
                read_charge: 0,
                reward_escrow: @switchboard,
                read_whitelist: vector::empty(),
                limit_reads_to_whitelist: false,
            });

            move_to(&agg_signer, Aggregator {
                signer_cap,
                authority: user_addr,
                name: b"Switchboard Aggregator",
                metadata: b"",
                created_at: timestamp::now_seconds(),
                is_locked: false,
                _ebuf: vector::empty(),
                features: vector::empty(),
            });
        };

        let aggregator = borrow_global_mut<Aggregator>(feed_addr);
        assert!(aggregator.authority == user_addr, errors::InvalidAuthority());
        let latest_confirmed_round = borrow_global_mut<AggregatorRound<LatestConfirmedRound>>(feed_addr);
        latest_confirmed_round.result = math::new((value as u128), 9, false);
        latest_confirmed_round.round_confirmed_timestamp = timestamp::now_seconds();
    }
}
