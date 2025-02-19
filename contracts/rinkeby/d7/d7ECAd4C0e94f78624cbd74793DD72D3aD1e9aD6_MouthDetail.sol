// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import "base64-sol/base64.sol";

/// @title Mouth SVG generator
library MouthDetail {
    /// @dev Mouth N°1 => Neutral
    function item_1() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path d="M177.1,251.1c3.6-0.2,7.4-0.1,11,0s7.4,0.3,10.9,0.9c-3.6,0.3-7.4,0.3-11,0.2C184.4,252.1,180.7,251.8,177.1,251.1z" /></g><g display="inline" ><path d="M203.5,251.9c10.1-0.7,19.1,0.1,29.2-1.3C222.6,253.7,213.9,252.6,203.5,251.9z" /></g><g display="inline" ><path d="M196.7,261.5c0.9,0.5,2.1,0.9,2.9,1.1c0.8,0.2,2.1,0.4,2.9,0.5c0.8,0.1,2.1,0,3.1-0.1s2.1-0.5,3.1-0.9c-0.8,0.8-1.9,1.5-2.8,1.9c-1.1,0.3-2.3,0.5-3.3,0.4c-1.1-0.1-2.3-0.3-3.2-0.9C198.5,263.1,197.4,262.5,196.7,261.5z" /></g>',
                "Neutral"
            );
    }

    /// @dev Mouth N°2 => Canine
    function item_2() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><polyline  fill="#FFFFFF" points="222.4,251.9 225.5,260.1 230,251.7 " /><path d="M222.4,251.9c0.6,1.4,1.1,2.6,1.8,4c0.5,1.4,1,2.7,1.6,4h-0.4c0.3-0.7,0.7-1.4,1.1-2.1l1.1-2.1c0.8-1.4,1.6-2.7,2.4-4.1c-0.6,1.5-1.4,2.9-2.1,4.3l-1,2.1c-0.4,0.7-0.7,1.5-1.1,2.1l-0.3,0.5l-0.2-0.5c-0.5-1.4-1-2.7-1.5-4.1C223.3,254.7,222.8,253.3,222.4,251.9z" /></g><g display="inline" ><polyline  fill="#FFFFFF" points="187.3,252 184,259.7 180,251.5 " /><path d="M187.3,252c-0.4,1.4-0.9,2.7-1.5,4c-0.5,1.4-1,2.6-1.6,4l-0.2,0.5l-0.3-0.5c-0.3-0.6-0.6-1.4-1-2.1l-1-2.1c-0.6-1.4-1.3-2.7-1.9-4.2c0.8,1.4,1.5,2.6,2.2,4l1,2c0.3,0.7,0.7,1.4,1,2.1h-0.4c0.5-1.3,1-2.6,1.7-3.9C186.2,254.5,186.7,253.2,187.3,252z" /></g><path display="inline"  d="M174.6,251c0,0,24.6,3.4,60.2,0.5"  /><g display="inline" ><path d="M195.8,256.6c1.1,0.3,2.4,0.5,3.5,0.6c1.3,0.1,2.4,0.2,3.6,0.2s2.4-0.1,3.6-0.2s2.4-0.2,3.6-0.4c-0.6,0.2-1.1,0.4-1.8,0.6c-0.6,0.1-1.3,0.3-1.8,0.4c-1.3,0.2-2.5,0.3-3.8,0.3s-2.5-0.1-3.8-0.3C197.9,257.6,196.8,257.2,195.8,256.6z" /></g>',
                "Canine"
            );
    }

    /// @dev Mouth N°3 => Canine up
    function item_3() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><polyline  fill="#FFFFFF" points="219.5,252.5 222.7,244.3 227.4,252.8 " /><path d="M219.5,252.5c0.6-1.4,1.1-2.6,1.9-4c0.5-1.4,1-2.7,1.7-4h-0.4c0.3,0.7,0.7,1.4,1.1,2.1l1.1,2.1c0.8,1.4,1.7,2.7,2.5,4.1c-0.6-1.5-1.5-2.9-2.2-4.3l-1-2.1c-0.4-0.7-0.7-1.5-1.1-2.1l-0.3-0.5l-0.2,0.5c-0.5,1.4-1,2.7-1.6,4.1C220.3,249.6,219.9,251,219.5,252.5z" /></g><g display="inline" ><polyline  fill="#FFFFFF" points="185,252.4 181.8,244.5 177.4,252.7 " /><path d="M185,252.4c-0.4-1.4-0.9-2.7-1.5-4c-0.5-1.4-1-2.6-1.6-4l-0.2-0.5l-0.3,0.5c-0.3,0.6-0.6,1.4-1.1,2.1l-1.1,2.1c-0.6,1.4-1.4,2.7-2,4.2c0.8-1.4,1.6-2.6,2.3-4l1.1-2c0.3-0.7,0.7-1.4,1.1-2.1h-0.4c0.5,1.3,1,2.6,1.7,3.9C183.9,249.9,184.4,251.1,185,252.4z" /></g><path display="inline"  d="M171.9,252.3c0,0,25.6,3.2,62.8,0"  /><g display="inline" ><path d="M194.1,257.7c1.1,0.3,2.5,0.5,3.6,0.6c1.4,0.1,2.5,0.2,3.9,0.2s2.5-0.1,3.9-0.2s2.5-0.2,3.9-0.4c-0.6,0.2-1.1,0.4-1.9,0.6c-0.6,0.1-1.4,0.3-1.9,0.4c-1.4,0.2-2.6,0.3-4,0.3s-2.6-0.1-4-0.3C196.4,258.7,195.2,258.3,194.1,257.7z" /></g>',
                "Canine up"
            );
    }

    /// @dev Mouth N°4 => Poker
    function item_4() public pure returns (string memory) {
        return
            base(
                '<g id="Poker" ><path d="M174.5,253.4c2.7-0.4,5.4-0.6,8-0.7c2.7-0.1,5.4-0.2,8-0.1c2.7,0.1,5.4,0.4,8,0.5c2.7,0.1,5.4,0,8-0.2c2.7-0.2,5.4-0.3,8-0.4c2.7-0.1,5.4-0.2,8-0.1c5.4,0.1,10.7,0.3,16.1,1c0.1,0,0.1,0.1,0.1,0.1c0,0,0,0.1-0.1,0.1c-5.4,0.6-10.7,0.9-16.1,1c-2.7,0-5.4-0.1-8-0.1c-2.7,0-5.4-0.2-8-0.4c-2.7-0.2-5.4-0.3-8-0.2c-2.7,0.1-5.4,0.4-8,0.5c-2.7,0.1-5.4,0.1-8-0.1c-2.7-0.1-5.4-0.3-8-0.7C174.4,253.6,174.4,253.5,174.5,253.4C174.4,253.4,174.5,253.4,174.5,253.4z" /></g>',
                "Poker"
            );
    }

    /// @dev Mouth N°5 => Angry
    function item_5() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path fill="#FFFFFF" d="M211.5,246.9c-7.9,1.5-19.6,0.3-23.8-0.9c-4.5-1.3-8.6,3.2-9.7,7.5c-0.5,2.6-1.4,7.7,3.9,10.5c6.7,2.5,6.4,0.1,10.4-2c3.9-2.1,11.3-1.1,17.3,2c6.1,3.1,15.1,2.3,20.2-0.4c3.2-1.8,3.8-7.9-4.8-14.7C222.5,247,220.4,245.2,211.5,246.9" /><path d="M211.5,247c-4.1,1-8.3,1.2-12.4,1.2c-2.1,0-4.2-0.2-6.3-0.4c-1-0.1-2.1-0.3-3.1-0.4c-0.5-0.1-1-0.2-1.6-0.3c-0.3-0.1-0.6-0.1-0.8-0.2c-0.2,0-0.4-0.1-0.6-0.1c-1.7-0.2-3.5,0.6-4.9,1.9c-1.4,1.3-2.5,3-3.1,4.8c-0.5,1.9-0.8,4-0.3,5.8c0.2,0.9,0.7,1.8,1.3,2.6c0.6,0.7,1.4,1.4,2.3,1.9l0,0c1.6,0.6,3.2,1.2,4.9,1c1.6-0.1,2.8-1.6,4.3-2.5c1.4-1,3.2-1.6,5-1.8c1.8-0.2,3.5-0.1,5.3,0.1c1.7,0.2,3.5,0.7,5.1,1.2c0.8,0.3,1.7,0.6,2.5,1s1.6,0.7,2.3,1c3,1.1,6.4,1.4,9.7,1.1c1.6-0.2,3.3-0.4,4.9-0.9c0.8-0.2,1.6-0.5,2.3-0.8c0.4-0.1,0.7-0.3,1.1-0.5l0.4-0.3c0.1-0.1,0.2-0.2,0.4-0.3c0.9-0.9,1.1-2.4,0.8-3.9s-1.1-2.9-2-4.3c-0.9-1.3-2.1-2.5-3.3-3.7c-0.6-0.6-1.3-1.1-1.9-1.6c-0.7-0.5-1.3-0.9-2.1-1.2c-1.5-0.6-3.2-0.8-4.9-0.8C214.9,246.6,213.2,246.8,211.5,247c-0.1,0-0.1,0-0.1-0.1s0-0.1,0.1-0.1c1.7-0.4,3.4-0.8,5.1-0.9c1.7-0.2,3.5-0.1,5.3,0.5c0.9,0.3,1.7,0.7,2.4,1.2s1.4,1,2.1,1.6c1.4,1.1,2.7,2.3,3.8,3.7s2.1,3,2.5,4.9c0.5,1.8,0.3,4.1-1.2,5.8c-0.2,0.2-0.4,0.4-0.6,0.6c-0.2,0.2-0.5,0.3-0.7,0.5c-0.4,0.2-0.8,0.4-1.2,0.6c-0.8,0.4-1.7,0.7-2.6,0.9c-1.7,0.5-3.5,0.8-5.3,0.9c-3.5,0.2-7.2-0.1-10.5-1.5c-0.8-0.4-1.7-0.8-2.4-1.1c-0.7-0.4-1.5-0.7-2.3-1c-1.6-0.6-3.2-1.1-4.8-1.4s-3.3-0.5-5-0.4s-3.2,0.5-4.7,1.4c-0.7,0.4-1.4,0.9-2.1,1.4c-0.7,0.5-1.6,1-2.5,1c-0.9,0.1-1.8-0.1-2.7-0.3c-0.9-0.2-1.7-0.5-2.5-0.8l0,0l0,0c-0.9-0.5-1.8-1.1-2.6-1.9c-0.7-0.8-1.3-1.8-1.7-2.8c-0.7-2.1-0.5-4.3-0.1-6.5c0.5-2.2,1.6-4.1,3.2-5.7c0.8-0.8,1.7-1.5,2.8-1.9c1.1-0.5,2.3-0.7,3.5-0.5c0.3,0,0.6,0.1,0.9,0.2c0.3,0.1,0.5,0.1,0.7,0.2c0.5,0.1,1,0.2,1.5,0.3c1,0.2,2,0.4,3,0.5c2,0.3,4.1,0.5,6.1,0.7c4.1,0.3,8.2,0.4,12.3,0c0.1,0,0.1,0,0.1,0.1C211.6,246.9,211.6,247,211.5,247z" /></g><g display="inline" ><path fill="#FFFFFF" d="M209.7,255.6l4.6-2.3c0,0,4.2,3,5.6,3.1s5.5-3.3,5.5-3.3l4.4,1.5" /><path d="M209.7,255.5c0.6-0.7,1.3-1.2,2-1.7s1.5-0.9,2.2-1.3l0.5-0.2l0.4,0.3c0.8,0.7,1.5,1.6,2.4,2.2c0.4,0.3,0.9,0.6,1.4,0.8s1.1,0.3,1.4,0.3c0.2-0.1,0.7-0.4,1.1-0.7c0.4-0.3,0.8-0.6,1.2-0.9c0.8-0.6,1.6-1.3,2.5-1.9l0.5-0.4l0.4,0.2c0.7,0.3,1.4,0.7,2.1,1c0.7,0.4,1.4,0.8,2,1.3c0,0,0.1,0.1,0,0.1h-0.1c-0.8,0-1.6-0.1-2.4-0.2c-0.8-0.1-1.5-0.3-2.3-0.5l1-0.2c-0.8,0.8-1.7,1.4-2.7,2c-0.5,0.3-1,0.6-1.5,0.8c-0.6,0.2-1.1,0.4-1.9,0.4c-0.8-0.2-1.1-0.6-1.6-0.8c-0.5-0.3-0.9-0.6-1.4-0.8c-1-0.5-2.1-0.7-3-1.3l0.9,0.1c-0.7,0.4-1.5,0.7-2.4,1c-0.8,0.3-1.7,0.5-2.6,0.6C209.7,255.7,209.6,255.6,209.7,255.5C209.6,255.6,209.6,255.5,209.7,255.5z" /></g><g display="inline" ><polyline fill="#FFFFFF" points="177.9,255.4 180.5,253.4 184.2,255.6 187.1,255.5 " /><path d="M177.8,255.3c0.1-0.4,0.2-0.6,0.3-0.9c0.2-0.3,0.3-0.5,0.5-0.7s0.4-0.4,0.6-0.5c0.2-0.1,0.6-0.2,0.8-0.2l0.6-0.1l0.1,0.1c0.2,0.3,0.5,0.6,0.8,0.8s0.7,0.2,1.1,0.3c0.4,0,0.7,0.1,1.1,0.3c0.3,0.1,0.7,0.3,1,0.4l-0.6-0.2c0.5,0,1,0.1,1.5,0.2c0.2,0.1,0.5,0.2,0.7,0.3s0.5,0.2,0.7,0.4c0.1,0,0.1,0.1,0,0.2l0,0c-0.2,0.2-0.5,0.3-0.7,0.5c-0.2,0.1-0.5,0.2-0.7,0.3c-0.5,0.2-1,0.3-1.4,0.3h-0.3l-0.3-0.2c-0.3-0.2-0.6-0.4-0.9-0.7c-0.3-0.2-0.5-0.5-0.8-0.8c-0.2-0.3-0.5-0.6-0.8-0.8s-0.6-0.3-1-0.3h0.6c-0.1,0.3-0.3,0.6-0.5,0.8s-0.4,0.3-0.7,0.5c-0.2,0.1-0.5,0.2-0.8,0.3s-0.6,0.1-1,0.1C177.9,255.5,177.8,255.4,177.8,255.3L177.8,255.3z" /></g>',
                "Angry"
            );
    }

    /// @dev Mouth N°6 => Sulk
    function item_6() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="none" stroke="#000000" stroke-width="2" stroke-miterlimit="10" d="M178.5,252.7c0,0,27.4,3.6,48.5,0.1"  /><g display="inline" ><path d="M175.6,245.9c0.9,0.7,1.8,1.6,2.4,2.6c0.6,1,1.1,2.2,1.1,3.4c0,0.3,0,0.6-0.1,0.9l-0.2,0.9c-0.3,0.5-0.5,1.1-1,1.6c-0.4,0.5-0.9,0.8-1.5,1.1c-0.5,0.3-1,0.5-1.7,0.7c0.4-0.4,0.9-0.7,1.4-1.1c0.4-0.4,0.8-0.7,1-1.3c0.6-0.8,1-1.9,0.9-2.9c0-1-0.3-2.1-0.8-3.1C176.9,247.9,176.4,247,175.6,245.9z" /></g><g display="inline" ><path d="M230.5,246.9c-0.6,0.9-1.3,2-1.7,3s-0.7,2.1-0.7,3.1s0.3,2.1,1,2.9c0.3,0.5,0.7,0.8,1.1,1.3c0.4,0.4,0.9,0.7,1.4,1.1c-0.5-0.2-1.1-0.4-1.7-0.7s-1-0.6-1.5-1.1c-0.5-0.4-0.7-1-1-1.6l-0.2-0.9c-0.1-0.3-0.1-0.6-0.1-0.9c0-1.3,0.4-2.5,1.1-3.5C228.7,248.5,229.5,247.6,230.5,246.9z" /></g>',
                "Sulk"
            );
    }

    /// @dev Mouth N°7 => Tongue
    function item_7() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#FF155D" d="M208.3,255.3c0,0,4.3,11.7,13.4,10.2c12.2-1.9,6.8-12.3,6.8-12.3L208.3,255.3z"  /><line display="inline" fill="none" stroke="#73093E" stroke-miterlimit="10" x1="219.3" y1="254.7" x2="221.2" y2="259.7"  /><path display="inline" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M203.4,255.6c0,0,22.3,0.1,29.7-4.5"  /><path display="inline" fill="none" stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M177.9,251.6c0,0,10.6,4.4,21.3,4.1"  />',
                "Tongue"
            );
    }

    /// @dev Mouth N°8 => None
    function item_8() public pure returns (string memory) {
        return base("", "None");
    }

    /// @dev Mouth N°9 => Fantom
    function item_9() public pure returns (string memory) {
        return
            base(
                '<path d="M220.3,255.4l-4.9,7.8c-.4.6-.9.6-1.3,0l-4.8-7.8a2.56,2.56,0,0,1,0-2.1l4.9-7.8c.4-.6.9-.6,1.3,0l4.8,7.8A2,2,0,0,1,220.3,255.4Zm-11.9-.1-4.9,7.8c-.4.6-.9.6-1.3,0l-4.8-7.8a2.56,2.56,0,0,1,0-2.1l4.9-7.8c.4-.6.9-.6,1.3,0l4.8,7.8A2,2,0,0,1,208.4,255.3Zm-12.3-.1-4.9,7.8c-.4.6-.9.6-1.3,0l-4.8-7.8a2.56,2.56,0,0,1,0-2.1l4.9-7.8c.4-.6.9-.6,1.3,0l4.8,7.8A2,2,0,0,1,196.1,255.2Z" transform="translate(0 0.5)" fill="none" stroke="#000" stroke-width="2"/> <path d="M190.8,244.8l23.9.2m-24,18.6,23.9.2m-17.1-9.6,11.2.1" transform="translate(0 0.5)" fill="none" stroke="#000" stroke-linecap="square" stroke-width="2"/>',
                "Fantom"
            );
    }

    /// @dev Mouth N°10 => Evil
    function item_10() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path fill="#FFFFFF" d="M177.3,250.9c0,0,16.5-1.1,17.8-1.6c1.4-0.4,35.2,6.6,37.2,5.7c2.1-0.8,4.7-2,4.7-2s-14.4,8.3-44.5,8.2c0,0-4-0.7-4.8-1.9C186.8,258.3,179.7,251.4,177.3,250.9z" /><path d="M177.2,250.9c0.3-0.1,0.4-0.1,0.6-0.1l0.6-0.1l1.1-0.1l2.2-0.3l4.4-0.5l4.4-0.5l2.2-0.3l1.1-0.2c0.4-0.1,0.7-0.1,1-0.2h0.1c0.5-0.1,0.6,0,0.9,0l0.7,0.1l1.3,0.2l2.7,0.4c1.8,0.3,3.5,0.6,5.3,0.9c3.5,0.7,7,1.4,10.5,2.1c3.5,0.7,7,1.4,10.5,1.9c0.9,0.1,1.8,0.2,2.6,0.3c0.9,0.1,1.8,0.2,2.6,0.1c0.1,0,0.4-0.1,0.6-0.2l0.6-0.3l1.2-0.5l2.4-1.1l0.3,0.7c-3.4,1.9-7,3.2-10.7,4.3s-7.4,1.9-11.2,2.6l-2.8,0.5c-0.9,0.1-1.9,0.2-2.8,0.4c-1.9,0.3-3.8,0.4-5.7,0.5s-3.8,0.2-5.7,0.3h-5.7h-0.1l0,0c-0.9-0.2-1.8-0.4-2.6-0.7c-0.4-0.2-0.9-0.3-1.3-0.5c-0.4-0.2-0.9-0.5-1.2-1v0.1c-0.7-0.8-1.5-1.6-2.3-2.4s-1.6-1.6-2.4-2.3c-0.8-0.8-1.6-1.5-2.5-2.2c-0.4-0.4-0.9-0.7-1.3-1C178.3,251.4,177.8,251.2,177.2,250.9z M177.4,250.9c0.3,0,0.5,0,0.8,0.2c0.3,0.1,0.5,0.2,0.8,0.4c0.5,0.3,1,0.6,1.4,0.9c0.9,0.6,1.8,1.3,2.7,2s1.7,1.4,2.6,2.2c0.8,0.8,1.7,1.5,2.5,2.3v0.1c0.1,0.2,0.5,0.4,0.8,0.6c0.4,0.2,0.8,0.3,1.2,0.4c0.8,0.2,1.6,0.4,2.5,0.6h-0.1l5.7-0.2c1.9-0.1,3.8-0.2,5.7-0.4c3.8-0.3,7.5-0.7,11.3-1.3c3.7-0.6,7.4-1.3,11.1-2.3c1.8-0.5,3.6-1,5.4-1.6c1.8-0.6,3.6-1.3,5.2-2.1l0.3,0.7l-2.5,1l-1.2,0.5l-0.6,0.3c-0.2,0.1-0.4,0.2-0.7,0.2c-1,0.1-1.8-0.1-2.7-0.2c-0.9-0.1-1.8-0.2-2.7-0.4l-10.6-1.6c-3.5-0.5-7.1-1-10.6-1.6l-5.3-0.9l-2.6-0.4l-1.3-0.2l-0.6-0.1c-0.2,0-0.5,0-0.4,0h0.1c-0.5,0.1-0.9,0.2-1.2,0.2l-1.1,0.1c-0.7,0.1-1.5,0.1-2.2,0.2l-4.5,0.3c-1.5,0.1-3,0.2-4.5,0.2l-2.2,0.1h-1.1h-0.6C177.7,250.9,177.5,251,177.4,250.9z" /></g><g display="inline" ><path d="M184.2,256.2c0.5-0.5,1.2-0.9,1.8-1.1c0.3-0.1,0.7-0.1,1.1-0.2c0.4,0,0.7-0.2,1-0.3l0,0h0.1c0.3,0.1,0.7,0.1,1,0.1s0.7,0.1,1,0.2c0.7,0.1,1.3,0.4,1.9,0.7h-0.3c0.4-0.1,0.8-0.2,1.3-0.3v0.1c-0.3,0.4-0.6,0.6-0.9,0.9l-0.1,0.1h-0.2c-0.7-0.1-1.3-0.2-1.9-0.5c-0.3-0.1-0.6-0.2-0.9-0.4c-0.3-0.2-0.6-0.3-0.9-0.5h0.1c-0.3,0.1-0.7,0.2-1,0.4s-0.6,0.4-0.9,0.6C185.7,256.1,185,256.3,184.2,256.2L184.2,256.2z" /></g><g display="inline" ><path d="M201.3,256.5c1.3-0.4,2.7-0.6,4-0.8s2.7-0.4,4.1-0.4h0.1h0.1c1.1,0.6,2.2,1.3,3.3,1.8h-0.1c1.5-0.5,2.9-1.2,4.3-1.7h0.1l0.2,0.1c1.1,0.4,2.1,0.8,3.1,1.2h-0.2c1.5-0.1,3-0.2,4.5-0.2s3,0,4.5,0.1v0.1c-1.5,0.3-2.9,0.5-4.4,0.6c-1.5,0.2-3,0.3-4.4,0.3h-0.1h-0.1c-1-0.5-2-0.9-3.1-1.4h0.3c-1.5,0.4-3,0.8-4.5,1.3h-0.1h-0.1c-1.1-0.6-2.3-1-3.5-1.4h0.2c-1.3,0.3-2.7,0.4-4,0.5C204,256.6,202.7,256.6,201.3,256.5L201.3,256.5z" /></g>',
                "Evil"
            );
    }

    /// @dev Mouth N°11 => Monster
    function item_11() public pure returns (string memory) {
        return
            base(
                '<polyline display="inline" fill="none" stroke="#000000" stroke-width="0.5" stroke-linejoin="round" stroke-miterlimit="10" points="145.8,244.7 150,250.4 153.3,242.5 157.5,255 165.4,242.3 170.3,260.1 179.5,243 185.4,263.2 194.4,243.5 202.9,265.5 212.8,243.8 219.6,263.1 227.1,243.5 235.2,259.1 242.5,243 250.3,254.8 255.6,242.3 260.3,251.8 265.6,241.8 269.8,248.8 274.2,241 276.3,244.6 "  />',
                "Monster"
            );
    }

    /// @dev Mouth N°12 => Drool
    function item_12() public pure returns (string memory) {
        return
            base(
                '<path display="inline" stroke="#000000" stroke-width="0.5" stroke-miterlimit="10" d="M191.1,248c2.8,0.6,7.8,1.6,10.9,1.2l17.1-2.7c0,0,13.1-2.3,13.3,3.9c-1,6.3-2.3,10.5-5.5,11.2c0,0,3.7,10.8-3.2,10.2c-4.2-0.4-2.8-8.6-2.8-8.6s-19.9,5-40.1-1.9c-3.4-1.5-8.4-10-5.2-14.5C177.6,245.4,181.5,244.9,191.1,248z"  />',
                "Drool"
            );
    }

    /// @dev Mouth N°13 => UwU Kitsune
    function item_13() public pure returns (string memory) {
        return
            base(
                '<polyline display="inline" fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" points="217.9,254.7 221.2,259.6 224.3,251.9 "  /><g display="inline" ><path d="M178,246.5c1.4,2,3,3.8,4.8,5.3c0.5,0.4,0.9,0.8,1.4,1.1l0.8,0.5c0.3,0.2,0.5,0.3,0.8,0.4c1.1,0.5,2.3,0.7,3.5,0.8c2.4,0.1,4.8-0.4,7.1-0.9l3.5-1.1c1.1-0.5,2.3-0.9,3.4-1.3c0,0,0.1,0,0.1,0c0,0,0,0,0,0.1c-1,0.7-2.1,1.3-3.2,1.9c-1.1,0.5-2.3,1-3.5,1.4c-0.6,0.1-1.2,0.3-1.8,0.4l-0.9,0.2l-0.9,0.1c-0.6,0-1.3,0.1-1.9,0.1c-0.6-0.1-1.3-0.2-1.9-0.2c-0.6-0.1-1.2-0.3-1.8-0.4c-0.6-0.1-1.2-0.4-1.8-0.6c-0.6-0.2-1.2-0.4-1.7-0.7c-0.6-0.2-1.1-0.6-1.7-0.9C180.3,251.1,178.7,249,178,246.5C177.9,246.6,177.9,246.5,178,246.5C178,246.5,178,246.5,178,246.5L178,246.5z" /></g><g display="inline" ><path d="M231.1,245.2c-1.2,2.4-3.1,4.5-5.2,6.1c-1.1,0.8-2.3,1.4-3.6,1.9c-1.2,0.6-2.5,1.1-3.7,1.5c-2.6,0.8-5.4,0.9-8.1,0.2c-2.6-0.7-5.1-1.9-7.2-3.6c0,0,0,0,0-0.1c0,0,0,0,0.1,0c2.4,1.1,4.9,2.1,7.4,2.7c2.5,0.6,5.1,0.7,7.7,0.3c1.3-0.2,2.6-0.6,3.7-1.2c1.2-0.6,2.2-1.4,3.2-2.3C227.4,248.9,229.3,247.1,231.1,245.2C231.1,245.1,231.1,245.1,231.1,245.2C231.1,245.1,231.1,245.2,231.1,245.2z" /></g>',
                "UwU Kitsune"
            );
    }

    /// @dev Mouth N°14 => Stitch
    function item_14() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path d="M146.7,249c10.6,1.8,21.4,2.9,32.1,3.9c2.7,0.2,5.3,0.5,8,0.7s5.4,0.3,8,0.5c5.4,0.2,10.7,0.2,16.2,0.1c5.4-0.1,10.7-0.5,16.2-0.7l8-0.6c1.4-0.1,2.7-0.2,4.1-0.3l4-0.4c10.7-1,21.3-2.9,31.9-4.8v0.1l-7.9,1.9l-4,0.8c-1.4,0.3-2.6,0.5-4,0.7l-8,1.4c-2.7,0.4-5.3,0.6-8,1c-5.3,0.7-10.7,0.9-16.2,1.4c-5.4,0.2-10.7,0.4-16.2,0.3c-10.7-0.1-21.6-0.3-32.3-0.9C167.9,252.9,157.1,251.5,146.7,249L146.7,249z" /></g><path display="inline" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M192.9,254.2c0,0,7.8-2.1,17.5,0.2C210.4,254.4,201.6,257.3,192.9,254.2z"  /><g display="inline" ><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M215.2,250.7c0,0,1.1-3.4,2.8-1c0,0,0.5,5.3-0.7,9.9c0,0-1,2.2-1.6-0.6C215.2,256.2,216.3,255.9,215.2,250.7z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M223.3,250.9c0,0,1-3.1,2.5-0.9c0,0,0.5,4.7-0.6,8.9c0,0-0.9,1.9-1.4-0.5C223.3,255.8,224.2,255.5,223.3,250.9z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M229.7,250.8c0,0,0.9-2.7,2.2-0.8c0,0,0.4,4.1-0.5,7.7c0,0-0.8,1.7-1.1-0.4C229.7,255,230.6,254.8,229.7,250.8z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M235.2,250.5c0,0,0.8-2.4,2-0.7c0,0,0.4,3.6-0.5,6.9c0,0-0.7,1.5-1-0.4C235.4,254.3,236,254.1,235.2,250.5z" /></g><g display="inline" ><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M188.4,250.3c0,0-1.1-3.4-2.8-1c0,0-0.5,5.3,0.7,9.9c0,0,1,2.2,1.6-0.6S187.1,255.5,188.4,250.3z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M180.4,250.5c0,0-1-3.1-2.5-0.9c0,0-0.5,4.7,0.6,8.9c0,0,0.9,1.9,1.4-0.5C180.3,255.5,179.4,255,180.4,250.5z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M173.8,250.4c0,0-0.9-2.7-2.2-0.8c0,0-0.4,4.1,0.5,7.7c0,0,0.8,1.7,1.1-0.4C173.6,254.7,172.9,254.4,173.8,250.4z" /><path fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M168.2,250c0,0-0.8-2.4-2-0.7c0,0-0.4,3.6,0.5,6.9c0,0,0.7,1.5,1-0.4C168.2,253.9,167.5,253.7,168.2,250z" /></g>',
                "Stitch"
            );
    }

    /// @dev Mouth N°15 => Pantin
    function item_15() public pure returns (string memory) {
        return
            base(
                '<path display="inline"  d="M227.4,254h-46.7c-0.5,0-0.9-0.4-0.9-0.9v-2c0-0.5,0.4-0.9,0.9-0.9h46.7c0.5,0,0.9,0.4,0.9,0.9v2C228.2,253.7,228,254,227.4,254z"  /><path display="inline"  stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M180.4,251.1c-0.9,9.5-0.5,18.8,0.5,29.7"  /><path display="inline"  stroke="#000000" stroke-linecap="round" stroke-miterlimit="10" d="M227.7,251c0.5,10.5,0.1,22.5-0.7,35.3"  />',
                "Pantin"
            );
    }

    /// @dev Mouth N°16 => Akuma
    function item_16() public pure returns (string memory) {
        return
            base(
                '<path display="inline" d="M278,243.1c-8.1,1.5-18.1,4.2-26.3,5.5c-8.1,1.4-16.3,2.5-24.6,2.8l0.3-0.2l-5.6,10.9l-0.4,0.7l-0.4-0.7l-5.3-10.4l0.4,0.2c-4.8,0.3-9.6,0.6-14.4,0.5c-4.8,0-9.6-0.5-14.4-1.1l0.4-0.2l-5.7,11.3l-0.3,0.5l-0.3-0.5l-5.9-11.6l0.2,0.1l-7.6-0.6c-2.5-0.2-5.1-0.6-7.6-1.1c-1.3-0.2-2.5-0.5-3.8-0.8s-2.5-0.6-3.8-1c-2.4-0.7-4.9-1.5-7.3-2.4v-0.1c2.5,0.4,5,1,7.5,1.6c1.3,0.2,2.5,0.5,3.8,0.8l3.8,0.8c2.5,0.5,5,1.1,7.5,1.6s5,0.8,7.6,0.8h0.1l0.1,0.1l6.1,11.6h-0.5l5.5-11.3l0.1-0.2h0.3c4.8,0.5,9.5,1,14.3,1s9.6-0.2,14.4-0.5h0.3l0.1,0.2l5.3,10.4h-0.7l5.7-10.8l0.1-0.2h0.2c8.2-0.2,16.4-1.3,24.5-2.6c8-1.1,16.2-2.7,24.3-4L278,243.1z"  />',
                "Akuma"
            );
    }

    /// @dev Mouth N°17 => Monster Teeth
    function item_17() public pure returns (string memory) {
        return
            base(
                '<path display="inline" fill="#FFFFFF" stroke="#000000" stroke-width="0.75" stroke-miterlimit="10" d="M165.5,241.9c0,0,0.5,0.1,1.4,0.3c4.3,1.2,36.4,12.1,81.4-1c0.1,0.1-17.5,28.2-43.1,28.6C192.4,270.1,181.1,263.4,165.5,241.9z"  /><polyline display="inline" fill="none" stroke="#000000" stroke-width="0.75" stroke-linejoin="round" stroke-miterlimit="10" points="168.6,245.8 171.3,243.6 173.9,252.6 177.5,245.1 181.7,260.4 188.2,246.8 192.8,267.3 198.5,247.8 204,269.9 209,247.9 215.5,268.3 219.3,247.1 225.4,264 228.2,246 234,257.8 236.7,244.5 240.4,251.4 243.1,242.7 245.9,245.1 "  /><g display="inline" opacity="0.52" ><path d="M246.1,239.5c1.9-0.8,3.5-1.4,5.9-1.9l0.6-0.1l-0.2,0.6c-0.6,2.2-1.3,4.5-2.1,6.5c0.3-2.4,0.8-4.6,1.4-6.9l0.4,0.5C250.1,239,248.2,239.4,246.1,239.5z" /></g><g display="inline" opacity="0.52" ><path d="M168,240.4c-2-0.2-4-0.5-5.9-0.8l0.4-0.5c0.6,2.4,1.3,4.7,1.5,7.2c-0.9-2.2-1.6-4.6-2.2-7l-0.2-0.6l0.6,0.1C164.1,239,165.9,239.7,168,240.4z" /></g>',
                "Monster Teeth"
            );
    }

    /// @dev Mouth N°18 => Dubu
    function item_18() public pure returns (string memory) {
        return
            base(
                '<g display="inline" ><path d="M204,251.4c-2.2-1.2-4.5-2.1-6.9-2.6c-1.2-0.2-2.4-0.4-3.6-0.4c-1.1,0-2.4,0.2-3.1,0.7c-0.4,0.2-0.5,0.5-0.5,0.9s0.3,1,0.6,1.5c0.6,1,1.5,1.9,2.5,2.6c2,1.5,4.3,2.6,6.6,3.6l3.3,1.4l-3.7-0.3c-2.4-0.2-4.9-0.4-7.2-0.2c-0.6,0.1-1.1,0.2-1.5,0.4c-0.4,0.2-0.7,0.4-0.6,0.5c0,0.1,0,0.5,0.3,0.9s0.6,0.8,1,1.2c1.7,1.5,3.8,2.6,6,3.3c2.2,0.6,4.7,0.8,6.9-0.4h0.1v0.1c-0.9,0.9-2.1,1.5-3.4,1.7c-1.3,0.3-2.6,0.2-3.9,0c-2.6-0.4-5-1.5-7.1-3.2c-0.5-0.4-1-1-1.4-1.6s-0.8-1.5-0.6-2.6c0.1-0.5,0.5-1,0.8-1.3c0.2-0.2,0.4-0.3,0.5-0.4c0.2-0.1,0.4-0.2,0.6-0.3c0.7-0.3,1.4-0.4,2.1-0.4c2.7-0.2,5.1,0.3,7.5,0.9l-0.4,1.1l-1.6-1c-0.5-0.3-1.1-0.7-1.6-1l-1.6-1c-0.5-0.4-1.1-0.7-1.6-1.1c-1-0.7-2.1-1.5-3-2.5c-0.4-0.5-0.9-1.1-1.1-1.9c-0.1-0.4-0.1-0.9,0.1-1.3c0.2-0.4,0.4-0.8,0.8-1.1c1.3-1,2.8-1.1,4.1-1.2c1.4,0,2.7,0.2,3.9,0.6c2.5,0.8,4.9,2.1,6.6,4v0.1C204.1,251.4,204.1,251.4,204,251.4z" /></g>',
                "Dubu"
            );
    }

    /// @notice Return the skin name of the given id
    /// @param id The skin Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Neutral";
        } else if (id == 2) {
            name = "Canine";
        } else if (id == 3) {
            name = "Canine up";
        } else if (id == 4) {
            name = "Poker";
        } else if (id == 5) {
            name = "Angry";
        } else if (id == 6) {
            name = "Sulk";
        } else if (id == 7) {
            name = "Tongue";
        } else if (id == 8) {
            name = "None";
        } else if (id == 9) {
            name = "Fantom";
        } else if (id == 10) {
            name = "Evil";
        } else if (id == 11) {
            name = "Monster";
        } else if (id == 12) {
            name = "Drool";
        } else if (id == 13) {
            name = "UwU Kitsune";
        } else if (id == 14) {
            name = "Stitch";
        } else if (id == 15) {
            name = "Pantin";
        } else if (id == 16) {
            name = "Akuma";
        } else if (id == 17) {
            name = "Monster Teeth";
        } else if (id == 18) {
            name = "Dubu";
        }
    }

    /// @dev The base SVG for the body
    function base(string memory children, string memory name) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="mouth"><g id="', name, '">', children, "</g></g>"));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}