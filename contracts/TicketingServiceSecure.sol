// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address OldOwner, address NewOwner);

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner access");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0x0));
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Ticket is ERC721, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant MAX_TICKETS_PER_USER = 1;
    Counters.Counter private _tokenIdCounter;

    error AlreadyMinted();
    error NotSoulboundToken();

    constructor() ERC721("ERC721", "ERC721") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current(); 
    }

    function mint(address receiver) public onlyRole(MINTER_ROLE) {
        if(balanceOf(receiver) == MAX_TICKETS_PER_USER) revert AlreadyMinted();
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(receiver, tokenId);
    }

    function burn(uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal pure override(ERC721) {
        if(from != address(0) && to != address(0)) revert NotSoulboundToken();
    }
}

contract TicketingService is Ownable, ReentrancyGuard {
    Ticket public immutable ticketContract;
    uint256 public constant PRICE = 0.01 ether;
    uint256 public constant MAX_TICKETS_PER_BATCH = 4;

    event NewTicket(address indexed receiver);
    event Refund(address indexed ticketOwner);
    
    error NotEnoughEth();
    error ZeroAddress();
    error TransferFailed();
    error InvalidTokenOwner();
    error ExceedsMaxTicketsPerBatch();

    constructor(address ticketContractAddress) {
        ticketContract = Ticket(ticketContractAddress);
    }

    function mintTicket(address receiver) public payable {
        if(receiver == address(0x0)) revert ZeroAddress();
        if(msg.value < PRICE) revert NotEnoughEth();

        ticketContract.mint(receiver);

        emit NewTicket(receiver);
    }

    function mintBatch(address[] memory receivers) public payable {
        if(receivers.length > MAX_TICKETS_PER_BATCH) revert ExceedsMaxTicketsPerBatch();
        if(msg.value < PRICE * receivers.length) revert NotEnoughEth();

        for(uint256 i = 0; i < receivers.length; i++) {
            if(receivers[i] == address(0x0)) revert ZeroAddress();

            ticketContract.mint(receivers[i]);

            emit NewTicket(receivers[i]);
        }
    }

    function refundTicket(uint256 tokenId) public nonReentrant {
        if(msg.sender != ticketContract.ownerOf(tokenId)) revert InvalidTokenOwner();

        ticketContract.burn(tokenId);
        
        (bool success, ) = payable(msg.sender).call{value: PRICE}("");
        
        if(!success) revert TransferFailed();

        emit Refund(msg.sender);
    }


    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if(!success) revert TransferFailed();
    }

}
