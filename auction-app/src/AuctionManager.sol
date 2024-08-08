// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract AuctionManager is IERC721Receiver{

    address private brokerAddress;
    uint private auctionId;
    mapping(uint => Auction) public availableAuctions;
    uint[] private auctionIds; 
    
    struct Auction{
        address nftOwnerAddress;
        ERC721 nftAddress;
        uint nftId;
        uint startTime;
        uint endTime;
        uint price;
        address highestBidder;
    }
    
    constructor(uint _auctionId) {
        brokerAddress = msg.sender;
        auctionId = _auctionId;
    }
     
    function createAuction(address _nftOwnerAddress,address _nftAddress, uint256 _nftID, uint _startTime, uint _endTime, uint _price) public {
        ERC721 erc721Contract = ERC721(_nftAddress);
        erc721Contract.safeTransferFrom(_nftOwnerAddress, brokerAddress, _nftID);
        availableAuctions[auctionId] = Auction(_nftOwnerAddress, erc721Contract, _nftID, _startTime, _endTime, _price, _nftOwnerAddress);
        auctionIds.push(auctionId);
        
    }

    function bid(uint _auctionId, uint _price, address _bidderAddress, uint _time) public {
        require(contains(_auctionId), "Auction does not exist for this id"); 
        Auction storage currAuction = availableAuctions[_auctionId];
        require(currAuction.startTime < _time, "The auction has not started");
        require(currAuction.price < _price, "The bid price is lower than the current price");
        currAuction.price = _price;
        currAuction.highestBidder = _bidderAddress;
    }

    function getClaimableAuctions(uint _time, address _bidderAddress) public view returns (uint[] memory){
        uint[] memory localArray = new uint[](auctionIds.length);
        uint x = 0;
        for (uint i = 0; i < auctionIds.length; i++) {
            Auction memory currAuction = availableAuctions[auctionIds[i]];
            if (_time > currAuction.endTime && _bidderAddress == currAuction.highestBidder){
                localArray[x] = auctionIds[i];
                x+=1;
            }
        }
        return localArray;
    }

    function getActiveAuctions(uint _time) public view returns (uint[] memory){
        uint[] memory localArray = new uint[](auctionIds.length);
        uint x = 0;
        for (uint i = 0; i < auctionIds.length; i++) {
            Auction memory currAuction = availableAuctions[auctionIds[i]];
            if (_time <= currAuction.endTime &&  _time >= currAuction.startTime){
                localArray[x] = auctionIds[i];
                x+=1;
            }
        }
        return localArray;
    } 

    function claim(uint _auctionId, address _userAddress)public {
        Auction storage currAuction = availableAuctions[_auctionId];
        require(_userAddress == currAuction.highestBidder, "Only highest bidder can claim");
        currAuction.nftAddress.safeTransferFrom(brokerAddress, currAuction.highestBidder, currAuction.nftId);
        
        delete availableAuctions[_auctionId];
        removeValue(_auctionId);
    }

    // helper functions
    function contains(uint _auctionId) private view returns (bool) {
        for (uint i = 0; i < auctionIds.length; i++) {
            if (auctionIds[i] == _auctionId) {
                return true;
            }
        }
        return false;
    }

    function removeValue(uint _valueToRemove) private {
        bool found = false;
        uint length = auctionIds.length;
        for (uint i = 0; i < length; i++) {
            if (auctionIds[i] == _valueToRemove) {
                // Move the last element to the current position
                auctionIds[i] = auctionIds[length - 1];
                auctionIds.pop();
                found = true;
                break;
            }
        }
        require(found, "Value not found in the array");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}