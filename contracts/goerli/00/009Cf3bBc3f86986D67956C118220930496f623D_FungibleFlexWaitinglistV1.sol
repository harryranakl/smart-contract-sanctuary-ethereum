// SPDX-License-Identifier: GPL-3.0

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: contracts/qr.sol

pragma solidity ^0.8.0;

interface Collection {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/*
 * @author - Michel
 * @notice The contract allows whitelisted users to create multiple displays
 * with a fixed rent parameter. Those who wish to display their NFTs can set their
 * token data using the setImage functionality and pay the required amount of rent.
 * This will map the NFT token data to the respective display IDs.
 */

contract FungibleFlexWaitinglistV1 is Ownable {
    uint256 displayCounter;
    uint256 establishmentCounter;
    uint256 public minimumRent = 0.0001 ether;

    struct displayStruct {
        address displayOwner;
        string displayName;
        uint256[] tokenId;
        uint256[] startTime;
        uint256[] endTime;
        address[] collectionAddress;
        address[] nftOwnerAddress;
        uint256 rentPer10Mins;
        uint256 amountGenerated;
    }

    struct displayNumber {
        uint256 dispNum;
    }
    //
    struct establishmentStruct {
        string establishmentName;
        address establishmentOwner;
        uint256[] displayIds;
    }
    //
    struct establishmentsNumber {
        uint256 estNum;
    }
    //
    mapping(uint256 => establishmentStruct) public establishments;
    //
    mapping(address => establishmentsNumber[]) establishmentsAddress;

    mapping(uint256 => displayStruct) public display;

    mapping(address => displayNumber[]) displayOwnerMapping;

    mapping(address => bool) whitelist;
    mapping(address => bool) blacklistContracts;

    event Display(uint256 _displayId, displayStruct _displayDetails);

    /**
     * @dev Initializes the contract setting the displayCounter to 0.
     */
    constructor() {
        displayCounter = 0;
        establishmentCounter = 0;
    }

    //create establishment
    function createEstablishment(string memory _estName) public {
        require(isWhitelisted(msg.sender), "The address is not whitelisted");
        uint256 newEstID = establishmentCounter;
        establishments[newEstID].establishmentName = _estName;
        establishments[newEstID].establishmentOwner = msg.sender;
        establishmentsAddress[msg.sender].push(establishmentsNumber(newEstID));
        establishmentCounter++;
    }

    /*
     * @notice Whitelisted users create display with initial rent
     * Minimum rent criteria must be met
     *
     * @dev Function checks if the caller is whitelisted and the rent exceeds
     * the minimum criteria. If checks are passed, initializes the display
     * mapping's "displayOwner" and "rentPer10Mins" properties.
     * Finally, the newly created display is pushed to the "displayOwnerMapping"
     * array which is mapped to the corresponding address.
     *
     * @param _rentPer10Mins rent to be set for the newly created display
     */
    function createDisplay(
        string memory _displayName,
        uint256 _estID,
        uint256 _rentPer10Mins
    ) public {
        require(isWhitelisted(msg.sender), "The address is not whitelisted");
        require(_rentPer10Mins >= minimumRent, "Minimum rent criteria not met");
        //display owner must match establishment owner
        require(
            establishments[_estID].establishmentOwner == msg.sender,
            "The address is not the establishment owner"
        );
        uint256 newDisplayId = displayCounter;
        display[displayCounter].displayOwner = msg.sender;
        display[displayCounter].rentPer10Mins = _rentPer10Mins;
        display[displayCounter].displayName = _displayName;
        displayOwnerMapping[msg.sender].push(displayNumber(newDisplayId));
        establishments[_estID].displayIds.push(newDisplayId);
        displayCounter++;
    }

    /*
     * @notice Any user who holds an ERC721 NFT can set image for particular display
     * Display must not be occupied. The function caller must own the NFT.
     * The NFT should be ERC721 standaard
     *
     * @dev Function checks if the display is occupied, validates the rent
     * and checks for NFT ownership. Upon validation, the displayId, startTime,endTime,
     * collectionAddress and nftOwnerAddress properties of the display will be changed
     * A fixed share of display will be sent to the display owner wallet,
     * rest will stay in the contract
     * Finally the Display event is emitted which contains displayId and display struct
     *
     * @param _NFTAddress address of the NFT collection to be displayed
     * @param _tokenId token id of NFT collection to display
     * @param _displayId id of display to set the image on
     * @param _time time duration in seconds for the image display
     */

    function setImage(
        address _NFTAddress,
        uint256 _tokenId,
        uint256 _displayId,
        uint256 _time
    ) public payable {
        //require(!isOccupied(_displayId), "Display is occupied");
        require(
            msg.value >= (display[_displayId].rentPer10Mins * _time) / 600,
            "Cost error"
        );
        require(!blacklistContracts[_NFTAddress], "NFT address is blacklisted");
        Collection thisCollection = Collection(_NFTAddress);
        require(
            thisCollection.ownerOf(_tokenId) == msg.sender,
            "Sender is not the owner of NFT"
        );
        display[_displayId].tokenId.push(_tokenId);
        uint256 start = block.timestamp;
        display[_displayId].startTime.push(start);
        // display[_displayId].endTime.push(start + _time);

        // display[_displayId].endTime.push(display[_displayId].endTime[display[_displayId].endTime.length - 1] + _time);
        //if endtime length is 0, then endtime is starttime + time
        if (display[_displayId].endTime.length == 0) {
            display[_displayId].endTime.push(start + _time);
        }
        //if endtime length is not 0, then endtime is endtime + time
        else {
            display[_displayId].endTime.push(
                display[_displayId].endTime[
                    display[_displayId].endTime.length - 1
                ] + _time
            );
        }

        display[_displayId].collectionAddress.push(_NFTAddress);
        display[_displayId].nftOwnerAddress.push(msg.sender);
        uint256 displayOwnerShare = (msg.value * 95) / 100;
        display[_displayId].amountGenerated += displayOwnerShare;

        address displayOwner = display[_displayId].displayOwner;
        payable(displayOwner).transfer(displayOwnerShare);
        emit Display(_displayId, display[_displayId]);

        //clear the arrays start time end time collection address and token id for all end time less than current time
        for (uint256 i = 0; i < display[_displayId].endTime.length; i++) {
            if (display[_displayId].endTime[i] < block.timestamp) {
                delete display[_displayId].startTime[i];
                delete display[_displayId].endTime[i];
                delete display[_displayId].collectionAddress[i];
                delete display[_displayId].tokenId[i];
                delete display[_displayId].nftOwnerAddress[i];
            }
        }
    }

    /*
     * @notice Any User Who holds an ERC721 NFT can set image for multiple displays
     * Display must not be occupied. The function caller must own the NFT.
     * The NFT should be ERC721 standaard
     *
     * @dev Function checks if the displays are occupied, validates the rent
     * and checks for NFT ownership. Upon validation, the displayId, startTime,endTime,
     * collectionAddress and nftOwnerAddress phroperties of the display will be changed for each display
     * A fixed share of display will be sent to the display owner wallet,
     * rest will stay in the contract
     * Finally the Display event is emitted which contains displayId and display struct
     *
     * @param _NFTAddress address of the NFT collection to be displayed
     * @param _tokenId token id of NFT collection to display
     * @param _displayIds array of display ids to set the image on
     * @param _time time duration in seconds for the image display
     */

    function setImageMultiple(
        address _NFTAddress,
        uint256 _tokenId,
        uint256[] memory _displayIds,
        uint256 _time
    ) public payable {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < _displayIds.length; i++) {
            totalCost += (display[_displayIds[i]].rentPer10Mins * _time) / 600;
        }
        require(msg.value >= totalCost, "Cost error");
        require(!blacklistContracts[_NFTAddress], "NFT address is blacklisted");
        Collection thisCollection = Collection(_NFTAddress);
        require(
            thisCollection.ownerOf(_tokenId) == msg.sender,
            "Sender is not the owner of NFT"
        );
        for (uint256 i = 0; i < _displayIds.length; i++) {
            require(!isOccupied(_displayIds[i]), "Display is occupied");
            display[_displayIds[i]].tokenId.push(_tokenId);
            uint256 start = block.timestamp;
            display[_displayIds[i]].startTime.push(start);
            display[_displayIds[i]].endTime.push(start + _time);
            display[_displayIds[i]].collectionAddress.push(_NFTAddress);
            display[_displayIds[i]].nftOwnerAddress.push(msg.sender);
            display[_displayIds[i]].amountGenerated +=
                (msg.value * 95) /
                100 /
                _displayIds.length;
        }
        uint256 displayOwnerShare = (msg.value * 95) / 100;
        address displayOwner = display[_displayIds[0]].displayOwner;
        payable(displayOwner).transfer(displayOwnerShare);

        //emit for each display
        for (uint256 i = 0; i < _displayIds.length; i++) {
            emit Display(_displayIds[i], display[_displayIds[i]]);
        }
    }

