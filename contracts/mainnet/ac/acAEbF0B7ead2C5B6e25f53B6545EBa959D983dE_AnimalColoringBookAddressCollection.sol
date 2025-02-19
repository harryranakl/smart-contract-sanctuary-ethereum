pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './AnimalColoringBook.sol';
import './AnimalColoringBookDescriptors.sol';
import 'base64-sol/base64.sol';

contract AnimalColoringBookAddressCollection is ERC721, Ownable {
    uint256 private _nonce;
    address immutable private animalColoringBook;
    address immutable private animalColoringBookDescriptors;

    constructor(address _owner, address _animalColoringBook, address _animalColoringBookDescriptors) ERC721("Animal Coloring Book Address Collection Viewer", "ACB-ACV"){
        transferOwnership(_owner);
        animalColoringBook = _animalColoringBook;
        animalColoringBookDescriptors = _animalColoringBookDescriptors;
    }

    function mint(address to) external {
        require(balanceOf(to) == 0, 'AnimalColoringBookAddressCollection: address already minted');
        _safeMint(to, ++_nonce);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(from == address(0), 'AnimalColoringBookAddressCollection: no transfers allowed');
    }

    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        address owner = ownerOf(tokenId);
        return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{"name":"Animal Coloring Book Collection of ',
                                    Strings.toHexString(uint256(uint160(owner))),
                                    '", "description":"',
                                    "This NFT is non-transferable and is free to mint, one per address. This NFT's purpose is to display the owner's Animal Coloring Book collection in one image. The image contains up to six Animal Coloring Books which are owned by the address. Image is generated and stored entirely on chain.",
                                    '", "image": "',
                                    'data:image/svg+xml;base64,',
                                    Base64.encode(svg(owner, tokenId)),
                                    '"}'
                                )
                            )
                        )
                )
            );
    }

    function svg(address owner, uint256 tokenId) public view returns(bytes memory){
        return abi.encodePacked(
                '<svg version="1.1" shape-rendering="optimizeSpeed" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 960 630" width="960" height="630" xml:space="preserve">',
                buildAnimals(owner, tokenId),
                '</svg>'
            );
    }

    function buildAnimals(address owner, uint256 tokenId) public view returns(string memory result) {
        uint256 tokenCount = AnimalColoringBook(animalColoringBook).balanceOf(owner);
        uint256 min = tokenCount < 5 ? tokenCount : 5;
        for (uint i; i < tokenCount; i++){
                uint256 tokenId = AnimalColoringBook(animalColoringBook).tokenOfOwnerByIndex(owner, i);
                (uint8 animalType, uint8 mood) = AnimalColoringBook(animalColoringBook).animalInfo(tokenId);
                address[] memory history = AnimalColoringBook(animalColoringBook).transferHistory(tokenId);
                result = string(abi.encodePacked(result, 
                '<image href="data:image/svg+xml;base64,',
                Base64.encode(AnimalColoringBookDescriptors(animalColoringBookDescriptors).svgImage(tokenId, animalType, mood, history)),
                '" x="',
                Strings.toString(i * 300 % 900 + (i % 3) * 30),
                '" y="',
                Strings.toString((i / 3 * 300) + (i / 3 * 30)),
                '"/>'
                ));
            }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


interface IDescriptors {
    function tokenURI(uint256 tokenId, AnimalColoringBook animalColoringBook) external view returns(string memory);
}

interface IMintableBurnable {
    function mint(address mintTo) external;
    function burn(uint256 tokenId) external;
}

interface IGTAP1 {
    function copyOf(uint256 tokenId) external returns(uint256);
}

struct Animal {
    uint8 animalType;
    uint8 mood;
}

// types = cat = 1, bunny  = 2, mouse = 3, skull = 4, unicorn = 5, creator = 6 

contract AnimalColoringBook is ERC721Enumerable, Ownable {
    IDescriptors public immutable descriptors;
    address public immutable gtap1Contract;
    address public immutable wrappedGtap1Contract;
    address public eraserContract;
    uint256 public immutable publicMintintingOpenBlock;
    uint256 public immutable mintFeeWei = 2e17;
    uint256 public immutable eraserMintFeeWei = 1e17;
    uint256 public immutable maxNonOGCount = 936;
    bytes32 public immutable merkleRoot;
    uint256 private _nonce;

    mapping(uint256 => Animal) public animalInfo;
    mapping(uint256 => address[]) private _transferHistory;
    // Can mint 1 per GTAP1 OG
    mapping(uint256 => uint256) public ogMintCount;
    // each GTAP1 holder can mint 2
    mapping(address => uint256) public gtapHolderMintCount;

    constructor(address _owner, bytes32 _merkleRoot, IDescriptors _descriptors, address _gtap1Contract, address _wrappedGtap1Contract) ERC721("Animal Coloring Book", "GTAP2") {
        transferOwnership(_owner);
        descriptors = _descriptors;
        publicMintintingOpenBlock = block.number + 0; // 12300 ~48 hrs
        merkleRoot = _merkleRoot;
        gtap1Contract = _gtap1Contract;
        wrappedGtap1Contract = _wrappedGtap1Contract;
    }

    function transferHistory(uint256 tokenId) external view returns (address[] memory){
        return _transferHistory[tokenId];
    }

    function mint(address mintTo, bool mintEraser) payable external {
        uint256 mintFee = mintEraser ? mintFeeWei + eraserMintFeeWei : mintFeeWei;
        require(msg.value >= mintFee, "AnimalColoringBook: fee too low");
        require(block.number >= publicMintintingOpenBlock, 'AnimalColoringBook: public minting not open yet');
        require(_nonce < maxNonOGCount, 'AnimalColoringBook: minting closed');
        _mint(mintTo, mintEraser);
    }

    function gtap1HolderMint(address mintTo, bool mintEraser, bytes32[] calldata merkleProof) payable external {
        uint256 mintFee = mintEraser ? mintFeeWei + eraserMintFeeWei : mintFeeWei;
        require(msg.value >= mintFee, "AnimalColoringBook: fee too low");
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'AnimalColoringBook: invalid proof');
        require(gtapHolderMintCount[msg.sender] < 2, 'AnimalColoringBook: reached max mint');
        require(_nonce < maxNonOGCount, 'AnimalColoringBook: minting closed');
        _mint(mintTo, mintEraser);
        gtapHolderMintCount[msg.sender]++;
    }

    function gtap1OGHolderMint(address mintTo, uint256 gtap1TokenId) external {
        require(ogMintCount[gtap1TokenId] == 0, 'AnimalColoringBook: reached max mint');
        require(_isOgHolder(gtap1TokenId), 'AnimalColoringBook: must be gtap1 original owner');
        _mint(mintTo, true);
        ogMintCount[gtap1TokenId]++;
    }

    function _isOgHolder(uint256 gtap1TokenId) private returns(bool){
        if(IERC721(gtap1Contract).ownerOf(gtap1TokenId) == msg.sender && IGTAP1(gtap1Contract).copyOf(gtap1TokenId) == 0 ){
            return true;
        }
        return IERC721(wrappedGtap1Contract).ownerOf(gtap1TokenId) == msg.sender;
    }

    function _mint(address mintTo, bool mintEraser) private {
        require(_nonce < 1000, 'AnimalColoringBook: reached max mint');
        _safeMint(mintTo, ++_nonce, "");

        uint256 randomNumber = _randomishIntLessThan("animal", 101);
        uint8 animalType = (
         (randomNumber < 31 ? 1 :
          (randomNumber < 56 ? 2 :
           (randomNumber < 76 ? 3 :
            (randomNumber < 91 ? 4 :
             (randomNumber < 99 ? 5 : 6))))));
        
        animalInfo[_nonce].animalType = animalType;

        if(mintEraser){
            IMintableBurnable(eraserContract).mint(mintTo);
        }
    }

    function erase(uint256 tokenId, uint256 eraserTokenId) external {
        IMintableBurnable(eraserContract).burn(eraserTokenId);
        address[] memory fresh;
        _transferHistory[tokenId] = fresh;
        animalInfo[tokenId].mood = 0;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
         if(_transferHistory[tokenId].length < 4) {
            _transferHistory[tokenId].push(to);
            if(_transferHistory[tokenId].length == 4){
                uint8 random = _randomishIntLessThan("mood", 10) + 1;
                animalInfo[tokenId].mood = random > 6  ? 1 : random;
            }
        }
    }
    
    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        return descriptors.tokenURI(tokenId, this);
    }

    function setEraser(address _eraserContract) external {
        require(address(eraserContract) == address(0), 'set');
        eraserContract = _eraserContract;
    }

    function _randomishIntLessThan(bytes32 salt, uint8 n) private view returns (uint8) {
        if (n == 0)
            return 0;
        return uint8(keccak256(abi.encodePacked(block.timestamp, _nonce, msg.sender, salt))[0]) % n;
    }

    function payOwner(address to, uint256 amount) public onlyOwner() {
        require(amount <= address(this).balance, "amount too high");
        payable(to).transfer(amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;
import '../libraries/UintStrings.sol';
import './AnimalDescriptors.sol';
import 'base64-sol/base64.sol';

interface IAnimalColoringBook{
    function animalInfo(uint256 tokenId) external view returns (uint8, uint8);
    function transferHistory(uint256 tokenId) external view returns (address[] memory);
}

interface IAnimalDescriptors{
    function animalSvg(uint8 animalType, uint8 mood) external view returns (string memory);
    function moodSvg(uint8 mood) external view returns (string memory);
    function animalTypeString(uint8 animalType) external view returns (string memory);
    function moodTypeString(uint8 mood) external view returns (string memory);
    // function randomishIntLessThan(bytes32 salt, uint8 n) external view returns (uint8);
}

contract AnimalColoringBookDescriptors {
    address public animalDescriptors;

    constructor(address _animalDescriptors) {
        animalDescriptors = _animalDescriptors;
    }

    function addressH(address account) public view returns (string memory){
        uint256 h = uint256(keccak256(abi.encodePacked(account))) % 360;
        return UintStrings.decimalString(h, 0, false);
    }

    function tokenURI(uint256 tokenId, IAnimalColoringBook animalColoringBook) external view returns(string memory) {
        (uint8 animalType, uint8 mood) = animalColoringBook.animalInfo(tokenId);
        address[] memory history = animalColoringBook.transferHistory(tokenId);
        return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                        Base64.encode(
                            bytes(
                                abi.encodePacked(
                                    '{"name":"',
                                    '#',
                                    UintStrings.decimalString(tokenId, 0, false),
                                    ' - ',
                                    history.length < 4 ? '' : string(abi.encodePacked(IAnimalDescriptors(animalDescriptors).moodTypeString(mood), ' ')),
                                    IAnimalDescriptors(animalDescriptors).animalTypeString(animalType),
                                    '", "description":"',
                                    "The first four transfers of this NFT add a color to part of the image. First, the background. Second, the body. Third, the nose and mouth. And finally, the eyes. The colors are determined by the to address of the transfer. On the fourth transfer, the Animal's mood is revealed, corresponding to the animation of its eyes. The SVG image and animation are generated and stored entirely on-chain.",
                                    '", "attributes": [',
                                    '{',
                                    '"trait_type": "Type",', 
                                    '"value":"',
                                    IAnimalDescriptors(animalDescriptors).animalTypeString(animalType),
                                    '"}',
                                    ', {',
                                    '"trait_type": "Coloring",', 
                                    '"value":"',
                                    UintStrings.decimalString(history.length, 0, false),
                                    '/4',
                                    '"}',
                                    moodTrait(mood),
                                    ']',
                                    ', "image": "'
                                    'data:image/svg+xml;base64,',
                                    Base64.encode(bytes(svgImage(tokenId, animalType, mood, history))),
                                    '"}'
                                )
                            )
                        )
                )
            );
    }

    function moodTrait(uint8  mood) public view returns (string memory) {
        if (mood == 0){
            return '';
        }
        return string(
            abi.encodePacked(
                ', {',
                '"trait_type": "Mood",', 
                '"value":"',
                IAnimalDescriptors(animalDescriptors).moodTypeString(mood),
                '"}'
            )
        );
    }


    function svgImage(uint256 tokenId, uint8 animalType, uint8 mood, address[] memory history) public view returns (bytes memory){
        return abi.encodePacked(
                '<svg version="1.1" shape-rendering="optimizeSpeed" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 10 10" width="300" height="300" xml:space="preserve">',
                styles(tokenId, history),
                IAnimalDescriptors(animalDescriptors).animalSvg(animalType, mood),
                '</svg>'
            );
    }

    function styles(uint256 tokenId, address[] memory history) public view returns (string memory) {
        string memory color1 = history.length > 0 ? string(abi.encodePacked('hsl(', addressH(history[0]),',100%,50%)')) : '#ffffff;';
        string memory color2 = history.length > 1 ? string(abi.encodePacked('hsl(', addressH(history[1]),',100%,50%)')) : '#ffffff;';
        string memory color3 = history.length > 2 ? string(abi.encodePacked('hsl(', addressH(history[2]),',100%,50%)')) : history.length > 1 ? color2 : '#ffffff';
        string memory color4 = history.length > 3 ? string(abi.encodePacked('hsl(', addressH(history[3]),',100%,50%)')) : history.length > 1 ? color2 : '#ffffff';
        string memory color5 = history.length < 4 ? color2 : '#ffffff;';
        return string(
            abi.encodePacked(
                '<style type="text/css">',
                    'rect{width: 1px; height: 1px;}',
                    '.l{width: 2px; height: 1px;}',
	                '.c1{fill:',
                    color2
                    ,'}',
                    '.c2{fill:',
                    color3
                    ,'}'
                    '.c3{fill:',
                    color4
                    ,'}'
                    '.c4{fill:',
                    color1
                    ,'}'
                    '.c5{fill:',
                    color5,
                    '}',
                '</style>'
                )
        );

    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity 0.8.6;


library UintStrings {
    function decimalString(uint256 number, uint8 decimals, bool isPercent) internal pure returns(string memory){
        if(number == 0){
            return isPercent ? "0%" : "0";
        }
        
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10 ** decimals;

        uint256 temp = number;
        uint8 digits;
        uint8 numSigfigs;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params;
        params.isPercent = isPercent;
        if((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if(tenPowDecimals > number){
                // number is less than one
                // in this case, there may be leading zeros after the decimal place 
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                params.sigfigIndex = numSigfigs + params.zerosEndIndex;
                params.bufferLength = params.sigfigIndex + percentBufferOffset;
                params.isLessThanOne = true;
            } else {
                // In this case, there are digits before and
                // after the decimal place
                params.sigfigIndex = numSigfigs + 1;
                params.decimalIndex = digits - decimals + 1;
            }
        }
        params.bufferLength = params.sigfigIndex + percentBufferOffset;
        return generateDecimalString(params);
    }

    // With modifications, From https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/NFTDescriptor.sol#L189-L231

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function generateDecimalString(DecimalStringParams memory params) private pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = '%';
        }
        if (params.isLessThanOne) {
            buffer[0] = '0';
            buffer[1] = '.';
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex; zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                buffer[--params.sigfigIndex] = '.';
            }
            buffer[--params.sigfigIndex] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
            params.sigfigs /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import './Eyes.sol';
import '../libraries/UintStrings.sol';
import './interfaces/IAnimalSVG.sol';

contract AnimalDescriptors {
    IAnimalSVG public immutable creator;
    IAnimalSVG public immutable unicorn;
    IAnimalSVG public immutable skull;
    IAnimalSVG public immutable cat;
    IAnimalSVG public immutable mouse;
    IAnimalSVG public immutable bunny;

    constructor(IAnimalSVG _creator, IAnimalSVG _unicorn, IAnimalSVG _skull, IAnimalSVG _cat, IAnimalSVG _mouse, IAnimalSVG _bunny){
        creator = _creator;
        unicorn = _unicorn;
        skull = _skull;
        cat = _cat;
        mouse = _mouse;
        bunny = _bunny;
    }

    function animalSvg(uint8 animalType, uint8 mood) external view returns (string memory){
        string memory moodSVG = moodSvg(mood);
        return (animalType == 1 ? cat.svg(moodSVG) :
                    (animalType == 2 ? bunny.svg(moodSVG) :
                        (animalType == 3 ? mouse.svg(moodSVG) :
                            (animalType == 4 ? skull.svg(moodSVG) : 
                                (animalType == 5 ? unicorn.svg(moodSVG) : creator.svg(moodSVG))))));
    }

    function moodSvg(uint8 mood) public view returns (string memory){
        if(mood == 1){
            string memory rand1 = UintStrings.decimalString(_randomishIntLessThan('rand1', 4) + 10, 0, false);
            string memory rand2 = UintStrings.decimalString(_randomishIntLessThan('rand2', 5) + 14, 0, false);
            string memory rand3 = UintStrings.decimalString(_randomishIntLessThan('rand3', 3) + 5, 0, false);
            return Eyes.aloof(rand1, rand2, rand3);
        } else {
            return (mood == 2 ? Eyes.sly() : 
                        (mood == 3 ? Eyes.dramatic() : 
                            (mood == 4 ? Eyes.mischievous() : 
                                (mood == 5 ? Eyes.flirty() : Eyes.shy()))));
        }
    }

    function _randomishIntLessThan(bytes32 salt, uint8 n) private view returns (uint8) {
        if (n == 0)
            return 0;
        return uint8(keccak256(abi.encodePacked(block.timestamp, msg.sender, salt))[0]) % n;
    }

    function animalTypeString(uint8 animalType) public view returns (string memory){
        return (animalType == 1 ? "Cat" : 
                (animalType == 2 ? "Bunny" : 
                    (animalType == 3 ? "Mouse" : 
                        (animalType == 4 ? "Skull" : 
                            (animalType == 5 ? "Unicorn" : "Creator")))));
    }

    function moodTypeString(uint8 mood) public view returns (string memory){
        return (mood == 1 ? "Aloof" : 
                (mood == 2 ? "Sly" : 
                    (mood == 3 ? "Dramatic" : 
                        (mood == 4 ? "Mischievous" : 
                            (mood == 5 ? "Flirty" : "Shy")))));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

library Eyes{
    function sly() internal pure returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="sly">',
                    '<rect x="1" y="1" class="c3">',
                        '<animate attributeName="x" values="1;1;.5;.5;1;1" keyTimes="0;.55;.6;.83;.85;1" dur="13s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="6" y="1" class="c3">',
                        '<animate attributeName="x" values="6;6;5.5;5.5;6;6" keyTimes="0;.55;.6;.83;.85;1" dur="13s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="0" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;1;1;2;1;1;0;0" keyTimes="0;.55;.6;.72;.73;.74;.83;.85;1" dur="13s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;1;1;0;0" keyTimes="0;.55;.6;.83;.85;1" dur="13s" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }

    function aloof(string memory rand1, string memory rand2, string memory rand3) internal view returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="aloof">',
                    '<rect x="0" y="1" class="c3">',
                        '<animate attributeName="x" values="0;0;1;1;0;0" keyTimes="0;.5;.56;.96;.98;1" dur="',
                        rand1,
                        's" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="1;1;0;0;1;1" keyTimes="0;.5;.56;.96;.98;1" dur="',
                        rand2,
                        's" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="1" class="c3">',
                        '<animate attributeName="x" values="5;5;6;6;5;5" keyTimes="0;.5;.56;.96;.98;1" dur="',
                        rand1,
                        's" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="1;1;0;0;1;1" keyTimes="0;.5;.56;.96;.98;1" dur="',
                        rand2,
                        's" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="0" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;0" keyTimes="0;.55;.57;.59;1" dur="',
                        rand3,
                        's" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;0" keyTimes="0;.55;.57;.59;1" dur="',
                        rand3,
                        's" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }

    function dramatic() internal pure returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="dramatic">',
                    '<rect x="0" y="1" class="c3">',
                        '<animate attributeName="x" values="0;0;0;1;1;0;0;" keyTimes="0;.6;.62;.64;.82;.84;1" dur="12s" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="1;1;0;0;0;1;1" keyTimes="0;.6;.62;.64;.82;.84;1" dur="12s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="1" class="c3">',
                        '<animate attributeName="x" values="5;5;5;6;6;5;5" keyTimes="0;.6;.62;.64;.82;.84;1" dur="12s" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="1;1;0;0;0;1;1" keyTimes="0;.6;.62;.64;.82;.84;1" dur="12s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="0" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;0;2;0;0" keyTimes="0;.58;.59;.6;.8;.81;.82;1" dur="12s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;0;2;0;0" keyTimes="0;.58;.59;.6;.8;.81;.82;1" dur="12s" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }

    function flirty() internal pure returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="flirty">',
                    '<rect x="0" y="0" class="c3">',
                        '<animate attributeName="x" values="0;0;1;1;0;0" keyTimes="0;.5;.52;.96;.98;1" dur="20s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c3">',
                        '<animate attributeName="x" values="5;5;6;6;5;5" keyTimes="0;.5;.52;.96;.98;1" dur="20s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="0" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;2;0;0" keyTimes="0;.16;.17;.18;.19;.2;1" dur="10s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;2;0;2;0;0" keyTimes="0;.16;.17;.18;.19;.2;1" dur="10s" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }

    function mischievous() internal pure returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="mischievous">',
                    '<rect x="0" y="1" class="c3 s">',
                        '<animate attributeName="x" values="0;0;1;1;0;0" keyTimes="0;.3;.5;.83;.85;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="1" class="c3 s">',
                        '<animate attributeName="x" values="5;5;6;6;5;5" keyTimes="0;.3;.5;.83;.85;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="0" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;1;1;0;0" keyTimes="0;.2;.25;.63;.65;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c1 l" height="0">',
                        '<animate attributeName="height" values="0;0;1;1;0;0" keyTimes="0;.2;.25;.63;.65;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }

    function shy() internal pure returns (string memory){
        return string(
            abi.encodePacked(
                '<g id="shy">',
                    '<rect x="0" y="0" class="c3">',
                        '<animate attributeName="x" values="0;0;.5;0;0" keyTimes="0;.1;.7;.71;1" dur="8s" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="0;0;.5;0;0" keyTimes="0;.1;.7;.71;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                    '<rect x="5" y="0" class="c3">',
                        '<animate attributeName="x" values="5;5;5.5;5;5" keyTimes="0;.1;.7;.71;1" dur="8s" repeatCount="indefinite"/>',
                        '<animate attributeName="y" values="0;0;.5;0;0" keyTimes="0;.1;.7;.71;1" dur="8s" repeatCount="indefinite"/>',
                    '</rect>',
                '</g>'
            )
        );
    }
}

pragma solidity 0.8.6;

interface IAnimalSVG {
    function svg(string memory eyes) external pure returns(string memory);
}

