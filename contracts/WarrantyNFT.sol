// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WarrantyNFT is ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;

    mapping(uint256 => Item) public tokenIdToItem;

    Product[] public products;
    uint256[] private _tokensInWarranty;

    struct Item {
        uint256 product;
        uint256 serialNumber;
        uint256 purchaseTime;
        bool warrantyStatus;
    }

    struct Product {
        string productName;
        string productURI;
        string expiredProductURI;
        uint256 productWarrantyPeriod;
        bool soulbound;
    }

    constructor() ERC721("Warranty NFTs", "wNFT") {}

    function mintWarrantyNFT(
        uint256 serialNumber,
        uint256 productId,
        address recipient
    ) public onlyOwner {
        require(productId < products.length, "Invalid product ID");
        require(recipient != address(0));
        _mint(serialNumber, productId, recipient);
    }

    function addProduct(
        string memory productName,
        string memory productURI,
        string memory expiredProductURI,
        uint256 productWarrantyPeriod,
        bool soulbound
    ) public onlyOwner returns (uint256) {
        uint256 newProductID = products.length;
        _addProduct(
            productName,
            productURI,
            expiredProductURI,
            productWarrantyPeriod,
            soulbound
        );
        return (newProductID);
    }

    function claimWarranty(uint tokenId) public returns (bool) {
        require(tokenId < _tokenIds.current(), "Invalid token ID");
        require(
            msg.sender == ownerOf(tokenId),
            "Only token owner can claim warranty."
        );

        Product memory product = products[tokenIdToItem[tokenId].product];
        tokenIdToItem[tokenId].warrantyStatus = false;
        _setTokenURI(tokenId, product.expiredProductURI);
        _updateWarrantyStatus();
        return true;
    }

    function updateWarrantyStatus() public {
        _updateWarrantyStatus();
    }

    function checkWarranty(uint tokenId) public view returns (bool) {
        require(tokenId < _tokenIds.current(), "Invalid token ID");
        return (tokenIdToItem[tokenId].warrantyStatus);
    }

    function getNumberOfProductsInWarranty() public view returns (uint256) {
        return _tokensInWarranty.length;
    }

    function _mint(
        uint256 serialNumber,
        uint256 productId,
        address recipient
    ) internal {
        uint256 newTokenID = _tokenIds.current();
        string memory tokenURI_ = products[productId].productURI;
        _safeMint(recipient, newTokenID);
        _setTokenURI(newTokenID, tokenURI_);
        Item memory item = Item(productId, serialNumber, block.timestamp, true);
        tokenIdToItem[newTokenID] = item;
        _tokensInWarranty.push(newTokenID);
        _tokenIds.increment();
    }

    function _addProduct(
        string memory productName,
        string memory productURI,
        string memory expiredProductURI,
        uint256 productWarrantyPeriod,
        bool soulbound
    ) internal {
        Product memory product = Product(
            productName,
            productURI,
            expiredProductURI,
            productWarrantyPeriod,
            soulbound
        );
        products.push(product);
    }

    function _updateWarrantyStatus() internal {
        int256 n = int256(_tokensInWarranty.length);
        int256 last = n - 1;
        for (int256 i = n - 1; i >= 0; i--) {
            uint tokenId = _tokensInWarranty[uint(i)];
            Product memory product = products[tokenIdToItem[tokenId].product];
            if (
                block.timestamp >=
                (tokenIdToItem[tokenId].purchaseTime +
                    product.productWarrantyPeriod) &&
                tokenIdToItem[tokenId].warrantyStatus == true
            ) {
                tokenIdToItem[tokenId].warrantyStatus = false;
                _setTokenURI(tokenId, product.expiredProductURI);
                _tokensInWarranty[uint(i)] = _tokensInWarranty[uint(last)];
                _tokensInWarranty.pop();
                last--;
            } else if (tokenIdToItem[tokenId].warrantyStatus == false) {
                _tokensInWarranty[uint(i)] = _tokensInWarranty[uint(last)];
                _tokensInWarranty.pop();
                last--;
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        if (from != address(0)) {
            Item memory item = tokenIdToItem[tokenId];
            Product memory product = products[item.product];
            require(!product.soulbound, "Token is Soulbound!");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {}
}
