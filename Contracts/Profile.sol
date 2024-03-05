// SPDX-License-Identifier: UNLICENSED
// This smart contract code is proprietary.
// Unauthorized copying, modification, or distribution is strictly prohibited.
// For licensing inquiries or permissions, contact info@toolblox.net.
pragma solidity ^0.8.20;
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v5.0.1/contracts/access/Ownable.sol";
import "https://raw.githubusercontent.com/Ideevoog/Toolblox.Token/main/Contracts/WorkflowBase.sol";
/*
	Toolblox smart-contract workflow: https://app.toolblox.net/summary/devcoin_profile
*/
contract ProfileWorkflow  is Ownable, WorkflowBase{
	struct Profile {
		uint id;
		uint64 status;
		address owner;
		string name;
		uint64 rating;
		uint64 totalVotes;
		string image;
	}
	bytes32 workFlowAddress = keccak256("devcoin_work_workflow");
	mapping(uint => Profile) public items;
	address public token = 0xb9DbbE09591F5d5d672Dca272f222b4fcb81b71D;
	function _assertOrAssignOwner(Profile memory item) private view {
		address owner = item.owner;
		if (owner != address(0))
		{
			require(_msgSender() == owner, "Invalid Owner");
			return;
		}
		item.owner = _msgSender();
	}
	uint _faucetValue;
	function getFaucetValue() public view returns (uint) {
		return _faucetValue;
	}
	function setFaucetValue(uint faucetValue) public onlyOwner {
		_faucetValue = faucetValue;
	}
	constructor() Ownable(_msgSender()) {
		serviceLocator = IExternalServiceLocator(0xABD5F9cFB2C796Bbd1647023ee2BEA74B23bf672);
	}
	function setOwner(address _newOwner) public {
		transferOwnership(_newOwner);
	}
/*
	Available statuses:
	0 Active
*/
	function _assertStatus(Profile memory item, uint64 status) private pure {
		require(item.status == status, "Cannot run Workflow action; unexpected status");
	}
	function getItem(uint256 id) public view returns (Profile memory) {
		Profile memory item = items[id];
		require(item.id == id, "Cannot find item with given id");
		return item;
	}
	function getLatest(uint256 cnt) public view returns(Profile[] memory) {
		uint256[] memory latestIds = getLatestIds(cnt);
		Profile[] memory latestItems = new Profile[](latestIds.length);
		for (uint256 i = 0; i < latestIds.length; i++) latestItems[i] = items[latestIds[i]];
		return latestItems;
	}
	function getPage(uint256 cursor, uint256 howMany) public view returns(Profile[] memory) {
		uint256[] memory ids = getPageIds(cursor, howMany);
		Profile[] memory result = new Profile[](ids.length);
		for (uint256 i = 0; i < ids.length; i++) result[i] = items[ids[i]];
		return result;
	}
	
	mapping(address => uint) public itemsByOwner;
	function getItemIdByOwner(address owner) public view returns (uint) {
		return itemsByOwner[owner];
	}
	function getItemByOwner(address owner) public view returns (Profile memory) {
		return getItem(getItemIdByOwner(owner));
	}
	function _setItemIdByOwner(Profile memory item, uint id) private {
		if (item.owner == address(0))
		{
			return;
		}
		uint existingItemByOwner = itemsByOwner[item.owner];
		require(
			existingItemByOwner == 0 || existingItemByOwner == item.id,
			"Cannot set Owner. Another item already exist with same value."
		);
		itemsByOwner[item.owner] = id;
	}
	
	mapping(string => uint) public itemsByName;
	function getItemIdByName(string calldata name) public view returns (uint) {
		return itemsByName[name];
	}
	function getItemByName(string calldata name) public view returns (Profile memory) {
		return getItem(getItemIdByName(name));
	}
	function _setItemIdByName(Profile memory item, uint id) private {
		if (bytes(item.name).length == 0)
		{
			return;
		}
		uint existingItemByName = itemsByName[item.name];
		require(
			existingItemByName == 0 || existingItemByName == item.id,
			"Cannot set Name. Another item already exist with same value."
		);
		itemsByName[item.name] = id;
	}
	function getId(uint id) public view returns (uint){
		return getItem(id).id;
	}
	function getStatus(uint id) public view returns (uint64){
		return getItem(id).status;
	}
	function getOwner(uint id) public view returns (address){
		return getItem(id).owner;
	}
	function getName(uint id) public view returns (string memory){
		return getItem(id).name;
	}
	function getRating(uint id) public view returns (uint64){
		return getItem(id).rating;
	}
	function getTotalVotes(uint id) public view returns (uint64){
		return getItem(id).totalVotes;
	}
	function getImage(uint id) public view returns (string memory){
		return getItem(id).image;
	}
/*
	### Transition: 'Create profile'
	This transition creates a new object and puts it into `Active` state.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Name` (Text)
	* `Image` (Image)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Owner` property. If `Owner` property is not yet set then the method caller becomes the objects `Owner`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Image` (Image)
	
	#### Payment Process
	In the end a payment is made.
	A payment in the amount of `Faucet value` is made from workflow to the address specified in the `Owner` property.
*/
	function createProfile(string calldata name,string calldata image) external returns (uint256) {
		uint256 id = _getNextId();
		Profile memory item;
		item.id = id;
		items[id] = item;
		_assertOrAssignOwner(item);
		_setItemIdByName(item, 0);
		_setItemIdByOwner(item, 0);
		item.name = name;
		item.image = image;
		item.status = 0;
		items[id] = item;
		_setItemIdByName(item, id);
		_setItemIdByOwner(item, id);
		emit ItemUpdated(id, item.status);
		if (item.owner != address(0) && getFaucetValue() > 0){
			safeTransferExternal(token, item.owner, getFaucetValue());
		}
		return id;
	}
/*
	### Transition: 'Update profile'
	This transition begins from `Active` and leads to the state `Active`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Profile identifier
	* `Name` (Text)
	* `Image` (Image)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Owner` property. If `Owner` property is not yet set then the method caller becomes the objects `Owner`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Image` (Image)
*/
	function updateProfile(uint256 id,string calldata name,string calldata image) external returns (uint256) {
		Profile memory item = getItem(id);
		_assertOrAssignOwner(item);
		_assertStatus(item, 0);
		_setItemIdByName(item, 0);
		_setItemIdByOwner(item, 0);
		item.name = name;
		item.image = image;
		item.status = 0;
		items[id] = item;
		_setItemIdByName(item, id);
		_setItemIdByOwner(item, id);
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Rate'
	This transition begins from `Active` and leads to the state `Active`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Profile identifier
	* `New rating` (Integer)
	
	#### Access Restrictions
	Access is exclusively provided to the workflow at URL: `devcoin_work_workflow`.
	
	#### Checks and updates
	The following calculations will be done and updated:
	
	* `Total votes` = `Total votes + 1`
	* `Rating` = `( ( Rating * ( Total votes - 1 ) ) + New rating ) / Total votes`
*/
	function rate(uint256 id,uint64 newRating) external returns (uint256) {
		Profile memory item = getItem(id);
		require(_msgSender() == serviceLocator.getService(workFlowAddress), "Only Work flow is allowed to execute");
		_assertStatus(item, 0);
		item.totalVotes = item.totalVotes + 1;
		item.rating = ( ( item.rating * ( item.totalVotes - 1 ) ) + newRating ) / item.totalVotes;
		item.status = 0;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
}