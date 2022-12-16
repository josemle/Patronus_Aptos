module switchboard::errors {
    use std::error;
    // https://github.com/aptos-labs/aptos-core/blob/main/aptos-move/framework/move-stdlib/sources/error.move
    
    public fun Generic(): u64 { error::internal(0) }

    public fun StateNotFound(): u64 { error::not_found(1) }
    public fun QueueNotFound(): u64 { error::not_found(2) }
    public fun OracleNotFound(): u64 { error::not_found(3) }
    public fun JobNotFound(): u64 { error::not_found(4) }
    public fun CrankNotFound(): u64 { error::not_found(5) }
    public fun AggregatorNotFound(): u64 { error::not_found(6) }
    public fun LeaseNotFound(): u64 { error::not_found(7) }
    public fun OracleWalletNotFound(): u64 { error::not_found(8) }

    public fun StateAlreadyExists(): u64 { error::already_exists(9) }
    public fun QueueAlreadyExists(): u64 { error::already_exists(10) }
    public fun OracleAlreadyExists(): u64 { error::already_exists(11) }
    public fun JobAlreadyExists(): u64 { error::already_exists(12) }
    public fun CrankAlreadyExists(): u64 { error::already_exists(13) }
    public fun AggregatorAlreadyExists(): u64 { error::already_exists(14) }
    public fun LeaseAlreadyExists(): u64 { error::already_exists(15) }
    public fun OracleWalletAlreadyExists(): u64 { error::already_exists(16) }

    public fun InvalidAuthority(): u64 { error::permission_denied(17) }
    public fun PermissionDenied(): u64 { error::permission_denied(18) }
    public fun CrankDisabled(): u64 { error::permission_denied(19) }

    public fun OracleMismatch(): u64 { error::invalid_argument(20) }
    public fun JobsChecksumMismatch(): u64 { error::invalid_argument(21) }
    public fun OracleAlreadyResponded(): u64 { error::invalid_argument(22) }
    public fun InvalidArgument(): u64 { error::invalid_argument(23) }

    public fun CrankNotReady(): u64 { error::invalid_state(24) }
    public fun CrankEmpty(): u64 { error::invalid_state(25) }
    public fun LeaseInactive(): u64 { error::invalid_state(26) }
    public fun AggregatorLocked(): u64 { error::invalid_state(27) }
    
    public fun InsufficientCoin(): u64 { error::resource_exhausted(28) }
    public fun LeaseInsufficientCoin(): u64 { error::resource_exhausted(29) }
    public fun OracleWalletInsufficientCoin(): u64 { error::resource_exhausted(30) }

    public fun AggregatorInvalidBatchSize(): u64 { error::invalid_argument(31) }
    public fun AggregatorInvalidMinOracleResults(): u64 { error::invalid_argument(32) }
    public fun AggregatorInvalidUpdateDelay(): u64 { error::invalid_argument(33) }
    public fun AggregatorIllegalRoundOpenCall(): u64 { error::invalid_argument(34) }
    public fun AggregatorQueueNotReady(): u64 { error::invalid_argument(35) }

    public fun ResourceAlreadyExists(): u64 { error::already_exists(36) }
    public fun PermissionAlreadyExists(): u64 { error::already_exists(37) }
    #[test(account = @0x1)]
    public entry fun test_errors() {
        std::debug::print(&Generic());                           // 720896

        std::debug::print(&StateNotFound());                     // 393217
        std::debug::print(&QueueNotFound());                     // 393218 
        std::debug::print(&OracleNotFound());                    // 393219
        std::debug::print(&JobNotFound());                       // 393220
        std::debug::print(&CrankNotFound());                     // 393221
        std::debug::print(&AggregatorNotFound());                // 393222
        std::debug::print(&LeaseNotFound());                     // 393223
        std::debug::print(&OracleWalletNotFound());              // 393224

        std::debug::print(&StateAlreadyExists());                // 524297
        std::debug::print(&QueueAlreadyExists());                // 524298
        std::debug::print(&AggregatorAlreadyExists());           // 524302
        std::debug::print(&LeaseAlreadyExists());                // 524303
        std::debug::print(&OracleWalletAlreadyExists());         // 524304

        std::debug::print(&InvalidAuthority());                  // 327697
        std::debug::print(&PermissionDenied());                  // 327698
        std::debug::print(&CrankDisabled());                     // 327699

        std::debug::print(&OracleMismatch());                    // 65556
        std::debug::print(&JobsChecksumMismatch());              // 65557
        std::debug::print(&OracleAlreadyResponded());            // 65558
        std::debug::print(&InvalidArgument());                   // 65559

        std::debug::print(&CrankNotReady());                     // 196632
        std::debug::print(&CrankEmpty());                        // 196633
        std::debug::print(&LeaseInactive());                     // 196634
        std::debug::print(&AggregatorLocked());                  // 196635

        std::debug::print(&InsufficientCoin());                  // 589852
        std::debug::print(&LeaseInsufficientCoin());             // 589853
        std::debug::print(&OracleWalletInsufficientCoin());      // 589854

        std::debug::print(&AggregatorInvalidBatchSize());        // 65567
        std::debug::print(&AggregatorInvalidMinOracleResults()); // 65568
        std::debug::print(&AggregatorInvalidUpdateDelay());      // 65569
        std::debug::print(&AggregatorIllegalRoundOpenCall());    // 65570
        std::debug::print(&AggregatorQueueNotReady());           // 65571

        std::debug::print(&ResourceAlreadyExists());             // 524324
        std::debug::print(&PermissionAlreadyExists());           // 524325
    }
}
