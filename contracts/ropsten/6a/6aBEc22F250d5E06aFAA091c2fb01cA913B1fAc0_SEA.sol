/**
 *Submitted for verification at Etherscan.io on 2022-07-15
 */
//................................................................
//.....SSSSSSSSSSS......EEEEEEEEEEEEEEEEEE........AAAAAAAA........
//....SSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEEE........AAAAAAAA........
//...SSSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEEE.......AAAAAAAAA........
//...SSSSSSSSSSSSSSSS...EEEEEEEEEEEEEEEEEE.......AAAAAAAAAA.......
//..SSSSSSSS.SSSSSSSS...EEEEEE...................AAAAAAAAAA.......
//..SSSSSS.....SSSSSS...EEEEEE..................AAAAAAAAAAA.......
//..SSSSSSS.............EEEEEE..................AAAAAAAAAAAA......
//..SSSSSSSSS...........EEEEEE.................AAAAAA.AAAAAA......
//..SSSSSSSSSSSS........EEEEEE.................AAAAAA.AAAAAA......
//...SSSSSSSSSSSSSS.....EEEEEEEEEEEEEEEEE......AAAAAA..AAAAAA.....
//....SSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEE.....AAAAAA...AAAAAA.....
//.....SSSSSSSSSSSSSS...EEEEEEEEEEEEEEEEE.....AAAAAA...AAAAAAA....
//.......SSSSSSSSSSSSS..EEEEEEEEEEEEEEEEE.....AAAAAA....AAAAAA....
//...........SSSSSSSSS..EEEEEE...............AAAAAAAAAAAAAAAAA....
//.............SSSSSSS..EEEEEE...............AAAAAAAAAAAAAAAAAA...
//.SSSSSS.......SSSSSS..EEEEEE...............AAAAAAAAAAAAAAAAAA...
//..SSSSSS......SSSSSS..EEEEEE..............AAAAAAAAAAAAAAAAAAA...
//..SSSSSSSS..SSSSSSSS..EEEEEE..............AAAAAA.......AAAAAAA..
//..SSSSSSSSSSSSSSSSSS..EEEEEEEEEEEEEEEEEE.AAAAAA.........AAAAAA..
//...SSSSSSSSSSSSSSSS...EEEEEEEEEEEEEEEEEE.AAAAAA.........AAAAAA..
//....SSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEEE.AAAAAA.........AAAAAA..
//.....SSSSSSSSSSSS.....EEEEEEEEEEEEEEEEEE.AAAAA...........AAAAA..
//................................................................

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}

