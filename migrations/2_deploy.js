const ArrayUtils = artifacts.require("ArrayUtils");
const Coordinate = artifacts.require("Coordinate");
const Distance = artifacts.require("Distance");
const BytesUtils = artifacts.require("BytesUtils");

const FleetsConfig = artifacts.require("FleetsConfig");
const ExploreConfig = artifacts.require("ExploreConfig");

const Registry = artifacts.require("Registry");
const Explore = artifacts.require("Explore");
const Battle = artifacts.require("Battle");

const Account = artifacts.require("Account");
const AccountProxy = artifacts.require("AccountProxy");
const Fleets = artifacts.require("Fleets");
const FleetsProxy = artifacts.require("FleetsProxy");

module.exports = async function (deployer) {

    //libraries
    await deployer.deploy(ArrayUtils);
    await deployer.deploy(Coordinate);
    await deployer.deploy(Distance);
    await deployer.link(ArrayUtils, Fleets);
    await deployer.link(Coordinate, Fleets);
    await deployer.link(Distance, Fleets);
    await deployer.deploy(BytesUtils);
    await deployer.link(BytesUtils, Battle);

    //registry
    // await deployer.deploy(Registry);
    // const registry = await Registry.deployed();
    const registry = await Registry.at('0xE3B7f2e2Aa898153beeE6Df61eE3b818212a7F47');

    //fleets config
    await deployer.deploy(FleetsConfig, registry.address);
    const fleetsConfig = await FleetsConfig.deployed();
    await registry.setFleetsConfig(fleetsConfig.address);

    //explore config
    await deployer.deploy(ExploreConfig, registry.address);
    const exploreConfig = await ExploreConfig.deployed();
    await registry.setExploreConfig(exploreConfig.address);

    //battle
    await deployer.deploy(Battle, registry.address);
    const battle = await Battle.deployed();
    await registry.setBattle(battle.address);

    //explore
    await deployer.deploy(Explore, registry.address);
    const explore = await Explore.deployed();
    await registry.setExplore(explore.address);

    //account
    await deployer.deploy(AccountProxy, registry.address);
    const accountProxy = await AccountProxy.deployed();
    await deployer.deploy(Account);
    const account = await Account.deployed();
    await accountProxy.setAccount(account.address);
    await registry.setAccount(accountProxy.address);

    //fleets
    await deployer.deploy(FleetsProxy, registry.address);
    const fleetsProxy = await FleetsProxy.deployed();
    await deployer.deploy(Fleets);
    const fleets = await Fleets.deployed();
    await fleetsProxy.setFleets(fleets.address);
    await registry.setFleets(fleetsProxy.address);

};
