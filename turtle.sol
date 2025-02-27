// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "./IERC20.sol";

contract Turtle is IERC20 {
    uint256 private _totalSupply;
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;
    string private _name = "turtle token";
    string private _symbol = "TURTLE";
    uint8 private _decimals = 18;

    uint256 constant public Free_MAX_Miner = 1000*10000;
    uint256 constant public MAX_Miner = 100*10000;
    uint256 constant public Total_Coin_Num = 2100_000_000 * (10**18);
    uint256 constant public Init_Day_Coin_Produce = 2876712 * (10**18);
    uint256 constant public Miner_Base_Price = 1 * (10**16);
    uint256 constant public Miner_Free_POWER = 100;
    uint256 constant public Miner_Base_POWER = 10000;
    uint256 constant public Day_Time = 24*3600;
    uint256 constant public Year_Time =365*24*3600;
    uint256 private day_coin_produce;
    uint256 private current_epoch;
    uint256 private current_miner_id;
    uint256 private init_time;
    uint256 private free_miner_num;
    uint256 private miner1_num;
    uint256 private miner2_num;
    uint256 private miner3_num;
    uint256 private miner4_num;
    uint256 private miner5_num;
    address private receiver; 

    mapping (address => uint256) private Miner0;
    mapping (address => uint256) private Miner1;
    mapping (address => uint256) private Miner2;
    mapping (address => uint256) private Miner3;
    mapping (address => uint256) private Miner4;
    mapping (address => uint256) private Miner5;

    struct EpochInfo{
        uint256 start_time;
        uint256 coin_num;
        uint256 total_power;
    }

    struct MinerInfo{
        uint256 start_time;
        uint256 mine_coin;
        uint256 current_epoch;
        uint8 types;
        address owner;
    }

    mapping (uint256 => EpochInfo) private epochinfos;
    mapping (uint256 => MinerInfo) private minerinfos;

    constructor(address _recev) {   
        receiver = _recev;
        init_time = block.timestamp;
        day_coin_produce = Init_Day_Coin_Produce;
        current_epoch = 1;
        epochinfos[1].start_time = block.timestamp;
        epochinfos[1].coin_num = day_coin_produce;
        epochinfos[1].total_power = 0;
        current_miner_id = 0;
        _totalSupply = 0;
    }

    function mint_free_miner() public {
        require(Miner0[msg.sender] < 1, 'already mint');
        require(free_miner_num < Free_MAX_Miner, 'free miner exceed');
        current_miner_id = current_miner_id + 1;
        free_miner_num = free_miner_num + 1;
        Miner0[msg.sender] = current_miner_id;
        start_miner(current_miner_id, msg.sender, 0);
    }

    function mint_Miner(uint8 _types) public payable{
        require((_types < 6) && (_types > 0), 'types not allow');

        require(msg.value >= Miner_Base_Price*_types, "not enough pay");
        (bool success, ) = (receiver).call{value: msg.value}("");
        if(!success){
            revert('call failed');
        }

        if(_types == 1){
            require(Miner1[msg.sender] < 1, 'already mint');
            require(miner1_num < MAX_Miner, 'miner num exceed');
            miner1_num += 1;
            current_miner_id = current_miner_id + 1;
            Miner1[msg.sender] = current_miner_id;
        }else if(_types == 2){
            require(Miner2[msg.sender] < 1, 'already mint');
            require(miner2_num < MAX_Miner, 'miner num exceed');
            miner2_num += 1;
            current_miner_id = current_miner_id + 1;
            Miner2[msg.sender] = current_miner_id;
        }else if(_types == 3){
            require(Miner3[msg.sender] < 1, 'already mint');
            require(miner3_num < MAX_Miner, 'miner num exceed');
            miner3_num += 1;
            current_miner_id = current_miner_id + 1;
            Miner3[msg.sender] = current_miner_id;
        }else if(_types == 4){
            require(Miner4[msg.sender] < 1, 'already mint');
            require(miner4_num < MAX_Miner, 'miner num exceed');
            miner4_num += 1;
            current_miner_id = current_miner_id + 1;
            Miner4[msg.sender] = current_miner_id;
        }else if(_types == 5){
            require(Miner5[msg.sender] < 1, 'already mint');
            require(miner5_num < MAX_Miner, 'miner num exceed');
            miner5_num += 1;
            current_miner_id = current_miner_id + 1;
            Miner5[msg.sender] = current_miner_id;
        }
        
        start_miner(current_miner_id, msg.sender, _types);
    }

    function start_miner(uint256 _miner_id, address _addr, uint8 _types) private {
        minerinfos[_miner_id].owner = _addr;
        minerinfos[_miner_id].start_time = block.timestamp;
        minerinfos[_miner_id].mine_coin = 0;
        minerinfos[_miner_id].types = _types;
        //check current epoch time
        if((epochinfos[current_epoch].start_time + Day_Time) <= block.timestamp){
            current_epoch = current_epoch + 1;
            epochinfos[current_epoch].start_time = block.timestamp;
            deal_day_coin_produce();
            epochinfos[current_epoch].coin_num = day_coin_produce;
            if(_types == 0){
                epochinfos[current_epoch].total_power = Miner_Free_POWER;
            }else{
                epochinfos[current_epoch].total_power = Miner_Base_POWER * _types;
            }
            
        }else{
            if(_types == 0){
                epochinfos[current_epoch].total_power += Miner_Free_POWER;
            }else{
                epochinfos[current_epoch].total_power += Miner_Base_POWER * _types;
            }
        }
        minerinfos[_miner_id].current_epoch = current_epoch;
    }

    function deal_day_coin_produce() private {
        uint256 passed_year = (block.timestamp - init_time) / Year_Time;
        if(passed_year > 0){
            day_coin_produce = Init_Day_Coin_Produce/(2**passed_year);
        }  
    }

    function claim_and_continue(uint256 _miner_id, uint256 _provide_time, uint256 _nonce) public {
        require(_miner_id > 0, 'miner id not allow');
        require(minerinfos[_miner_id].owner == msg.sender, 'not owner');
        require(block.timestamp > (minerinfos[_miner_id].start_time + Day_Time), 'time not allow');
        require((block.timestamp >= _provide_time) && (block.timestamp < (_provide_time + 10*3600)), 'provide time not allow');
        bytes32 hashbyte = keccak256(abi.encodePacked(_provide_time, _nonce, msg.sender));
        bytes1 firstBytes = bytes1(hashbyte);
        require(uint8(firstBytes) == 0, 'pow not pass');
        // calculate 
        uint256 _mine_epoch = minerinfos[_miner_id].current_epoch;
        uint8 _mine_types = minerinfos[_miner_id].types;
        require(epochinfos[_mine_epoch].total_power > 0, 'total power error');
        uint256 _mine_coin = 0;
        if(_mine_types == 0){
            _mine_coin = (epochinfos[_mine_epoch].coin_num * Miner_Free_POWER) / epochinfos[_mine_epoch].total_power;
        }else{
            _mine_coin = (epochinfos[_mine_epoch].coin_num * Miner_Base_POWER * _mine_types) / epochinfos[_mine_epoch].total_power;
        }
        
        minerinfos[_miner_id].mine_coin += _mine_coin;
        //claim coin 
        require(((_totalSupply + _mine_coin) <= Total_Coin_Num), 'amount exceed');
        _mint(msg.sender, _mine_coin);
        continue_mine(_miner_id, _mine_types);
    }

    function continue_mine(uint256 _miner_id, uint8 _types) private {
        //check current epoch time
        if((epochinfos[current_epoch].start_time + Day_Time) <= block.timestamp){
            current_epoch = current_epoch + 1;
            epochinfos[current_epoch].start_time = block.timestamp;
            deal_day_coin_produce();
            epochinfos[current_epoch].coin_num = day_coin_produce;
            if(_types == 0){
                epochinfos[current_epoch].total_power = Miner_Free_POWER;
            }else{
                epochinfos[current_epoch].total_power = Miner_Base_POWER * _types;
            }
            
        }else{
            if(_types == 0){
                epochinfos[current_epoch].total_power += Miner_Free_POWER;
            }else{
                epochinfos[current_epoch].total_power += Miner_Base_POWER * _types;
            }
            
        }
        minerinfos[_miner_id].current_epoch = current_epoch;
        minerinfos[_miner_id].start_time = block.timestamp;
    }

    function getInitInfo() public view returns(uint256, uint256, EpochInfo memory, uint256[6] memory) {
        return (current_epoch, current_miner_id, epochinfos[current_epoch], [free_miner_num, miner1_num, miner2_num, miner3_num, miner4_num, miner5_num]);
    }

    function getInfo(address _addr) public view returns(uint256[6] memory, MinerInfo[6] memory, EpochInfo[6] memory, uint256[5] memory){
        uint256 my_miner0_id = Miner0[_addr];
        uint256 my_miner1_id = Miner1[_addr];
        uint256 my_miner2_id = Miner2[_addr];
        uint256 my_miner3_id = Miner3[_addr];
        uint256 my_miner4_id = Miner4[_addr];
        uint256 my_miner5_id = Miner5[_addr];

        return([my_miner0_id, my_miner1_id, my_miner2_id, my_miner3_id, my_miner4_id, my_miner5_id], [minerinfos[my_miner0_id], minerinfos[my_miner1_id], minerinfos[my_miner2_id], minerinfos[my_miner3_id], minerinfos[my_miner4_id], minerinfos[my_miner5_id]], [epochinfos[minerinfos[my_miner0_id].current_epoch], epochinfos[minerinfos[my_miner1_id].current_epoch], epochinfos[minerinfos[my_miner2_id].current_epoch], epochinfos[minerinfos[my_miner3_id].current_epoch], epochinfos[minerinfos[my_miner4_id].current_epoch], epochinfos[minerinfos[my_miner5_id].current_epoch]], [current_epoch, current_miner_id, epochinfos[current_epoch].start_time, epochinfos[current_epoch].coin_num, epochinfos[current_epoch].total_power]);
    }

    function get_blocktime() public view returns(uint256){
        return block.timestamp;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) external view returns (uint256){
        return _balanceOf[account];
    }

    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(block.timestamp > init_time + Year_Time, 'time not allow');
        require(_balanceOf[msg.sender] >= amount, 'amount exceed');
        _balanceOf[msg.sender] -= amount;
        _balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance[owner][spender];
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(_allowance[sender][msg.sender] >= amount, 'allow exceed');
        require(_balanceOf[sender] >= amount, 'amount exceed');
        _allowance[sender][msg.sender] -= amount;
        _balanceOf[sender] -= amount;
        _balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address _account, uint256 amount) private {
        _balanceOf[_account] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), _account, amount);
    }

    function burn(uint256 amount) external {
        require(_balanceOf[msg.sender] >= amount, 'amount exceed');
        _balanceOf[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
