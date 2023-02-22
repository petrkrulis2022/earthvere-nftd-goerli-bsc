// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IEarthverseMarketplace.sol";

error NotOwner();
error ZeroAddress();
error PriceMustBeAboveZero();
error NotApprovedForMarketPlace();
error AlreadyListed(uint256 tokenId);
error PriceDoNotMet(uint256 itemId, uint256 price);
error ItemDoesntExit(uint256 itemId);
error SellerCannotBeBuyer();

contract EarthverseMarketplace is ReentrancyGuard, IEarthverseMarketplace {
  uint256 public itemCount;

  struct ListingNFTLand {
    uint256 id;
    IERC721 nftLand;
    uint256 tokenId;
    uint256 price;
    address seller;
  }

  mapping(uint256 => ListingNFTLand) public listing;

  modifier isOwner(
    IERC721 nftLand,
    uint256 tokenId,
    address spender
  ) {
    address owner = nftLand.ownerOf(tokenId);
    if (spender != owner) {
      revert NotOwner();
    }
    _;
  }

  modifier notListed(uint256 tokenId) {
    ListingNFTLand memory _listing = listing[tokenId];
    if (_listing.price > 0) revert AlreadyListed(tokenId);
    _;
  }

  event NFTLandListed(
    uint256 itemId,
    uint256 indexed tokenId,
    uint256 indexed price,
    address indexed seller
  );

  event NFTLandBought(
    uint256 itemId,
    uint256 price,
    uint256 indexed tokenId,
    address indexed seller,
    address indexed buyer
  );

  function listNFTLand(
    IERC721 nftLand,
    uint256 tokenId,
    uint256 price
  )
    external
    notListed(tokenId)
    isOwner(nftLand, tokenId, msg.sender)
    nonReentrant
  {
    if (price <= 0) revert PriceMustBeAboveZero();

    ++itemCount;
    listing[itemCount] = ListingNFTLand(
      itemCount,
      nftLand,
      tokenId,
      price,
      msg.sender
    );

    nftLand.transferFrom(msg.sender, address(this), tokenId);

    emit NFTLandListed(itemCount, tokenId, price, msg.sender);
  }

  function buyNFTLand(
    address buyer,
    uint256 itemId,
    uint256 price,
    uint256 decimalsOfInput
  ) external nonReentrant returns (address) {
    if (buyer == address(0)) revert ZeroAddress();
    if (itemId <= 0 || itemId > itemCount) revert ItemDoesntExit(itemId);

    ListingNFTLand storage nftLandItem = listing[itemId];

    if (price < (nftLandItem.price * 10 ** decimalsOfInput))
      revert PriceDoNotMet(itemId, nftLandItem.price);
    if (buyer == nftLandItem.seller) revert SellerCannotBeBuyer();

    address oldSeller = nftLandItem.seller;
    nftLandItem.seller = buyer;

    emit NFTLandBought(
      itemId,
      nftLandItem.price,
      nftLandItem.tokenId,
      oldSeller,
      buyer
    );

    return oldSeller;
  }
}
