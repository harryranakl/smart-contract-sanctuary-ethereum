// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// Used for OpenSea Whitelisting
contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract NFT is ERC721A, ReentrancyGuard {

	// Project Name
	string private _name = "FuckYourInfluencers";

	// Project Symbol
	string private _symbol = "FYI";

	// Locked, Presale, PublicSale 
	enum Stage {
		Locked,
		Presale,
		PublicSale
	}
	Stage internal _currentStage;

	// OpenSea Whitelisting
	address public constant _proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

	// Wrapped Ethereum Address
	address constant _wrappedETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

	// Total NFT Supply
	uint256 constant _totalSupply = 2700;

	// Public Sale Constants 
	uint256 constant _publicSaleSupply = 2700;
	uint256 constant _publicSalePrice = 5000000000000000;
	uint256 constant _publicSaleMaxMint = 3;

	// Addresses for payment splitter here
	address constant account1 = 0x28A782553C4B3f78991B41Cb47Ab4D78716Ef738;
	uint256 constant accountPercentage1 = 100;

	// Check if caller is sender
	modifier isUserCaller() {
		require(tx.origin == msg.sender, "Caller is Smart Contract");
		_;
	}

	// Check if not locked
	modifier notLocked() {
		require(_currentStage != Stage.Locked, "Stage Locked"); 
		_;
	}

	constructor(string memory URI_) ERC721A(_name,_symbol,URI_) {
		_currentStage = Stage.Locked;
	}

	/**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner,operator);
    }

    // Check if shareholder
	function isShareHolder() private isUserCaller view returns(bool) {
		return (msg.sender == account1);	
	}


    // Refund excess ETH
	function refundIfOver(uint256 price) private {
    	if (msg.value > price) {
      		payable(msg.sender).transfer(msg.value - price);
    	}
  	}

  	// Set stage for NFT drops
	function setStage(uint256 newStage) external onlyOwner {
		require(newStage <= 2, "Wrong Stage Index");
		if(newStage == 0) {
			_currentStage = Stage.Locked;
		}
		else if(newStage == 1) {
			_currentStage = Stage.Presale;
		}
		else if(newStage == 2) {
			_currentStage = Stage.PublicSale;
		} 
	}

	// Mint function
	function mint(uint256 quantity ) external notLocked nonReentrant isUserCaller payable {
		require(quantity > 0, "Quantity cannot be 0");
		uint256 currentSupply = totalSupply();
		uint256 currentMintCount = _numberMinted(msg.sender); // numberMinted

		// FYI Configurations
		if(currentSupply < 800) {
			require(quantity == 1, "Exceeds Allowed Mint");
			require(currentMintCount < 1, "Exceeds Allowed Mint");
		}
		else{
			require(currentSupply + quantity <= _totalSupply, "Exceeds Collection Size");
			require(currentMintCount + quantity <= _publicSaleMaxMint, "Exceeds Allowed Mint");
			require(currentSupply + quantity <= _publicSaleSupply, "Exceeds Public Sale Supply");
			require(msg.value >= _publicSalePrice * quantity, "Need more ETH");
		}
		
		_safeMint(msg.sender, quantity);
		refundIfOver(_publicSalePrice * quantity);
	}

	// Withdraw Wrapped ETH funds
	function withdrawWrappedETHFunds() external {
		require(isShareHolder(),"Not Shareholder");

		// Get Wrapped Ethereum Balance of this contract
		IERC20 wrappedETHContract = IERC20(_wrappedETH);
		uint256 wETHBalance = wrappedETHContract.balanceOf(address(this));
		
		wrappedETHContract.transfer(account1, wETHBalance * 100 / 100);
	}

	// Withdraw ETH Funds
	function withdrawETHFunds() external {
		require(isShareHolder(),"Not Shareholder");

		// Get Ethereum Balance of this contract
		uint256 ETHBalance = address(this).balance;

		_widthdraw(account1,ETHBalance * 100 / 100);
	}

	function _widthdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}