    /*
     * @notice Display owners can call this function to reset image on any of their owned display
     *
     * @dev Only owners of the display can utilize this function
     * collectionAddress and nftOwner address of display will be set to address(0)
     * endTime and startTime will be initialized
     * Finally the Display event is emitted which contains displayId and display struct
     *
     * @param _displayId display id of display to reset
     */
    //function resetDisplay(uint256 _displayId) public {
    //     require(
    //         display[_displayId].displayOwner == msg.sender,
    //         "Only display owners are authorized to reset display"
    //     );
    //      display[_displayId].collectionAddress = address(0);
    //      display[_displayId].nftOwnerAddress = address(0);
    //     display[_displayId].endTime = 0;
    //    display[_displayId].startTime = 0;
    //    emit Display(_displayId, display[_displayId]);
    // }

    /*
     * @notice Function to check whitelist status
     *
     * @param _address address to check in the whitelist
     *
     * @return bool returns status of whitelist
     */
    function isWhitelisted(address _address)
        public
        view
        virtual
        returns (bool)
    {
        return whitelist[_address];
    }

    /*
     * @notice Function to check blacklist status of contract
     *
     * @param _address contract address to check in the whitelist
     *
     * @return bool returns status of blacklist
     */
    function isBlacklisted(address _address)
        public
        view
        virtual
        returns (bool)
    {
        return blacklistContracts[_address];
    }

