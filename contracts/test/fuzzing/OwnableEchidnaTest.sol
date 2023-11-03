// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Ownable} from "../../TicketingService.sol";

contract OwnableEchidnaTest is Ownable {
    address owner_address = address(0xc9f79f728bAc5f2B8cBE58695f990484f71C50f9);

    constructor() Ownable() {
      owner = owner_address;
    }

    function echidna_test_ownership() public view returns (bool) {
        return owner == owner_address;
    }
}