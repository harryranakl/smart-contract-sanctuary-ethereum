// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {VoteProposalLib} from "../libraries/VotingStatusLib.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

/*Interface for the CERC20 (Compound) Contract*/
interface CErc20 {
    function mint(uint256) external;

    function redeem(uint256) external;
}

/*Interface for the CETH (Compound)  Contract*/
interface CEth {
    function mint() external payable;
    function redeem(uint256) external;
}

contract CompoundFacet {
    error COULD_NOT_PROCESS();
    
     function executeInvest(
        uint24 _id
    ) external {
      
      
        VoteProposalLib.enforceMarried();
        VoteProposalLib.enforceUserHasAccess(msg.sender);
        VoteProposalLib.enforceAcceptedStatus(_id);
        VoteProposalLib.VoteTracking storage vt = VoteProposalLib
            .VoteTrackingStorage();


        //A small fee for the protocol is deducted here
        uint256 _amount = (vt.voteProposalAttributes[_id].amount *
            (10000 - vt.cmFee)) / 10000;
        uint256 _cmfees = vt.voteProposalAttributes[_id].amount - _amount;
         
        if (vt.voteProposalAttributes[_id].voteType == 203) {
            vt.voteProposalAttributes[_id].voteStatus = 203;
       VoteProposalLib.processtxn(vt.addressWaveContract, _cmfees);

            CEth cToken = CEth(vt.voteProposalAttributes[_id].receiver);
            cToken.mint{value: _amount}();
           emit VoteProposalLib.AddStake(address(this), vt.voteProposalAttributes[_id].receiver, block.timestamp, _amount);
            }
    
    else if (vt.voteProposalAttributes[_id].voteType == 204){
        vt.voteProposalAttributes[_id].voteStatus =204;
         TransferHelper.safeTransfer(
                    vt.voteProposalAttributes[_id].tokenID,
                    vt.addressWaveContract,
                    _cmfees
                );

            CErc20 cToken = CErc20(vt.voteProposalAttributes[_id].receiver);

            TransferHelper.safeApprove(
                vt.voteProposalAttributes[_id].tokenID,
                vt.voteProposalAttributes[_id].receiver,
                _amount
            );
             cToken.mint(_amount);
            }

     else if (vt.voteProposalAttributes[_id].voteType == 205) {
           vt.voteProposalAttributes[_id].voteStatus = 205;
           TransferHelper.safeTransfer(
                    vt.voteProposalAttributes[_id].tokenID,
                    vt.addressWaveContract,
                    _cmfees
                );

            CEth cEther = CEth(vt.voteProposalAttributes[_id].tokenID);

            cEther.redeem(_amount);

        }
        // Redeeming cToken for corresponding ERC20 token.
        else if (vt.voteProposalAttributes[_id].voteType == 206) {
             vt.voteProposalAttributes[_id].voteStatus = 206;
           TransferHelper.safeTransfer(
                    vt.voteProposalAttributes[_id].tokenID,
                    vt.addressWaveContract,
                    _cmfees
                );

            CErc20 cToken = CErc20(vt.voteProposalAttributes[_id].tokenID);
            cToken.redeem(_amount);

        } else {revert COULD_NOT_PROCESS();}
        emit VoteProposalLib.VoteStatus(
            _id,
            msg.sender,
            vt.voteProposalAttributes[_id].voteStatus,
            block.timestamp
        ); 
    }


}

// SPDX-License-Identifier: BSL
pragma solidity ^0.8.17;

/**
*   [BSL License]
*   @title Library of the Proxy Contract
*   @notice Proxy contracts use variables from this libriary. 
*   @dev The proxy uses Diamond Pattern for modularity. Relevant code was borrowed from  
    Nick Mudge.    
*   @author Ismailov Altynbek <[email protected]>
*/

