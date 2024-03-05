// SPDX-License-Identifier: UNLICENSED
// This smart contract code is proprietary.
// Unauthorized copying, modification, or distribution is strictly prohibited.
// For licensing inquiries or permissions, contact info@toolblox.net.
pragma solidity ^0.8.20;
interface IExternaldevcoin_profile {
	function rate(uint id, uint64 newRating) external returns (uint);
	function getStatus(uint id) external view returns (uint64);
	function getOwner(uint id) external view returns (address);
	function getName(uint id) external view returns (string memory);
	function getRating(uint id) external view returns (uint64);
	function getTotalVotes(uint id) external view returns (uint64);
	function getImage(uint id) external view returns (string memory);
	function getFaucetValue() external view returns (uint);
}
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v5.0.1/contracts/access/Ownable.sol";
import "https://raw.githubusercontent.com/Ideevoog/Toolblox.Token/main/Contracts/WorkflowBase.sol";
/*
	Toolblox smart-contract workflow: https://app.toolblox.net/summary/devcoin_work_workflow
*/
contract WorkWorkflow  is Ownable, WorkflowBase{
	struct Work {
		uint id;
		uint64 status;
		string url;
		string name;
		string description;
		uint rating;
		uint64 totalVotes;
		uint64 remixShare;
		uint price;
		address author;
		uint parentWorkId;
		bool hasRated;
		uint authorId;
	}
	bytes32 workFlowAddress = keccak256("devcoin_work_workflow");
	bytes32 profileFlowAddress = keccak256("devcoin_profile");
	mapping(uint => Work) public items;
	address public token = 0xb9DbbE09591F5d5d672Dca272f222b4fcb81b71D;
	function _assertOrAssignAuthor(Work memory item) private view {
		address author = item.author;
		if (author != address(0))
		{
			require(_msgSender() == author, "Invalid Author");
			return;
		}
		item.author = _msgSender();
	}
	constructor() Ownable(_msgSender()) {
		serviceLocator = IExternalServiceLocator(0xABD5F9cFB2C796Bbd1647023ee2BEA74B23bf672);
	}
	function setOwner(address _newOwner) public {
		transferOwnership(_newOwner);
	}
/*
	Available statuses:
	0 In progress
	1 Auditing
	2 Published
*/
	function _assertStatus(Work memory item, uint64 status) private pure {
		require(item.status == status, "Cannot run Workflow action; unexpected status");
	}
	function getItem(uint256 id) public view returns (Work memory) {
		Work memory item = items[id];
		require(item.id == id, "Cannot find item with given id");
		return item;
	}
	function getLatest(uint256 cnt) public view returns(Work[] memory) {
		uint256[] memory latestIds = getLatestIds(cnt);
		Work[] memory latestItems = new Work[](latestIds.length);
		for (uint256 i = 0; i < latestIds.length; i++) latestItems[i] = items[latestIds[i]];
		return latestItems;
	}
	function getPage(uint256 cursor, uint256 howMany) public view returns(Work[] memory) {
		uint256[] memory ids = getPageIds(cursor, howMany);
		Work[] memory result = new Work[](ids.length);
		for (uint256 i = 0; i < ids.length; i++) result[i] = items[ids[i]];
		return result;
	}
	
	mapping(uint => uint[]) public itemsByParentWorkId;
	function getItemIdsByParentWorkId(uint parentWorkId) public view returns (uint[] memory) {
		return itemsByParentWorkId[parentWorkId];
	}
	function getItemsByParentWorkId(uint parentWorkId) public view returns (Work[] memory) {
		uint[] memory itemIds = getItemIdsByParentWorkId(parentWorkId);
		Work[] memory itemsToReturn = new Work[](itemIds.length);
		for(uint256 i=0; i < itemIds.length; i++){
			itemsToReturn[i] = getItem(itemIds[i]);
		}
		return itemsToReturn;
	}
	function _setItemIdByParentWorkId(uint oldForeignKey, uint newForeignKey, uint id) private {
		// If the old and new foreign keys are the same, no need to do anything
		if(oldForeignKey == newForeignKey) {
			return;
		}
		// If the old foreign key is not 0, remove the item from the old list
		if(oldForeignKey != 0) {
			removeFkMappingItem(itemsByParentWorkId, oldForeignKey, id);
		}
		// If the new foreign key is not 0, add the item to the new list
		if(newForeignKey != 0) {
			addFkMappingItem(itemsByParentWorkId, newForeignKey, id);
		}
	}
	
	mapping(uint => uint[]) public itemsByAuthorId;
	function getItemIdsByAuthorId(uint authorId) public view returns (uint[] memory) {
		return itemsByAuthorId[authorId];
	}
	function getItemsByAuthorId(uint authorId) public view returns (Work[] memory) {
		uint[] memory itemIds = getItemIdsByAuthorId(authorId);
		Work[] memory itemsToReturn = new Work[](itemIds.length);
		for(uint256 i=0; i < itemIds.length; i++){
			itemsToReturn[i] = getItem(itemIds[i]);
		}
		return itemsToReturn;
	}
	function _setItemIdByAuthorId(uint oldForeignKey, uint newForeignKey, uint id) private {
		// If the old and new foreign keys are the same, no need to do anything
		if(oldForeignKey == newForeignKey) {
			return;
		}
		// If the old foreign key is not 0, remove the item from the old list
		if(oldForeignKey != 0) {
			removeFkMappingItem(itemsByAuthorId, oldForeignKey, id);
		}
		// If the new foreign key is not 0, add the item to the new list
		if(newForeignKey != 0) {
			addFkMappingItem(itemsByAuthorId, newForeignKey, id);
		}
	}
	function getId(uint id) public view returns (uint){
		return getItem(id).id;
	}
	function getStatus(uint id) public view returns (uint64){
		return getItem(id).status;
	}
	function getUrl(uint id) public view returns (string memory){
		return getItem(id).url;
	}
	function getName(uint id) public view returns (string memory){
		return getItem(id).name;
	}
	function getDescription(uint id) public view returns (string memory){
		return getItem(id).description;
	}
	function getRating(uint id) public view returns (uint){
		return getItem(id).rating;
	}
	function getTotalVotes(uint id) public view returns (uint64){
		return getItem(id).totalVotes;
	}
	function getRemixShare(uint id) public view returns (uint64){
		return getItem(id).remixShare;
	}
	function getPrice(uint id) public view returns (uint){
		return getItem(id).price;
	}
	function getAuthor(uint id) public view returns (address){
		return getItem(id).author;
	}
	function getParentWorkId(uint id) public view returns (uint){
		return getItem(id).parentWorkId;
	}
	function getHasRated(uint id) public view returns (bool){
		return getItem(id).hasRated;
	}
	function getAuthorId(uint id) public view returns (uint){
		return getItem(id).authorId;
	}
/*
	### Transition: 'Add new'
	This transition creates a new object and puts it into `In progress` state.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Name` (Text)
	* `Description` (Text)
	* `Url` (Text)
	* `Parent Work Id` (Other flow id)
	* `Author Id` (Other flow id)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Author` property. If `Author` property is not yet set then the method caller becomes the objects `Author`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Description` (String)
	* `Url` (String)
	* `Parent Work Id` (Fk)
	* `Author Id` (Fk)
	
	The following checks involving data from other smart-contracts are done next:
	
	* The condition ``Profile Flow Owner == Author`` needs to be true or the following error will be returned: *"Incorrect Author ID"*.
*/
	function addNew(string calldata name,string calldata description,string calldata url,uint parentWorkId,uint authorId) external returns (uint256) {
		uint256 id = _getNextId();
		Work memory item;
		item.id = id;
		items[id] = item;
		_assertOrAssignAuthor(item);
		uint oldParentWorkId = item.parentWorkId;
		uint oldAuthorId = item.authorId;
		item.name = name;
		item.description = description;
		item.url = url;
		item.parentWorkId = parentWorkId;
		item.authorId = authorId;
		IExternaldevcoin_profile profileFlow = IExternaldevcoin_profile(serviceLocator.getService(profileFlowAddress));
		address profileFlowOwner = profileFlow.getOwner(item.authorId);
		require(profileFlowOwner == item.author, "Incorrect Author ID");
		item.status = 0;
		items[id] = item;
		uint newParentWorkId = item.parentWorkId;
		_setItemIdByParentWorkId(oldParentWorkId, newParentWorkId, item.id);
		uint newAuthorId = item.authorId;
		_setItemIdByAuthorId(oldAuthorId, newAuthorId, item.id);
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Submit for audit'
	This transition begins from `In progress` and leads to the state `Auditing`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Work identifier
	* `Url` (Text)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Author` property. If `Author` property is not yet set then the method caller becomes the objects `Author`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Url` (String)
*/
	function submitForAudit(uint256 id,string calldata url) external returns (uint256) {
		Work memory item = getItem(id);
		_assertOrAssignAuthor(item);
		_assertStatus(item, 0);
		item.url = url;
		item.status = 1;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Direct publish'
	This transition begins from `In progress` and leads to the state `Published`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Work identifier
	* `Price` (Money)
	* `Remix share` (Integer)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Author` property. If `Author` property is not yet set then the method caller becomes the objects `Author`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Price` (Money)
	* `Remix share` (Integer)
*/
	function directPublish(uint256 id,uint price,uint64 remixShare) external returns (uint256) {
		Work memory item = getItem(id);
		_assertOrAssignAuthor(item);
		_assertStatus(item, 0);
		item.price = price;
		item.remixShare = remixShare;
		item.status = 2;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Rate'
	This transition begins from `Published` and leads to the state `Published`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Work identifier
	* `New rating` (Integer)
	
	#### Access Restrictions
	Access is exclusively provided to the workflow at URL: `devcoin_work_workflow`.
	
	#### Checks and updates
	The following calculations will be done and updated:
	
	* `Rating` = `( ( Rating * Total votes ) + New rating ) / ( Total votes + 1 )`
	* `Total votes` = `Total votes + 1`
	
	#### External Method Calls
	This transition involves a call to an external method in the `DevCoin Profile` workflow through the `Rate` transition on the `Testnet` blockchain.
*/
	function rate(uint256 id,uint64 newRating) internal returns (uint256) {
		Work memory item = getItem(id);
		_assertStatus(item, 2);
		item.rating = ( ( item.rating * item.totalVotes ) + newRating ) / ( item.totalVotes + 1 );
		item.totalVotes = item.totalVotes + 1;
		IExternaldevcoin_profile profileFlow = IExternaldevcoin_profile(serviceLocator.getService(profileFlowAddress));
		item.status = 2;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		profileFlow.rate(item.authorId, newRating);
		return id;
	}
/*
	### Transition: 'Retract'
	This transition begins from `Published` and leads to the state `In progress`.
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Author` property. If `Author` property is not yet set then the method caller becomes the objects `Author`.
*/
	function retract(uint256 id) external returns (uint256) {
		Work memory item = getItem(id);
		_assertOrAssignAuthor(item);
		_assertStatus(item, 2);

		item.status = 0;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Update code'
	This transition begins from `Auditing` and leads to the state `Auditing`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Work identifier
	* `Name` (Text)
	* `Description` (Text)
	* `Url` (Text)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Author` property. If `Author` property is not yet set then the method caller becomes the objects `Author`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Description` (String)
	* `Url` (String)
*/
	function updateCode(uint256 id,string calldata name,string calldata description,string calldata url) external returns (uint256) {
		Work memory item = getItem(id);
		_assertOrAssignAuthor(item);
		_assertStatus(item, 1);
		item.name = name;
		item.description = description;
		item.url = url;
		item.status = 1;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Update work'
	This transition begins from `In progress` and leads to the state `In progress`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Work identifier
	* `Name` (Text)
	* `Description` (Text)
	* `Url` (Text)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Author` property. If `Author` property is not yet set then the method caller becomes the objects `Author`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Description` (String)
	* `Url` (String)
*/
	function updateWork(uint256 id,string calldata name,string calldata description,string calldata url) external returns (uint256) {
		Work memory item = getItem(id);
		_assertOrAssignAuthor(item);
		_assertStatus(item, 0);
		item.name = name;
		item.description = description;
		item.url = url;
		item.status = 0;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Publish'
	This transition begins from `Auditing` and leads to the state `Published`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Work identifier
	* `Price` (Money)
	* `Remix share` (Integer)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Author` property. If `Author` property is not yet set then the method caller becomes the objects `Author`.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Price` (Money)
	* `Remix share` (Integer)
*/
	function publish(uint256 id,uint price,uint64 remixShare) external returns (uint256) {
		Work memory item = getItem(id);
		_assertOrAssignAuthor(item);
		_assertStatus(item, 1);
		item.price = price;
		item.remixShare = remixShare;
		item.status = 2;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Rate parent'
	#### Notes
	
	Rate how easy it was to use the work this work is based on. Please give a rating between 1-5
	This transition begins from `Published` and leads to the state `Published`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Work identifier
	* `New rating` (Integer)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Author` property. If `Author` property is not yet set then the method caller becomes the objects `Author`.
	
	#### Checks and updates
	The following checks are done before any changes take place:
	
	* The condition ``Has rated == False`` needs to be true or the following error will be returned: *"Has already rated"*.
	* The condition ``( New rating >= 1 ) && ( New rating <= 5 )`` needs to be true or the following error will be returned: *"Rating needs to be 1-5"*.
	
	The following calculations will be done and updated:
	
	* `Has rated` = `True`
	
	#### External Method Calls
	This transition involves a call to an external method in the `DevCoin Work Workflow` workflow through the `Rate` transition on the `Testnet` blockchain.
*/
	function rateParent(uint256 id,uint64 newRating) external returns (uint256) {
		Work memory item = getItem(id);
		_assertOrAssignAuthor(item);
		_assertStatus(item, 2);
		require(item.hasRated == false, "Has already rated");
		require(( newRating >= 1 ) && ( newRating <= 5 ), "Rating needs to be 1-5");
		item.hasRated = true;
		item.status = 2;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		rate(item.parentWorkId, newRating);
		return id;
	}
/*
	### Transition: 'Pay'
	This transition begins from `Published` and leads to the state `Published`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Work identifier
	* `Payment` (Money)
	
	#### Access Restrictions
	Access is exclusively provided to the workflow at URL: `devcoin_work_workflow`.
	
	#### Checks and updates
	The following calculations involving data from other smart-contracts will be done next:
	
	*  `Parent payment` = `( Payment * Work Flow Remix share ) / 100`
	*  `Self payment` = `Payment - Parent payment`
	
	#### External Method Calls
	This transition involves a call to an external method in the `DevCoin Work Workflow` workflow through the `Pay` transition on the `Testnet` blockchain.
	The call will **only** be done if the following is true: `( Parent Work Id > 0 ) && ( Parent payment > 0 )`.
	
	#### Payment Process
	In the end a payment is made.
	A payment in the amount of `Self payment` is made from caller to the address specified in the `Author` property.
*/
	function pay(uint256 id,uint payment) internal returns (uint256) {
		Work memory item = getItem(id);
		_assertStatus(item, 2);
		uint64 workFlowRemixShare = getRemixShare(item.parentWorkId);
		uint parentPayment = ( payment * workFlowRemixShare ) / 100;
		uint selfPayment = payment - parentPayment;
		item.status = 2;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		if (( ( item.parentWorkId > 0 ) && ( parentPayment > 0 ) )){
				pay(item.parentWorkId, parentPayment);
		}
		if (item.author != address(0) && selfPayment > 0){
			safeTransferFromExternal(token, _msgSender(), item.author, selfPayment);
		}
		return id;
	}
/*
	### Transition: 'Purchase'
	This transition begins from `Published` and leads to the state `Published`.
	
	First, an allowance in the amount of `Price` is approved to the workflow.
	
	#### External Method Calls
	This transition involves a call to an external method in the `DevCoin Work Workflow` workflow through the `Pay` transition on the `Testnet` blockchain.
*/
	function purchase(uint256 id) external returns (uint256) {
		Work memory item = getItem(id);
		_assertStatus(item, 2);

		item.status = 2;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		pay(item.id, item.price);
		return id;
	}
}