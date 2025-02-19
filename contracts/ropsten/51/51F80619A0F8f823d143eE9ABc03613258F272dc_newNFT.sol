// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
 
import "./nf-token-metadata.sol";
import "./ownable.sol";
import "./counters.sol";

 
contract newNFT is NFTokenMetadata, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

  constructor() {
    nftName = "TKENV1 NFT";
    nftSymbol = "TKENV1";
  }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
 
 function mintMul(address[] memory _to, string[] calldata _uri) external onlyOwner {        
        for (uint256 _idx = 0; _idx < _to.length; _idx++) {
            uint256 tokenId = _tokenIdCounter.current();
            super._mint(_to[_idx], tokenId);
            super._setTokenUri(tokenId, _uri[_idx]);
        }
    }
}