library VoteProposalLib {
    bytes32 constant VT_STORAGE_POSITION =
        keccak256("waverimplementation.VoteTracking.Lib"); //Storing position of the variables

    struct VoteProposal {
        uint24 id;
        address proposer;
        uint8 voteType;
        uint256 tokenVoteQuantity;
        string voteProposalText;
        uint8 voteStatus;
        uint256 voteends;
        address receiver;
        address tokenID;
        uint256 amount;
        uint8 votersLeft;
    }

    event VoteStatus(
        uint24 indexed id,
        address sender,
        uint8 voteStatus,
        uint256 timestamp
    );

    struct VoteTracking {
        uint8 familyMembers;
        MarriageStatus marriageStatus;
        uint24 voteid; //Tracking voting proposals by VOTEID
        address proposer;
        address proposed;
        address payable addressWaveContract;
        uint nonce;
        uint256 threshold;
        uint256 id;
        uint256 cmFee;
        uint256 marryDate;
        uint256 policyDays;
        uint256 setDeadline;
        uint256 divideShare;
        uint256 promoDays;
        address [] subAccounts; //an Array of Subaccounts; 
        mapping(address => bool) hasAccess; //Addresses that are alowed to use Proxy contract
        mapping(uint24 => VoteProposal) voteProposalAttributes; //Storage of voting proposals
        mapping(uint24 => mapping(address => bool)) votingStatus; // Tracking whether address has voted for particular voteid
        mapping(uint24 => uint256) numTokenFor; //Number of tokens voted for the proposal
        mapping(uint24 => uint256) numTokenAgainst; //Number of tokens voted against the proposal
        mapping (uint => uint) indexBook; //Keeping track of indexes 
        mapping(uint => address) addressBook; //To keep Addresses inside
        mapping(address => uint) subAccountIndex;//To keep track of subAccounts
        mapping(bytes32 => uint256) signedMessages;
        mapping(address => mapping(bytes32 => uint256)) approvedHashes;
    }

    function VoteTrackingStorage()
        internal
        pure
        returns (VoteTracking storage vt)
    {
        bytes32 position = VT_STORAGE_POSITION;
        assembly {
            vt.slot := position
        }
    }

    error ALREADY_VOTED();

    function enforceNotVoted(uint24 _voteid, address msgSender_) internal view {
        if (VoteTrackingStorage().votingStatus[_voteid][msgSender_] == true) {
            revert ALREADY_VOTED();
        }
    }

    error VOTE_IS_CLOSED();

    function enforceProposedStatus(uint24 _voteid) internal view {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteStatus !=
            1
        ) {
            revert VOTE_IS_CLOSED();
        }
    }

    error VOTE_IS_NOT_PASSED();

    function enforceAcceptedStatus(uint24 _voteid) internal view {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteStatus !=
            2 &&
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteStatus !=
            7
        ) {
            revert VOTE_IS_NOT_PASSED();
        }
    }

    error VOTE_PROPOSER_ONLY();

    function enforceOnlyProposer(uint24 _voteid, address msgSender_)
        internal
        view
    {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].proposer !=
            msgSender_
        ) {
            revert VOTE_PROPOSER_ONLY();
        }
    }

    error DEADLINE_NOT_PASSED();

    function enforceDeadlinePassed(uint24 _voteid) internal view {
        if (
            VoteTrackingStorage().voteProposalAttributes[_voteid].voteends >
            block.timestamp
        ) {
            revert DEADLINE_NOT_PASSED();
        }
    }

    /* Enum Statuses of the Marriage*/
    enum MarriageStatus {
        Proposed,
        Declined,
        Cancelled,
        Married,
        Divorced
    }

    /* Listening to whether ETH has been received/sent from the contract*/
    event AddStake(
        address indexed from,
        address indexed to,
        uint256 timestamp,
        uint256 amount
    );

    error USER_HAS_NO_ACCESS(address user);

    function enforceUserHasAccess(address msgSender_) internal view {
        if (VoteTrackingStorage().hasAccess[msgSender_] != true) {
            revert USER_HAS_NO_ACCESS(msgSender_);
        }
    }

    error USER_IS_NOT_PARTNER(address user);

    function enforceOnlyPartners(address msgSender_) internal view {
       
        if (
            VoteTrackingStorage().proposed != msgSender_ &&
            VoteTrackingStorage().proposer != msgSender_
        ) {
            revert USER_IS_NOT_PARTNER(msgSender_);
        } 
    }

    error CANNOT_USE_PARTNERS_ADDRESS();

    function enforceNotPartnerAddr(address _member) internal view {
        if (
            VoteTrackingStorage().proposed == _member &&
            VoteTrackingStorage().proposer == _member
        ) {
            revert CANNOT_USE_PARTNERS_ADDRESS();
        }
    }

    error CANNOT_PERFORM_WHEN_PARTNERSHIP_IS_ACTIVE();

    function enforceNotYetMarried() internal view {
        if (
            VoteTrackingStorage().marriageStatus != MarriageStatus.Proposed &&
            VoteTrackingStorage().marriageStatus != MarriageStatus.Declined && 
            VoteTrackingStorage().marriageStatus != MarriageStatus.Cancelled 
        ) {
            revert CANNOT_PERFORM_WHEN_PARTNERSHIP_IS_ACTIVE();
        }
    }

    error PARNERSHIP_IS_NOT_ESTABLISHED();

    function enforceMarried() internal view {
        if (VoteTrackingStorage().marriageStatus != MarriageStatus.Married) {
            revert PARNERSHIP_IS_NOT_ESTABLISHED();
        }
    }

    error PARNERSHIP_IS_DISSOLUTED();

    function enforceNotDivorced() internal view {
        if (VoteTrackingStorage().marriageStatus == MarriageStatus.Divorced) {
            revert PARNERSHIP_IS_DISSOLUTED();
        }
    }

    error PARTNERSHIP_IS_NOT_DISSOLUTED();

    function enforceDivorced() internal view {
        if (VoteTrackingStorage().marriageStatus != MarriageStatus.Divorced) {
            revert PARTNERSHIP_IS_NOT_DISSOLUTED();
        }
    }

    error CONTRACT_NOT_AUTHORIZED(address contractAddress);

    function enforceContractHasAccess() internal view {
        if (msg.sender != VoteTrackingStorage().addressWaveContract) {
            revert CONTRACT_NOT_AUTHORIZED(msg.sender);
        }
    }

    error COULD_NOT_PROCESS(address _to, uint256 amount);

    /**
     * @notice Internal function to process payments.
     * @dev call method is used to keep process gas limit higher than 2300. Amount of 0 will be skipped,
     * @param _to Address that will be reveiving payment
     * @param _amount the amount of payment
     */

    function processtxn(address payable _to, uint256 _amount) internal {
        if (_amount > 0) {
            (bool success, ) = _to.call{value: _amount}("");
            if (!success) {
                revert COULD_NOT_PROCESS(_to, _amount);
            }
            emit AddStake(address(this), _to, block.timestamp, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard
interface WaverContractCheck {
    function whiteListedAddresses(address _contract) external view returns (uint);
}

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }
    //event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);
    struct DiamondStorage {
        address waveAddress;
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        mapping(address => bool) connectedApps;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    error DIAMOND_ACTION_NOT_FOUND();
     // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            DiamondStorage storage ds = diamondStorage();
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
                ds.connectedApps[_diamondCut[facetIndex].facetAddress] = true;
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                ds.connectedApps[ds.facetAddressAndSelectorPosition[_diamondCut[facetIndex].functionSelectors[0]].facetAddress] = false;
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert DIAMOND_ACTION_NOT_FOUND();
            }
        }
        //emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }
    error FUNCTION_SELECTORS_CANNOT_BE_EMPTY();
    error FACET_ADDRESS_CANNOT_BE_EMPTY();
    error FACET_ALREADY_EXISTS();
    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {revert FUNCTION_SELECTORS_CANNOT_BE_EMPTY();}
        enforceContractIsWhitelisted(_facetAddress);
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        if (_facetAddress == address(0)) {revert FACET_ADDRESS_CANNOT_BE_EMPTY();}
        enforceHasContractCode(_facetAddress,"");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) {revert FACET_ALREADY_EXISTS();}
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {revert FUNCTION_SELECTORS_CANNOT_BE_EMPTY();}
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {revert FACET_ALREADY_EXISTS();}
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {revert FACET_ADDRESS_CANNOT_BE_EMPTY();}
            // can't remove immutable functions -- functions defined directly in the diamond
            require(oldFacetAddressAndSelectorPosition.facetAddress != address(this));
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0);
        } else {
            require(_calldata.length > 0);
            if (_init != address(this)) {
                enforceHasContractCode(_init,"");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert();
                }
            }
        }
    }

    error CONTRACT_NOT_WHITELISTED(address contractAddress);

    function enforceContractIsWhitelisted(address contractAddress) internal view {
        DiamondStorage storage ds = diamondStorage();
        WaverContractCheck _wavercContract = WaverContractCheck(ds.waveAddress);
        if (_wavercContract.whiteListedAddresses(contractAddress) == 0) {
            revert CONTRACT_NOT_WHITELISTED(contractAddress);
        }
    }
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}