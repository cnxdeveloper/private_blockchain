
var Test = require('../config/testConfig.js');
var web3 = require('web3')
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

    var config;
    before('setup contract', async () => {
        config = await Test.Config(accounts);
        await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
    });

    /****************************************************************************************/
    /* Operations and Settings                                                              */
    /****************************************************************************************/

    it(`(multiparty) has correct initial isOperational() value`, async function () {

        // Get operating status
        let status = await config.flightSuretyData.isOperational.call();
        assert.equal(status, true, "Incorrect initial operating status value");

    });

    it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

        // Ensure that access is denied for non-Contract Owner account
        let accessDenied = false;
        try {
            await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
        }
        catch (e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

        // Ensure that access is allowed for Contract Owner account
        let accessDenied = false;
        try {
            await config.flightSuretyData.setOperatingStatus(false);
        }
        catch (e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

    });

    it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

        await config.flightSuretyData.setOperatingStatus(false);

        let reverted = false;
        try {
            await config.flightSurety.setTestingMode(true);
        }
        catch (e) {
            reverted = true;
        }
        assert.equal(reverted, true, "Access not blocked for requireIsOperational");

        // Set it back for other tests to work
        await config.flightSuretyData.setOperatingStatus(true);

    });

    it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

        let error;
        try {
            await config.flightSuretyApp.registerAirline("CNXAIRLINE", config.firstAirline, { from: config.owner });
        }
        catch (e) {
            error = e;
        }
        let result = await config.flightSuretyData.isAirlineRegistered.call(config.firstAirline);
        assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

    });

    it('(airline) can be funded with 10 or more ether only', async () => {
        let fee = web3.utils.toWei('20', 'ether')
        try {
            await config.flightSuretyApp.fundAirline(config.owner, { from: config.owner, value: fee });
        }
        catch (e) {
            console.log(e);
        }
        let result = await config.flightSuretyData.isAirlineFunded.call(config.owner);
        assert.equal(result, true, "Airline should be funded");
    });

    it('Funded Airline can register other airline', async () => {
        
        try {
            await config.flightSuretyApp.registerAirline("CNXAIRLINE", config.secondAirline, { from: config.owner });
        }
        catch (e) {
            console.log(e);
        }
        let result = await config.flightSuretyData.isAirlineRegistered.call(config.secondAirline);
        assert.equal(result, true, "Second airline should be registered");
    });

    it('(insurence) Pessanger purchase insurence paying 1 ether max', async () => {

        const insuranceAmount = web3.utils.toWei('0.5', "ether");
        const flightName = "Third Air";
        const thirdAirline = config.testAddresses[3];
        const timeStamp = 1630021956;
        const passengerAddress = config.testAddresses[8];
        let error;
        try {
            await config.flightSuretyApp.buy(flightName, thirdAirline, timeStamp, { from: passengerAddress, value: insuranceAmount });
        }
        catch (e) {
            error = e;
        }
        assert.notEqual(error, undefined, "Passenger should be able to buy an insurance.")
    });
});
