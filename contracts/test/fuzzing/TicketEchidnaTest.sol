// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Ticket} from "../../TicketingService.sol";

contract TicketEchidnaTest is Ticket {
    address receiver_address = address(0x6f443bCABBbcbe9b9660e6604c721439028881D7);

    constructor() Ticket() {}

    function echidna_test_max() public pure returns (bool) {
        return MAX_TICKETS_PER_USER == 1;    
    }

    function echidna_test_mint() public returns (bool) {
        mint(receiver_address); // ErrorRevert
        return true;
    }

}