// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lzApp/NonblockingLzApp.sol";

contract Reborn is ERC721, ERC721Burnable, NonblockingLzApp {
    event AddressLogged(address indexed _address);
    event PayloadLogged(bytes _payload);
    event MsgSenderLogged(address indexed _msgSender);

    uint256 private _nextTokenId;
    address private _lzEndpoint;
    address private _relayer;

    constructor(address lzEndpoint, address relayer)
        ERC721("Reborn", "RBN")
        NonblockingLzApp(lzEndpoint, msg.sender)
    {
        _nextTokenId = 0;
        _lzEndpoint = lzEndpoint;
        _relayer = relayer;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://i.seadn.io/s/raw/files/b80ce737ebbf95eda0c518d9d14e7136.png?auto=format&dpr=1&w=3840";
    }

    function safeMint(address to) public onlyOwnerOrLz() {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    modifier onlyOwnerOrLzThis() {
        require(
            msg.sender == owner() || msg.sender == _lzEndpoint || msg.sender == _relayer || msg.sender == address(this),
            "Only owner or lz can call this function"
        );
        _;
    }


    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        emit MsgSenderLogged(msg.sender);
        emit PayloadLogged(_payload);

        require(_srcChainId == 10108, "Only accept from aptos testnet");
        address to = bytesToAddress(_payload);
        emit AddressLogged(to);
        safeMint(to);
    }

    function bytesToAddress(bytes memory b) public pure returns (address) {
        // require(b.length == 20, "Invalid bytes length");

        address addr;
        assembly {
            // Read the bytes data from memory and store into addr.
            // We use `mload` to load the data and assume the data is in the format of an Ethereum address.
            addr := mload(add(b, 20))
        }

        return addr;
    }

}
