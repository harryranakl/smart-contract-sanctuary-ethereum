// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Chainfy is Ownable {

    string contractName;
    mapping(address => bool) allowedAccounts;
    address[] public allAllowedAccounts;  
    struct Product {string productName; uint productCode; bytes32[] productDigests;}
    event newProduct(string name, uint code, bytes32 digest);
    event addDigest(string name, uint code, bytes32 digest);
    //Product[] Products;
    mapping(string => Product) Products;
    mapping(string => bool) Existence;
    string[] productNameList;

    
    modifier authorizedAccounts() {
        require(checkAllowed(msg.sender), "l'utente non ha il permesso");
        _;
    }

    // constructor (string memory _name ) {
    //     contractName = _name;
    // } 
    constructor() {
        contractName = "CryptoInnova";
    }

    function addAllowed(address  _newAllowed) public onlyOwner{
        require(!allowedAccounts[_newAllowed], "Account gia presente tra quelli autorizzati!");
        allowedAccounts[_newAllowed] = true;
        allAllowedAccounts.push(_newAllowed);
    }

    function removeAllowed(address  _removeAllowed) public onlyOwner{
        require(allowedAccounts[_removeAllowed], "Account gia privo di autorizzazione!");
        allowedAccounts[_removeAllowed] = false;
        uint length = allAllowedAccounts.length;
        for(uint i; i <= length; i++){
            if (allAllowedAccounts[i] == _removeAllowed){
                allAllowedAccounts[i] = allAllowedAccounts[length - 1];
                allAllowedAccounts.pop();
                break;
            }
        }
    }

    function showAllowed() public view returns (address[] memory _allAllowedAccounts){
        return allAllowedAccounts;
    }

    function checkAllowed(address _allowed) internal view returns(bool _check){
        if(allowedAccounts[_allowed]){
            return true;
        }
    }

    function addProduct(string memory _productName, uint _productCode, bytes32 _productDigest) public authorizedAccounts{
        require(!productExists(_productName), "nome prodotto gia in lista!");
        Products[_productName].productName = _productName;
        Products[_productName].productCode = _productCode;
        Products[_productName].productDigests.push(_productDigest);

        productNameList.push(_productName);
        Existence[_productName] = true;
        emit newProduct(_productName, _productCode, _productDigest);
    }

    function checkProduct(string memory _name) public view returns(string memory _productName, uint _productCode, bytes32[] memory _productDigests){
        require(productExists(_name), "nome prodotto errato o non in lista!");
        return (Products[_name].productName, Products[_name].productCode, Products[_name].productDigests);
    }

    function addProductDigest(string memory _name, bytes32 _digest) public authorizedAccounts{
        require(productExists(_name), "nome prodotto errato o non in lista!");
        Products[_name].productDigests.push(_digest);
        emit addDigest(_name, Products[_name].productCode, _digest);
    }

    function showProductsByName() public view returns(string[] memory _allProducts){
        return productNameList;
    }

    function productExists(string memory _productName) internal view returns(bool _exists){
        if (Existence[_productName]){
            return true;
        }
    }
        

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}