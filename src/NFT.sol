// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title NFT
 * @dev This contract represents a non-fungible token (NFT) with royalty and discount features.
 */
contract NFT is ERC721Royalty, Ownable2Step {
    uint256 public totalSupply;

    uint256 public constant PRICE = 0.2 ether;
    uint256 public constant PRICE_WITH_DISCOUNT = 0.1 ether;
    uint256 public constant MAX_TOTAL_SUPPLY = 1000;

    bytes32 public immutable DISCOUNT_TREE_ROOT;

    BitMaps.BitMap private _discountList;

    event DiscountClaimed(uint256 index, address account);

    error NFTPriceNotMatched(uint256 expected, uint256 payed);
    error NFTAlreadyClaimed(uint256 index);
    error NFTTotalSupplyReached();
    error NFTDiscountInvalidProof();

    /**
     * @dev Initializes the NFT contract
     * @param name The name of the NFT
     * @param symbol The symbol of the NFT
     * @param owner The address of the contract owner
     * @param discountTreeRoot The root hash of the discount Merkle tree
     */
    constructor(string memory name, string memory symbol, address owner, bytes32 discountTreeRoot)
        ERC721(name, symbol)
        Ownable(owner)
    {
        _setDefaultRoyalty(owner, 250);
        DISCOUNT_TREE_ROOT = discountTreeRoot;
    }

    /**
     * @dev Allows the contract owner to withdraw the contract's ETH balance
     */
    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Mints a new NFT for the sender at the regular price
     * @return tokenId The ID of the minted NFT
     */
    function mint() external payable returns (uint256 tokenId) {
        return _mintForPrice(PRICE);
    }

    /**
     * @dev Mints a new NFT for the sender with a discount
     * @param proof The Merkle proof for the discount
     * @param index The index of the discount
     * @return tokenId The ID of the minted NFT
     */
    function mintWithDiscount(bytes32[] calldata proof, uint256 index) external payable returns (uint256 tokenId) {
        _claimDiscount(proof, index, msg.sender);
        tokenId = _mintForPrice(PRICE_WITH_DISCOUNT);

        emit DiscountClaimed(index, msg.sender);
    }

    /**
     * @dev Internal function to mint a new NFT for the sender at the specified price
     * @param price The price to be paid for the NFT
     * @return tokenId The ID of the minted NFT
     */
    function _mintForPrice(uint256 price) internal returns (uint256 tokenId) {
        if (msg.value != price) revert NFTPriceNotMatched(price, msg.value);
        tokenId = totalSupply;
        _safeMint(msg.sender, tokenId, "");
    }

    /**
     * @inheritdoc ERC721
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal override {
        if (totalSupply >= MAX_TOTAL_SUPPLY) revert NFTTotalSupplyReached();

        unchecked {
            totalSupply++;
        }

        super._safeMint(to, tokenId, data);
    }

    /**
     * @dev Internal function to claim a discount for an account
     * @param proof The Merkle proof for the discount
     * @param index The index of the discount
     * @param account The account claiming the discount
     */
    function _claimDiscount(bytes32[] calldata proof, uint256 index, address account) internal {
        if (BitMaps.get(_discountList, index)) {
            revert NFTAlreadyClaimed(index);
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, index))));
        if (!MerkleProof.verifyCalldata(proof, DISCOUNT_TREE_ROOT, leaf)) {
            revert NFTDiscountInvalidProof();
        }

        BitMaps.set(_discountList, index);
    }
}
