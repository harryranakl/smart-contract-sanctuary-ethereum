// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { GlobalState } from "../libraries/GlobalState.sol";

contract AdminPauseFacet {
    event Paused(address account);
    event Unpaused(address account);

    function paused() public view returns (bool) {
        return GlobalState.getState().paused;
    }

    function togglePause() public {
        GlobalState.requireCallerIsAdmin();
        if (GlobalState.togglePause()) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library GlobalState {
    // GLOBAL STORAGE //

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("globalstate.storage");

    struct state {
        address owner;
        mapping(address => bool) admins;

        bool paused;
    }

    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    // OWNERSHIP FACET // 

    function setOwner(address _newOwner) internal {
        // It is the responsibility of the facet calling
        // this function to follow ERC-173 standard
        getState().owner = _newOwner;
    }

    function owner() internal view returns (address contractOwner_) {
        contractOwner_ = getState().owner;
    }

    function isAdmin(address _addr) internal view returns (bool) {
        state storage ds = getState();
        return ds.owner == _addr || ds.admins[_addr];
    }

    function requireCallerIsAdmin() internal view {
        require(isAdmin(msg.sender), "LibDiamond: caller must be an admin");
    }

    function toggleAdmins(address[] calldata accounts) internal {
        state storage ds = getState();

        for (uint256 i; i < accounts.length; i++) {
            if (ds.admins[accounts[i]]) {
                delete ds.admins[accounts[i]];
            } else {
                ds.admins[accounts[i]] = true;
            }
        }
    }

    // ADMINPAUSE FACET //

    function paused() internal view returns (bool) {
        return getState().paused;
    }

    function togglePause() internal returns (bool) {
        bool priorStatus = getState().paused;
        getState().paused = !priorStatus;
        return !priorStatus;
    }

    function requireContractIsNotPaused() internal view {
        require(!getState().paused);
    }
}