contract SEA {
    IERC20 public usdt = IERC20(0x1cC415f549Ab7Db5Df83f3c016EeCBde1De77118);

    address public admin = 0x41117dE328eb851F29941c8689c50851E3a82154;
    address public registerer = 0x41117dE328eb851F29941c8689c50851E3a82154;
    address public BOT_A = 0x2DA9ddb3e1797C082c056f423b31a26078F7F7F9;
    address public BOT_B = 0x16443B371cCF28B6078Aea650d8619D046523E07;
    address public companyWallet = 0x32A79BeBa092acE07A7932Eda026ee7857017A31;

    uint256 public totalUsers;
    uint256 public registrationFee1;
    uint256 public registrationFee2;

    mapping(address => User) public user;
    mapping(address => Register) public registered;
    mapping(address => bool) public isAuthorized;
    mapping(address => uint256) public approvedAmount;
    mapping(address => bool) public paid;

    mapping(string => uint256) public plan;
    string[] plannames;

    struct Register {
        string name;
        address UserAddress;
        bool alreadyExists;
    }

    struct User {
        string name;
        address userAddress;
        uint256 amountDeposit;
    }
    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender] == true, "Not an Authorized");
        _;
    }
    modifier onlyRegisterer() {
        require(msg.sender == registerer, "Not an Authorized");
        _;
    }
    event Deposit(address user, uint256 amount);

    constructor(
        // address _admin,
        // address _registerer,
        // address _usdt,
        // address _BOT_A,
        // address _BOT_B,
        // address _Company
    ) {
        // admin = _admin;
        // registerer = _registerer;
        isAuthorized[admin] = true;
        isAuthorized[registerer] = true;
        // BOT_A = _BOT_A;
        // BOT_B = _BOT_B;
        // companyWallet = _Company;
        // usdt = IERC20(_usdt);
        registrationFee1 = 45 * 10**usdt.decimals();
        registrationFee2 = 27 * 10**usdt.decimals();
    }

    function register(string memory _name, address users)
        public
        onlyRegisterer
    {
        require(!registered[users].alreadyExists, "User already registered");
        registered[users].name = _name;
        registered[users].UserAddress = users;
        registered[users].alreadyExists = true;
    }

    function addRegisterData(string memory _name, address users)
        public
        onlyAuthorized
    {
        require(registered[users].alreadyExists, "User not registered");
        registered[users].name = _name;
        registered[users].UserAddress = users;
    }

    function updateRegisterData2(
        string memory _name,
        address oldUser,
        address newUser
    ) public onlyAuthorized {
        require(registered[oldUser].alreadyExists, "User not registered");
        require(!registered[newUser].alreadyExists, "User already registered");
        registered[newUser].name = _name;
        registered[newUser].UserAddress = newUser;
        user[newUser] = user[oldUser];
        approvedAmount[newUser] = approvedAmount[oldUser];
        isAuthorized[newUser] = isAuthorized[oldUser];
        paid[newUser] = paid[oldUser];
        delete registered[oldUser];
        delete user[oldUser];
        delete approvedAmount[oldUser];
        delete isAuthorized[oldUser];
        delete paid[oldUser];
    }

    function DeletRegisterData(address users) public onlyAuthorized {
        delete registered[users];
    }

    function deposit(
        uint256 amount,
        string memory _name,
        string memory _planname
    ) public {
        require(plan[_planname] > 0, "plan not found");
        require(amount >= 0, "amount should be more than 0");
        require(
            amount == plan[_planname] * (10**usdt.decimals()),
            "amount should be according to the plan"
        );
        require(registered[msg.sender].alreadyExists, "User not registered");
        uint256 trasnferamount;
        if (!paid[msg.sender]) {
            trasnferamount = registrationFee1;
            paid[msg.sender] = true;
        } else {
            trasnferamount = registrationFee2;
        }
        usdt.transferFrom(msg.sender, BOT_A, amount);
        usdt.transferFrom(msg.sender, companyWallet, trasnferamount);

        user[msg.sender].name = _name;
        user[msg.sender].userAddress = msg.sender;
        user[msg.sender].amountDeposit =
            user[msg.sender].amountDeposit +
            (amount);
        emit Deposit(msg.sender, amount);
    }

    function AuthorizeUser(address _user, bool _state) public {
        require(admin == msg.sender, "Only admin can authorize user");
        isAuthorized[_user] = _state;
    }

    function distribute(address[] memory recivers, uint256[] memory amount)
        public
        onlyAuthorized
    {
        require(recivers.length == amount.length, "unMatched Data");

        for (uint256 i; i < recivers.length; i++) {
            require(
                registered[recivers[i]].alreadyExists,
                "User not registered"
            );
            approvedAmount[recivers[i]] += amount[i]; 
        }
    }

    function claim() public {
        require(approvedAmount[msg.sender] > 0, "not authorized");
        uint256 amount = approvedAmount[msg.sender];
        usdt.transfer( msg.sender, amount);
        approvedAmount[msg.sender] = 0;
    }

    function changeAdmin(address newAdmin) public {
        require(msg.sender == admin, "Not an admin");
        admin = newAdmin;
    }

    function changeToken(address newToken) public onlyAuthorized {
        usdt = IERC20(newToken);
    }

    function changeBOT_A(address newBOT_A) public onlyAuthorized {
        BOT_A = newBOT_A;
    }

    function changeBOT_B(address newBOT_B) public onlyAuthorized {
        BOT_B = newBOT_B;
    }

    function changeCompanyWallet(address newCompany) public onlyAuthorized {
        companyWallet = newCompany;
    }

    function changeregistrer(address newRegistrar) public onlyAuthorized {
        registerer = newRegistrar;
    }

    function setplan(string calldata _planname, uint256 amount)
        public
        onlyAuthorized
    {
        require(plan[_planname] > 0, "plan not found");
        plan[_planname] = amount;
    }

    function addplan(string calldata _planname, uint256 amount)
        public
        onlyAuthorized
    {
        require(!checkplanexists(_planname), "plan already exists");
        plan[_planname] = amount;
        plannames.push(_planname);
    }

    function changeregiestrationFee1(uint256 amount) public onlyAuthorized {
        registrationFee1 = amount;
    }

    function changeregiestrationFee2(uint256 amount) public onlyAuthorized {
        registrationFee2 = amount;
    }

    function checkplanexists(string memory _planname)
        public
        view
        returns (bool val)
    {
        for (uint256 i = 0; i < plannames.length; i++) {
            if (keccak256(bytes(plannames[i])) == keccak256(bytes(_planname))) {
                return true;
            }
        }
    }

    function getplannames() public view returns (string[] memory names) {
        return plannames;
    }

    function removeplan(string memory _planname) public onlyAuthorized {
        require(checkplanexists(_planname), "plan not found");
        for (uint256 i = 0; i < plannames.length; i++) {
            if (keccak256(bytes(plannames[i])) == keccak256(bytes(_planname))) {
                delete plannames[i];
                delete plan[_planname];
                return;
            }
        }
    }

    function withdrawStukFunds(IERC20 token) public onlyAuthorized {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}