    /*
     * @notice Display owners can call this function to change rent for any of their owned display
     *
     * @dev Only owners of the display can utilize this function
     * Minimum rent criteria must be met
     *
     * @param _rentPer10Mins new rent
     */
    function setRent(uint256 _displayId, uint256 _cost) public {
        require(
            display[_displayId].displayOwner == msg.sender,
            "Only display owners are authorized to set rent"
        );
        require(_cost >= minimumRent, "Minimum rent criteria not met");
        display[_displayId].rentPer10Mins = _cost;
    }

    //set name
    function setName(uint256 _displayId, string memory _name) public {
        require(
            display[_displayId].displayOwner == msg.sender,
            "Only display owners are authorized to set name"
        );
        display[_displayId].displayName = _name;
    }

    /*
     * @notice Function to get displays owned by particular address
     *
     * @param _address wallet address whose displays are to be fetched
     *
     * @return uint256[] returns array of display id's owned by the address
     */
    function getDisplaysOwned(address _address)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 len = displayOwnerMapping[_address].length;
        uint256[] memory displaysArray = new uint256[](len);
        for (uint256 counter = 0; counter < len; counter++)
            displaysArray[counter] = displayOwnerMapping[_address][counter]
                .dispNum;
        return displaysArray;
    }

    /*
     * @notice Function to get unoccupied displays owned by particular address
     *
     * @param _address wallet address whose displays are to be fetched
     *
     * @return uint256[] returns array of unoccupied display id's owned by the address
     */

    function getUnoccupiedDisplaysOwned(address _address)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 len = displayOwnerMapping[_address].length;
        uint256[] memory displaysArray = new uint256[](len);
        uint256 counter = 0;
        for (uint256 i = 0; i < len; i++) {
            if (!isOccupied(displayOwnerMapping[_address][i].dispNum)) {
                displaysArray[counter] = displayOwnerMapping[_address][i]
                    .dispNum;
                counter++;
            }
        }
        return displaysArray;
    }

    //get establishments owned by address
    function getEstablishmentsOwned(address _address)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 len = establishmentsAddress[_address].length;
        uint256[] memory establishmentsArray = new uint256[](len);
        for (uint256 counter = 0; counter < len; counter++)
            establishmentsArray[counter] = establishmentsAddress[_address][
                counter
            ].estNum;
        return establishmentsArray;
    }

    //get display owned by establishment
    function getDisplaysOwnedByEstablishment(uint256 _estID)
        public
        view
        returns (uint256[] memory)
    {
        uint256 len = establishments[_estID].displayIds.length;

        uint256[] memory displaysArray = new uint256[](len);
        for (uint256 counter = 0; counter < len; counter++)
            displaysArray[counter] = establishments[_estID].displayIds[counter];
        return displaysArray;
    }

    //get unoccupied display owned by establishment
    function getUnoccupiedDisplaysOwnedByEstablishment(uint256 _estID)
        public
        view
        returns (uint256[] memory)
    {
        uint256 len = establishments[_estID].displayIds.length;
        uint256[] memory displaysArray = new uint256[](len);
        uint256 counter = 0;
        for (uint256 i = 0; i < len; i++) {
            if (!isOccupied(establishments[_estID].displayIds[i])) {
                displaysArray[counter] = establishments[_estID].displayIds[
                    counter
                ];
                counter++;
            }
        }
        return displaysArray;
    }

    /*
     * @notice Function to add addresses to the whitelist
     * Only contract owner can call
     *
     * @param _addressList list of wallet address to add in whitelist
     */
    function addWhitelist(address[] memory _addressList) public onlyOwner {
        uint256 len = _addressList.length;
        for (uint256 counter = 0; counter < len; counter++)
            whitelist[_addressList[counter]] = true;
    }

    /*
     * @notice Function to remove addresses from the whitelist
     * Only contract owner can call
     *
     * @param _addressList list of wallet address to remove from whitelist
     */
    function removeWhitelist(address[] memory _addressList) public onlyOwner {
        uint256 len = _addressList.length;
        for (uint256 counter = 0; counter < len; counter++)
            whitelist[_addressList[counter]] = false;
    }

    /*
     * @notice Function to add addresses to the whitelist
     * Only contract owner can call
     *
     * @param _addressList list of wallet address to add in whitelist
     */
    function addBlacklist(address[] memory _addressList) public onlyOwner {
        uint256 len = _addressList.length;
        for (uint256 counter = 0; counter < len; counter++)
            blacklistContracts[_addressList[counter]] = true;
    }

    /*
     * @notice Function to remove addresses from the blacklist
     * Only contract owner can call
     *
     * @param _addressList list of wallet address to remove from blacklist
     */
    function removeBlacklist(address[] memory _addressList) public onlyOwner {
        uint256 len = _addressList.length;
        for (uint256 counter = 0; counter < len; counter++)
            blacklistContracts[_addressList[counter]] = false;
    }

    /*
     * @notice Function to withdraw all balance to contract owner's wallet
     * Only contract owner can call
     */
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /*
     * @notice Function to check if a display is occupied
     *
     * @dev The display should be initialized
     * display not occupied if endTime of display is lesser tahn current block's timestamp
     *
     * @param _displayId display id
     * @return bool returns true if occupied and false if not
     */
    function isOccupied(uint256 _displayId) public view virtual returns (bool) {
        require(
            display[_displayId].displayOwner != address(0),
            "Display does not exist"
        );
        for (
            uint256 counter = 0;
            counter < display[_displayId].endTime.length;
            counter++
        ) {
            if (display[_displayId].endTime[counter] > block.timestamp) {
                return true;
            }
        }
        return false;
    }

    //return the display with the correct token address and token id based on timestamp
    function getCurrentDisplaySettings(uint256 _displayId)
        public
        view
        virtual
        returns (
            address ownerdisplay,
            string memory displayName,
            address collectionAddress,
            uint256 tokenId,
            uint256 endTime,
            uint256 startTime
        )
    {
        require(
            display[_displayId].displayOwner != address(0),
            "Display does not exist"
        );
        for (
            uint256 counter = 0;
            counter < display[_displayId].endTime.length;
            counter++
        ) {
            if (display[_displayId].endTime[counter] > block.timestamp) {
                return (
                    display[_displayId].displayOwner,
                    display[_displayId].displayName,
                    display[_displayId].collectionAddress[counter],
                    display[_displayId].tokenId[counter],
                    display[_displayId].endTime[counter],
                    display[_displayId].startTime[counter]
                );
            }
        }
        return (address(0),string(""),address(0), 0, 0, 0);
    }

    //get arrays of displya setting for all endtimes greater than current timestamp
    function getSettingsWaitingList(uint256 _displayId)
        public
        view
        virtual
        returns (
            uint256 displayId,
            address[] memory collectionAddress,
            uint256[] memory tokenId,
            uint256[] memory endTime,
            uint256[] memory startTime
        )
    {
        require(
            display[_displayId].displayOwner != address(0),
            "Display does not exist"
        );
        uint256 len = display[_displayId].endTime.length;
        address[] memory collectionAddressArray = new address[](len);
        uint256[] memory tokenIdArray = new uint256[](len);
        uint256[] memory endTimeArray = new uint256[](len);
        uint256[] memory startTimeArray = new uint256[](len);
        uint256 counter = 0;
        for (
            uint256 i = 0;
            i < len;
            i++
        ) {
            if (display[_displayId].endTime[i] > block.timestamp) {
                collectionAddressArray[counter] = display[_displayId]
                    .collectionAddress[i];
                tokenIdArray[counter] = display[_displayId].tokenId[i];
                endTimeArray[counter] = display[_displayId].endTime[i];
                startTimeArray[counter] = display[_displayId].startTime[i];
                counter++;
            }
        }
        return (
            _displayId,
            collectionAddressArray,
            tokenIdArray,
            endTimeArray,
            startTimeArray
        );
    }
   

    /*
     * @notice Function to set minimum rent
     * Only contract owner can call
     *
     * @param _minRent minimum rent cost
     */
    function setMinimumRent(uint256 _minRent) public onlyOwner {
        minimumRent = _minRent;
    }
}