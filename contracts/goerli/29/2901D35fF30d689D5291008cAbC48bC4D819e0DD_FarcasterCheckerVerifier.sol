//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@big-whale-labs/versioned-contract/contracts/Versioned.sol";

library Pairing {
  struct G1Point {
    uint256 X;
    uint256 Y;
  }
  // Encoding of field elements is: X[0] * z + X[1]
  struct G2Point {
    uint256[2] X;
    uint256[2] Y;
  }

  /// @return the generator of G1
  function P1() internal pure returns (G1Point memory) {
    return G1Point(1, 2);
  }

  /// @return the generator of G2
  function P2() internal pure returns (G2Point memory) {
    // Original code point
    return
      G2Point(
        [
          11559732032986387107991004021392285783925812861821192530917403151452391805634,
          10857046999023057135944570762232829481370756359578518086990519993285655852781
        ],
        [
          4082367875863433681332203403145435568316851327593401208105741076214120093531,
          8495653923123431417604973247489272438418190587263600148770280649306958101930
        ]
      );

    /*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
  }

  /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory r) {
    // The prime q in the base field F_q for G1
    uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
    return G1Point(p.X, q - (p.Y % q));
  }

  /// @return r the sum of two points of G1
  function addition(G1Point memory p1, G1Point memory p2)
    internal
    view
    returns (G1Point memory r)
  {
    uint256[4] memory input;
    input[0] = p1.X;
    input[1] = p1.Y;
    input[2] = p2.X;
    input[3] = p2.Y;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, "pairing-add-failed");
  }

  /// @return r the product of a point on G1 and a scalar, i.e.
  /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
  function scalar_mul(G1Point memory p, uint256 s)
    internal
    view
    returns (G1Point memory r)
  {
    uint256[3] memory input;
    input[0] = p.X;
    input[1] = p.Y;
    input[2] = s;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, "pairing-mul-failed");
  }

  /// @return the result of computing the pairing check
  /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
  /// return true.
  function pairing(G1Point[] memory p1, G2Point[] memory p2)
    internal
    view
    returns (bool)
  {
    require(p1.length == p2.length, "pairing-lengths-failed");
    uint256 elements = p1.length;
    uint256 inputSize = elements * 6;
    uint256[] memory input = new uint256[](inputSize);
    for (uint256 i = 0; i < elements; i++) {
      input[i * 6 + 0] = p1[i].X;
      input[i * 6 + 1] = p1[i].Y;
      input[i * 6 + 2] = p2[i].X[0];
      input[i * 6 + 3] = p2[i].X[1];
      input[i * 6 + 4] = p2[i].Y[0];
      input[i * 6 + 5] = p2[i].Y[1];
    }
    uint256[1] memory out;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(
        sub(gas(), 2000),
        8,
        add(input, 0x20),
        mul(inputSize, 0x20),
        out,
        0x20
      )
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, "pairing-opcode-failed");
    return out[0] != 0;
  }

  /// Convenience method for a pairing check for two pairs.
  function pairingProd2(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2
  ) internal view returns (bool) {
    G1Point[] memory p1 = new G1Point[](2);
    G2Point[] memory p2 = new G2Point[](2);
    p1[0] = a1;
    p1[1] = b1;
    p2[0] = a2;
    p2[1] = b2;
    return pairing(p1, p2);
  }

  /// Convenience method for a pairing check for three pairs.
  function pairingProd3(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2
  ) internal view returns (bool) {
    G1Point[] memory p1 = new G1Point[](3);
    G2Point[] memory p2 = new G2Point[](3);
    p1[0] = a1;
    p1[1] = b1;
    p1[2] = c1;
    p2[0] = a2;
    p2[1] = b2;
    p2[2] = c2;
    return pairing(p1, p2);
  }

  /// Convenience method for a pairing check for four pairs.
  function pairingProd4(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2,
    G1Point memory d1,
    G2Point memory d2
  ) internal view returns (bool) {
    G1Point[] memory p1 = new G1Point[](4);
    G2Point[] memory p2 = new G2Point[](4);
    p1[0] = a1;
    p1[1] = b1;
    p1[2] = c1;
    p1[3] = d1;
    p2[0] = a2;
    p2[1] = b2;
    p2[2] = c2;
    p2[3] = d2;
    return pairing(p1, p2);
  }
}

contract FarcasterCheckerVerifier is Versioned {
  constructor(string memory _version) Versioned(_version) {}

  using Pairing for *;
  struct VerifyingKey {
    Pairing.G1Point alfa1;
    Pairing.G2Point beta2;
    Pairing.G2Point gamma2;
    Pairing.G2Point delta2;
    Pairing.G1Point[] IC;
  }
  struct Proof {
    Pairing.G1Point A;
    Pairing.G2Point B;
    Pairing.G1Point C;
  }

  function verifyingKey() internal pure returns (VerifyingKey memory vk) {
    vk.alfa1 = Pairing.G1Point(
      20491192805390485299153009773594534940189261866228447918068658471970481763042,
      9383485363053290200918347156157836566562967994039712273449902621266178545958
    );

    vk.beta2 = Pairing.G2Point(
      [
        4252822878758300859123897981450591353533073413197771768651442665752259397132,
        6375614351688725206403948262868962793625744043794305715222011528459656738731
      ],
      [
        21847035105528745403288232691147584728191162732299865338377159692350059136679,
        10505242626370262277552901082094356697409835680220590971873171140371331206856
      ]
    );
    vk.gamma2 = Pairing.G2Point(
      [
        11559732032986387107991004021392285783925812861821192530917403151452391805634,
        10857046999023057135944570762232829481370756359578518086990519993285655852781
      ],
      [
        4082367875863433681332203403145435568316851327593401208105741076214120093531,
        8495653923123431417604973247489272438418190587263600148770280649306958101930
      ]
    );
    vk.delta2 = Pairing.G2Point(
      [
        12599857379517512478445603412764121041984228075771497593287716170335433683702,
        7912208710313447447762395792098481825752520616755888860068004689933335666613
      ],
      [
        11502426145685875357967720478366491326865907869902181704031346886834786027007,
        21679208693936337484429571887537508926366191105267550375038502782696042114705
      ]
    );
    vk.IC = new Pairing.G1Point[](12);

    vk.IC[0] = Pairing.G1Point(
      3285650613922991056854123343567668363934668471261490501630349949353364906875,
      18262678837335562037530994438848384421943739580592206223099035320701049714481
    );

    vk.IC[1] = Pairing.G1Point(
      3029693899169249500219296328987719690928668164143296448099670741323869915051,
      20696304855992256285250857891555636987697778243582344284388198822316267711334
    );

    vk.IC[2] = Pairing.G1Point(
      21121435205772427229852330606864955782672617735372877694022943078912145663916,
      7921766228416184350274482374119382402862784031843292508332885273911270888886
    );

    vk.IC[3] = Pairing.G1Point(
      20416004139604879894275605701575917201639645766417398356725757494303336014467,
      12249183587927331597295206123242119144047915565444543050311704096371039929048
    );

    vk.IC[4] = Pairing.G1Point(
      7968942414166988899703352861420931883035103112348708452596553796900795436109,
      7426318200033008702706274584997315653313466557836682464234703930707149653891
    );

    vk.IC[5] = Pairing.G1Point(
      18808876245525087172441424065442302941196662997506826998320106532233303988012,
      17761439124620836125296796422621800008489373180932777481799974398649600951300
    );

    vk.IC[6] = Pairing.G1Point(
      12691079137396118718234817994291022648552262647640427409760653218046733003806,
      9333881463191233394065542836986981268528063831601388873406487325073932878731
    );

    vk.IC[7] = Pairing.G1Point(
      1247846141245828402652085436991225356209146043942089096407877489722597786560,
      3948433394494060840617011864119914884905098885295751365822319921880703979421
    );

    vk.IC[8] = Pairing.G1Point(
      21539014104400612083289810029645118180218028053944061837728151500813594520213,
      16314724917306033348196560371945425826324118081719647710683183856787996858672
    );

    vk.IC[9] = Pairing.G1Point(
      20289047720879074802130530053642834771104043540121455520016063124563868585540,
      15109006404444680680212836560603143819390727594167922024840608497671499296292
    );

    vk.IC[10] = Pairing.G1Point(
      15778668343983588686078190773357431062843833873643308238844451271926945589389,
      12769819882585828379242057730463460897747886825792182800344799633762409494189
    );

    vk.IC[11] = Pairing.G1Point(
      14184068041994100388457868236887410089640253528884841061927910165200594655760,
      4238292305386934569365132807296549719095291068752113401002108822571072023835
    );
  }

  function verify(uint256[] memory input, Proof memory proof)
    internal
    view
    returns (uint256)
  {
    uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    VerifyingKey memory vk = verifyingKey();
    require(input.length + 1 == vk.IC.length, "verifier-bad-input");
    // Compute the linear combination vk_x
    Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
    for (uint256 i = 0; i < input.length; i++) {
      require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
      vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
    }
    vk_x = Pairing.addition(vk_x, vk.IC[0]);
    if (
      !Pairing.pairingProd4(
        Pairing.negate(proof.A),
        proof.B,
        vk.alfa1,
        vk.beta2,
        vk_x,
        vk.gamma2,
        proof.C,
        vk.delta2
      )
    ) return 1;
    return 0;
  }

  /// @return r  bool true if proof is valid
  function verifyProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256[11] memory input
  ) public view returns (bool r) {
    Proof memory proof;
    proof.A = Pairing.G1Point(a[0], a[1]);
    proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
    proof.C = Pairing.G1Point(c[0], c[1]);
    uint256[] memory inputValues = new uint256[](input.length);
    for (uint256 i = 0; i < input.length; i++) {
      inputValues[i] = input[i];
    }
    if (verify(inputValues, proof) == 0) {
      return true;
    } else {
      return false;
    }
  }
}

//                                                                        ,-,
//                            *                      .                   /.(              .
//                                       \|/                             \ {
//    .                 _    .  ,   .    -*-       .                      `-`
//     ,'-.         *  / \_ *  / \_      /|\         *   /\'__        *.                 *
//    (____".         /    \  /    \,     __      .    _/  /  \  * .               .
//               .   /\/\  /\/ :' __ \_  /  \       _^/  ^/    `—./\    /\   .
//   *       _      /    \/  \  _/  \-‘\/  ` \ /\  /.' ^_   \_   .’\\  /_/\           ,'-.
//          /_\   /\  .-   `. \/     \ /.     /  \ ;.  _/ \ -. `_/   \/.   \   _     (____".    *
//     .   /   \ /  `-.__ ^   / .-'.--\      -    \/  _ `--./ .-'  `-/.     \ / \             .
//        /     /.       `.  / /       `.   /   `  .-'      '-._ `._         /.  \
// ~._,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'
// ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~~
// ~~    ~~~~    ~~~~     ~~~~   ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~
//     ~~     ~~      ~~      ~~      ~~      ~~      ~~      ~~       ~~     ~~      ~~      ~~
//                          ๐
//                                                                              _
//                                                  ₒ                         ><_>
//                                  _______     __      _______
//          .-'                    |   _  "\   |" \    /" _   "|                               ๐
//     '--./ /     _.---.          (. |_)  :)  ||  |  (: ( \___)
//     '-,  (__..-`       \        |:     \/   |:  |   \/ \
//        \          .     |       (|  _  \\   |.  |   //  \ ___
//         `,.__.   ,__.--/        |: |_)  :)  |\  |   (:   _(  _|
//           '._/_.'___.-`         (_______/   |__\|    \_______)                 ๐
//
//                  __   __  ___   __    __         __       ___         _______
//                 |"  |/  \|  "| /" |  | "\       /""\     |"  |       /"     "|
//      ๐          |'  /    \:  |(:  (__)  :)     /    \    ||  |      (: ______)
//                 |: /'        | \/      \/     /' /\  \   |:  |   ₒ   \/    |
//                  \//  /\'    | //  __  \\    //  __'  \   \  |___    // ___)_
//                  /   /  \\   |(:  (  )  :)  /   /  \\  \ ( \_|:  \  (:      "|
//                 |___/    \___| \__|  |__/  (___/    \___) \_______)  \_______)
//                                                                                     ₒ৹
//                          ___             __       _______     ________
//         _               |"  |     ₒ     /""\     |   _  "\   /"       )
//       ><_>              ||  |          /    \    (. |_)  :) (:   \___/
//                         |:  |         /' /\  \   |:     \/   \___  \
//                          \  |___     //  __'  \  (|  _  \\    __/  \\          \_____)\_____
//                         ( \_|:  \   /   /  \\  \ |: |_)  :)  /" \   :)         /--v____ __`<
//                          \_______) (___/    \___)(_______/  (_______/                  )/
//                                                                                        '
//
//            ๐                          .    '    ,                                           ₒ
//                         ₒ               _______
//                                 ____  .`_|___|_`.  ____
//                                        \ \   / /                        ₒ৹
//                                          \ ' /                         ๐
//   ₒ                                        \/
//                                   ₒ     /      \       )                                 (
//           (   ₒ৹               (                      (                                  )
//            )                   )               _      )                )                (
//           (        )          (       (      ><_>    (       (        (                  )
//     )      )      (     (      )       )              )       )        )         )      (
//    (      (        )     )    (       (              (       (        (         (        )
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Versioned {
  string public version;

  constructor(string memory _version) {
    version = _version;
  }
}