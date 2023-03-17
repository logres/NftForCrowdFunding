// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract CrowdFundingNFT is ERC1155 {

    enum ProjectState {Started, Faid, Fullfilled, FailEnded, SuccessEnded}

    struct Project{
        uint projectId;
        address funder;
        string name;
        string description;
        uint goal;
        uint process;
        ProjectState state;
        uint endTime;
    }

    uint projectCounter;
    Project[] public projects;//id2project
    mapping(address=>uint[]) funder2Projects;

    struct BackRecord{
        uint backRecordId;
        uint project_id;
        address backer;
        uint amount;
    }

    uint public backRecordCounter;
    BackRecord[] backRecords;

    mapping(address=>uint[]) backer2BackRecords;
    mapping(uint=>uint[]) project2backRecords;

    struct NFT {
        uint id;
        uint projectId;
        string tokenURI;
    }

    NFT[] public nfts;
    uint NFTCounter;


    constructor(string memory _name, string memory _symbol) ERC1155("") {}


    function _safeback(address _backer, uint _projectId, uint _donate) internal {
        BackRecord memory br = BackRecord(backRecordCounter, _projectId, _backer, _donate);
        backRecords.push(br);
        backer2BackRecords[_backer].push(br.backRecordId);
        project2backRecords[_projectId].push(br.backRecordId);
        backRecordCounter++;
    }

    function release(string calldata _name, string calldata _description, uint _goal, uint _duringDays) public {
        Project memory p = Project(projectCounter,msg.sender,_name,_description,_goal,0,ProjectState.Started,block.timestamp + (_duringDays * 1 days));
        projects.push(p);
        funder2Projects[msg.sender].push(projectCounter);
        projectCounter++;
    }

    function back(uint _projectId) payable public {
        uint value = msg.value;
        require(_projectId<projectCounter,"UnExist");
        Project storage p = projects[_projectId];
        require(p.state==ProjectState.Started,"Project not active now");
        uint donate = msg.value;
        if (value>p.goal-p.process) {
            donate = p.goal-p.process;
        }
        _safeback(msg.sender, _projectId, donate);
        p.process +=donate;
        if (value>donate){
            payable(msg.sender).transfer(value-donate);
        }
        if (p.process==p.goal){
            p.state = ProjectState.Fullfilled;
            payable(p.funder).transfer(p.goal);
        }
    }

    function releaseNFT(uint _projectId, string calldata _tokenURI) external {
        require(_projectId < projectCounter, "UnExist");
        Project storage p = projects[_projectId];
        require(p.state==ProjectState.Fullfilled, "Not finished CrowdFunding!");

        // Create NFT?
        NFT memory nft = NFT(NFTCounter,_projectId,_tokenURI);
        nfts.push(nft);
        NFTCounter++;
        // Send NFT
        uint[] storage nameList = project2backRecords[_projectId];
        for(uint i=0;i<nameList.length;i++){
            address name = backRecords[nameList[i]].backer;
            _mint(name,nft.id,1,'');
        }
        _mint(p.funder,nft.id,1,'');
    }

}