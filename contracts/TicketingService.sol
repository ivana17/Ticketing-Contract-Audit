// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

abstract contract Ownable {
    address public owner;

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Ticket is ERC721Enumerable {
    uint256 public constant MAX_TICKETS_PER_USER = 1;

    constructor() ERC721("ERC721","ERC721") {}

    function mint(address receiver) public {
        uint256 tokenId = totalSupply();
        _safeMint(receiver, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256) pure override internal {
        require(from == address(0) || to == address(0), "Soulbound token");
    }
}

contract TicketingService is Ownable {
    Ticket immutable ticketContract;
    
    uint256 public constant PRICE = 0.01 ether;
    uint8 public constant MAX_TICKETS_PER_BATCH = 4;

    event NewTicket(address indexed receiver);
    event Refund(address indexed ticketOwner);

    constructor(address ticketContractAddress) {
        ticketContract = Ticket(ticketContractAddress);
    }

    function mintTicket(address receiver) public payable {
        require(msg.value >= PRICE, "Invalid price");
        require(ticketContract.balanceOf(receiver) <= ticketContract.MAX_TICKETS_PER_USER(), "One ticket per address allowed");

        ticketContract.mint(receiver);

        emit NewTicket(receiver);
    }

    function mintBatch(address[] memory receivers) public payable {
        for(uint256 i = 0; i < MAX_TICKETS_PER_BATCH; i++) {
            mintTicket(receivers[i]);
        }
    }

    function refundTicket(uint256 tokenId) public {
        require(msg.sender == ticketContract.ownerOf(tokenId));

        payable(msg.sender).transfer(PRICE);
        ticketContract.burn(tokenId);
        
        emit Refund(msg.sender);
    }
}